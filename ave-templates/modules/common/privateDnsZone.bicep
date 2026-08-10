targetScope = 'resourceGroup'

@description('Private DNS zone name.')
param name string

@description('Tags applied to the private DNS zone.')
param tags object = {}

resource privateDnsZoneResource 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: name
  location: 'global'
  tags: tags
}

output resourceId string = privateDnsZoneResource.id
output resourceName string = privateDnsZoneResource.name
