param name string
param location string
param tags object = {}

// Service Bus Namespace
resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
}

// Service Bus Namespace Authorization Rule
resource serviceBusNamespaceAuthorizationRule 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2022-10-01-preview' = {
  name: 'listener'
  parent: serviceBusNamespace
  properties: {
    rights: [
      'Listen'
    ]
  }
}

// Service Bus Queue
resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2022-01-01-preview' = {
  name: 'orders'
  parent: serviceBusNamespace
}

// Service Bus Namespace Authorization Rule
resource serviceBusNamespaceQueueAuthorizationRule 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2022-10-01-preview' = {
  name: 'sender'
  parent: serviceBusNamespace
  properties: {
    rights: [
      'Send'
    ]
  }
}

output serviceBusEndpoint string = serviceBusNamespace.properties.serviceBusEndpoint
output serviceBusListenerName string = serviceBusNamespaceAuthorizationRule.name
output serviceBusSenderName string = serviceBusNamespaceQueueAuthorizationRule.name
output serviceBusListenerKey string = serviceBusNamespaceAuthorizationRule.listKeys().primaryKey
output serviceBusSenderKey string = serviceBusNamespaceQueueAuthorizationRule.listKeys().primaryKey
output serviceBusNamespaceName string = serviceBusNamespace.name
