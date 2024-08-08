# Localnet
Localnet is a test kit that allows you to spin up local testnet.

## Help
```sh
make localnet
```

## Setup
```sh
make localnet-init
make localnet-start
```
* `localnet-init` populates testnet configuration in build directory by using `terrad testnet` command.
* `localnet-start` starts testnet containers

Each validator mnemonics are stored in build/node*/terrad/key_seed.json

## Feature: Upgrade test
Once the new upgrade source code is ready for app/upgrades, you can test the upgrade with the `make localnet-upgrade-test` command.

The scripts used in the `localnet-upgrade-test` perform the following.
* **upgrade-prepare.sh**: Find the version currently used by GitHub, install it as genesis/bin, and copy the version that will be upgraded to cosmovisor.
* **upgrade-test.sh**: Propose a Software upgrade governance proposal, vote with each validator node, and test the success of the final upgrade.

