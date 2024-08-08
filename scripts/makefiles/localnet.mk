###############################################################################
###                                Localnet                                 ###
###############################################################################
localnet-help:
	@echo "localnet subcommands"
	@echo ""
	@echo "Usage:"
	@echo "  make localnet-[command]"
	@echo ""
	@echo "Available Commands:"
	@echo "  start                 Start localnet"
	@echo "  stop                  Stop localnet"
	@echo "  start-upgrade         Start localnet upgrade"
	@echo "  stop-upgrade          Stop localnet upgrade"
localnet: localnet-help

LOCALNET_CHAINID ?= localnet
LOCALNET_VALIDATOR_COUNT ?= 7

# Run a 7-node testnet locally by default
localnet-init: localnet-stop localnet-clean
	mkdir -p $(BUILDDIR)
	./tests/localnet/init.sh $(BUILDDIR) ${LOCALNET_VALIDATOR_COUNT} ${LOCALNET_CHAINID}

localnet-start: localnet-stop
	docker compose -f ./tests/localnet/docker-compose.yml up -d

localnet-stop:
	docker compose -f ./tests/localnet/docker-compose.yml down

localnet-upgrade-test: localnet-stop localnet-clean
	./tests/localnet/upgrade-prepare.sh $(BUILDDIR) ${LOCALNET_VALIDATOR_COUNT} ${LOCALNET_CHAINID}
	docker compose -f ./tests/localnet/docker-compose.yml up -d
	@sleep 10
	./tests/localnet/upgrade-test.sh $(BUILDDIR) ${LOCALNET_VALIDATOR_COUNT} ${LOCALNET_CHAINID}

localnet-clean: localnet-stop
	rm -rf $(BUILDDIR)/node*
	rm -rf $(BUILDDIR)/gentxs

.PHONY: localnet-start localnet-stop
