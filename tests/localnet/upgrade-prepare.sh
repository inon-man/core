#!/bin/sh
set -e
BUILDDIR=${1:-./build}
LOCALNET_VALIDATOR_COUNT=${2:-7}
LOCALNET_CHAINID=${3:-localnet}

YELLOW='\033[1;33m'
NC='\033[0m' # No Color

## Build old version
OLD_VERSION=$(curl --silent "https://api.github.com/repos/classic-terra/core/releases/latest" | jq -r '.tag_name')
echo "${YELLOW}Building old version ${OLD_VERSION}.${NC}"
git checkout $OLD_VERSION
DOCKER_BUILDKIT=1 docker build --platform linux/amd64 --tag terra:localnet-old ./
docker create --platform linux/amd64 --name temp terra:localnet-old
# TODO: /usr/local/bin should be changed to /bin
docker cp temp:/usr/local/bin/terrad $BUILDDIR/terrad
docker rm temp

docker run -v $BUILDDIR:/terra terra:localnet testnet -o . --chain-id $LOCALNET_CHAINID --v $LOCALNET_VALIDATOR_COUNT --starting-ip-address 192.168.10.2 --keyring-backend=test

# Copy terrad to cosmovisor genesis
for (( i=0; i<$LOCALNET_VALIDATOR_COUNT; i++ )); do
    CURRENT=$BUILDDIR/node$i/terrad
    
    dasel put -t string -f $CURRENT/config/genesis.json '.app_state.gov.params.voting_period' -v '60s'; \
    dasel put -t bool -f $CURRENT/config/app.toml -v "true" '.api.enable'
    dasel put -t bool -f $CURRENT/config/app.toml -v "true" '.api.swagger'
    dasel put -t bool -f $CURRENT/config/app.toml -v "true" '.api.enabled-unsafe-cors'
    dasel put -t string -f $CURRENT/config/app.toml -v "tcp://0.0.0.0:1317" '.api.address'

    mkdir -p $CURRENT/cosmovisor/genesis/bin
    echo "${YELLOW}Copying $BUILDDIR/terrad to $CURRENT/cosmovisor/genesis/bin${NC}"
    cp $BUILDDIR/terrad $CURRENT/cosmovisor/genesis/bin
done

## Build upgrade version
echo "${YELLOW}Building upgrade version.${NC}"
## Checkout last version
git checkout -

# this command will retrieve the folder with the largest number in format v<number>
SOFTWARE_UPGRADE_NAME=$(ls -d -- ./app/upgrades/v* | sort -Vr | head -n 1 | xargs basename)
DOCKER_BUILDKIT=1 docker build --platform linux/amd64 --tag terra:localnet-new ./
docker create --platform linux/amd64 --name temp terra:localnet-new
docker cp temp:/bin/terrad $BUILDDIR/terrad-new
docker rm temp

# Copy terrad to cosmovisor upgrades
for (( i=0; i<$LOCALNET_VALIDATOR_COUNT; i++ )); do
    CURRENT=$BUILDDIR/node$i/terrad

    mkdir -p $CURRENT/cosmovisor/upgrades/$SOFTWARE_UPGRADE_NAME/bin
    echo "${YELLOW}Copying $BUILDDIR/terrad-new to $CURRENT/cosmovisor/upgrades/$SOFTWARE_UPGRADE_NAME/bin/terrad${NC}"
    cp $BUILDDIR/terrad-new $CURRENT/cosmovisor/upgrades/$SOFTWARE_UPGRADE_NAME/bin/terrad
    touch $CURRENT/cosmovisor/upgrades/$SOFTWARE_UPGRADE_NAME/upgrade-info.json
done