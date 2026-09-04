targetScope = 'resourceGroup'

@description('Name of the community expected to own the endpoint.')
@minLength(1)
param communityName string

@description('Expected endpoint resource ID.')
@minLength(1)
param expectedResourceId string

@description('Expected endpoint location.')
@minLength(1)
param expectedLocation string

var endpointName = last(split(expectedResourceId, '/'))

resource communityResource 'Microsoft.Mission/communities@2026-03-01-preview' existing = {
  name: communityName
}

resource endpointResource 'Microsoft.Mission/communities/communityEndpoints@2026-03-01-preview' existing = {
  parent: communityResource
  name: endpointName
}

var expectedCanonicalResourceId = resourceId('Microsoft.Mission/communities/communityEndpoints', communityName, endpointName)
var endpointIsCompatible = toLower(expectedResourceId) == toLower(expectedCanonicalResourceId) && toLower(endpointResource.location) == toLower(expectedLocation)

module compatibilityGate './requiredTextResourceGroupGate.bicep' = {
  name: 'existingEndpointCompatibility'
  params: {
    requiredText: endpointIsCompatible ? 'compatible' : ''
  }
}

output resourceId string = endpointResource.id
