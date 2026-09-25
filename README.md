# Cloud-native DevOps with Radius

## Introduction

This repository accompanies a session on building cloud-native .NET applications with [Radius](https://radapp.io) without the YAML overload and without locking applications to a single cloud provider. Radius separates application definitions from infrastructure and deployment details by using abstract resource types such as SQL databases and Redis caches. This makes applications easier to develop, deploy, adapt, and move across environments.

The workspace contains hands-on demos that cover the complete journey from a local development loop with KIND to running applications on Azure Kubernetes Service (AKS). It also includes infrastructure definitions for Azure, application manifests, and custom [Recipes](recipes/) that show how Radius resources can be implemented. Recipes act as reusable infrastructure templates while still giving teams full control over the underlying deployment.

The examples are designed for .NET developers who want to build scalable applications while keeping infrastructure complexity manageable. They demonstrate how Radius tooling can simplify collaboration, support repeatable deployments, and provide greater flexibility across local Kubernetes and cloud environments.

## Local Environment - KIND

## Setup

> In a dev container the kind cluster is automatically provisioned.

### Forward KIND cluster services

- Do a port-forward in VS Code to `IP:Port` or
- Do a service forward with *kubectl*: `kubectl port-forward svc/nginx 8080:8080 --address 0.0.0.0`

### cloud-provider-kind service

[`cloud-provider-kind`](https://github.com/kubernetes-sigs/cloud-provider-kind) implements `LoadBalancer` services for KIND clusters and runs as a background service in the dev container (no systemd is available, so it is managed via a SysV init script).

- Start: `sudo service cloud-provider-kind start`
- Stop: `sudo service cloud-provider-kind stop`
- Restart: `sudo service cloud-provider-kind restart`
- Status: `sudo service cloud-provider-kind status`

#### Retrieve logs

Logs are written to `/var/log/cloud-provider-kind.log`:

```bash
tail -n +1 -f /var/log/cloud-provider-kind.log
```

### Nginx Test Deployment

Do an *nginx* test deployment in *default* namespace.

> Ensure cloud-provider-kind is running: `sudo service cloud-provider-kind start`

Create a deployment:

```bash
kubectl create deployment --image=nginx --replicas=3 --port=80 nginx
```

Expose the deployment:

```bash
kubectl expose deployment nginx --port=8080 --target-port=80 --type=LoadBalancer
```

## Azure Environment - AKS + ACR

The Azure demo environment consists of a small Azure Kubernetes Service (AKS) cluster and an Azure Container Registry (ACR). The infrastructure is defined in [`setup/infra/main.bicep`](setup/infra/main.bicep) and can be deployed with the accompanying PowerShell script.

### Prerequisites

- An Azure subscription with permission to create resources and role
    assignments
- The [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
- [PowerShell](https://learn.microsoft.com/powershell/scripting/install/installing-powershell)

Sign in to Azure and select the subscription to use:

```bash
az login
az account set --subscription <subscription-id-or-name>
```

### Deploy the environment

From the repository root, run:

```bash
setup/infra/main.ps1
```

The script uses the default parameters from [`setup/infra/parameters.default.bicepparam`](setup/infra/parameters.default.bicepparam).
No parameter changes are required for demo purposes. The default Azure region is `polandcentral`; it can be changed when necessary:

```bash
setup/infra/main.ps1 -Location westeurope
```

### Use the deployed resources

List the created resources:

```bash
az resource list \
    --resource-group rg-cloud-native-radius \
    --output table
```

### Remove the environment

The resources can be removed after the demo by deleting the resource group:

```bash
az group delete --name rg-cloud-native-radius
```

## Radius Recipes

Radius Recipes encapsulate the deployment of infrastructure used by a Radius application. The custom recipes in this repository are located under [`recipes/`](recipes/).

### Overview

| Recipe | Resource | File | Deployment | Description |
| --- | --- | --- | --- | --- |
| Azure SQL Database | Applications.Datastores/sqlDatabases | [`recipes/azure/sqldatabase.bicep`](recipes/azure/sqldatabase.bicep) | Azure Resource Manager / Azure SQL | An Azure SQL server resource with a configurable SKU and backup storage redundancy. |

### Publish a recipe to Azure Container Registry

Recipes are published as Bicep OCI artifacts. The helper script [`recipes/push-recipe-to-acr.sh`](recipes/push-recipe-to-acr.sh) logs in to the Azure Container Registry and publishes the recipe with `rad bicep publish`.

Example for publishing the SQL recipe:

```bash
./recipes/push-recipe-to-acr.sh \
    --acr <registry-name>.azurecr.io \
    --file recipes/azure/sqldatabase.bicep \
    --target br:<registry-name>.azurecr.io/radius-recipes/sqldatabase:0.60.2
```

Here, `<registry-name>` is the name of the Azure Container Registry. The `--target` value must start with `br:` and contain the registry's complete login server.

### Register a recipe in Radius

After publishing, register the recipe for the Radius environment and group
created for your application. The values are not required to be `azure`; use
the names of the environment and group you created for the Radius application.
The following example registers the recipe from the Azure Container Registry
for the `Applications.Datastores/sqlDatabases` resource type:

```bash
rad recipe register default \
    --environment <environment-name> \
    --group <group-name> \
    --template-kind bicep \
    --template-path "<registry-name>.azurecr.io/radius-recipes/sqldatabase:0.60.2" \
    --resource-type "Applications.Datastores/sqlDatabases" \
    --parameters skuName=Basic \
    --parameters skuTier=Basic \
    --parameters backupStorageRedundancy=Local
```

Replace `<environment-name>` and `<group-name>` with the names of the Radius
environment and group created for your application.

The recipe must be registered before deploying
[`apps/demo99-beer-rating-azure/app.bicep`](apps/demo99-beer-rating-azure/app.bicep).
The `Applications.Datastores/sqlDatabases` resource then uses the registered
recipe automatically.

Registered recipes can be removed with the following command:

```bash
rad recipe unregister default \
    --resource-type "Applications.Datastores/sqlDatabases"
```

