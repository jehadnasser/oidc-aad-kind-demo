echo "############### 00_load-data.sh ###############"

# Customize the following variables as needed
# -------------------------------------------

### AAD OIDC Configurations ###
# Define registered app name
APP_NAME="kind-oidc-app-$(openssl rand -hex 4)"
CLIENT_SECRET_NAME="kind-oidc-secret-$(openssl rand -hex 4)"

# Define the redirect URIs for the app
readonly WEB_REDIRECT_URIS="http://localhost"
GENERAL_ENV_FILE_PATH="./.env"
ENV_FILE_PATH="./oidc-aad-config.env"
ENV_FILE_NAME=$(basename "$ENV_FILE_PATH")

readonly OUTPUT_RBAC_DIR="rbac"
readonly TEMPLATE_RBAC_FILE="templates/cluster-role-binding.yaml.tpl"
readonly TEMPLATE_KIND_CONFIG_FILE="templates/kind-cluster-configs.yaml.tpl"

# Load the environment variables
load_env_vars "$GENERAL_ENV_FILE_PATH"
load_env_vars "$ENV_FILE_PATH" "$ANSIBLE_VAULT_PASSWORD"

# Check if the required variables are set
is_var_set "$KIND_CLUSTER_NAME" "KIND_CLUSTER_NAME" || return 1
is_var_set "$ANSIBLE_VAULT_PASSWORD" "ANSIBLE_VAULT_PASSWORD" || return 1
is_var_set "$AZURE_TENANT_ID" "AZURE_TENANT_ID" || return 1

OIDC_ISSUER_URL=https://login.microsoftonline.com/$AZURE_TENANT_ID/v2.0

TIMEOUT=60
DELAY=5

# Don't edit under this line
# ---------------------------

# Permission Identifier for `email` and `User.Read` (fixed values)
# full list: https://docs.microsoft.com/en-us/graph/permissions-reference
EMAIL_PERMISSION_ID="64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0"
USER_READ_PERMISSION_ID="e1fe6dd8-ba31-4d61-89e7-88639da4683d"
# Microsoft Graph API ID (fixed value)
GRAPH_API_ID="00000003-0000-0000-c000-000000000000"