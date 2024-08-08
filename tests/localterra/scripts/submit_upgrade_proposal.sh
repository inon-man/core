#!/bin/sh
set -e

APP_BIN=terrad
BOND_DENOM=uluna

# Validator mnemonic of the validator that will make the proposal and vote on it
# it should have enough voting power to pass the proposal
RPC_NODE=http://localhost:26657/

# Default upgrade version
UPGRADE_VERSION=${1:-"v9"}

# Parameters
KEY=lo-val
PROPOSAL_DEPOSIT=1600000000$BOND_DENOM
TX_FEES=1000$BOND_DENOM

# Define ANSI escape sequences for colors
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get chain info
get_chain_info() {
    echo
    echo "${YELLOW}Getting chain info...${NC}"
    CHAIN_ID=$(curl -s localhost:26657/status | jq -r '.result.node_info.network')
    
    ABCI_INFO=$(curl -s localhost:26657/abci_info)
    CURRENT_HEIGHT=$(echo "$ABCI_INFO" | jq -r .result.response.last_block_height)
    UPGRADE_HEIGHT=$((CURRENT_HEIGHT + 50))

docker exec localterra-terrad-1 tar -cf ./terrad.tar -C /bin terrad
SUM=$(docker exec localterra-terrad-1 sha256sum terrad.tar | cut -d ' ' -f1)
DOCKER_BASE_PATH=$(docker exec localterra-terrad-1 pwd)
UPGRADE_INFO='{"binaries":{"linux/amd64":"file://'$DOCKER_BASE_PATH'/terrad.tar?checksum=sha256:'"$SUM"'",}}'

    echo "CHAIN_ID: $CHAIN_ID"
    echo "CURRENT_HEIGHT: $CURRENT_HEIGHT"
    echo "UPGRADE_HEIGHT: $UPGRADE_HEIGHT"
    echo "UPGRADE_VERSION: $UPGRADE_VERSION"
    echo "UPGRADE_INFO: $UPGRADE_INFO"
}

# Make proposal and get proposal ID
make_proposal() {
    echo
    echo "${YELLOW}Creating software-upgrade proposal...${NC}"
    APP_CMD="$APP_BIN tx gov submit-legacy-proposal software-upgrade \
        $UPGRADE_VERSION \
        --title \"$UPGRADE_VERSION Upgrade\" \
        --description \"$UPGRADE_VERSION Upgrade\" \
        --upgrade-height $UPGRADE_HEIGHT \
        --upgrade-info '$UPGRADE_INFO' \
        --no-validate \
        --chain-id $CHAIN_ID \
        --deposit $PROPOSAL_DEPOSIT \
        --from $KEY \
        --fees $TX_FEES \
        --keyring-backend test \
        --node $RPC_NODE \
        --yes \
        -o json"

    TX_JSON=$(eval "$APP_CMD")
    TX_HASH=$(echo "$TX_JSON" | jq -r '.txhash')
    sleep 5
    PROPOSAL_JSON=$(eval "$APP_BIN q tx $TX_HASH -o json")
    echo $PROPOSAL_JSON
    PROPOSAL_ID=$(echo "$PROPOSAL_JSON" | jq -r '.logs[0].events[] | select(.type == "submit_proposal") | .attributes[] | select(.key == "proposal_id") | .value')
}


# Query proposal
query_proposal() {
    $APP_BIN q gov proposal $PROPOSAL_ID \
        --node $RPC_NODE \
        -o json | jq
}

# Vote on proposal
vote_on_proposal() {
    echo
    echo "${YELLOW}Voting on proposal $PROPOSAL_ID...${NC}"
    APP_CMD="$APP_BIN tx gov vote $PROPOSAL_ID yes \
        --from $KEY \
        --chain-id $CHAIN_ID \
        --fees $TX_FEES \
        --node $RPC_NODE \
        --yes \
        --keyring-backend test \
        -o json"

    # Execute the command and capture the output
    VOTE_OUTPUT=$(eval "$APP_CMD")
    echo $VOTE_OUTPUT | jq

}


# Main function
main() {
    get_chain_info
    make_proposal
    query_proposal
    vote_on_proposal
}

# Run main function
main
