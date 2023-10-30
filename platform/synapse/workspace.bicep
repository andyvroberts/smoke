param azTags object
param synapseName string
param azLocation string
param dataLakeUrlFormat string
param dataLakeName string
param dataLakeFilesystemName string
param rgName string
param ipAddress string

var rgNameManaged = '${rgName}-managed'

@secure()
param synapseAdminUser string

@secure()
param synapseAdminUserPassword string

resource synapse 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: synapseName
  location: azLocation
  tags: azTags
  properties: {
    sqlAdministratorLogin: synapseAdminUser
    sqlAdministratorLoginPassword: synapseAdminUserPassword
    defaultDataLakeStorage:{
      accountUrl: format(dataLakeUrlFormat, dataLakeName)
      filesystem: dataLakeFilesystemName
    }
    managedResourceGroupName: rgNameManaged
  }
  identity:{
    type:'SystemAssigned'
  }
}
  
// If you specify zero to zero IP range, the name must be "AllowAllWindowsAzureIps".
resource openAccessFirewallRule 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01' = {
  name: 'AllowAllWindowsAzureIps'
  parent: synapse
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

// This needs to be the IP address of your own computer (be specific unless you have a network range).
resource localAccessPoint 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01' = {
  name: 'AllowAccessPoint'
  parent: synapse
  properties: {
    endIpAddress: ipAddress
    startIpAddress: ipAddress
  }
}
