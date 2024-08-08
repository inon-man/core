#!/usr/bin/make -f

include scripts/makefiles/tools.mk
include scripts/makefiles/build.mk
include scripts/makefiles/deps.mk
include scripts/makefiles/e2e.mk
include scripts/makefiles/lint.mk
include scripts/makefiles/proto.mk
include scripts/makefiles/tests.mk
include scripts/makefiles/localterra.mk
include scripts/makefiles/localnet.mk
include scripts/makefiles/release.mk

.DEFAULT_GOAL := help
help:
	@echo "Available top-level commands:"
	@echo ""
	@echo "Usage:"
	@echo "    make [command]"
	@echo ""
	@echo "  make install               Install terrad binary"
	@echo "  make build                 Build terrad binary"
	@echo "  make build-linux           Build static terrad binary for linux environment"
	@echo "  make deps                  Show available deps commands"
	@echo "  make e2e                   Show available e2e commands"
	@echo "  make lint                  Show available lint commands"
	@echo "  make localterra            Show available localterra commands"
	@echo "  make localnet              Show available localnet commands"
	@echo "  make proto                 Show available proto commands"
	@echo "  make test                  Show available test commands"
	@echo "  make release               Show available release commands"
	@echo ""
	@echo "Run 'make [subcommand]' to see the available commands for each subcommand."

# Go version to be used in docker images
GO_VERSION := $(shell cat go.mod | grep -E 'go [0-9].[0-9]+' | cut -d ' ' -f 2)
# currently installed Go version
GO_MODULE := $(shell cat go.mod | grep "module " | cut -d ' ' -f 2)
GO_MAJOR_VERSION = $(shell go version | cut -c 14- | cut -d' ' -f1 | cut -d'.' -f1)
GO_MINOR_VERSION = $(shell go version | cut -c 14- | cut -d' ' -f1 | cut -d'.' -f2)
# minimum supported Go version
GO_MINIMUM_MAJOR_VERSION = $(shell cat go.mod | grep -E 'go [0-9].[0-9]+' | cut -d ' ' -f2 | cut -d'.' -f1)
GO_MINIMUM_MINOR_VERSION = $(shell cat go.mod | grep -E 'go [0-9].[0-9]+' | cut -d ' ' -f2 | cut -d'.' -f2)
# message to be printed if Go does not meet the minimum required version
GO_VERSION_ERR_MSG = "ERROR: Go version $(GO_MINIMUM_MAJOR_VERSION).$(GO_MINIMUM_MINOR_VERSION)+ is required"

export GO111MODULE = on

VERSION := $(shell echo $(shell git describe --tags) | sed 's/^v//')
COMMIT := $(shell git log -1 --format='%H')

LEDGER_ENABLED ?= true
BUILDDIR ?= $(CURDIR)/build
HTTPS_GIT := https://github.com/classic-terra/core.git
DOCKER := $(shell which docker)
E2E_UPGRADE_VERSION := "v8_1"

# process build tags

build_tags = netgo
ifeq ($(LEDGER_ENABLED),true)
  ifeq ($(OS),Windows_NT)
    GCCEXE = $(shell where gcc.exe 2> NUL)
    ifeq ($(GCCEXE),)
      $(error gcc.exe not installed for ledger support, please install or set LEDGER_ENABLED=false)
    else
      build_tags += ledger
    endif
  else
		UNAME_S = $(shell uname -s)
    ifeq ($(UNAME_S),OpenBSD)
      $(warning OpenBSD detected, disabling ledger support (https://github.com/cosmos/cosmos-sdk/issues/1988))
    else
      GCC = $(shell command -v gcc 2> /dev/null)
      ifeq ($(GCC),)
        $(error gcc not installed for ledger support, please install or set LEDGER_ENABLED=false)
      else
        build_tags += ledger
      endif
    endif
  endif
endif

ifeq (cleveldb,$(findstring cleveldb,$(COSMOS_BUILD_OPTIONS)))
  build_tags += gcc
else ifeq (rocksdb,$(findstring rocksdb,$(COSMOS_BUILD_OPTIONS)))
  build_tags += gcc rocksdb
else ifeq (pebbledb,$(findstring pebbledb,$(COSMOS_BUILD_OPTIONS)))
  build_tags += pebbledb
endif
build_tags += $(BUILD_TAGS)
build_tags := $(strip $(build_tags))

whitespace :=
whitespace := $(whitespace) $(whitespace)
comma := ,
build_tags_comma_sep := $(subst $(whitespace),$(comma),$(build_tags))

# process linker flags

ldflags = -X github.com/cosmos/cosmos-sdk/version.Name=terra \
		  -X github.com/cosmos/cosmos-sdk/version.AppName=terrad \
		  -X github.com/cosmos/cosmos-sdk/version.Version=$(VERSION) \
		  -X github.com/cosmos/cosmos-sdk/version.Commit=$(COMMIT) \
		  -X "github.com/cosmos/cosmos-sdk/version.BuildTags=$(build_tags_comma_sep)"

# DB backend selection
ifeq (cleveldb,$(findstring cleveldb,$(COSMOS_BUILD_OPTIONS)))
  ldflags += -X github.com/cosmos/cosmos-sdk/types.DBBackend=cleveldb
else ifeq (rocksdb,$(findstring rocksdb,$(COSMOS_BUILD_OPTIONS)))
  ldflags += -X github.com/cosmos/cosmos-sdk/types.DBBackend=rocksdb
else ifeq (pebbledb,$(findstring pebbledb,$(COSMOS_BUILD_OPTIONS)))
	ldflags += -X github.com/cosmos/cosmos-sdk/types.DBBackend=pebbledb
endif
ifeq (,$(findstring nostrip,$(COSMOS_BUILD_OPTIONS)))
  ldflags += -w -s
endif
ifeq ($(LINK_STATICALLY),true)
	ldflags += -linkmode=external -extldflags "-Wl,-z,muldefs -static"
endif
ldflags += $(LDFLAGS)
ldflags := $(strip $(ldflags))

BUILD_FLAGS := -tags "$(build_tags)" -ldflags '$(ldflags)'
# check for nostrip option
ifeq (,$(findstring nostrip,$(COSMOS_BUILD_OPTIONS)))
  BUILD_FLAGS += -trimpath
endif

# Note that this skips certain tests that are not supported on WSL
# This is a workaround to enable quickly running full unit test suite locally
# on WSL without failures. The failures are stemming from trying to upload
# wasm code. An OS permissioning issue.
is_wsl := $(shell uname -a | grep -i Microsoft)
ifeq ($(is_wsl),)
    # Not in WSL
    SKIP_WASM_WSL_TESTS := "false"
else
    # In WSL
    SKIP_WASM_WSL_TESTS := "true"
endif
###############################################################################
###                            Build & Install                              ###
###############################################################################

build: build-check-version go.sum
	mkdir -p $(BUILDDIR)/
	GOWORK=off go build -mod=readonly  $(BUILD_FLAGS) -o $(BUILDDIR)/ $(GO_MODULE)/cmd/terrad

install: build-check-version go.sum
	GOWORK=off go install -mod=readonly $(BUILD_FLAGS) $(GO_MODULE)/cmd/terrad

build-linux:
	mkdir -p $(BUILDDIR)
	@DOCKER_BUILDKIT=1 docker build --platform linux/amd64 --tag classic-terra/core ./
	docker tag classic-terra/core classic-terra/core:${COMMIT}
	docker create --platform linux/amd64 --name temp classic-terra/core:latest
	docker cp temp:/bin/terrad $(BUILDDIR)/
	docker rm temp

build-release: build-release-amd64 build-release-arm64

build-release-amd64: go.sum
	mkdir -p $(BUILDDIR)/release
	$(DOCKER) buildx create --name core-builder || true
	$(DOCKER) buildx use core-builder
	$(DOCKER) buildx build \
		--build-arg GO_VERSION=$(GO_VERSION) \
		--build-arg GIT_VERSION=$(VERSION) \
		--build-arg GIT_COMMIT=$(COMMIT) \
    --build-arg BUILDPLATFORM=linux/amd64 \
    --build-arg GOOS=linux \
    --build-arg GOARCH=amd64 \
		-t core:local-amd64 \
		--load \
		-f Dockerfile .
	$(DOCKER) rm -f core-builder || true
	$(DOCKER) create -ti --name core-builder core:local-amd64
	$(DOCKER) cp core-builder:/bin/terrad $(BUILDDIR)/release/terrad
	tar -czvf $(BUILDDIR)/release/terra_$(VERSION)_Linux_x86_64.tar.gz -C $(BUILDDIR)/release/ terrad
	rm $(BUILDDIR)/release/terrad
	$(DOCKER) rm -f core-builder

build-release-arm64: go.sum
	mkdir -p $(BUILDDIR)/release
	$(DOCKER) buildx create --name core-builder || true
	$(DOCKER) buildx use core-builder 
	$(DOCKER) buildx build \
		--build-arg GO_VERSION=$(GO_VERSION) \
		--build-arg GIT_VERSION=$(VERSION) \
		--build-arg GIT_COMMIT=$(COMMIT) \
    --build-arg BUILDPLATFORM=linux/arm64 \
    --build-arg GOOS=linux \
    --build-arg GOARCH=arm64 \
		-t core:local-arm64 \
		--load \
		-f Dockerfile .
	$(DOCKER) rm -f core-builder || true
	$(DOCKER) create -ti --name core-builder core:local-arm64
	$(DOCKER) cp core-builder:/bin/terrad $(BUILDDIR)/release/terrad 
	tar -czvf $(BUILDDIR)/release/terra_$(VERSION)_Linux_arm64.tar.gz -C $(BUILDDIR)/release/ terrad 
	rm $(BUILDDIR)/release/terrad
	$(DOCKER) rm -f core-builder

###############################################################################
###                               Interchain test                           ###
###############################################################################
# Executes basic chain tests via interchaintest
ictest-start: ictest-build
	@cd tests/interchaintest && go test -race -v -run TestTerraStart .

ictest-validator: ictest-build
	@cd tests/interchaintest && go test -timeout=25m -race -v -run TestValidator .

ictest-ibc: ictest-build
	@cd tests/interchaintest && go test -race -v -run TestTerraGaiaIBCTranfer .

ictest-ibc-hooks: ictest-build
	@cd tests/interchaintest && go test -race -v -run TestTerraIBCHooks .

ictest-ibc-pfm: ictest-build
	@cd tests/interchaintest && go test -race -v -run TestTerraGaiaOsmoPFM .

ictest-ibc-pfm-terra: ictest-build
	@cd tests/interchaintest && go test -race -v -run TestTerraPFM .

ictest-build:
	@DOCKER_BUILDKIT=1 docker build -t terra:ictest ./

.PHONY: all build-linux build-linux-static install format lint \
	go-mod-cache draw-deps clean build \
	test test-all test-build test-cover test-unit test-race benchmark \
	release release-dry-run release-snapshot
