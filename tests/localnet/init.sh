#!/bin/sh
set -e
BUILDDIR=${1:-./build}
LOCALNET_VALIDATOR_COUNT=${2:-7}
LOCALNET_CHAINID=${3:-localnet}

DOCKER_BUILDKIT=1 docker build -f ./tests/localnet/Dockerfile.cosmovisor -t terra-cosmovisor ./tests/localnet
DOCKER_BUILDKIT=1 docker build --platform linux/amd64 --tag terra:localnet ./
docker create --platform linux/amd64 --name temp terra:localnet
docker cp temp:/bin/terrad $BUILDDIR/
docker rm temp

docker run -v $BUILDDIR:/terra terra:localnet testnet -o . --chain-id $LOCALNET_CHAINID --v $LOCALNET_VALIDATOR_COUNT --starting-ip-address 192.168.10.2 --keyring-backend=test

if [ ! -d "$BUILDDIR/node$i/terrad" ]; then
  for (( i=0; i<$LOCALNET_VALIDATOR_COUNT; i++ )); do
      CURRENT=$BUILDDIR/node$i/terrad
      dasel put -t string -f $CURRENT/config/genesis.json '.app_state.gov.params.voting_period' -v '60s'; \
      dasel put -t bool -f $CURRENT/config/app.toml -v "true" '.api.enable'
      dasel put -t bool -f $CURRENT/config/app.toml -v "true" '.api.swagger'
      dasel put -t bool -f $CURRENT/config/app.toml -v "true" '.api.enabled-unsafe-cors'
      dasel put -t string -f $CURRENT/config/app.toml -v "tcp://0.0.0.0:1317" '.api.address'
      mkdir -p $CURRENT/cosmovisor/genesis/bin
      cp $BUILDDIR/terrad $CURRENT/cosmovisor/genesis/bin
  done
fi