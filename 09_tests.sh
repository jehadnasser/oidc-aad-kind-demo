#############################################
# tests
#############################################
echo -e "############### tests.sh ###############\n"

echo -e '⚙ Testing the oidc user `kubectl --user=$OIDC_USER_NAME get nodes`: \n'
# test the oidc user
kubectl --user=$OIDC_USER_NAME get nodes

echo -e '\n\n⚙ Testing the default user (now it is the oidc user) `kubectl get nodes`: \n'
# test the default user
kubectl get nodes