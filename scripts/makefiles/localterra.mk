###############################################################################
###                                LocalTerra                               ###
###############################################################################
#
# Please refer to https://github.com/osmosis-labs/osmosis/blob/main/tests/localosmosis/README.md for detailed
# usage of localterra.

localterra-help:
	@echo "localterra subcommands"
	@echo ""
	@echo "Usage:"
	@echo "  make localterra-[command]"
	@echo ""
	@echo "Available Commands:"
	@echo "  build                           Build localterra"
	@echo "  clean                           Clean localterra"
	@echo "  init                            Initialize localterra"
	@echo "  keys                            Add keys for localterra"
	@echo "  start                           Start localterra"
	@echo "  start-with-state                Start localterra with state"
	@echo "  startd                          Start localterra in detached mode"
	@echo "  startd-with-state               Start localterra in detached mode with state"
	@echo "  stop                            Stop localterra"
localterra: localterra-help

localterra-keys:
	@tests/localterra/scripts/add_keys.sh

localterra-init: localterra-clean localterra-build

localterra-build:
	@DOCKER_BUILDKIT=1 COMPOSE_DOCKER_CLI_BUILD=1 docker compose -f tests/localterra/docker-compose.yml build

localterra-start:
	@STATE="" docker compose -f tests/localterra/docker-compose.yml up

localterra-startd:
	@STATE="" docker compose -f tests/localterra/docker-compose.yml up -d

localterra-stop:
	@STATE="" docker compose -f tests/localterra/docker-compose.yml down

localterra-clean:
	@tests/localterra/scripts/clean.sh
