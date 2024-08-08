#!/bin/sh

CHAIN_ID=localterra
LOCALTERRA_HOME=$HOME/.terra
CONFIG_FOLDER=$LOCALTERRA_HOME/config
MONIKER=lo-val
STATE='false'
BOND_DENOM='uluna'
APP_BIN=terrad

MNEMONIC="satisfy adjust timber high purchase tuition stool faith fine install that you unaware feed domain license impose boss human eager hat rent enjoy dawn"
POOLSMNEMONIC="traffic cool olive pottery elegant innocent aisle dial genuine install shy uncle ride federal soon shift flight program cave famous provide cute pole struggle"

while getopts s flag
do
    case "${flag}" in
        s) STATE='true';;
    esac
done

install_prerequisites () {
    apk add dasel
}

edit_genesis () {
    GENESIS=$CONFIG_FOLDER/genesis.json

    # Update staking module
    dasel put -t string -f $GENESIS '.app_state.staking.params.bond_denom' -v $BOND_DENOM
    dasel put -t string -f $GENESIS '.app_state.staking.params.unbonding_time' -v '240s'

    # Update bank module
    dasel put -t string -f $GENESIS '.app_state.bank.denom_metadata.[].description' -v 'Registered denom '$BOND_DENOM' for testing'
    dasel put -t string -f $GENESIS '.app_state.bank.denom_metadata.[0].denom_units.[].denom' -v $BOND_DENOM
    dasel put -t string -f $GENESIS '.app_state.bank.denom_metadata.[0].denom_units.[0].exponent' -v 0
    dasel put -t string -f $GENESIS '.app_state.bank.denom_metadata.[0].base' -v $BOND_DENOM
    dasel put -t string -f $GENESIS '.app_state.bank.denom_metadata.[0].display' -v $BOND_DENOM
    dasel put -t string -f $GENESIS '.app_state.bank.denom_metadata.[0].name' -v $BOND_DENOM
    dasel put -t string -f $GENESIS '.app_state.bank.denom_metadata.[0].symbol' -v $BOND_DENOM

    # Update crisis module
    dasel put -t string -f $GENESIS '.app_state.crisis.constant_fee.denom' -v $BOND_DENOM

    # Update gov module
    dasel put -t string -f $GENESIS '.app_state.gov.params.voting_period' -v '60s'
    dasel put -t string -f $GENESIS '.app_state.gov.params.min_deposit.[0].denom' -v $BOND_DENOM

    # Update epochs module
    # dasel put -t string -f $GENESIS '.app_state.epochs.epochs.[1].duration' -v "60s"

    # Update poolincentives module
    # dasel put -t string -f $GENESIS '.app_state.poolincentives.lockable_durations.[0]' -v "120s"
    # dasel put -t string -f $GENESIS '.app_state.poolincentives.lockable_durations.[1]' -v "180s"
    # dasel put -t string -f $GENESIS '.app_state.poolincentives.lockable_durations.[2]' -v "240s"
    # dasel put -t string -f $GENESIS '.app_state.poolincentives.params.minted_denom' -v $BOND_DENOM

    # Update incentives module
    # dasel put -t string -f $GENESIS '.app_state.incentives.lockable_durations.[0]' -v "1s"
    # dasel put -t string -f $GENESIS '.app_state.incentives.lockable_durations.[1]' -v "120s"
    # dasel put -t string -f $GENESIS '.app_state.incentives.lockable_durations.[2]' -v "180s"
    # dasel put -t string -f $GENESIS '.app_state.incentives.lockable_durations.[3]' -v "240s"
    # dasel put -t string -f $GENESIS '.app_state.incentives.params.distr_epoch_identifier' -v "hour"

    # Update mint module
    # dasel put -t string -f $GENESIS '.app_state.mint.params.mint_denom' -v $BOND_DENOM
    # dasel put -t string -f $GENESIS '.app_state.mint.params.epoch_identifier' -v "hour"

    # Update poolmanager module
    # dasel put -t string -f $GENESIS '.app_state.poolmanager.params.pool_creation_fee.[0].denom' -v $BOND_DENOM

    # Update txfee basedenom
    # dasel put -t string -f $GENESIS '.app_state.txfees.basedenom' -v $BOND_DENOM

    # Update wasm permission (Nobody or Everybody)
    # dasel put -t string -f $GENESIS '.app_state.wasm.params.code_upload_access.permission' -v "Everybody"

    # Update concentrated-liquidity (enable pool creation)
    # dasel put -t bool -f $GENESIS '.app_state.concentratedliquidity.params.is_permissionless_pool_creation_enabled' -v true
}

add_genesis_accounts () {
    $APP_BIN add-genesis-account terra1dcegyrekltswvyy0xy69ydgxn9x8x32zdtapd8 100000000000$BOND_DENOM,100000000000uusd,100000000000usdr,100000000000ukrw,100000000000umnt --home $LOCALTERRA_HOME
    # note such large amounts are set for e2e tests on FE 
    $APP_BIN add-genesis-account terra1x46rqay4d3cssq8gxxvqz8xt6nwlz4td20k38v 9999999999999999999999999999999999999999999999999$BOND_DENOM,9999999999999999999999999999999999999999999999999uusd,100000000000usdr,100000000000ukrw,100000000000umnt --home $LOCALTERRA_HOME
    $APP_BIN add-genesis-account terra17lmam6zguazs5q5u6z5mmx76uj63gldnse2pdp 100000000000$BOND_DENOM,100000000000uusd,100000000000usdr,100000000000ukrw,100000000000umnt --home $LOCALTERRA_HOME
    $APP_BIN add-genesis-account terra1757tkx08n0cqrw7p86ny9lnxsqeth0wgp0em95 100000000000$BOND_DENOM,100000000000uusd,100000000000usdr,100000000000ukrw,100000000000umnt --home $LOCALTERRA_HOME
    $APP_BIN add-genesis-account terra199vw7724lzkwz6lf2hsx04lrxfkz09tg8dlp6r 100000000000$BOND_DENOM,100000000000uusd,100000000000usdr,100000000000ukrw,100000000000umnt --home $LOCALTERRA_HOME
    $APP_BIN add-genesis-account terra18wlvftxzj6zt0xugy2lr9nxzu402690ltaf4ss 100000000000$BOND_DENOM,100000000000uusd,100000000000usdr,100000000000ukrw,100000000000umnt --home $LOCALTERRA_HOME
    $APP_BIN add-genesis-account terra1e8ryd9ezefuucd4mje33zdms9m2s90m57878v9 100000000000$BOND_DENOM,100000000000uusd,100000000000usdr,100000000000ukrw,100000000000umnt --home $LOCALTERRA_HOME
    $APP_BIN add-genesis-account terra17tv2hvwpg0ukqgd2y5ct2w54fyan7z0zxrm2f9 100000000000$BOND_DENOM,100000000000uusd,100000000000usdr,100000000000ukrw,100000000000umnt --home $LOCALTERRA_HOME
    $APP_BIN add-genesis-account terra1lkccuqgj6sjwjn8gsa9xlklqv4pmrqg9dx2fxc 100000000000$BOND_DENOM,100000000000uusd,100000000000usdr,100000000000ukrw,100000000000umnt --home $LOCALTERRA_HOME
    $APP_BIN add-genesis-account terra1333veey879eeqcff8j3gfcgwt8cfrg9mq20v6f 100000000000$BOND_DENOM,100000000000uusd,100000000000usdr,100000000000ukrw,100000000000umnt --home $LOCALTERRA_HOME
    $APP_BIN add-genesis-account terra1fmcjjt6yc9wqup2r06urnrd928jhrde6gcld6n 100000000000$BOND_DENOM,100000000000uusd,100000000000usdr,100000000000ukrw,100000000000umnt --home $LOCALTERRA_HOME
    $APP_BIN add-genesis-account terra1a7fgca0746t9kjz079s0m63eqkczfjp3luesac 1000000000000$BOND_DENOM,1000000000000uusd,1000000000000usdr,1000000000000ukrw,1000000000000umnt --home $LOCALTERRA_HOME

    echo $MNEMONIC | $APP_BIN keys add $MONIKER --recover --keyring-backend=test --home $LOCALTERRA_HOME
    echo $POOLSMNEMONIC | $APP_BIN keys add pools --recover --keyring-backend=test --home $LOCALTERRA_HOME
    $APP_BIN gentx $MONIKER 500000000$BOND_DENOM --keyring-backend=test --chain-id=$CHAIN_ID --home $LOCALTERRA_HOME

    $APP_BIN collect-gentxs --home $LOCALTERRA_HOME
}

edit_config () {

    # Remove seeds
    dasel put -t string -f $CONFIG_FOLDER/config.toml '.p2p.seeds' -v ''

    # Expose the rpc
    dasel put -t string -f $CONFIG_FOLDER/config.toml '.rpc.laddr' -v "tcp://0.0.0.0:26657"
    
    # Expose pprof for debugging
    # To make the change enabled locally, make sure to add 'EXPOSE 6060' to the root Dockerfile
    # and rebuild the image.
    dasel put -t string -f $CONFIG_FOLDER/config.toml '.rpc.pprof_laddr' -v "0.0.0.0:6060"
}

enable_cors () {

    # Enable cors on RPC
    dasel put -t string -f $CONFIG_FOLDER/config.toml -v "*" '.rpc.cors_allowed_origins.[]'
    dasel put -t string -f $CONFIG_FOLDER/config.toml -v "Accept-Encoding" '.rpc.cors_allowed_headers.[]'
    dasel put -t string -f $CONFIG_FOLDER/config.toml -v "DELETE" '.rpc.cors_allowed_methods.[]'
    dasel put -t string -f $CONFIG_FOLDER/config.toml -v "OPTIONS" '.rpc.cors_allowed_methods.[]'
    dasel put -t string -f $CONFIG_FOLDER/config.toml -v "PATCH" '.rpc.cors_allowed_methods.[]'
    dasel put -t string -f $CONFIG_FOLDER/config.toml -v "PUT" '.rpc.cors_allowed_methods.[]'

    # Enable unsafe cors and swagger on the api
    dasel put -t bool -f $CONFIG_FOLDER/app.toml -v "true" '.api.enable'
    dasel put -t bool -f $CONFIG_FOLDER/app.toml -v "true" '.api.swagger'
    dasel put -t bool -f $CONFIG_FOLDER/app.toml -v "true" '.api.enabled-unsafe-cors'
    dasel put -t string -f $CONFIG_FOLDER/app.toml -v "tcp://0.0.0.0:1317" '.api.address'

    # Enable cors on gRPC Web
    dasel put -t bool -f $CONFIG_FOLDER/app.toml -v "true" '.grpc-web.enable-unsafe-cors'

    # Enable SQS & route caching
    # dasel put -t string -f $CONFIG_FOLDER/app.toml -v "true" '.osmosis-sqs.is-enabled'
    # dasel put -t string -f $CONFIG_FOLDER/app.toml -v "true" '.osmosis-sqs.route-cache-enabled'
    # dasel put -t string -f $CONFIG_FOLDER/app.toml -v "redis" '.osmosis-sqs.db-host'
}

run_with_retries() {
  cmd=$1
  success_msg=$2

  substring='code: 0'
  COUNTER=0

  while [ $COUNTER -lt 15 ]; do
    string=$(eval $cmd 2>&1)
    echo $string

    if [ "$string" != "${string%"$substring"*}" ]; then
      echo "$success_msg"
      break
    else
      COUNTER=$((COUNTER+1))
      sleep 0.5
    fi
  done
}

# Define the functions using the new function
# create_two_asset_pool() {
#   run_with_retries "$APP_BIN tx gamm create-pool --pool-file=$1 --from pools --chain-id=$CHAIN_ID --home $LOCALTERRA_HOME --keyring-backend=test -b block --fees 5000$BOND_DENOM --yes" "create two asset pool: successful"
# }

# create_stable_pool() {
#   run_with_retries "$APP_BIN tx gamm create-pool --pool-file=uwethUusdcStablePool.json --pool-type=stableswap --from pools --chain-id=$CHAIN_ID --home $LOCALTERRA_HOME --keyring-backend=test -b block --fees 5000$BOND_DENOM --yes" "create two asset pool: successful"
# }

# create_three_asset_pool() {
#   run_with_retries "$APP_BIN tx gamm create-pool --pool-file=nativeDenomThreeAssetPool.json --from pools --chain-id=$CHAIN_ID --home $LOCALTERRA_HOME --keyring-backend=test -b block --fees 5000$BOND_DENOM --gas 900000 --yes" "create three asset pool: successful"
# }

# create_concentrated_pool() {
#   run_with_retries "$APP_BIN tx concentratedliquidity create-pool uion $BOND_DENOM 1 \"0.0005\" --from pools --chain-id=$CHAIN_ID --home $LOCALTERRA_HOME --keyring-backend=test -b block --fees 5000$BOND_DENOM --gas 900000 --yes" "create concentrated pool: successful"
# }

# create_concentrated_pool_positions () {
#     # Define an array to hold the parameters that change for each command
#     set "[-1620000] 3420000" "305450 315000" "315000 322500" "300000 309990" "[-108000000] 342000000" "[-108000000] 342000000"

#     substring='code: 0'
#     COUNTER=0
#     # Loop through each set of parameters in the array
#     for param in "$@"; do
#         run_with_retries "$APP_BIN tx concentratedliquidity create-position 6 $param 5000000000$BOND_DENOM,1000000uion 0 0 --from pools --chain-id=$CHAIN_ID --home $LOCALTERRA_HOME --keyring-backend=test -b block --fees 5000$BOND_DENOM --gas 900000 --yes"
#     done
# }

if [[ ! -d $CONFIG_FOLDER ]]
then
    echo $MNEMONIC | $APP_BIN init -o --chain-id=$CHAIN_ID --home $LOCALTERRA_HOME --recover $MONIKER
    install_prerequisites
    edit_genesis
    add_genesis_accounts
    edit_config
    enable_cors
fi

$APP_BIN start --home $LOCALTERRA_HOME &

# if [[ $STATE == 'true' ]]
# then
#     echo "Creating pools"

#     echo "$BOND_DENOM / uusdc balancer"
#     create_two_asset_pool "$BOND_DENOMUusdcBalancerPool.json"

#     echo "$BOND_DENOM / uion balancer"
#     create_two_asset_pool "$BOND_DENOMUionBalancerPool.json"

#     echo "uweth / uusdc stableswap"
#     create_stable_pool

#     echo "uusdc / uion balancer"
#     create_two_asset_pool "uusdcUionBalancerPool.json"

#     echo "stake / uion / $BOND_DENOM balancer"
#     create_three_asset_pool

#     echo "uion / $BOND_DENOM concentrated"
#     create_concentrated_pool
#     create_concentrated_pool_positions
# fi
wait
