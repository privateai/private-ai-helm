# This is a helper script to create a secret for your helm chart. Please replace your username and password with valid credentials

kubectl create secret docker-registry crprivateaiprod-creds \
    --docker-server=crprivateaiprod.azurecr.io \
    --docker-username=username \
    --docker-password=pass
