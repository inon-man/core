###############################################################################
###                                Protobuf                                 ###
###############################################################################
proto-help:
	@echo "proto subcommands"
	@echo ""
	@echo "Usage:"
	@echo "  make proto-[command]"
	@echo ""
	@echo "Available Commands:"
	@echo "  all               Run proto-format, proto-lint, proto-gen, and proto-docs"
	@echo "  format            Format Protobuf files"
	@echo "  lint              Run protobuf linter"
	@echo "  gen               Generate protobuf files"
	@echo "  docs              Update swagger file"
	@echo "  check-breaking    Check breaking changes"
	@echo "  update-deps       Update dependencies"
proto: proto-help

protoVer=0.14.0
protoImageName=ghcr.io/cosmos/proto-builder:$(protoVer)
protoImage=$(DOCKER) run --rm -v $(CURDIR):/workspace --workdir /workspace $(protoImageName)

proto-all: proto-format proto-lint proto-gen proto-docs

proto-gen:
	@echo "Generating Protobuf files"
	@$(protoImage) sh ./proto/scripts/protocgen.sh

proto-format:
	@$(protoImage) find ./ -name "*.proto" -exec clang-format -i {} \;

proto-lint:
	@$(protoImage) buf lint --error-format=json

proto-check-breaking:
	@$(protoImage) buf breaking --against $(HTTPS_GIT)#branch=main

proto-update-deps:
	@echo "Updating Protobuf dependencies"
	$(DOCKER) run --rm -v $(CURDIR)/proto:/workspace --workdir /workspace $(protoImageName) buf mod update

proto-docs: statik
	@echo
	@echo "=========== Generate Message ============"
	@echo
	@sh ./proto/scripts/protoc-swagger-gen.sh

	$(GOPATH)/bin/statik -src=client/docs/swagger-ui -dest=client/docs -f -m
	@if [ -n "$(git status --porcelain)" ]; then \
        echo "\033[91mSwagger docs are out of sync!!!\033[0m";\
        exit 1;\
    else \
        echo "\033[92mSwagger docs are in sync\033[0m";\
    fi
	@echo
	@echo "=========== Generate Complete ============"
	@echo

.PHONY: proto-all proto-gen proto-format proto-lint proto-check-breaking proto-update-deps docs
