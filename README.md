# Private AI Helm Chart

This infrastructure as code project is suitable for a development environment release of the Private AI product.
Feel free to use this Helm chart as a boilerplate for your Private AI container deployment.

Please keep in mind that for deployments requiring a public facing endpoint, you will need to provide your own cerificate / deployment configurations. This Helm chart is meant to help you get started with your deployment, and is NOT ready to be used directly for a production deployment.

## Prerequisites

- You must have a valid Private AI license file and docker credentials. If you do not have both, please [contact us](https://www.private-ai.com/en/company/contact-us)
- You must have an existing kubernetes cluster

## Installing the chart

To install the Private AI chart, follow the steps below.

```console
# Make sure you place your license file in your current directory
cp /path/to/license.json ./license.json

# Create a namespace in your cluster for the private-ai deployment
kubectl create namespace private-ai

# Update the helper script create-kubesecret.sh with your docker login credentials and then run it with the command below
sh helper_scripts/create-kubesecret.sh

# Login to the helm registry with your docker credentials
helm registry login crprivateaiprod.azurecr.io

# Optional - View and change the default helm values to customize your deployment. Add -f values.yaml.custom to the next command
helm show values oci://crprivateaiprod.azurecr.io/helm/private-ai:1.2.1 > values.yaml.custom

# Create a license values file from your license.json to enable the pod to startup successfully
echo -e "license:\n  data: '$(cat license.json)'" > license.yaml

# Upgrade or install the Private AI chart with a name and namespace of private-ai
helm upgrade --install \
--namespace private-ai \
private-ai \
-f license.yaml \
oci://crprivateaiprod.azurecr.io/helm/private-ai \
--version 1.2.1
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

## Ingress Configuration
If you would like to set up an external ingress to enable external traffic to reach your the Private AI deployment, you must enable the ingress-nginx and cert-manager helm charts in the values.yaml file. Additionally, a sample ingress deployment file is included, and can be deployed with self-signed certificates for testing.

If you would like to deploy your own certificate issuer and certificates, please see the [cert-manager docs](https://cert-manager.io/docs/)

The ingress-nginx configuration required to host a certificate and manage incoming traffic from the ingress to the Private AI deployment is included with the chart. For more advanced configuration, please see the [ingress-nginx docs](https://github.com/kubernetes/ingress-nginx)
