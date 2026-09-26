# Cloud-native DevOps with Radius

## Introduction

This repository accompanies a session on building cloud-native .NET applications with [Radius](https://radapp.io) without the YAML overload and without locking applications to a single cloud provider. Radius separates application definitions from infrastructure and deployment details by using abstract resource types such as SQL databases and Redis caches. This makes applications easier to develop, deploy, adapt, and move across environments.

The workspace contains hands-on demos that cover the complete journey from a local development loop with KIND to running applications on Azure Kubernetes Service (AKS). It also includes infrastructure definitions for Azure, application manifests, and custom [Recipes](recipes/) that show how Radius resources can be implemented. Recipes act as reusable infrastructure templates while still giving teams full control over the underlying deployment.

The examples are designed for .NET developers who want to build scalable applications while keeping infrastructure complexity manageable. They demonstrate how Radius tooling can simplify collaboration, support repeatable deployments, and provide greater flexibility across local Kubernetes and cloud environments.

## Local Environment - KIND

## Setup

> In a dev container the kind cluster is automatically provisioned.

```
kind create cluster --config .devcontainer/kind/config.yaml
```

### Forward KIND cluster services

- Do a port-forward in VS Code to `IP:Port` or
- Do a service forward with *kubectl*: `kubectl port-forward svc/nginx 8080:8080 --address 0.0.0.0`

### cloud-provider-kind service

> **WARNING**:  
> If you start the cloud-provider-kind, it provisions CRDs for Gateway API. After that, Radius init (`rad init`) and installation (`rad install kubernetes`) will not run proberly, because Radius tries to install the same CRDs via *helm*. That results in a conflict error.  
> *So when running the rad setup, ensure to start cloud-provider-kind after `rad init` or `rad installation kubernetes`*

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

## Azure Environment - Service Principal

To use Azure Backing Service, Radius requires a connection to Azure. The simples way to do this, is by creating a service principal.
Create a service principal named **radius* with access on resource group *rg-cnr-resources*:

```bash
az ad sp create-for-rbac --name radius \
    --role Owner \
    --scope /subscriptions/63d3cb88-9621-46c0-b611-36e23c5b402d/resourceGroups/rg-cnr-resources
```

Use the service principal when connecting to Azure via `rad init --full`. After that, Radius can create Azure resources using the service principal.

> The service principal is required for [*demo5-beer-rating-azure-sql*](apps/demo5-beer-rating-azure-sql/app.bicep)

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
recipes/push-recipe-to-acr.sh \
    --acr <registry-name>.azurecr.io \
    --file recipes/azure/sqldatabase.bicep \
    --target br:<registry-name>.azurecr.io/radius-recipes/sqldatabase:0.60.2
```

Here, `<registry-name>` is the name of the Azure Container Registry. The `--target` value must start with `br:` and contain the registry's complete login server.

### Register a recipe in Radius

After publishing, register the recipe for the Radius environment and group created for your application. The values are not required to be `azure`; use
the names of the environment and group you created for the Radius application. The following example registers the recipe from the Azure Container Registry
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

## Dev Environment - hosts file

Some demos use specified fully qualified domain names (FQDNs) to access the applications. Add the following entries to your environment's `hosts` file. Each entry resolves a hostname to a specific IP address.

You may need administrator or root privileges to edit the file. If the browser runs on the host operating system, update the host's `hosts` file. If the browser runs inside the dev container, update the container's `/etc/hosts` file instead. The address must point to the machine where the demo gateway is exposed.

You can find the hosts file here:
- Windows: `%SystemRoot%\System32\drivers\etc\hosts` (normally `C:\Windows\System32\drivers\etc\hosts`)
- macOS: `/etc/hosts`
- Linux: `/etc/hosts`

Add these entries:

```
127.0.0.1       gateway.todolist.radius.local         # radius config for todo list
127.0.0.1       demo4-gateway.beerrating.radius.local # radius config for beer rating
127.0.0.1       demo5-gateway.beerrating.radius.local # radius config for beer rating
```

The entries configure local name resolution for the demo gateways:

- `gateway.todolist.radius.local` resolves to the gateway used by the Todo List demo.
- `demo4-gateway.beerrating.radius.local` resolves to the gateway used by the local Beer Rating demo.
- `demo5-gateway.beerrating.radius.local` resolves to the gateway used by the Azure SQL Beer Rating demo.

When a browser requests one of these hostnames, it connects to `127.0.0.1` and sends the hostname in the HTTP `Host` header. The gateway uses that hostname to select the corresponding application route. This avoids requiring a DNS server or a publicly registered domain.

Keep the existing whitespace and comments optional; only the IP address and hostname are significant. Verify that the names resolve locally before opening a demo:

```bash
getent hosts gateway.todolist.radius.local
getent hosts demo4-gateway.beerrating.radius.local
getent hosts demo5-gateway.beerrating.radius.local
```

Each command should return `127.0.0.1`. On Windows, use `Resolve-DnsName` or `ping` instead of `getent`.

## Demos

Demo instructions: [Demos.md](Demos.md)
