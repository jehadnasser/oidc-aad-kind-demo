# OIDC AzureAD Kind Demo
Azure AD as an OIDC Identity Provider for Kind cluster

## Prerequisites

Before you begin, ensure you have the following installed:
- **Bash 4.0+ (for MacOS only)**: Needed for associative array syntax.
- **Ansible Vault**: For encrypting credentials.
- **Docker**: To run Kind and create Kubernetes clusters.

The following are being installed by the script (01_dependencies.sh):
- **Kind**
- **kubectl**
- **krew**
- **kubectl oidc-login**
- **Azure CLI (az)**


### Before you run the script
---
- Create a new ansible vault password and export it(we will use it in the next step)
  ```sh
  export ANSIBLE_VAULT_PASSWORD="mypassword"
  ```

- To create the encrypted .env file called `oidc-aad-config.yaml`:
  - Gather Required Azure Values from your Azure account
    - In Azure portal, search for `Microsoft Entra ID` and find `Tenant ID`
    - In Azure portal, search for `Subscriptions` and find `Subscription ID`
  - Create an .env file `secret.oidc-aad-config.env`:
      ```sh
      # Create a local file (ignored by .gitignore)
      touch secret.oidc-aad-config.env

      # Add these values (replace with your actual Azure data)
      echo "AZURE_TENANT_ID=xxxxx" >> secret.oidc-aad-config.env
      echo "AZURE_SUBSCRIPTION_ID=xxxxx" >> secret.oidc-aad-config.env

      ```
  - Encrypt the file with the output name `oidc-aad-config.env`:
      ```sh
      ansible-vault encrypt \
      secret.oidc-aad-config.env \
      --vault-password-file=<(echo "$ANSIBLE_VAULT_PASSWORD")  \
      --output oidc-aad-config.env
      ```
  - You can decrypt with the fowlling (if you need to)
    ```sh
    ansible-vault decrypt \
        oidc-aad-config.env \
        --vault-password-file=<(echo "$ANSIBLE_VAULT_PASSWORD")  \
        --output secret.oidc-aad-config.env
    ```
- Add your users in `03_users.sh`:
```sh
declare -A USERS
USERS["Red Rose"]="red.rose@example.com"
USERS["Blue Sky"]="blue.sky@example.com"
```

## Setup & Usage
### Running the Setup
```sh
bash bootstrap.sh
# or
./bootstrap.sh
```
This will: 
- Login to Azure account(Opens a login window for you to sign in to your Azure account.)
- Configure Azure AD as an OIDC Identity Provider
- Deploy a Kind cluster with OIDC authentication(A permission approval request will appear.)
- Apply RBAC roles for Azure AD users
- Configure kubectl for OIDC authentication

Once it's done, you should be able to run the following:
```sh
# test the oidc user
kubectl --user=oidc get nodes

# test the default user(it's same as oidc user)
kubectl get nodes
```


## Cleanup

To delete the Kind cluster and all resources:
```sh
kind delete cluster --name=oidc-aad-demo
```


## License

Under the **MIT License**.


## Author Information

&copy; Jehad Nasser 2025

https://github.com/jehadnasser

https://linkedin.com/in/jehadnasser

### Maintainer Contact

* Jehad Nasser
  <jehadnasser (at) outlook (dot) de>

---


Enjoy 🚀
