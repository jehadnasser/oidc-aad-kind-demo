#############################################
# tests
#############################################
echo "############### tests.sh ###############"

# test the oidc user
kubectl --user=oidc get nodes

# test the default user
kubectl get nodes