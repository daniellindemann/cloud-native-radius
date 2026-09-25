// @description('Name of the AKS cluster.')
// param aksName string
@description('Name of the Azure Container Registry.')
param acrName string

var deployerObjectId = deployer().objectId

// roles

// resource azureKubernetesServiceRBACClusterAdminRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
//   name: 'b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b' // role name: Azure Kubernetes Service RBAC Cluster Admin
//   scope: subscription()
// }

resource containerRegistryRepositoryCatalogListerRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'bfdb9389-c9a5-478a-bb2f-ba9ca092c3c7' // role name: Container Registry Repository Catalog Lister
  scope: subscription()
}

resource containerRegistryRepositoryContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '2efddaa5-3f1f-4df3-97df-af3f13818f4c' // role name: Container Registry Repository Contributor
  scope: subscription()
}

// existing resources

// resource aks 'Microsoft.ContainerService/managedClusters@2026-05-02-preview' existing = {
//   name: aksName
// }

resource acr 'Microsoft.ContainerRegistry/registries@2026-03-01-preview' existing = {
  name: acrName
}

// role assignments

// aks

// resource roleAssignment_aks_azureKubernetesServiceRBACClusterAdminRole_deployer 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid(aks.id, azureKubernetesServiceRBACClusterAdminRole.id, deployerObjectId)
//   scope: aks
//   properties: {
//     description: 'Assigns the Azure Kubernetes Service RBAC Cluster Admin role to the bicep deployer.'
//     roleDefinitionId: azureKubernetesServiceRBACClusterAdminRole.id
//     principalId: deployerObjectId
//     principalType: 'User'
//   }
// }

// acr

resource roleAssignment_aks_containerRegistryRepositoryCatalogListerRole_deployer 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, containerRegistryRepositoryCatalogListerRole.id, deployerObjectId)
  scope: acr
  properties: {
    description: 'Assigns the Container Registry Repository Catalog Lister role to the bicep deployer.'
    roleDefinitionId: containerRegistryRepositoryCatalogListerRole.id
    principalId: deployerObjectId
    principalType: 'User'
  }
}

resource roleAssignment_aks_containerRegistryRepositoryContributorRole_deployer 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, containerRegistryRepositoryContributorRole.id, deployerObjectId)
  scope: acr
  properties: {
    description: 'Assigns the Container Registry Repository Contributor role to the bicep deployer.'
    roleDefinitionId: containerRegistryRepositoryContributorRole.id
    principalId: deployerObjectId
    principalType: 'User'
  }
}


