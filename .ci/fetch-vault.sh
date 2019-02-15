#!/usr/bin/env bash
# This script fetches and unzips vault.
set -ex

VAULT_VERSION="${VAULT_VERSION:-1.0.1}"
VAULT_ZIPFILE="vault_${VAULT_VERSION}_linux_amd64.zip"

wget "https://releases.hashicorp.com/vault/${VAULT_VERSION}/${VAULT_ZIPFILE}"
unzip "${VAULT_ZIPFILE}"
