targetScope = 'resourceGroup'

type autoApprovedPrivateLinkConnection = {
  approvalMode: 'Auto'
  groupIds: string[]
  name: string
  privateLinkServiceResourceId: string
  requestMessage: string?
}

@sealed()
type manuallyApprovedPrivateLinkConnection = {
  approvalMode: 'Manual'
  groupIds: string[]
  name: string
  privateLinkServiceResourceId: string
  requestMessage: string
}

@sealed()
@discriminator('approvalMode')
type privateLinkConnectionConfiguration = autoApprovedPrivateLinkConnection | manuallyApprovedPrivateLinkConnection

@sealed()
type privateDnsZoneGroupEntry = {
  name: string
  privateDnsZoneResourceId: string
}

@description('Private endpoint resource name.')
param name string

@description('Azure region for the private endpoint.')
param location string

@description('Resource ID of the subnet that hosts the private endpoint.')
param subnetResourceId string

@description('Private Link service connection configuration.')
param privateLinkConnection privateLinkConnectionConfiguration

@description('Tags applied to the private endpoint.')
param tags object = {}

@description('Optional custom NIC name.')
param customNetworkInterfaceName string = ''

@description('Private DNS zone group name.')
param privateDnsZoneGroupName string = 'default'

@description('Private DNS zones to attach to the endpoint.')
param privateDnsZones privateDnsZoneGroupEntry[] = []

var connectionProperties = {
  groupIds: privateLinkConnection.groupIds
  privateLinkServiceId: privateLinkConnection.privateLinkServiceResourceId
}

var requestMessage = privateLinkConnection.?requestMessage ?? ''

var automaticConnection = union({
  name: privateLinkConnection.name
  properties: connectionProperties
}, empty(requestMessage) ? {} : {
  properties: union(connectionProperties, {
    requestMessage: requestMessage
  })
})

var manualConnection = {
  name: privateLinkConnection.name
  properties: union(connectionProperties, {
    requestMessage: requestMessage
  })
}

resource privateEndpointResource 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: name
  location: location
  tags: tags
  properties: union({
    subnet: {
      id: subnetResourceId
    }
  }, empty(customNetworkInterfaceName) ? {} : {
    customNetworkInterfaceName: customNetworkInterfaceName
  }, privateLinkConnection.approvalMode == 'Manual' ? {
    manualPrivateLinkServiceConnections: [
      manualConnection
    ]
  } : {
    privateLinkServiceConnections: [
      automaticConnection
    ]
  })
}

resource privateDnsZoneGroupResource 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = if (length(privateDnsZones) > 0) {
  parent: privateEndpointResource
  name: privateDnsZoneGroupName
  properties: {
    privateDnsZoneConfigs: [for privateDnsZone in privateDnsZones: {
      name: privateDnsZone.name
      properties: {
        privateDnsZoneId: privateDnsZone.privateDnsZoneResourceId
      }
    }]
  }
}

output resourceId string = privateEndpointResource.id
output resourceName string = privateEndpointResource.name
output privateDnsZoneGroupId string = length(privateDnsZones) > 0 ? privateDnsZoneGroupResource.id : ''
