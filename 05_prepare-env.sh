echo "############### 001_prepare-env.sh ###############"

TIMEOUT_CMD=$(get_timeout_cmd) || exit 1

# Create the rbac directory if it does not exist
mkdir -p "$OUTPUT_RBAC_DIR"
