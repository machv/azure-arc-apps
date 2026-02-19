var location = resourceGroup().location
var subscriptionId = subscription().subscriptionId

@description('Whether to deploy Logic App with webhook triggered when Arc machine is created.')
param deployArcWebhook bool = false

param windowsServerLogicAppWebhookName string = 'la-arc-sa-windows-webhook'
param windowsServerLogicAppScheduledName string = 'la-arc-sa-windows-scheduled'
param sqlServerLogicAppScheduledName string = 'la-arc-sa-sql-scheduled'
@description('Only needed if webhook Logic Apps is being deployed.')
param integrationAccountName string = 'ia-arc-logic'
@description('If there is already a system topic created for subscription events, provide the name here to reuse it. If not provided, a new system topic will be created.')
param subscriptionSystemTopicName string = ''

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'mi-arc-logicapps'
  location: location
}

resource scheduledLogicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: windowsServerLogicAppScheduledName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    definition: json(replace(loadTextContent('logicApps/sa-server-scheduled.json'), '\${MI_ID}', managedIdentity.id)).definition
  }
}

resource scheduledSqlLogicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: sqlServerLogicAppScheduledName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    definition: json(replace(loadTextContent('logicApps/sa-sql-scheduled.json'), '\${MI_ID}', managedIdentity.id)).definition
  }
}

resource integrationAccount 'Microsoft.Logic/integrationAccounts@2019-05-01' = if (deployArcWebhook) {
  name: integrationAccountName
  location: location
  sku: {
    name: 'Free'
  }
  properties: {}
}

resource webhookLogicApp 'Microsoft.Logic/workflows@2019-05-01' = if (deployArcWebhook) {
  name: windowsServerLogicAppWebhookName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    integrationAccount: {
      id: integrationAccount.id
    }

    definition: json(replace(loadTextContent('logicApps/sa-server-webhook.json'), '\${MI_ID}', managedIdentity.id)).definition
  }
}

var useExistingSystemTopic = subscriptionSystemTopicName != ''
var systemTopicName = subscriptionSystemTopicName != '' ? subscriptionSystemTopicName : 'st-subscription-${subscriptionId}'

// Only one system topic can be created per subscription, therefore if there is any other topic already, it needs to be referenced
resource existingSystemTopic 'Microsoft.EventGrid/systemTopics@2021-12-01' existing = if (deployArcWebhook && useExistingSystemTopic) {
  name: systemTopicName
}

// if not, create a new system topic for webhook trigger
resource systemTopic 'Microsoft.EventGrid/systemTopics@2021-12-01' = if (deployArcWebhook && !useExistingSystemTopic) {
  name: systemTopicName
  location: 'global'
  properties: {
    source: '/subscriptions/${subscriptionId}'
    topicType: 'Microsoft.Resources.Subscriptions'
  }
}

var systemTopicRef = useExistingSystemTopic ? existingSystemTopic.name : systemTopic.name

resource eventSubscription 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2021-12-01' = if (deployArcWebhook) {
  //parent: systemTopic
  name: '${systemTopicRef}/sub-arc-machines-creation-${subscriptionId}'
  properties: {
    destination: {
      endpointType: 'WebHook'
      properties: {
        endpointUrl: listCallbackUrl('${webhookLogicApp.id}/triggers/When_a_resource_event_occurs', '2016-06-01').value
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

output miPrincipalId string = managedIdentity.properties.principalId
