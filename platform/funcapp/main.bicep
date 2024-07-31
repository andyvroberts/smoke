@description('the parameters needed to deploy all Azure resources for the FunctionApp')
param azLocation string
param azTags object
param logRetention int
param dataLakeRg string
param dataLakeName string
param dataLakeConfigName string
param dataLakeContainer string
param storageName string
param storageSku string
param hostPlanName string
param insightsName string
param funcName string

@secure()
param elexonApiKey string

@description('create the Function App storage account')
resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageName
  location: azLocation
  sku: {
    name: storageSku
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
  }
  tags: azTags
}

// Specify kind: as 'linux' otherwise it defaults to windows.
// https://learn.microsoft.com/en-us/azure/templates/microsoft.web/serverfarms?pivots=deployment-language-bicep
@description('Create the App Service Plan for the Server Farm. sku Y1 is the free tier.')
resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: hostPlanName
  location: azLocation
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
  tags: azTags
}

@description('Create the Application Insights instance, which is mandatory for a Function App')
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: insightsName
  location: azLocation
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
    RetentionInDays: logRetention
  }
  tags: azTags
}

// Get a reference to the seperate data lake storage account (data lake)
resource dataLake 'Microsoft.Storage/storageAccounts@2019-06-01' existing = {
  scope: resourceGroup(dataLakeRg)
  name: dataLakeName
}

// Get a reference to the seperate configuration storage account (table storage)
resource dataLakeConfig 'Microsoft.Storage/storageAccounts@2019-06-01' existing = {
  scope: resourceGroup(dataLakeRg)
  name: dataLakeConfigName
}

// Specify kind: as 'functionapp,linux' to run functions on Linux O/S.
@description('Create the Function App with references to all other resources')
resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: funcName
  location: azLocation
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(funcName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'EnergyDataLake'
          value: 'DefaultEndpointsProtocol=https;AccountName=${dataLakeName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${dataLake.listKeys().keys[0].value}'
        }
        {
          name: 'EnergyDataConfigStore'
          value: 'DefaultEndpointsProtocol=https;AccountName=${dataLakeConfigName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${dataLakeConfig.listKeys().keys[0].value}'
        }
        {
          name: 'elexonApiKey'
          value: elexonApiKey
        }
        {
          name: 'Container'
          value: dataLakeContainer
        }
      ]
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
  tags: azTags
}
