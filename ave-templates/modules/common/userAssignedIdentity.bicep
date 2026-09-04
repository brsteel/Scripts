targetScope = 'resourceGroup'

@description('Name of the user-assigned managed identity.')
param name string

@description('Azure region for the user-assigned managed identity.')
param location string

@description('Tags applied to the user-assigned managed identity.')
param tags object = {}

resource identityResource 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
  tags: tags
}

output resourceId string = identityResource.id
output resourceName string = identityResource.name
output clientId string = identityResource.properties.clientId
output principalId string = identityResource.properties.principalId
