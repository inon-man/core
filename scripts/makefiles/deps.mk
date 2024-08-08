###############################################################################
###                           Dependency Updates                            ###
###############################################################################
deps-help:
	@echo "Dependency Update subcommands"
	@echo ""
	@echo "Usage:"
	@echo "  make deps-[command]"
	@echo ""
	@echo "Available Commands:"
	@echo "  clean                    Remove artifacts"
	@echo "  distclean                Remove vendor directory"
	@echo "  go-mod-cache             Download go modules to local cache"
	@echo "  go.sum                   Ensure dependencies have not been modified"
deps: deps-help

deps-go-mod-cache: go.sum
	@echo "--> Download go modules to local cache"
	@go mod download

deps-go.sum: go.mod
	@echo "--> Ensure dependencies have not been modified"
	@GOWORK=off go mod verify

deps-clean:
	rm -rf $(CURDIR)/artifacts/

deps-distclean: deps-clean
	rm -rf vendor/
