targetScope = 'subscription'

type deploymentContextType = {
  tags: object?
}

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

type sourceSubnetKind = 'DelegatedPostgreSql' | 'PrivateEndpoints'

type phaseAType = {
  contractVersion: '2.0'
  communityResourceId: string
  enclaveOwnership: 'managed' | 'existing'
  enclaveResourceId: string
  location: string
  postgreSqlSubnetAddressPrefix: string
  postgreSqlSubnetName: string
  privateEndpointSubnetAddressPrefix: string
  privateEndpointSubnetName: string
  workloadResourceId: string
  workloadResourceGroupId: string
}

type foundationType = {
  contractVersion: '2.0'
  phaseA: phaseAType
  communityEndpointResourceIds: string[]
  enclaveConnectionResourceIds: string[]
}

type managedCommunityEndpointType = {
  mode: 'managed'
  name: string?
  ruleCollection: {
    endpointRuleName: string
    destinationType: endpointDestinationType
    destination: string
    protocols: endpointProtocolType[]
    ports: string
    transitHubResourceId: string?
  }[]
  updateMode: 'Automatic' | 'Manual'?
}

type existingCommunityEndpointType = {
  mode: 'existing'
  resourceId: string
}

@discriminator('mode')
type communityEndpointDefinitionType = managedCommunityEndpointType | existingCommunityEndpointType

type connectivityDefinitionType = {
  connectionName: string?
  endpoint: communityEndpointDefinitionType
  sourceSubnets: sourceSubnetKind[]
}

type managedNetworkFinalizationType = {
  mode: 'Managed'
}

type existingReferenceOnlyNetworkFinalizationType = {
  mode: 'ExistingReferenceOnly'
  communityEndpointResourceIds: string[]
  enclaveConnectionResourceIds: string[]
}

type existingApprovedEndpointChangesType = {
  mode: 'ExistingApprovedEndpointChanges'
  existingCommunityEndpointResourceIds: string[]
  existingEnclaveConnectionResourceIds: string[]
}

@discriminator('mode')
type networkFinalizationDefinitionType = managedNetworkFinalizationType | existingReferenceOnlyNetworkFinalizationType | existingApprovedEndpointChangesType

@description('Tags applied to created Mission connectivity resources.')
param deploymentContext deploymentContextType = {}

@description('Serialized Phase A handoff from avePostgreSqlEnclaveDeployment.')
param phaseA phaseAType

@description('Managed or reference-only Mission network finalization mode. Existing enclaves default to reference-only unless explicitly approved for additive endpoint/connection creation.')
param networkFinalization networkFinalizationDefinitionType

@description('Managed or existing community endpoint plus enclave connection requests.')
param communityConnectivity connectivityDefinitionType[] = []

var tags = deploymentContext.?tags ?? {}
var enclaveSegments = split(phaseA.enclaveResourceId, '/')
var enclaveSubscriptionId = enclaveSegments[2]
var enclaveResourceGroupName = enclaveSegments[4]
var communitySegments = split(phaseA.communityResourceId, '/')
var communitySubscriptionId = communitySegments[2]
var communityResourceGroupName = communitySegments[4]
var communityName = communitySegments[8]

var effectiveEndpointNames = [for (connectivity, index) in communityConnectivity: connectivity.endpoint.mode == 'managed'
  ? (connectivity.endpoint.?name ?? 'ce-pg-${substring(uniqueString(phaseA.communityResourceId, string(connectivity.endpoint.ruleCollection), string(index)), 0, 8)}')
  : last(split(connectivity.endpoint.resourceId, '/'))
]

module communityEndpointModules '../../modules/common/missionCommunityEndpoint.bicep' = [for (connectivity, index) in communityConnectivity: if (connectivity.endpoint.mode == 'managed') {
  name: 'postgresqlCommunityEndpoint${index}'
  scope: resourceGroup(communitySubscriptionId, communityResourceGroupName)
  params: {
    communityName: communityName
    location: phaseA.location
    name: effectiveEndpointNames[index]
    ruleCollection: connectivity.endpoint.ruleCollection
    tags: tags
    updateMode: connectivity.endpoint.?updateMode ?? 'Manual'
  }
}]

var effectiveEndpointIds = [for (connectivity, index) in communityConnectivity: connectivity.endpoint.mode == 'managed'
  ? resourceId(communitySubscriptionId, communityResourceGroupName, 'Microsoft.Mission/communities/communityEndpoints', communityName, effectiveEndpointNames[index])
  : connectivity.endpoint.resourceId
]

var connectionNames = [for (connectivity, index) in communityConnectivity: connectivity.?connectionName ?? 'conn-pg-${substring(uniqueString(phaseA.enclaveResourceId, effectiveEndpointIds[index], string(connectivity.sourceSubnets)), 0, 8)}']
var connectionSourceCidrs = [for connectivity in communityConnectivity: contains(connectivity.sourceSubnets, 'DelegatedPostgreSql') && contains(connectivity.sourceSubnets, 'PrivateEndpoints')
  ? '${phaseA.postgreSqlSubnetAddressPrefix},${phaseA.privateEndpointSubnetAddressPrefix}'
  : (contains(connectivity.sourceSubnets, 'DelegatedPostgreSql') ? phaseA.postgreSqlSubnetAddressPrefix : phaseA.privateEndpointSubnetAddressPrefix)
]

module enclaveConnectionModules '../../modules/common/missionEnclaveConnection.bicep' = [for (connectivity, index) in communityConnectivity: if (networkFinalization.mode != 'ExistingReferenceOnly') {
  name: 'postgresqlEnclaveConnection${index}'
  scope: resourceGroup(enclaveSubscriptionId, enclaveResourceGroupName)
  params: {
    communityResourceId: phaseA.communityResourceId
    destinationEndpointResourceId: effectiveEndpointIds[index]
    enclaveResourceId: phaseA.enclaveResourceId
    location: phaseA.location
    name: connectionNames[index]
    sourceCidr: connectionSourceCidrs[index]
    tags: tags
  }
  dependsOn: [
    communityEndpointModules
  ]
}]

var createdConnectionIds = [for connectionName in connectionNames: resourceId(enclaveSubscriptionId, enclaveResourceGroupName, 'Microsoft.Mission/enclaveConnections', connectionName)]
var finalCommunityEndpointIds = networkFinalization.mode == 'ExistingReferenceOnly'
  ? networkFinalization.communityEndpointResourceIds
  : (networkFinalization.mode == 'ExistingApprovedEndpointChanges'
      ? concat(networkFinalization.existingCommunityEndpointResourceIds, effectiveEndpointIds)
      : effectiveEndpointIds)
var finalEnclaveConnectionIds = networkFinalization.mode == 'ExistingReferenceOnly'
  ? networkFinalization.enclaveConnectionResourceIds
  : (networkFinalization.mode == 'ExistingApprovedEndpointChanges'
      ? concat(networkFinalization.existingEnclaveConnectionResourceIds, createdConnectionIds)
      : createdConnectionIds)

output contractVersion string = '2.0'
output foundation foundationType = {
  contractVersion: '2.0'
  communityEndpointResourceIds: finalCommunityEndpointIds
  enclaveConnectionResourceIds: finalEnclaveConnectionIds
  phaseA: phaseA
}
output communityEndpointResourceIds string[] = finalCommunityEndpointIds
output enclaveConnectionResourceIds string[] = finalEnclaveConnectionIds
output enclaveResourceId string = phaseA.enclaveResourceId
output communityResourceId string = phaseA.communityResourceId
