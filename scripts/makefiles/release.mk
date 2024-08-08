###############################################################################
###                                Release                                  ###
###############################################################################
release-help:
	@echo "release subcommands"
	@echo ""
	@echo "Usage:"
	@echo "  make release-[command]"
	@echo ""
	@echo "Available Commands:"
	@echo "  dry-run                   Perform a dry run release"
	@echo "  snapshot                  Create a snapshot release"
release: release-help

GO_VERSION ?= $(shell cat go.mod | grep -E 'go [0-9].[0-9]+' | cut -d ' ' -f 2)
GORELEASER_IMAGE := ghcr.io/goreleaser/goreleaser-cross:v$(GO_VERSION)
COSMWASM_VERSION := $(shell go list -m github.com/CosmWasm/wasmvm | sed 's/.* //')

release-dry-run:
	docker run \
		--rm \
		-e COSMWASM_VERSION=$(COSMWASM_VERSION) \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v `pwd`:/go/src/terrad \
		-w /go/src/terrad \
		$(GORELEASER_IMAGE) \
		release \
		--clean \
		--skip-publish

release-snapshot:
	docker run \
		--rm \
		-e COSMWASM_VERSION=$(COSMWASM_VERSION) \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v `pwd`:/go/src/terrad \
		-w /go/src/terrad \
		$(GORELEASER_IMAGE) \
		release \
		--clean \
		--snapshot \
		--skip-validate \
		--skip-publish