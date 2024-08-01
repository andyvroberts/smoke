@description('the parameters needed to create and deploy an application insights instance connected to a log analytics workspace')
param azLocation string
param azTags object
param logRetention int
param insightsName string
param workspaceName string
param dailyQuota int
param workspaceSku string


resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: azLocation
  tags: azTags
  properties: {
    sku: {
      name: workspaceSku
    }
    retentionInDays: logRetention
    features: {
      enableLogAccessUsingOnlyResourcePermissions: false
    }
    workspaceCapping: {
      dailyQuotaGb: dailyQuota
    }    
  }
}

resource insights 'Microsoft.Insights/components@2020-02-02' = {
  name: insightsName
  location: azLocation
  tags: azTags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    ImmediatePurgeDataOn30Days: true
    IngestionMode: 'string'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    Request_Source: 'rest'
    RetentionInDays: logRetention
    WorkspaceResourceId: workspace.id
  }
}

output insightsConnectionString string = insights.properties.ConnectionString
