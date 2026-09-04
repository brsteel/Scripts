targetScope = 'resourceGroup'

@description('Name of the existing PostgreSQL Flexible Server to reference. This module never writes the server or its children.')
@minLength(3)
@maxLength(63)
param flexibleServerName string

resource flexibleServerResource 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' existing = {
  name: flexibleServerName
}

output flexibleServerResourceId string = flexibleServerResource.id
output flexibleServerName string = flexibleServerResource.name
output fullyQualifiedDomainName string = flexibleServerResource.properties.fullyQualifiedDomainName
output serverState object = {
  identity: flexibleServerResource.identity
  id: flexibleServerResource.id
  location: flexibleServerResource.location
  name: flexibleServerResource.name
  properties: {
    authConfig: flexibleServerResource.properties.authConfig
    availabilityZone: flexibleServerResource.properties.availabilityZone
    backup: flexibleServerResource.properties.backup
    dataEncryption: flexibleServerResource.properties.dataEncryption
    fullyQualifiedDomainName: flexibleServerResource.properties.fullyQualifiedDomainName
    highAvailability: flexibleServerResource.properties.highAvailability
    maintenanceWindow: flexibleServerResource.properties.maintenanceWindow
    network: flexibleServerResource.properties.network
    privateEndpointConnections: flexibleServerResource.properties.privateEndpointConnections
    state: flexibleServerResource.properties.state
    storage: flexibleServerResource.properties.storage
    version: flexibleServerResource.properties.version
  }
  sku: flexibleServerResource.sku
  tags: flexibleServerResource.tags
  type: flexibleServerResource.type
}
