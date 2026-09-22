@description('Name of the AKS cluster.')
param aksName string

var deployerObjectId = deployer().objectId

// roles

resource azureKubernetesServiceRBACClusterAdminRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b' // role name: Azure Kubernetes Service RBAC Cluster Admin
  scope: subscription()
}

// existing resources

resource aks 'Microsoft.ContainerService/managedClusters@2026-05-02-preview' existing = {
  name: aksName
}

// role assignments
@description('Assigns the Azure Kubernetes Service RBAC Cluster Admin role to the bicep deployer')
resource roleAssignment_aks_AzureKubernetesServiceRBACClusterAdminRole_deployer 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aks.id, azureKubernetesServiceRBACClusterAdminRole.id, deployerObjectId)
  scope: aks
  properties: {
    description: 'Assigns the Azure Kubernetes Service RBAC Cluster Admin role to the AKS cluster admin group from Entra ID.'
    roleDefinitionId: azureKubernetesServiceRBACClusterAdminRole.id
    principalId: deployerObjectId
    principalType: 'User'
  }
}
