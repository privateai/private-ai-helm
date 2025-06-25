# This is a helper script to create a secret for your helm chart. Please replace your username and password with valid credentials
# If you are following the tutorial from https://docs.private-ai.com/setup-guide-kubernetes/ please replace NAMESPACENAME with 
# the namespace name you have selected for the deployment

kubectl create secret docker-registry crprivateaiprod-creds \
    --docker-server=crprivateaiprod.azurecr.io \
    --docker-username=username \
    --docker-password=pass \
    --namespace NAMESPACENAME
