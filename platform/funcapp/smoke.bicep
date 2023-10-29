targetScope = 'resourceGroup'
//
// resource group name = Smoke001
// resource group is only defined when issuing the Azure CLI "az deployment group create" command on build.
// all resources in this file will inherit the resource group defined by the CLI deployment.
//
// Bicep quick start template for Function App:
// https://github.com/Azure/azure-quickstart-templates/tree/master/quickstarts/microsoft.web/app-function
//

@description('the parameters from the params.<env>.json file')
param projShortName string
param projVersion string
param azLocation string
param envType string
param azTags object
param logRetention int
param dataLakeRg string
param dataLakeName string
param dataLakeConfigName string
param dataLakeContainer string
param dataVaultName string
param bmrsApiKeySecretName string

var storageName = toLower('${projShortName}data${projVersion}')

param storageSku string = (envType == 'prod') ? 'Standard_ZRS' : 'Standard_LRS'

var hostPlanName = '${projShortName}Func${projVersion}'

var insightsName = '${projShortName}Func${projVersion}'

var funcName = '${projShortName}Func${projVersion}'

// Get the Bmrs API key from the Energy Data key vault.
// the key vault must have "enabledForTemplateDeployment: true" as a property.
resource lakeVault 'Microsoft.KeyVault/vaults@2016-10-01' existing = {
  scope: resourceGroup(dataLakeRg)
  name: dataVaultName
}

// Build Smoke Azure Resources
module functionApp 'main.bicep' = {
  name: 'functionsModule'
  scope: resourceGroup(resourceGroup().name)
  params: {
    azLocation: azLocation
    azTags: azTags
    logRetention: logRetention
    dataLakeRg: dataLakeRg
    dataLakeName: dataLakeName
    dataLakeConfigName: dataLakeConfigName
    dataLakeContainer: dataLakeContainer
    storageName: storageName
    storageSku: storageSku
    hostPlanName: hostPlanName
    insightsName: insightsName
    funcName: funcName
    bmrsApiKey: lakeVault.getSecret(bmrsApiKeySecretName)
  }
}
