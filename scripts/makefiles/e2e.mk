###############################################################################
###                                 E2E                                     ###
###############################################################################
e2e-help:
	@echo "e2e subcommands"
	@echo ""
	@echo "Usage:"
	@echo "  make e2e-[command]"
	@echo ""
	@echo "Available Commands:"
	@echo "  build-script-node                     Build e2e script"
	@echo "  build-node                            Build e2e node"
	@echo "  build-chain                           Build e2e chain"
	@echo "  check-image-sha                       Check e2e image SHA"
	@echo "  remove-resources                      Remove e2e resources"
	@echo "  setup                                 Set up e2e environment"
e2e: e2e-help

e2e-build-script:
	mkdir -p $(BUILDDIR)
	go build -mod=readonly $(BUILD_FLAGS) -o $(BUILDDIR)/ ./tests/e2e/initialization/$(E2E_SCRIPT_NAME)

e2e-build-node:
	@E2E_SCRIPT_NAME=node make e2e-build-script

e2e-build-chain:
	@E2E_SCRIPT_NAME=chain make e2e-build-script

e2e-check-image-sha:
	tests/e2e/scripts/run/check_image_sha.sh

e2e-remove-resources:
	tests/e2e/scripts/run/remove_stale_resources.sh

e2e-build-debug:
	@DOCKER_BUILDKIT=1 docker build \
		-t terra \
		-t terra:debug \
		./

e2e-setup: e2e-check-image-sha e2e-remove-resources e2e-build-debug
	@echo Finished e2e environment setup, ready to start the test
