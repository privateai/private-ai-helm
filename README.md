# Private AI Template Helm Chart 

This infrastructure as code project is suitable for a development environment release of the Private AI product.
Feel free to use this Helm chart as a boilerplate for your Private AI container deployment.
Please keep in mind that for deployments requiring a public facing endpoint, you will need to provide your own cerificate / deployment configurations.
This Helm chart is meant to help you get started with your deployment, and is NOT ready to be used directly for a production deployment.

If you would like to set up ingress-nginx to enable external traffic to reach your kubernetes cluster, you must install the ingress-nginx helm chart. There are some helper values for this chart for major cloud providers in `ingress-nginx/helm-values.yaml`.

Rename the values.example.yaml file to values.yaml and customize for your environment.
