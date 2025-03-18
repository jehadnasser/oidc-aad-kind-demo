kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: "$KIND_CLUSTER_NAME"
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        apiVersion: kubeadm.k8s.io/v1beta3
        kind: ClusterConfiguration
        apiServer:
          extraArgs:
            oidc-issuer-url: "https://login.microsoftonline.com/${AZURE_TENANT_ID}/v2.0"
            oidc-client-id: "$AZURE_CLIENT_ID"
            oidc-username-claim: "email"
            oidc-groups-claim: "groups"
  - role: worker
