param name string
param location string
param tags object = {}

param keyVaultName string
param listenerKeyName string = 'AZURE-SERVICE-BUS-LISTENER-KEY'
param senderKeyName string = 'AZURE-SERVICE-BUS-SENDER-KEY'

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

module senderKey '../core/security/keyvault-secret.bicep' = {
  name: 'senderKey'
  params: {
    name: senderKeyName
    keyVaultName: keyVaultName
    secretValue: serviceBusNamespaceQueueAuthorizationRule.listKeys().primaryKey
  }
}

module listenerKey '../core/security/keyvault-secret.bicep' = {
  name: 'listenerKey'
  params: {
    name: listenerKeyName
    keyVaultName: keyVaultName
    secretValue: serviceBusNamespaceAuthorizationRule.listKeys().primaryKey
  }
}

output serviceBusEndpoint string = serviceBusNamespace.properties.serviceBusEndpoint
output serviceBusListenerName string = serviceBusNamespaceAuthorizationRule.name
output serviceBusSenderName string = serviceBusNamespaceQueueAuthorizationRule.name
output serviceBusListenerKey string = listenerKeyName
output serviceBusSenderKey string = senderKeyName
output serviceBusNamespaceName string = serviceBusNamespace.name
