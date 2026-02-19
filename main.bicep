targetScope = 'subscription'

//@description('The Azure region for resources')
//param location string = 'eastus'

@description('The name of the resource group where Logic Apps will be created.')
param logicAppsResourceGroupName string = 'rg-arc-logicapps'

@description('Whether to deploy Logic App with webhook triggered when Arc machine is created.')
param deployArcWebhook bool = false

@description('Name for the Windows Server Logic App with webhook trigger')
param windowsServerLogicAppWebhookName string = 'la-arc-sa-windows-webhook'

@description('Name for the Windows Server Logic App with scheduled trigger')
param windowsServerLogicAppScheduledName string = 'la-arc-sa-windows-scheduled'

@description('Name for the SQL Server Logic App with scheduled trigger')
param sqlServerLogicAppScheduledName string = 'la-arc-sa-sql-scheduled'

@description('Only needed if webhook Logic Apps is being deployed.')
param integrationAccountName string = 'ia-arc-logic'

@description('If there is already a system topic created for subscription events, provide the name here to reuse it. If not provided, a new system topic will be created.')
param subscriptionSystemTopicName string = ''

resource appsResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: logicAppsResourceGroupName
  location: deployment().location
}

module logicApps 'logic-apps.bicep' = {
  name: 'rg-deployment'
  scope: appsResourceGroup
  
  params: {
    deployArcWebhook: deployArcWebhook
    windowsServerLogicAppWebhookName: windowsServerLogicAppWebhookName
    windowsServerLogicAppScheduledName: windowsServerLogicAppScheduledName
    sqlServerLogicAppScheduledName: sqlServerLogicAppScheduledName
    integrationAccountName: integrationAccountName
    subscriptionSystemTopicName: subscriptionSystemTopicName
  }
}

var azureConnectedMachineResourceAdminRoleId = 'cd570a14-e51a-42ad-bac8-bafd67325302'
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(appsResourceGroup.id, azureConnectedMachineResourceAdminRoleId)
  scope: subscription()
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      azureConnectedMachineResourceAdminRoleId
    )
    principalId: logicApps.outputs.miPrincipalId
    principalType: 'ServicePrincipal'
  }
}
