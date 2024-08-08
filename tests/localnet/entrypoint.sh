#!/usr/bin/env sh
PATH=$PATH:$DAEMON_HOME/cosmovisor/current/bin

cosmovisor init $DAEMON_NAME
cosmovisor run start --home $DAEMON_HOME