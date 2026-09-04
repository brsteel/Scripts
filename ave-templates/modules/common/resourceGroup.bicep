targetScope = 'subscription'

@description('Name of the resource group to create.')
param name string

@description('Azure region for the resource group.')
param location string

@description('Tags applied to the resource group.')
param tags object = {}

resource resourceGroupResource 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: name
  location: location
  tags: tags
}

output resourceId string = resourceGroupResource.id
output resourceName string = resourceGroupResource.name
output resourceLocation string = resourceGroupResource.location
