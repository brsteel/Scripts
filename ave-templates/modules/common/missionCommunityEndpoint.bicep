targetScope = 'resourceGroup'

type endpointProtocolType =
  | 'AH'
  | 'ANY'
  | 'ESP'
  | 'HTTP'
  | 'HTTPS'
  | 'ICMP'
  | 'TCP'
  | 'UDP'

type endpointDestinationType =
  | 'FQDN'
  | 'FQDNTag'
  | 'IPAddress'
  | 'PrivateNetwork'
  | 'ServiceTag'

type endpointUpdateMode = 'Automatic' | 'Manual'

@sealed()
type communityEndpointRuleType = {
  endpointRuleName: string
  destinationType: endpointDestinationType
  destination: string
  protocols: endpointProtocolType[]
  ports: string
  transitHubResourceId: string?
}

@description('Name of the existing Microsoft Mission community that owns the endpoint.')
@minLength(1)
param communityName string

@description('Mission community endpoint name.')
@minLength(1)
param name string

@description('Azure region for the endpoint.')
@minLength(1)
param location string

@description('Community endpoint rule collection.')
param ruleCollection communityEndpointRuleType[]

@description('Endpoint update mode.')
param updateMode endpointUpdateMode = 'Manual'

@description('Tags applied to the community endpoint.')
param tags object = {}

resource communityResource 'Microsoft.Mission/communities@2026-03-01-preview' existing = {
  name: communityName
}

resource communityEndpointResource 'Microsoft.Mission/communities/communityEndpoints@2026-03-01-preview' = {
  parent: communityResource
  name: name
  location: location
  tags: tags
  properties: {
    ruleCollection: ruleCollection
    updateMode: updateMode
  }
}

output resourceId string = communityEndpointResource.id
output resourceName string = communityEndpointResource.name
