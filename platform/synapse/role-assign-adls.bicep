param principalId string
param synapseName string
param adlsName string

var adlsBlobContributorId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')

// Get a reference to the existing data lake storage account
resource dataLake 'Microsoft.Storage/storageAccounts@2019-06-01' existing = {
  name: adlsName
}

// the synapse workspce identity requires 'storage blob data contributor' role on the ADLS account.
// the resource name needs to be unique so use a guid.
resource synapseidentityblobrole 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(synapseName, principalId, adlsBlobContributorId)
  scope: dataLake
  properties:{
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: adlsBlobContributorId
  }
}
