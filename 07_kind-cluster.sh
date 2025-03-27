echo "############### prepare-kind-cluster.sh ###############"

# Clean up the old Kind cluster if it exists
kubectl config delete-context "kind-$KIND_CLUSTER_NAME" || true
kubectl config delete-cluster "kind-$KIND_CLUSTER_NAME" || true
kubectl config unset "users.kind-$KIND_CLUSTER_NAME" || true
kubectl config unset "users.$OIDC_USER_NAME" || true
kind delete cluster --name "$KIND_CLUSTER_NAME" || true

# Load env vars in the kind template and create the Kind cluster
echo "🚀 Creating Kind cluster..."
envsubst < "$TEMPLATE_KIND_CONFIG_FILE" | kind create cluster --config=-

echo "⏳ Waiting for all nodes to be ready..."
kubectl wait --for=condition=ready node --all --timeout=300s

echo "✅ Kind cluster is ready!"
echo "🔍 OIDC client ID:"
kubectl get pod -n kube-system -l component=kube-apiserver -o yaml | grep -A3 "oidc-client-id"

#############################################
# add cluster role binding for users
#############################################
echo "🔹 Creating RBAC configurations for users..."
# Loop through users and generate RBAC configs
for user_name in "${!USERS[@]}"; do
  user_email="${USERS[$user_name]}"
  generate_rbac_config "$user_name" "$user_email"
done

# Apply all generated RBAC configurations
kubectl apply -f "$OUTPUT_RBAC_DIR/*.yaml"
echo "✅ All RBAC configurations applied to the cluster!"
rm -rf "$OUTPUT_RBAC_DIR"