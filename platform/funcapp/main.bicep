targetScope = 'resourceGroup'
//
// resource group name = Smoke005
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
param dailyQuota int 
param workspaceSku string

var storageName = toLower('${projShortName}data${projVersion}')
param storageSku string = (envType == 'prod') ? 'Standard_ZRS' : 'Standard_LRS'
var hostPlanName = '${projShortName}Farm${projVersion}'
var insightsName = '${projShortName}Insights${projVersion}'
var funcName = '${projShortName}Funcs${projVersion}'
var workspaceName = '${projShortName}Workspace${projVersion}'


// create the application insights components.
module appInsights 'insights.bicep' = {
  name: 'insightsModule'
  scope: resourceGroup(resourceGroup().name)
  params: {
    azLocation: azLocation
    azTags: azTags
    logRetention: logRetention
    insightsName: insightsName
    workspaceName: workspaceName
    dailyQuota: dailyQuota
    workspaceSku: workspaceSku
  }
}

// Get the Elexon API key from the Energy Data key vault (same as the previous BMRS key).
// the key vault must have "enabledForTemplateDeployment: true" as a property.
resource lakeVault 'Microsoft.KeyVault/vaults@2016-10-01' existing = {
  scope: resourceGroup(dataLakeRg)
  name: dataVaultName
}

// Build Smoke Azure Resources
module functionApp 'func.bicep' = {
  name: 'functionsModule'
  scope: resourceGroup(resourceGroup().name)
  params: {
    azLocation: azLocation
    azTags: azTags
    dataLakeRg: dataLakeRg
    dataLakeName: dataLakeName
    dataLakeConfigName: dataLakeConfigName
    dataLakeContainer: dataLakeContainer
    storageName: storageName
    storageSku: storageSku
    hostPlanName: hostPlanName
    insightsConnString: appInsights.outputs.insightsConnectionString
    funcName: funcName
    elexonApiKey: lakeVault.getSecret(bmrsApiKeySecretName)
  }
}
