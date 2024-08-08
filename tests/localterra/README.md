<p>&nbsp;</p>
<p align="center">
<img src="https://raw.githubusercontent.com/classic-terra/core/main/tests/localterra/localterra_logo_with_name.svg" width=500>
</p>
<p align="center">
An instant, zero-config Terra blockchain and ecosystem.
</p>

<br/>

# LocalTerra

LocalTerra is a complete Terra testnet containerized with Docker and orchestrated with a simple docker-compose file. LocalTerra comes preconfigured with opinionated, sensible defaults for a standard testing environment.

LocalTerra comes in two flavors:

1. No initial state: brand new testnet with no initial state. 
2. With mainnet state: creates a testnet from a mainnet state export

Both ways, the chain-id for LocalTerra is set to 'localterra'.

## Prerequisites
Ensure you have Docker (https://www.docker.com/get-started/) installed.

## 1. LocalTerra - No Initial State

The following commands must be executed from the root folder of the Terra repository.

1. Make any change to the osmosis code that you want to test

2. Initialize LocalTerra:

```bash
make localterra-init
```

The command:

- Builds a local docker image with the latest changes
- Cleans the `$HOME/.terra-local` folder

3. Start LocalTerra:

```bash
make localterra-start
```

> Note
>
> You can also start LocalTerra in detach mode with:
>
> `make localterra-startd`

4. (optional) Add your validator wallet and other preloaded wallets to local environment:

```bash
make localterra-keys
```

- These keys are added to your `--keyring-backend test`
- If the keys are already on your keyring, you will get an `"Error: aborted"`
- Ensure you use the name of the account as listed in the table below, as well as ensure you append the `--keyring-backend test` to your txs
- Example: `terrad tx bank send lo-test2 terra17lmam6zguazs5q5u6z5mmx76uj63gldnse2pdp 1000000uluna --keyring-backend test --chain-id localterra`

5. You can stop chain, keeping the state with

```bash
make localterra-stop
```

6. When you are done you can clean up the environment with:

```bash
make localterra-clean
```

## 2. LocalTerra - With Mainnet State (TBD)

Running an osmosis network with mainnet state is now as easy as setting up a stateless localterra.

1. Set up a mainnet node and stop it at whatever height you want to fork the network at.

2. There are now two options you can choose from:

   - **Mainnet is on version X, and you want to create a testnet on version X.**

     On version X, run:

      ```bash
      terrad in-place-testnet localterra osmo12smx2wdlyttvyzvzg54y2vnqwq2qjateuf7thj
      ```

      Where the first input is the desired chain-id of the new network and the second input is the desired validator operator address (where you vote from).
      The address provided above is included in the localterra keyring under the name 'val'.

     You now have a network you own with the mainnet state on version X.

   - **Mainnet is on version X, and you want to create a testnet on version X+1.**

     On version X, run:

      ```bash
      terrad in-place-testnet localterra osmo12smx2wdlyttvyzvzg54y2vnqwq2qjateuf7thj --trigger-testnet-upgrade
      ```

      Where the first input is the desired chain-id of the new network and the second input is the desired validator operator address (where you vote from).
      The address provided above is included in the localterra keyring under the name 'val'.

     The network will start and hit 10 blocks, at which point the upgrade will trigger and the network will halt.

     Then, on version X+1, run:

      ```bash
      terrad start
      ```

You now have a network you own with the mainnet state on version X+1.

## LocalTerra Accounts

LocalTerra is pre-configured with one validator and 9 accounts with ION and OSMO balances.

| Account   | Address                                                                                                  | Mnemonic                                                                                                                                                                   |
| --------- | -------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| lo-val    | `terra1dcegyrekltswvyy0xy69ydgxn9x8x32zdtapd8`<br/>`terravaloper1dcegyrekltswvyy0xy69ydgxn9x8x32zdy3ua5` | `satisfy adjust timber high purchase tuition stool faith fine install that you unaware feed domain license impose boss human eager hat rent enjoy dawn`                    |
| lo-test1  | `terra1x46rqay4d3cssq8gxxvqz8xt6nwlz4td20k38v`                                                           | `notice oak worry limit wrap speak medal online prefer cluster roof addict wrist behave treat actual wasp year salad speed social layer crew genius`                       |
| lo-test2  | `terra17lmam6zguazs5q5u6z5mmx76uj63gldnse2pdp`                                                           | `quality vacuum heart guard buzz spike sight swarm shove special gym robust assume sudden deposit grid alcohol choice devote leader tilt noodle tide penalty`              |
| lo-test3  | `terra1757tkx08n0cqrw7p86ny9lnxsqeth0wgp0em95`                                                           | `symbol force gallery make bulk round subway violin worry mixture penalty kingdom boring survey tool fringe patrol sausage hard admit remember broken alien absorb`        |
| lo-test4  | `terra199vw7724lzkwz6lf2hsx04lrxfkz09tg8dlp6r`                                                           | `bounce success option birth apple portion aunt rural episode solution hockey pencil lend session cause hedgehog slender journey system canvas decorate razor catch empty` |
| lo-test5  | `terra18wlvftxzj6zt0xugy2lr9nxzu402690ltaf4ss`                                                           | `second render cat sing soup reward cluster island bench diet lumber grocery repeat balcony perfect diesel stumble piano distance caught occur example ozone loyal`        |
| lo-test6  | `terra1e8ryd9ezefuucd4mje33zdms9m2s90m57878v9`                                                           | `spatial forest elevator battle also spoon fun skirt flight initial nasty transfer glory palm drama gossip remove fan joke shove label dune debate quick`                  |
| lo-test7  | `terra17tv2hvwpg0ukqgd2y5ct2w54fyan7z0zxrm2f9`                                                           | `noble width taxi input there patrol clown public spell aunt wish punch moment will misery eight excess arena pen turtle minimum grain vague inmate`                       |
| test8     | `terra1lkccuqgj6sjwjn8gsa9xlklqv4pmrqg9dx2fxc`                                                           | `cream sport mango believe inhale text fish rely elegant below earth april wall rug ritual blossom cherry detail length blind digital proof identify ride`                 |
| test9     | `terra1333veey879eeqcff8j3gfcgwt8cfrg9mq20v6f`                                                           | `index light average senior silent limit usual local involve delay update rack cause inmate wall render magnet common feature laundry exact casual resource hundred`       |
| lo-test10 | `terra1fmcjjt6yc9wqup2r06urnrd928jhrde6gcld6n`                                                           | `prefer forget visit mistake mixture feel eyebrow autumn shop pair address airport diesel street pass vague innocent poem method awful require hurry unhappy shoulder`     |


## Tests

### Software-upgrade test

To test a software upgrade, you can use the `submit_upgrade_proposal.sh` script located in the `scripts/` folder. This script automatically creates a proposal to upgrade the software to the specified version and votes "yes" on the proposal. Once the proposal passes and the upgrade height is reached, you can update your localterra instance to use the new version.

#### Usage 

To use the script:

1. make sure you have a running LocalTerra instance

2. run the following command:

```bash
./scripts/submit_upgrade_proposal.sh <upgrade version>
```

Replace `<upgrade version>` with the version of the software you want to upgrade to, for example. If no version is specified, the script will default to `v9` version.

The script does the following:

- Creates an upgrade proposal with the specified version and description.
- Votes "yes" on the proposal.

#### Upgrade

Once the upgrade height is reached, you need to update your `localterra` instance to use the new software. 

There are several ways to do this. Some examples are:

1. Change the image in the `docker-compose.yml` file to use the new version, and then restart LocalTerra using `make localterra-start`. For example:

```yaml
services:
  terrad:
    image: <NEW_IMAGE_I_WANT_TO_USE>
    # All this needs to be commented to don't build the image with local changes
    # 
    # build:
    #     context: ../../
    #     dockerfile: Dockerfile
    #     args:
    #     RUNNER_IMAGE: alpine:3.17
    #     GO_VERSION: 1.21
```

2. Checkout the Terra repository to a different `ref` that includes the new version, and then rebuild and restart LocalTerra using `make localterra-start`. Make sure to don't delete your `~/.terra-local` folder.

## FAQ

Q: How do I enable pprof server in localterra?

A: everything but the Dockerfile is already configured. Since we use a production Dockerfile in localterra, we don't want to expose the pprof server there by default. As a result, if you would like to use pprof, make sure to add `EXPOSE 6060` to the Dockerfile and rebuild the localterra image.
