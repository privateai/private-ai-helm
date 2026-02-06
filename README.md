# Private AI Helm Chart

This infrastructure as code project is suitable for a development environment release of the Private AI product.
Feel free to use this Helm chart as a boilerplate for your Private AI container deployment.

Please keep in mind that for deployments requiring a public facing endpoint, you will need to provide your own cerificate / deployment configurations. This Helm chart is meant to help you get started with your deployment, and is NOT ready to be used directly for a production deployment.

## Prerequisites

- You must have a valid Private AI license file and docker credentials. If you do not have both, please [contact us](https://www.private-ai.com/en/company/contact-us)
- You must have an existing kubernetes cluster
- Helm version 4.0.0 or greater

## Installing the chart

To install the Private AI chart, follow the steps below

```console
# Create a namespace in your cluster for the private-ai deployment
kubectl create namespace private-ai

# Create a secret with your docker credentials from the customer portal
kubectl -n private-ai create secret docker-registry crprivateaiprod-creds \
  --docker-server=crprivateaiprod.azurecr.io \
  --docker-username=USERNAME \
  --docker-password=PASSWORD

# Login to the helm registry with your docker credentials
helm registry login crprivateaiprod.azurecr.io

# Create a custom values file for your specific installation
helm show values oci://crprivateaiprod.azurecr.io/helm/private-ai:1.6.0 > values.custom.yaml

# Copy your license.json file contents and paste them into the license.data section of the values.custom.yaml file with single quotes surrounding, as per below
license:
  data: '{"id":"..."}'

# Upgrade or install the Private AI chart with a name and namespace of private-ai
helm upgrade --install \
  private-ai oci://crprivateaiprod.azurecr.io/helm/private-ai \
  --namespace private-ai \
  -f values.custom.yaml \
  --version 1.6.0
```

## Testing

To test the Private AI container is functional, follow the steps below.

```console
helm test --namespace private-ai private-ai
```

## Uninstall

To uninstall the Private AI container, follow the steps below.

```console
helm uninstall --namespace private-ai private-ai
```

## Additional Configuration
To customize your deployment, enable different sections of your values.yaml file as per the documentation below.

### Ingress Controller
If you would like to set up an external ingress to enable external traffic to reach your the Private AI deployment, you must enable the haproxy-ingress and cert-manager helm charts in the values.yaml file. Additionally, a sample ingress deployment file is included, and can be deployed with self-signed certificates for testing.

If you would like to deploy your own certificate issuer and certificates, please see the [cert-manager docs](https://cert-manager.io/docs/).

The haproxy-ingress configuration required to host a certificate and manage incoming traffic from the ingress to the Private AI deployment is included with the chart. For more advanced configuration, please see the [haproxy-ingress docs](https://haproxy-ingress.github.io/docs/getting-started/).

Note: The haproxy-ingress and cert-manager helm charts are not listed as dependencies in this chart, and must be installed separately prior to installation.

```console
# Create a namespaces in your cluster for the cert-manager chart
kubectl create namespace cert-manager

# Upgrade or install cert-manager into the cluster with custom resource definitions
helm upgrade --install \
  cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --namespace cert-manager \
  --set crds.enabled=true \
  --set clusterResourceNamespace=private-ai

# Required webhook settings if deploying to AWS with the VPC-CNI plugin
#  --set webhook.hostNetwork=true \
#  --set webhook.securePort=10255

# Create a namespaces in your cluster for the haproxy-ingress chart
kubectl create namespace haproxy-controller

# Upgrade or install haproxy-ingress into the cluster
helm upgrade --install \
  haproxy-kubernetes-ingress oci://ghcr.io/haproxytech/helm-charts/kubernetes-ingress \
  --namespace haproxy-controller \
  --set controller.service.type=LoadBalancer

# Required setting for AWS, see https://github.com/haproxytech/helm-charts/tree/main/kubernetes-ingress#installing-on-amazon-elastic-kubernetes-service-eks
#  --set controller.service.enablePorts.quic=false

# Required setting for Azure, see https://github.com/haproxytech/helm-charts/tree/main/kubernetes-ingress#installing-on-azure-managed-kubernetes-service-aks
#  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz


# Update your values.custom.yaml file with the appropriate values under ingress

# Proceed with installing / upgrading private-ai via helm into the private-ai namespace
helm upgrade --install \
  private-ai oci://crprivateaiprod.azurecr.io/helm/private-ai \
  --namespace private-ai \
  -f values.custom.yaml \
  --version 1.6.0
```

### External Secrets Operator
If you would like to store you license file and docker credentials in an external secret store, you can use the External Secrets Operator helm chart. Please see the [external secrets operator docs](https://external-secrets.io/latest/).

Note: The External Secrets chart is not listed as a dependency in this chart, and must be installed separately prior to installation.

```console
# Create a namespace in your cluster for the private-ai deployment
kubectl create namespace private-ai

# Add the External Secrets helm repo
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

# Upgrade or install the External Secrets operator into the private-ai namespace
helm upgrade --install \
  external-secrets external-secrets/external-secrets \
  --namespace private-ai

# Create two secrets, one for the license file and one for the docker credentials, in your external secret store of choice. You can optionally create a secret for environment variables to configure the Private AI container.
```

#### AWS Secrets Manager Steps
Example AWS secret for Private AI license file
![license-type](./images/aws-license-type.png)
![license-name](./images/aws-license-name.png)
Example AWS secret for Private AI docker credentials
![docker-type](./images/aws-docker-type.png)
![docker-name](./images/aws-docker-name.png)
Example AWS secret for Private AI environment variables
This is optional, and can be enabled or disabled in the values file.
![env-type](./images/aws-env-type.png)
![env-name](./images/aws-env-name.png)

Next, configure the AWS Secret Store. See [the AWS Secrets Manager docs](https://external-secrets.io/latest/provider/aws-secrets-manager/) for detailed instructions.
```console
# Create a secret-store within the private-ai namespace
# Example AWS secret store based on access key:
kubectl create secret -n private-ai generic awssm-secret --from-file=./access-key --from-file=./secret-access-key
kubectl apply -f aws-secret-store.yaml
```
```yaml
# aws-secret-store.yaml
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: secret-store
  namespace: private-ai
spec:
  provider:
    aws:
      service: SecretsManager
      region: ca-central-1
      auth:
        secretRef:
          accessKeyIDSecretRef:
            namespace: private-ai
            name: awssm-secret
            key: access-key
          secretAccessKeySecretRef:
            namespace: private-ai
            name: awssm-secret
            key: secret-access-key
```
#### Azure Key Vault Steps
Note: Azure does not allow for multiple key-value pairs per secret entry. To match the data structure of the External Secrets Operator, each secret must be uploaded as a JSON object, with the key matching the property from the values file.

Example Azure secret for Private AI license file
![license-name](./images/azure-license-name.png)
```json
{
  "license.json": { "id": 1, "tier": "..." }
}
```
Example Azure secret for Private AI docker credentials
![docker-name](./images/azure-docker-name.png)
```json
{
  "server": "crprivateaiprod.azurecr.io",
  "username": "docker-username",
  "password": "docker-password"
}
```
Example Azure secret for Private AI environment variables
This is optional, and can be enabled or disabled in the values file.
![env-name](./images/azure-env-name.png)
```json
{
  "PAI_AZ_COMPUTER_VISION_KEY": "secretvalue"
}
```

Next, configure the Azure Secret Store. See the [Azure Key Vault docs](https://external-secrets.io/latest/provider/azure-key-vault/) for more detailed instructions.

You must configure access from the Secret Store object in kubernetes to the Azure Key Vault. In this example, we are using a workload identity federated with an OIDC provider in the kubernetes cluster, and a simple access policy on the key vault. See the [Azure Workload Identity docs](https://azure.github.io/azure-workload-identity/docs/quick-start.html) for more options.

```console
# Set up your AKS cluster and resource group variables
export AKS_CLUSTER_NAME="yourcluster"
export RESOURCE_GROUP="yourresourcegroup"
export USER_ASSIGNED_IDENTITY_NAME="youridentityname"

# Get the Key Vault URL
export KEY_VAULT_URL="$(az keyvault show --name $AKS_CLUSTER_NAME --query 'properties.vaultUri' -o tsv)"

# Create a user-assigned managed identity if using user-assigned managed identity for this tutorial
az identity create --name $USER_ASSIGNED_IDENTITY_NAME --resource-group $RESOURCE_GROUP

# Create key vault policy for UAI
az keyvault set-policy --name $AKS_CLUSTER_NAME \
  --secret-permissions get \
  --object-id $(az identity show --name $USER_ASSIGNED_IDENTITY_NAME --resource-group $RESOURCE_GROUP --query 'principalId' -o tsv)

# Create kubernetes service account bound to UAI
export USER_ASSIGNED_IDENTITY_CLIENT_ID="$(az identity show --name $USER_ASSIGNED_IDENTITY_NAME --resource-group $RESOURCE_GROUP --query 'clientId' -o tsv)"
export USER_ASSIGNED_IDENTITY_TENANT_ID="$(az identity show --name $USER_ASSIGNED_IDENTITY_NAME --resource-group $RESOURCE_GROUP --query 'tenantId' -o tsv)"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: ${USER_ASSIGNED_IDENTITY_CLIENT_ID}
    azure.workload.identity/tenant-id: ${USER_ASSIGNED_IDENTITY_TENANT_ID}
  name: azure-keyvault
  namespace: private-ai
EOF

# Create federated credential
az identity federated-credential create \
  --name "kubernetes-federated-credential" \
  --identity-name $USER_ASSIGNED_IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --issuer $(az aks show --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --query "oidcIssuerProfile.issuerUrl" -o tsv) \
  --subject "system:serviceaccount:private-ai:azure-keyvault"

# Create the secret store
cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: azure-backend
  namespace: private-ai
spec:
  provider:
    azurekv:
      authType: WorkloadIdentity
      vaultUrl: ${KEY_VAULT_URL}
      serviceAccountRef:
        name: azure-keyvault
EOF
```

Update your values.custom.yaml file to enable the external secrets operator, and disable the default secret creation. Ensure to update the docker credentials and license remoteRefKey and properties as per the secret names and properties, respectively.

```console
externalsecrets:
  enabled: true
...
```

Proceed with installing the helm chart
```console
# Proceed with installing / upgrading private-ai via helm into the private-ai namespace
helm upgrade --install \
  private-ai oci://crprivateaiprod.azurecr.io/helm/private-ai \
  --namespace private-ai \
  -f values.custom.yaml \
  --version 1.6.0
```
