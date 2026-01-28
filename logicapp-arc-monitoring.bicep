param location string = resourceGroup().location
param logicAppName string = 'la-arc-windows-webhook'
param integrationAccountName string = 'ia-arc-logic'

// 1. Create Integration Account
resource integrationAccount 'Microsoft.Logic/integrationAccounts@2019-05-01' = {
  name: integrationAccountName
  location: location
  sku: {
    name: 'Free'
  }
  properties: {}
}

// 2. Create the Logic App
resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    integrationAccount: {
      id: integrationAccount.id
    }
    definition: loadJsonContent('logicapp-definition.json', 'definition')
  }
}

// 3. Create the Event Grid System Topic for the Resource Group
resource systemTopic 'Microsoft.EventGrid/systemTopics@2021-12-01' = {
  name: 'st-arc-resource-events'
  location: 'global'
  properties: {
    source: resourceGroup().id
    topicType: 'Microsoft.Resources.ResourceGroups'
  }
}

// 4. Create the Event Grid Subscription
resource eventSubscription 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2021-12-01' = {
  parent: systemTopic
  name: 'sub-arc-machines-creation'
  properties: {
    destination: {
      endpointType: 'WebHook'
      properties: {
        // Logic App trigger URL is required for WebHook destination
        endpointUrl: listCallbackUrl('${logicApp.id}/triggers/When_a_resource_event_occurs', '2016-06-01').value
      }
    }
    filter: {
      includedEventTypes: [
        'Microsoft.Resources.ResourceWriteSuccess'
      ]

      advancedFilters: [
        {
          operatorType: 'StringContains'
          key: 'data.resourceUri'
          values: [
            'providers/Microsoft.HybridCompute/machines'
          ]
        }
        {
          operatorType: 'StringIn'
          key: 'data.operationName'
          values: [
            'Microsoft.HybridCompute/machines/write'
          ]
        }
      ]
    }
  }
}
// 5. Grant Azure Connected Machine Resource Administrator role to Logic App managed identity
var azureConnectedMachineResourceAdminRoleId = 'cd570a14-e51a-42ad-bac8-bafd67325302'
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, logicApp.id, azureConnectedMachineResourceAdminRoleId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', azureConnectedMachineResourceAdminRoleId)
    principalId: logicApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
