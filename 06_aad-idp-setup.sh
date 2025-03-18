echo "############### prepare-azure-ad.sh ###############"


#############################################
### Login to Azure ##########################
#############################################
# Log in to Azure
az account clear 2>/dev/null || true
az logout 2>/dev/null || true
az login --use-device-code --only-show-errors


#############################################
### Create App Registration
### Configure Authentication
### Configure Optional claims (groups, email)
### Configure API Permissions
### Create Client Secret
#############################################
echo "🔹 Creating Azure AD App Registration: $APP_NAME ..."

# Create the App Registration
APP_ID=$(az ad app create \
    --display-name "$APP_NAME" \
    --sign-in-audience "AzureADMyOrg" \
    --web-redirect-uris "$WEB_REDIRECT_URIS" \
    --enable-id-token-issuance true \
    --optional-claims '{
        "groupMembershipClaims": "SecurityGroup",
        "optionalClaims": {
            "idToken": [
                {
                    "name": "groups",
                    "source": null,
                    "essential": false,
                    "additionalProperties": []
                },
                {
                    "name": "email", 
                    "essential": true
                }
            ]
        }
    }' \
    --query appId -o tsv )

echo "✅ App Registration created successfully!"
echo "🔹 App ID: $APP_ID"

# Enable public client flows for mobile/desktop authentication
az ad app update --id "$APP_ID" --set isFallbackPublicClient=true
echo "✅ Enabled Mobile & Desktop flows."

# Create a new client secret
CLIENT_SECRET_PASSWORD=$(az ad app credential reset \
    --id "$APP_ID" \
    --display-name "$CLIENT_SECRET_NAME" \
    --query password -o tsv)

echo "✅ Client secret created!"


#############################################
### Assign and Grant API Permissions
#############################################
echo "🔹 Assigning & Granting API Permissions..."
# https://learn.microsoft.com/en-us/cli/azure/ad/app/permission?view=azure-cli-latest#az_ad_app_permission_add
# Assign API permissions for the claims
az ad app permission add \
    --id "$APP_ID" \
    --api "$GRAPH_API_ID" \
    --api-permissions "${EMAIL_PERMISSION_ID}=Scope" 2>/dev/null # View users' email address

az ad app permission add \
    --id "$APP_ID" \
    --api "$GRAPH_API_ID" \
    --api-permissions "${USER_READ_PERMISSION_ID}=Scope" 2>/dev/null # User.Read Sign in and read user profile

az ad app permission grant \
    --id "$APP_ID" \
    --api "$GRAPH_API_ID" \
    --scope "email User.Read" 2>/dev/null || echo "⚠️ Permission granted..."

echo "✅ Assigned & Granted necessary API permissions."


#############################################
### Create Service Principal and wait for it,
### Then assign users to the Enterprise App
#############################################
echo "🔹 Checking if Service Principal is exists"
# Create a new service principal
SP_ID=$(az ad sp show --id "$APP_ID" --query "id" -o tsv || true)
if [[ -z "$SP_ID" ]]; then
  echo "⚠️ Service Principal does not exist. Creating it..."
  az ad sp create --id "$APP_ID" 2>/dev/null
  
  # Wait for Azure AD to propagate the new SP
  echo "⏳ Waiting for SP to be available..."
  $TIMEOUT_CMD "$TIMEOUT" bash <<EOF
    while true; do
      SP_ID=\$(az ad sp show --id "$APP_ID" --query "id" -o tsv || true)
      if [[ -n "\$SP_ID" ]]; then
      echo "✅ Service Principal created successfully: \$SP_ID"
      break
      fi
      echo "⏳ Still waiting for Service Principal. Retrying in $DELAY seconds..."
      sleep "$DELAY"
    done
EOF

  check_timeout "❌ Timeout reached! Service Principal did not appear."
else
  echo "✅ Service Principal already exists: $SP_ID"
fi


#############################################
### Assign users to the Enterprise App
#############################################
echo "🔹 Assigning user as a member..."
SP_OBJECT_ID=$(az ad sp show --id "$APP_ID" --query "id" -o tsv || true)
is_var_set "$SP_OBJECT_ID" "Service Principal with ID $APP_ID" || return 1

# Loop through users list above
for USER_DISPLAY_NAME in "${!USERS[@]}"; do
  echo "🔹 Processing user: $USER_DISPLAY_NAME"

  USER_OBJECT_ID=$(az ad user list --display-name "$USER_DISPLAY_NAME" --query "[].id" -o tsv)

  # Check if the user exists
  is_var_set "$USER_OBJECT_ID" "User with display name $USER_DISPLAY_NAME" || { 
    echo "⚠️ Skipping..."
    continue
  }

  echo "✅ Found User: $USER_DISPLAY_NAME (ID: $USER_OBJECT_ID)"

  # Assign user to the Enterprise App
  az rest --method POST \
      --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$SP_OBJECT_ID/appRoleAssignedTo" \
      --headers "Content-Type=application/json" \
      --body "{
        \"principalId\": \"$USER_OBJECT_ID\",
        \"resourceId\": \"$SP_OBJECT_ID\",
        \"appRoleId\": \"00000000-0000-0000-0000-000000000000\"
      }"

  echo "✅ User $USER_DISPLAY_NAME assigned to the Enterprise App!"
done

echo "🚀 All users processed!"

# Update AZURE_CLIENT_ID and AZURE_CLIENT_SECRET
DECRYPTED_OIDC_ENV=$(get_env_vars "$ENV_FILE_PATH" "$ANSIBLE_VAULT_PASSWORD") || exit 1
UPDATED_ENV=$(echo "$DECRYPTED_OIDC_ENV" | sed -E \
    -e "s/^AZURE_CLIENT_ID=.*/AZURE_CLIENT_ID=$APP_ID/" \
    -e "s/^AZURE_CLIENT_SECRET=.*/AZURE_CLIENT_SECRET=$CLIENT_SECRET_PASSWORD/")
# If AZURE_CLIENT_ID or AZURE_CLIENT_SECRET is missing, append them
if ! echo "$UPDATED_ENV" | grep -q "^AZURE_CLIENT_ID="; then
    UPDATED_ENV="$UPDATED_ENV"$'\n'"AZURE_CLIENT_ID=$APP_ID"
fi
if ! echo "$UPDATED_ENV" | grep -q "^AZURE_CLIENT_SECRET="; then
    UPDATED_ENV="$UPDATED_ENV"$'\n'"AZURE_CLIENT_SECRET=$CLIENT_SECRET_PASSWORD"
fi

# Encrypt the updated environment file and write it back
echo "🔐 Encrypting and writing back to $ENV_FILE_PATH..."
bash -c "echo \"$UPDATED_ENV\" | ansible-vault encrypt --vault-password-file=<(echo \"$ANSIBLE_VAULT_PASSWORD\") --output \"$ENV_FILE_PATH\""

# reload env var after updating its values above
load_env_vars "$ENV_FILE_PATH" "$ANSIBLE_VAULT_PASSWORD"

#############################################
##  Print final details
#############################################
# Print final details
echo "🔹 App Registration Complete!"
echo "📌 Client ID: $APP_ID"
echo "📌 Client Secret: $CLIENT_SECRET_PASSWORD"

#############################################
### Cleanup ################################
#############################################
# Log out of Azure
az logout 2>/dev/null || true

# Clear sensitive variables
unset DECRYPTED_OIDC_ENV UPDATED_ENV