targetScope = 'resourceGroup'

@description('Expected enclave connection resource ID.')
@minLength(1)
param expectedResourceId string

@description('Expected owning community resource ID.')
@minLength(1)
param expectedCommunityResourceId string

@description('Expected source enclave resource ID.')
@minLength(1)
param expectedEnclaveResourceId string

@description('Expected connection location.')
@minLength(1)
param expectedLocation string

@description('Validated endpoint IDs that may be the connection destination.')
@minLength(1)
param allowedDestinationEndpointResourceIds string[]

var connectionName = last(split(expectedResourceId, '/'))

resource connectionResource 'Microsoft.Mission/enclaveConnections@2026-03-01-preview' existing = {
  name: connectionName
}

var normalizedAllowedDestinationIds = map(allowedDestinationEndpointResourceIds, endpointId => toLower(endpointId))
var expectedCanonicalResourceId = resourceId('Microsoft.Mission/enclaveConnections', connectionName)
var connectionIsCompatible = toLower(expectedResourceId) == toLower(expectedCanonicalResourceId) && toLower(connectionResource.location) == toLower(expectedLocation) && toLower(string(connectionResource.properties.communityResourceId)) == toLower(expectedCommunityResourceId) && toLower(string(connectionResource.properties.sourceResourceId)) == toLower(expectedEnclaveResourceId) && contains(normalizedAllowedDestinationIds, toLower(string(connectionResource.properties.destinationEndpointId)))

module compatibilityGate './requiredTextResourceGroupGate.bicep' = {
  name: 'existingConnectionCompatibility'
  params: {
    requiredText: connectionIsCompatible ? 'compatible' : ''
  }
}

output resourceId string = connectionResource.id
