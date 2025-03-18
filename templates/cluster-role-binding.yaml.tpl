apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: crolebind-admin-$USER_NAME
subjects:
  - kind: User
    name: "$USER_EMAIL"  # The email address from the OIDC token
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io