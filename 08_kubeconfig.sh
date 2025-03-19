#############################################
# kubeconfig
#############################################
echo "############### configure-kubeconfig.sh ###############"

kubectl oidc-login setup \
--oidc-issuer-url $OIDC_ISSUER_URL \
--oidc-client-id $AZURE_CLIENT_ID \
--oidc-client-secret $AZURE_CLIENT_SECRET

kubectl config set-credentials oidc \
--exec-api-version=client.authentication.k8s.io/v1 \
--exec-command=kubectl \
--exec-arg=oidc-login \
--exec-arg=get-token \
--exec-arg=--oidc-issuer-url=$OIDC_ISSUER_URL \
--exec-arg=--oidc-client-id=$AZURE_CLIENT_ID \
--exec-arg=--oidc-client-secret=$AZURE_CLIENT_SECRET

# remove default kind user
kubectl config unset users.kind-oidc-aad-demo

# configure the current-context to use oidc as the default
kubectl config set-context $(kubectl config current-context) --user=oidc
