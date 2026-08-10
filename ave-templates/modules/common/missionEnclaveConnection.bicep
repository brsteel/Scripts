targetScope = 'resourceGroup'

@description('Mission enclave connection resource name.')
@minLength(1)
param name string

@description('Azure region for the enclave connection.')
@minLength(1)
param location string

@description('Resource ID of the owning community.')
@minLength(1)
param communityResourceId string

@description('Resource ID of the source enclave.')
@minLength(1)
param enclaveResourceId string

@description('Resource ID of the destination community endpoint.')
@minLength(1)
param destinationEndpointResourceId string

@description('Comma-separated source CIDR list for the enclave connection.')
param sourceCidr string = ''

@description('Tags applied to the enclave connection.')
param tags object = {}

resource enclaveConnectionResource 'Microsoft.Mission/enclaveConnections@2026-03-01-preview' = {
  name: name
  location: location
  tags: tags
  properties: {
    communityResourceId: communityResourceId
    destinationEndpointId: destinationEndpointResourceId
    sourceCidr: sourceCidr
    sourceResourceId: enclaveResourceId
  }
}

output resourceId string = enclaveConnectionResource.id
output resourceName string = enclaveConnectionResource.name
