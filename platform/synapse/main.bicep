targetScope = 'subscription'
//
// resource group name hardcoded 
// resource group is only defined when issuing the Azure CLI "az deployment group create" command on build.
// all resources in this file will inherit the resource group defined by the CLI deployment.
//
// Bicep quick start template for Synapse Workspace:
// https://learn.microsoft.com/en-us/azure/templates/Microsoft.Synapse/workspaces?pivots=deployment-language-bicep
//
param azTags object
param synapseName string
param rgName string
param azLocation string
param dataLakeUrlFormat string
param dataLakeName string
param dataLakeFilesystemName string
param dataLakeRgName string
param dataVaultName string
param adminUserSecretName string
param adminUserPasswordSecretName string
param ipAddress string

resource newRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgName
  location: azLocation
}

resource lakeVault 'Microsoft.KeyVault/vaults@2016-10-01' existing = {
  scope: resourceGroup(dataLakeRgName)
  name: dataVaultName
}

module synapse 'workspace.bicep' = {
  name: 'synapseModule'
  scope: newRG
  params: {
    azTags: azTags
    synapseName: synapseName
    azLocation: azLocation
    dataLakeUrlFormat: dataLakeUrlFormat
    dataLakeName: dataLakeName
    dataLakeFilesystemName: dataLakeFilesystemName
    synapseAdminUser: lakeVault.getSecret(adminUserSecretName)
    synapseAdminUserPassword: lakeVault.getSecret(adminUserPasswordSecretName)
    rgName: rgName
    ipAddress: ipAddress
  }
  
}
