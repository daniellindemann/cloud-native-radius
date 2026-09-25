targetScope = 'subscription'

/**********************************************************/
/*                       Parameters                       */
/**********************************************************/

@minLength(1)
@description('Location of resources')
param location string = deployment().location

@description('Tags')
param tags object = {}

/**********************************************************/
/*                     Main Variables                     */
/**********************************************************/

var uniqueIdentifierLength = 6 // 6 is the used length for wgv projects

var allTags = union(
  {
    ApplicationName: 'cloud-native-radius'
    Maintainer: 'Daniel Lindemann'
    Owner: 'Daniel Lindemann'
    Setup: 'bicep'
    TenantId: tenant().tenantId
    SubscriptionId: subscription().subscriptionId
    Location: location
  },
  tags
)

// generate suffix for resources based on subscription id, location and environment
var suffix = substring(uniqueString(subscription().id, location), 0, uniqueIdentifierLength)

/**********************************************************/
/*                 Configuration Variables                */
/**********************************************************/

// THESE VARIABLES COULD BE PARAMETERS

var resourceGroup = 'rg-cloud-native-radius'
var kubernetesVersion string = '1.36.3'
var systemNodeCount int = 3
var systemVmSize string = 'Standard_B2ms'


/**********************************************************/
/*                    Resource Groups                     */
/**********************************************************/

resource rg 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  location: location
  name: resourceGroup
  tags: allTags
  properties: {}
}

/**********************************************************/
/*                        Logging                         */
/**********************************************************/

module logAnalyticsWorkspaceModule 'modules/logAnalyticsWorkspace.bicep' = {
  name: 'module-logAnalyticsWorkspace'
  scope: rg
  params: {
    location: location
    suffix: suffix
    tags: allTags

    dailyCapQuotaInGb: 3
  }
}

// /**********************************************************/
// /*                          ACR                           */
// /**********************************************************/

module acr 'modules/acr.bicep' = {
  name: 'module-acr'
  scope: rg
  params: {
    location: location
    suffix: suffix
    tags: allTags

    skuName: 'Standard'
    anonymousPullEnabled: true
  }
}

// /**********************************************************/
// /*                      AKS Cluster                       */
// /**********************************************************/

// module aksCluster 'modules/aksCluster.bicep' = {
//   name: 'module-aksCluster'
//   scope: rg
//   params: {
//     location: location
//     suffix: suffix
//     tags: allTags

//     logAnalyticsWorkspaceId: logAnalyticsWorkspaceModule.outputs.id
//     kubernetesVersion: kubernetesVersion
//     systemNodeCount: systemNodeCount
//     systemVmSize: systemVmSize
//   }
// }

/**********************************************************/
/*                    Role Assignments                    */
/**********************************************************/

module roleAssignments 'modules/roleAssignments.bicep' = {
  name: 'module-roleAssignments'
  scope: rg
  params: {
    // aksName: aksCluster.outputs.name
    acrName: acr.outputs.name
  }
}
