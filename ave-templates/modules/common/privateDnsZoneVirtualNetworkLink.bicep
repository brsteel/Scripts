targetScope = 'resourceGroup'

@description('Private DNS zone name.')
param zoneName string

@description('Name of the virtual network link resource.')
param linkName string

@description('Resource ID of the virtual network to link.')
param virtualNetworkResourceId string

@description('Whether auto-registration is enabled for the linked virtual network.')
param registrationEnabled bool = false

@description('Tags applied to the virtual network link.')
param tags object = {}

resource privateDnsZoneResource 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: zoneName
}

resource virtualNetworkLinkResource 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZoneResource
  name: linkName
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: registrationEnabled
    virtualNetwork: {
      id: virtualNetworkResourceId
    }
  }
}

output resourceId string = virtualNetworkLinkResource.id
output resourceName string = virtualNetworkLinkResource.name
