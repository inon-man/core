import * as net from "net";
import * as fs from "fs";
import { randomBytes } from "crypto";
import {
  LCDClient,
  MnemonicKey,
  MsgAggregateExchangeRateVote,
} from "@classic-terra/terra.js";
import { parse } from "toml";
import * as ms from "ms"

const {
  MAINNET_LCD_URL = "https://lcd.terra-classic.hexxagon.io",
  MAINNET_CHAIN_ID = "columbus-5",
  TESTNET_LCD_URL = "http://localhost:1317",
  TESTNET_CHAIN_ID = "localterra",
  MNEMONIC = "satisfy adjust timber high purchase tuition stool faith fine install that you unaware feed domain license impose boss human eager hat rent enjoy dawn",
  CONFIG_PATH = "config.toml",
} = process.env;

let timeoutCommit = ms("5s"); // default 5s

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function checkConnection(host: string, port: number, timeout = 10000) {
  return new Promise(function (resolve, reject) {
    timeout = timeout || 10000; // default of 10 seconds
    var timer = setTimeout(function () {
      reject("timeout");
      socket.end();
    }, timeout);
    var socket = net.createConnection(port, host, function () {
      clearTimeout(timer);
      resolve("");
      socket.end();
    });
    socket.on("error", function (err) {
      clearTimeout(timer);
      reject(err);
    });
  });
}

async function waitForFirstBlock(client: LCDClient) {
  let shouldTerminate = false;

  console.info("waiting for connectivity");

  const [_, host, port] = /https?:\/\/([a-zA-Z0-9][a-zA-Z0-9\.-]+)\:(\d+)/.exec(
    TESTNET_LCD_URL
  );

  while (await checkConnection(host, +port).catch(err => err));

  console.info("waiting for first block");

  while (!shouldTerminate) {
    await delay(timeoutCommit);
    shouldTerminate = await client.tendermint
      .blockInfo()
      .then(async (blockInfo) => {

        if (blockInfo?.block) {
          return +blockInfo.block?.header.height > 0;
        }

        return false;
      })
      .catch(async (err) => {
        console.error(err);
        await delay(timeoutCommit);
        return false;
      });

    if (shouldTerminate) {
      break;
    }
  }
}

const mainnetClient = new LCDClient({
  URL: MAINNET_LCD_URL,
  chainID: MAINNET_CHAIN_ID,
  isClassic: true,
});

const testnetClient = new LCDClient({
  URL: TESTNET_LCD_URL,
  chainID: TESTNET_CHAIN_ID,
  // gasPrices: "",
  // gasAdjustment: 1.4,
  isClassic: true,
});

const mk = new MnemonicKey({
  mnemonic: MNEMONIC,
});

const wallet = testnetClient.wallet(mk);

async function loop() {
  let lastSuccessVotePeriod: number;
  let lastSuccessVoteMsg: MsgAggregateExchangeRateVote;

  // to get initial rates and params
  let [rates, oracleParams] = await Promise.all([
    mainnetClient.oracle.exchangeRates(),
    testnetClient.oracle.parameters(),
  ]);

  setInterval(async () => {
    try {
      [rates, oracleParams] = await Promise.all([
        mainnetClient.oracle.exchangeRates(),
        testnetClient.oracle.parameters(),
      ]);
    } catch (e) { }
  }, 10000);  // 5s -> 10s: to avoid rate limit

  while (true) {
    const latestBlock = await testnetClient.tendermint.blockInfo();

    const oracleVotePeriod = oracleParams.vote_period;
    const currentBlockHeight = parseInt(latestBlock.block.header.height, 10);
    const currentVotePeriod = Math.floor(currentBlockHeight / oracleVotePeriod);
    const indexInVotePeriod = currentBlockHeight % oracleVotePeriod;
    if (
      (lastSuccessVotePeriod && (lastSuccessVotePeriod === currentVotePeriod)) ||
      (indexInVotePeriod >= oracleVotePeriod - 1)
    ) {
      await delay(timeoutCommit);
      continue;
    }

    const coins = rates
      .filter(
        (coin) =>
          oracleParams.whitelist.findIndex((o) => o.name === coin.denom) !== -1
      )
      .toArray()
      .map((r) => `${r.amount}${r.denom}`)
      .join(",");

    const voteMsg = new MsgAggregateExchangeRateVote(
      coins,
      randomBytes(2).toString("hex"),
      mk.accAddress,
      mk.valAddress
    );

    const msgs = [lastSuccessVoteMsg, voteMsg.getPrevote()].filter(Boolean);
    try {
      const tx = await wallet.createAndSignTx({ msgs });
      const result = await testnetClient.tx.broadcastSync(tx);
      console.log(`vote_period: ${currentVotePeriod}, coins: ${coins}, txhash: ${result.txhash}`);
      lastSuccessVotePeriod = currentVotePeriod;
      lastSuccessVoteMsg = voteMsg;
    } catch (err) {
      console.log(err.data || err.message);
    };
    await delay(timeoutCommit);
  }
}

(async () => {
  await waitForFirstBlock(testnetClient);
  
  // read timeout_commit from config.toml
  const config = parse(fs.readFileSync(CONFIG_PATH).toString());
  timeoutCommit = ms(config.consensus.timeout_commit);

  while (true) {
    await loop().catch(err => {
      console.log(err.data || err.message);
    });
    await delay(timeoutCommit);
  }
})();
