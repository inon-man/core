#!/bin/sh
set -e
# should make this auto fetch upgrade name from app upgrades once many upgrades have been done
# this command will retrieve the folder with the largest number in format v<number>
SOFTWARE_UPGRADE_NAME=$(ls -d -- ./app/upgrades/v* | sort -Vr | head -n 1 | xargs basename)
NODE1_HOME=node1/terrad
BINARY_OLD="docker exec terradnode1 ./terrad"
LOCALNET_VALIDATOR_COUNT=${2:-7}
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 20 block from now
STATUS_INFO=($($BINARY_OLD status --home $NODE1_HOME | jq -r '.NodeInfo.network,.SyncInfo.latest_block_height'))
CHAIN_ID=${STATUS_INFO[0]}
UPGRADE_HEIGHT=$((STATUS_INFO[1] + 20))

echo "${YELLOW}Preparing $SOFTWARE_UPGRADE_NAME upgrade at height $UPGRADE_HEIGHT.${NC}"
docker exec terradnode1 tar -cf ./terrad.tar -C $NODE1_HOME/cosmovisor/upgrades/$SOFTWARE_UPGRADE_NAME/bin terrad
SUM=$(docker exec terradnode1 sha256sum ./terrad.tar | cut -d ' ' -f1)
UPGRADE_INFO='{"binaries":{"linux/amd64":"file:///terrad/terrad.tar?checksum=sha256:'"$SUM"'"}}'
echo "${YELLOW}Submitting $SOFTWARE_UPGRADE_NAME software upgrade proposal.${NC}"
APP_CMD="$BINARY_OLD tx gov submit-legacy-proposal software-upgrade "$SOFTWARE_UPGRADE_NAME" \
--upgrade-height $UPGRADE_HEIGHT \
--upgrade-info '$UPGRADE_INFO' \
--title "upgrade" \
--description "upgrade" \
--from node1 \
--keyring-backend test \
--chain-id $CHAIN_ID \
--home $NODE1_HOME \
--yes \
-o json"
TX_JSON=$(eval "$APP_CMD")
TX_HASH=$(echo "$TX_JSON" | jq -r '.txhash')
sleep 10
PROPOSAL_JSON=$(eval "$BINARY_OLD q tx $TX_HASH -o json")
echo $PROPOSAL_JSON
PROPOSAL_ID=$(echo "$PROPOSAL_JSON" | jq -r '.logs[0].events[] | select(.type == "submit_proposal") | .attributes[] | select(.key == "proposal_id") | .value')

echo "${YELLOW}Depositing asset to proposal ${PROPOSAL_ID}.${NC}"
$BINARY_OLD tx gov deposit $PROPOSAL_ID "20000000uluna" --from node1 --keyring-backend test --chain-id $CHAIN_ID --home $NODE1_HOME -y
sleep 10

# loop from 0 to LOCALNET_VALIDATOR_COUNT
for (( i=0; i<$LOCALNET_VALIDATOR_COUNT; i++ )); do
    # check if docker for node i is running
    if [[ $(docker ps -a | grep terradnode$i | wc -l) -eq 1 ]]; then
        echo "${YELLOW}Voting yes in terradnode$i container.${NC}"
        $BINARY_OLD tx gov vote ${PROPOSAL_ID} yes --from node$i --keyring-backend test --chain-id $CHAIN_ID --home "node$i/terrad" -y
    fi
done

# keep track of block_height
NIL_BLOCK=0
LAST_BLOCK=0
SAME_BLOCK=0
while true; do 
    BLOCK_HEIGHT=$($BINARY_OLD status --home $NODE1_HOME | jq '.SyncInfo.latest_block_height' -r)
    # if BLOCK_HEIGHT is empty
    if [[ -z $BLOCK_HEIGHT ]]; then
        # if 5 nil blocks in a row, exit
        if [[ $NIL_BLOCK -ge 5 ]]; then
            echo "ERROR: 5 nil blocks in a row"
            break
        fi
        NIL_BLOCK=$((NIL_BLOCK + 1))
    fi

    # if block height is not nil
    # if block height is same as last block height
    if [[ $BLOCK_HEIGHT -eq $LAST_BLOCK ]]; then
        # if 5 same blocks in a row, exit
        if [[ $SAME_BLOCK -ge 5 ]]; then
            echo "ERROR: 5 same blocks in a row"
            break
        fi
        SAME_BLOCK=$((SAME_BLOCK + 1))
    else
        # update LAST_BLOCK and reset SAME_BLOCK
        LAST_BLOCK=$BLOCK_HEIGHT
        SAME_BLOCK=0
    fi

    if [[ $BLOCK_HEIGHT -ge $UPGRADE_HEIGHT ]]; then
        # assuming running only 1 terrad
        echo "UPGRADE REACHED, CONTINUING NEW CHAIN"
        break
    else
        $BINARY_OLD q gov proposal ${PROPOSAL_ID} --output=json --home $NODE1_HOME | jq ".status"
        echo "BLOCK_HEIGHT = $BLOCK_HEIGHT"
        sleep 10
    fi
done

if [[ $SAME_BLOCK -ge 5 ]]; then
    docker logs terradnode0
    exit 1
fi

# check all nodes are online after upgrade
for (( i=0; i<$LOCALNET_VALIDATOR_COUNT; i++ )); do
    if [[ $(docker ps -a | grep terradnode$i | wc -l) -eq 1 ]]; then

        if ! [[ $BLOCK_HEIGHT -ge $UPGRADE_HEIGHT ]]; then
            echo "${YELLOW}Upgrade failed: terradnode$i has height $BLOCK_HEIGHT.${NC}"
            exit 1
        fi
    fi
done

echo "${YELLOW}Upgrade success.${NC}"
echo "localnet is still running. Please finish using 'make localnet-stop or localnet-clean'."