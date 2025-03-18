echo "############### functions.sh ###############"
#############################################
### Common Functions ###############################
#############################################

# Function to detect and set the correct timeout command
get_timeout_cmd() {
  if command -v gtimeout &>/dev/null; then
    echo "gtimeout"  # macOS (coreutils)
  elif command -v timeout &>/dev/null; then
    echo "timeout"   # Linux
  else
    # Detect OS
    my_os=$(uname -s)

    if [[ "$my_os" == "Linux" ]]; then
        if command -v apt &>/dev/null; then
            PKG_MANAGER="sudo apt install -y coreutils"
        elif command -v yum &>/dev/null; then
            PKG_MANAGER="sudo yum install -y coreutils"
        else
            echo "❌ ERROR: Unsupported package manager. Install coreutils manually."
            return 1
        fi
    elif [[ "$my_os" == "Darwin" ]]; then
        PKG_MANAGER="brew"
        $PKG_MANAGER install coreutils
    else
        echo "❌ Unsupported OS: $my_os"
        return 1
    fi
    echo "timeout"
  fi
}

# Function to check if a variable is not set
is_var_set() {
  local var_value="$1"
  local var_name="$2"

  if [ -z "$var_value" ]; then
    echo "❌ ERROR: $var_name is not set!"
    return 1  # Return error status
  fi
}

# Function to check if a file exists
is_file_exists() {
  local file_path="$1"

  if [ ! -f "$file_path" ]; then
    echo "❌ ERROR: File '$file_path' not found!"
    return 1  # Return error status
  fi
}

is_dir_exists() {
  local dir_path="$1"

  if [ ! -d "$dir_path" ]; then
    echo "❌ ERROR: Directory '$dir_path' not found!"
    return 1  # Return error status
  fi
}


# Function to check timeout
check_timeout() {
  if [ $? -eq 124 ]; then
    echo "❌ Timeout reached. $1"
    exit 1
  fi
}

load_env_vars() {
  echo "🔹 Running load_env_vars"
  local env_file_path="$1"
  local vault_password="$2"

  # Ensure the environment file exists
  is_var_set "$env_file_path" "Environment file path" || return 1
  is_file_exists "$env_file_path" || return 1

  # Extract file name for display
  local env_file_name
  env_file_name=$(basename "$env_file_path")

  local env_content=""

  # If a vault password is provided, attempt decryption
  if [[ -n "$vault_password" ]]; then
    echo "🔓 Decrypting $env_file_name..."
    env_content=$(bash -c "ansible-vault view '$env_file_path' --vault-password-file=<(echo '$vault_password')") || {
      echo "⚠️ Failed to decrypt $env_file_name. Skipping decryption..."
      return 1
  }
  else
    echo "⚠️ No vault password provided. Loading $env_file_name as plain text..."
    env_content=$(cat "$env_file_path")
  fi

  # Ensure the environment file has content
  is_var_set "$env_content" "Environment file content" || return 1

  # Load environment variables from the content
  echo "🔹 Reloading environment variables..."
  export $(echo "$env_content" | grep -v '^#' | xargs)

  echo "✅ Environment variables loaded successfully from $env_file_name!"
}

get_env_vars() {
  local env_file_path="$1"
  local vault_password="$2"

  # Ensure required variables are set
  is_var_set "$env_file_path" "Environment file path" || return 1
  is_var_set "$vault_password" "Ansible Vault password" || return 1
  is_file_exists "$env_file_path" || return 1

  # Use process substitution correctly with bash
  local decrypted_env
  decrypted_env=$(bash -c "ansible-vault view '$env_file_path' --vault-password-file=<(echo '$vault_password')")

  # Ensure decryption was successful
  is_var_set "$decrypted_env" "Decrypted environment content" || return 1

  # Return the decrypted content
  echo "$decrypted_env"
}

# Function to generate ClusterRoleBinding YAML from a template
generate_rbac_config() {
  local user_name="$1"
  local user_email="$2"

  # Ensure the template file exists
  is_file_exists "$TEMPLATE_RBAC_FILE" || return 1

  # Create the rbac directory if it does not exist
  is_dir_exists "$OUTPUT_RBAC_DIR" || mkdir -p "$OUTPUT_RBAC_DIR"


  # Create a filename-safe version of the username (replace spaces with dashes)
  local safe_user_name
  safe_user_name=$(echo "$user_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')

  # Define the output YAML file inside rbac/
  local output_file="$OUTPUT_RBAC_DIR/rbac-${safe_user_name}.yaml"

  # Replace placeholders in the template and save to output file
  sed -e "s|\$USER_NAME|$safe_user_name|g" \
      -e "s|\$USER_EMAIL|$user_email|g" \
      "$TEMPLATE_RBAC_FILE" > "$output_file"

  echo "✅ Generated: $output_file"
}
