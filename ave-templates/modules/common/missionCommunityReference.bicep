targetScope = 'resourceGroup'

@description('Existing community resource name.')
param name string

resource communityResource 'Microsoft.Mission/communities@2026-03-01-preview' existing = {
  name: name
}

output resourceId string = communityResource.id
output resourceName string = communityResource.name
