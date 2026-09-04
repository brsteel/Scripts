targetScope = 'subscription'

@description('Name of an existing customer-managed resource group.')
@minLength(1)
param resourceGroupName string

resource resourceGroupResource 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  name: resourceGroupName
}

output resourceId string = resourceGroupResource.id
output location string = resourceGroupResource.location
