#############################################
# kubeconfig
#############################################
echo "############### configure-kubeconfig.sh ###############"

# It configures your ~/.kube/config file to add a user entry 
# that uses OIDC as the authentication mechanism
kubectl config set-credentials $OIDC_USER_NAME \
--exec-api-version=client.authentication.k8s.io/v1 \
--exec-command=kubectl \
--exec-interactive-mode=Never \
--exec-arg=oidc-login \
--exec-arg=get-token \
--exec-arg=--oidc-issuer-url=$OIDC_ISSUER_URL \
--exec-arg=--oidc-client-id=$AZURE_CLIENT_ID \
--exec-arg=--oidc-client-secret=$AZURE_CLIENT_SECRET \

# remove default kind user
kubectl config unset "users.kind-$KIND_CLUSTER_NAME" || true

# configure the current-context to use oidc as the default
kubectl config set-context $(kubectl config current-context) --user=$OIDC_USER_NAME
