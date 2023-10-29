targetScope = 'resourceGroup'
//
// resource group name smoke + syn + proj version
// resource group is only defined when issuing the Azure CLI "az deployment group create" command on build.
// all resources in this file will inherit the resource group defined by the CLI deployment.
//
// Bicep quick start template for Synapse Workspace:
// https://learn.microsoft.com/en-us/azure/templates/Microsoft.Synapse/workspaces?pivots=deployment-language-bicep
//
