param principalId string
param synapseName string
param adlsName string
param warehouseContainerName string
param bscContainerName string

var storageBlobContributorId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
var storageBlobReaderId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1')

// Get a reference to the existing data lake storage account
resource dataLake 'Microsoft.Storage/storageAccounts@2019-06-01' existing = {
  name: adlsName
}

// get a reference to the data lake blob service
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-08-01' = {
  name: 'default'
  parent: dataLake
}

// get a reference to the 'warehouse' container
resource adlsWarehouse 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = {
  name: warehouseContainerName
  parent: blobService
}

// get a reference to the 'bsc' container
resource adlsBsc 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = {
  name: bscContainerName
  parent: blobService
}

// the synapse workspce identity requires 'storage blob data contributor' role on the warehouse container.
// the resource name needs to be unique so use a guid.
resource synIdBlobContrib 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(synapseName, warehouseContainerName, principalId, storageBlobContributorId)
  scope: adlsWarehouse
  properties:{
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: storageBlobContributorId
  }
}

// the synapse workspce identity requires 'storage blob data reader' role on the bsc container.
// the resource name needs to be unique so use a guid.
resource synIdBlobRead 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(synapseName, bscContainerName, principalId, storageBlobReaderId)
  scope: adlsBsc
  properties:{
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: storageBlobContributorId
  }
}
