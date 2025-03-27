#!/usr/bin/env bash

set -eo pipefail

# Ensure the script runs from its own directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Source all modules (relative paths will now work correctly)
source "$SCRIPT_DIR/01_dependencies.sh"
source "$SCRIPT_DIR/02_functions.sh"
source "$SCRIPT_DIR/03_users.sh"
source "$SCRIPT_DIR/04_load-data.sh"
source "$SCRIPT_DIR/05_prepare-env.sh"
source "$SCRIPT_DIR/06_aad-idp-setup.sh"
source "$SCRIPT_DIR/07_kind-cluster.sh"
source "$SCRIPT_DIR/08_kubeconfig.sh"
source "$SCRIPT_DIR/09_tests.sh"

echo -e "\n\n✅ OIDC established successfully!"
