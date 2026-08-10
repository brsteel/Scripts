targetScope = 'resourceGroup'

@description('Name of the community expected to own the endpoint.')
@minLength(1)
param communityName string

@description('Expected endpoint resource ID. Empty skips the reader for a managed endpoint.')
param expectedResourceId string = ''

@description('Expected endpoint location.')
@minLength(1)
param expectedLocation string

var endpointName = empty(expectedResourceId) ? '' : last(split(expectedResourceId, '/'))

resource communityResource 'Microsoft.Mission/communities@2026-03-01-preview' existing = if (!empty(expectedResourceId)) {
  name: communityName
}

resource endpointResource 'Microsoft.Mission/communities/communityEndpoints@2026-03-01-preview' existing = if (!empty(expectedResourceId)) {
  parent: communityResource
  name: endpointName
}

var expectedCanonicalResourceId = resourceId('Microsoft.Mission/communities/communityEndpoints', communityName, endpointName)
var endpointIsCompatible = empty(expectedResourceId) ? true : toLower(expectedResourceId) == toLower(expectedCanonicalResourceId) && toLower(endpointResource.location) == toLower(expectedLocation)

module compatibilityGate './requiredTextResourceGroupGate.bicep' = {
  name: 'existingEndpointCompatibility'
  params: {
    requiredText: endpointIsCompatible ? 'compatible' : ''
  }
}

output resourceId string = empty(expectedResourceId) ? '' : endpointResource.id
