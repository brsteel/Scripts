targetScope = 'subscription'

type deploymentContextType = {
  subscriptionId: string?
  location: string?
  tags: object?
}

type deploymentPrincipalType = {
  objectId: string
  principalType: 'User' | 'Group' | 'ServicePrincipal'
}

type missionPrincipalType = {
  id: string
  type: 'User' | 'Group' | 'ServicePrincipal'
}

type missionRoleAssignmentType = {
  condition: string?
  principals: missionPrincipalType[]
  roleDefinitionId: string
}

type managedCommunityType = {
  mode: 'managed'
  name: string
  resourceGroupName: string
  addressSpace: string?
  addressSpaces: string[]?
  dnsServers: string[]?
}

type existingCommunityType = {
  mode: 'existing'
  resourceId: string
}

@discriminator('mode')
type communityDefinitionType = managedCommunityType | existingCommunityType

type subnetRequestType = {
  name: string?
  networkPrefixSize: int
}

type governedServiceExpectationType = {
  enforcement: 'Enabled'
  option: 'Allow'
  policyAction: 'Enforce'
  serviceId: 'KeyVault' | 'PostgreSQL' | 'PrivateDNSZones'
}

type approvalPoliciesExpectationType = {
  connectionCreation: 'NotRequired' | 'Required'
  connectionUpdate: 'NotRequired' | 'Required'
  enclaveEndpointUpdate: 'NotRequired' | 'Required'
  enclaveMaintenanceMode: 'NotRequired' | 'Required'
}

type expectedEnclaveSubnetType = {
  addressPrefix: string
  name: string
  networkPrefixSize: int
  networkSecurityGroupResourceId: string
  resourceId: string
  subnetDelegation: string
}

type expectedEnclaveType = {
  approvalPolicies: approvalPoliciesExpectationType
  communityResourceId: string
  governedServiceList: governedServiceExpectationType[]
  location: string
  network: {
    allowSubnetCommunication: 'Disabled'
    delegatedSubnet: expectedEnclaveSubnetType
    privateEndpointSubnet: expectedEnclaveSubnetType
  }
  rbacInheritance: 'Disabled'
  workloadResourceVisibility: 'Disabled'
}

type managedEnclaveType = {
  mode: 'managed'
  name: string
  resourceGroupName: string
  addressSpaceCidr: string
  postgreSqlSubnet: subnetRequestType
  privateEndpointSubnet: subnetRequestType
  bastion: 'Enabled' | 'Disabled'?
  diagnosticDestination: 'Both' | 'CommunityOnly' | 'EnclaveOnly'?
  enclaveRoleAssignments: missionRoleAssignmentType[]?
  workloadRoleAssignments: missionRoleAssignmentType[]?
  additionalMaintenancePrincipals: missionPrincipalType[]?
}

type existingEnclaveType = {
  mode: 'existing'
  resourceId: string
  expectedConfiguration: expectedEnclaveType
}

@discriminator('mode')
type enclaveDefinitionType = managedEnclaveType | existingEnclaveType

type managedWorkloadType = {
  mode: 'managed'
  name: string
  resourceGroupName: string
}

type existingWorkloadType = {
  mode: 'existing'
  resourceId: string
  expectedResourceGroupCollection: string[]
}

@discriminator('mode')
type workloadDefinitionType = managedWorkloadType | existingWorkloadType

type expectedIdentityType = {
  clientId: string
  location: string
  principalId: string
}

type managedIdentityType = {
  mode: 'managed'
  name: string?
  location: string?
  resourceGroupName: string?
}

type existingIdentityType = {
  mode: 'existing'
  resourceId: string
  expectedConfiguration: expectedIdentityType
}

@discriminator('mode')
type identityDefinitionType = managedIdentityType | existingIdentityType

type expectedKeyVaultType = {
  location: string
  networkBypass: 'AzureServices' | 'None'
  networkDefaultAction: 'Deny'
  publicNetworkAccess: 'Disabled'
  purgeProtection: 'Enabled'
  rbacAuthorization: 'Enabled'
  skuName: 'premium' | 'standard'
  softDeleteRetentionDays: int
  tenantId: string
}

type managedKeyVaultType = {
  mode: 'managed'
  name: string?
  resourceGroupName: string?
  skuName: 'premium' | 'standard'?
}

type existingKeyVaultType = {
  mode: 'existing'
  resourceId: string
  expectedConfiguration: expectedKeyVaultType
}

@discriminator('mode')
type keyVaultDefinitionType = managedKeyVaultType | existingKeyVaultType

type expectedKeyType = {
  enabled: 'Enabled'
  keySize: 2048 | 3072 | 4096
  keyType: 'RSA' | 'RSA-HSM'
  versionlessKeyUri: string
}

type managedKeyType = {
  mode: 'managed'
  keySize: 2048 | 3072 | 4096?
  keyType: 'RSA' | 'RSA-HSM'?
  name: string?
}

type existingKeyType = {
  mode: 'existing'
  resourceId: string
  expectedConfiguration: expectedKeyType
}

@discriminator('mode')
type keyDefinitionType = managedKeyType | existingKeyType

type managedDnsZoneType = {
  mode: 'managed'
  name: string?
  resourceGroupName: string?
}

type existingDnsZoneType = {
  mode: 'existing'
  resourceId: string
  expectedName: string
}

@discriminator('mode')
type dnsZoneDefinitionType = managedDnsZoneType | existingDnsZoneType

type privateDnsDefinitionType = {
  delegatedZone: dnsZoneDefinitionType
  keyVaultPrivateLinkZone: dnsZoneDefinitionType
}

type foundationDefinitionType = {
  cmkIdentity: identityDefinitionType
  key: keyDefinitionType
  keyVault: keyVaultDefinitionType
  privateDns: privateDnsDefinitionType
}

type phaseAHandoffType = {
  contractVersion: '1.0'
  communityResourceId: string
  delegatedPrivateDnsZoneResourceId: string
  delegatedSubnetAddressPrefix: string
  delegatedSubnetName: string
  delegatedSubnetNsgResourceId: string
  delegatedSubnetResourceId: string
  enclaveManagedResourceGroupName: string
  enclaveOwnership: 'managed' | 'existing'
  enclaveResourceId: string
  enclaveVnetName: string
  enclaveVnetResourceId: string
  keyVaultPrivateEndpointResourceId: string
  keyVaultResourceId: string
  location: string
  maintenanceMode: 'Advanced'
  maintenancePrincipals: missionPrincipalType[]
  phaseADeploymentPrincipal: missionPrincipalType
  postgreSqlCmkIdentityClientId: string
  postgreSqlCmkIdentityPrincipalId: string
  postgreSqlCmkIdentityResourceId: string
  postgreSqlCmkKeyUri: string
  postgreSqlDnsSuffix: string
  postgreSqlPrivateLinkZoneName: string
  geoCmk: {
    mode: 'absent'
  }
  privateEndpointSubnetAddressPrefix: string
  privateEndpointSubnetName: string
  privateEndpointSubnetNsgResourceId: string
  privateEndpointSubnetResourceId: string
  targetSubscriptionId: string
  workloadResourceGroupId: string
  workloadResourceId: string
}

@description('Core deployment context.')
param deploymentContext deploymentContextType

@description('Deployment principal placed into the Advanced maintenance-principal set for managed enclaves.')
param deploymentPrincipal deploymentPrincipalType

@description('Managed-or-existing Mission community.')
param community communityDefinitionType

@description('Managed-or-existing Mission enclave. Existing enclaves are reference-only and must already contain a compatible delegated PostgreSQL subnet.')
param enclave enclaveDefinitionType

@description('Managed-or-existing Mission workload registration.')
param workload workloadDefinitionType

@description('Managed-or-existing CMK identity, Key Vault, key, and private DNS resources used by the PostgreSQL foundation.')
param foundation foundationDefinitionType

@description('Enable the template outputs only; no runtime telemetry or generated artifacts are emitted.')
param enableTelemetry bool = true

var targetSubscriptionId = !empty(deploymentContext.?subscriptionId) ? deploymentContext.subscriptionId! : subscription().subscriptionId
var location = !empty(deploymentContext.?location) ? deploymentContext.location! : deployment().location
var tags = deploymentContext.?tags ?? {}
var deploymentPrincipalForMission = {
  id: deploymentPrincipal.objectId
  type: deploymentPrincipal.principalType
}

var cloudDomain = replace(replace(environment().resourceManager, 'https://management.', ''), '/', '')
var postgreSqlDnsSuffix = 'postgres.database.${cloudDomain}'
var keyVaultDnsSuffix = environment().suffixes.keyvaultDns
var normalizedKeyVaultDnsSuffix = startsWith(keyVaultDnsSuffix, '.') ? substring(keyVaultDnsSuffix, 1) : keyVaultDnsSuffix
var keyVaultPrivateLinkZoneName = 'privatelink.${replace(normalizedKeyVaultDnsSuffix, 'vault.', 'vaultcore.')}'
var phaseToken = substring(uniqueString(targetSubscriptionId, enclave.mode == 'managed' ? enclave.name : enclave.resourceId, workload.mode == 'managed' ? workload.name : workload.resourceId), 0, 13)

var workloadResourceGroupName = workload.mode == 'managed'
  ? workload.resourceGroupName
  : split(workload.expectedResourceGroupCollection[0], '/')[4]
var workloadResourceGroupId = '/subscriptions/${targetSubscriptionId}/resourceGroups/${workloadResourceGroupName}'

module workloadResourceGroupModule '../../modules/common/resourceGroup.bicep' = if (workload.mode == 'managed') {
  name: 'postgresqlWorkloadResourceGroup'
  params: {
    location: location
    name: workloadResourceGroupName
    tags: tags
  }
}

var managedCommunityResourceGroupName = community.mode == 'managed' ? community.resourceGroupName : ''
module communityResourceGroupModule '../../modules/common/resourceGroup.bicep' = if (community.mode == 'managed') {
  name: 'postgresqlCommunityResourceGroup'
  params: {
    location: location
    name: managedCommunityResourceGroupName
    tags: tags
  }
}

var communitySegments = split(community.mode == 'existing' ? community.resourceId : '///////', '/')
var communityResourceGroupName = community.mode == 'managed' ? managedCommunityResourceGroupName : communitySegments[4]
var communityName = community.mode == 'managed' ? community.name : communitySegments[8]

module communityModule '../../modules/common/missionCommunity.bicep' = if (community.mode == 'managed') {
  name: 'postgresqlCommunity'
  scope: resourceGroup(targetSubscriptionId, communityResourceGroupName)
  params: {
    addressSpace: community.?addressSpace ?? ''
    addressSpaces: community.?addressSpaces ?? []
    communityFirewallSku: 'Standard'
    dnsServers: community.?dnsServers ?? []
    location: location
    name: communityName
    policyOverride: 'Enclave'
    tags: tags
  }
  dependsOn: [
    communityResourceGroupModule
  ]
}

module communityReferenceModule '../../modules/common/missionCommunityReference.bicep' = if (community.mode == 'existing') {
  name: 'postgresqlCommunityReference'
  scope: resourceGroup(communitySegments[2], communityResourceGroupName)
  params: {
    name: communityName
  }
}

var communityResourceId = community.mode == 'managed' ? communityModule.outputs.resourceId : communityReferenceModule.outputs.resourceId

var requiredGovernedServices = [
  {
    enforcement: 'Enabled'
    option: 'Allow'
    policyAction: 'Enforce'
    serviceId: 'KeyVault'
  }
  {
    enforcement: 'Enabled'
    option: 'Allow'
    policyAction: 'Enforce'
    serviceId: 'PostgreSQL'
  }
  {
    enforcement: 'Enabled'
    option: 'Allow'
    policyAction: 'Enforce'
    serviceId: 'PrivateDNSZones'
  }
]

var managedEnclaveMaintenancePrincipals = concat([
  deploymentPrincipalForMission
], enclave.mode == 'managed' ? enclave.?additionalMaintenancePrincipals ?? [] : [])
var managedEnclaveResourceGroupName = enclave.mode == 'managed' ? enclave.resourceGroupName : ''
var delegatedSubnetName = enclave.mode == 'managed' ? enclave.postgreSqlSubnet.?name ?? 'snet-postgresql' : enclave.expectedConfiguration.network.delegatedSubnet.name
var privateEndpointSubnetName = enclave.mode == 'managed' ? enclave.privateEndpointSubnet.?name ?? 'snet-private-endpoints' : enclave.expectedConfiguration.network.privateEndpointSubnet.name

module enclaveResourceGroupModule '../../modules/common/resourceGroup.bicep' = if (enclave.mode == 'managed') {
  name: 'postgresqlEnclaveResourceGroup'
  params: {
    location: location
    name: managedEnclaveResourceGroupName
    tags: tags
  }
}

module managedEnclaveModule '../../modules/common/missionVirtualEnclave.bicep' = if (enclave.mode == 'managed') {
  name: 'postgresqlManagedEnclave'
  scope: resourceGroup(targetSubscriptionId, managedEnclaveResourceGroupName)
  params: {
    approvalSettings: {
      connectionCreation: {
        approvalPolicy: 'Required'
        minimumApproversRequired: 1
      }
      connectionUpdate: {
        approvalPolicy: 'Required'
        minimumApproversRequired: 1
      }
      enclaveEndpointUpdate: {
        approvalPolicy: 'Required'
        minimumApproversRequired: 1
      }
      enclaveMaintenanceMode: {
        approvalPolicy: 'Required'
        minimumApproversRequired: 1
      }
    }
    bastionEnabled: (enclave.?bastion ?? 'Disabled') == 'Enabled'
    communityResourceId: communityResourceId
    enclaveDefaultSettings: {
      diagnosticDestination: enclave.?diagnosticDestination ?? 'EnclaveOnly'
    }
    enclaveRoleAssignments: enclave.?enclaveRoleAssignments ?? []
    governedServiceList: requiredGovernedServices
    location: location
    maintenanceModeConfiguration: {
      justification: 'Governance'
      mode: 'Advanced'
      principals: managedEnclaveMaintenancePrincipals
    }
    name: enclave.name
    networkConfiguration: {
      allowSubnetCommunication: false
      customCidrRange: enclave.addressSpaceCidr
      mode: 'CustomCidr'
      subnetConfigurations: [
        {
          networkPrefixSize: enclave.postgreSqlSubnet.networkPrefixSize
          subnetDelegation: 'Microsoft.DBforPostgreSQL/flexibleServers'
          subnetName: delegatedSubnetName
        }
        {
          networkPrefixSize: enclave.privateEndpointSubnet.networkPrefixSize
          subnetName: privateEndpointSubnetName
        }
      ]
    }
    rbacInheritance: 'Disabled'
    tags: tags
    workloadResourceVisibility: 'Disabled'
    workloadRoleAssignments: enclave.?workloadRoleAssignments ?? []
  }
  dependsOn: [
    enclaveResourceGroupModule
    communityModule
    communityReferenceModule
  ]
}

var existingEnclaveSegments = split(enclave.mode == 'existing' ? enclave.resourceId : '/////////', '/')
var existingEnclaveSubscriptionId = enclave.mode == 'existing' ? existingEnclaveSegments[2] : targetSubscriptionId
var existingEnclaveResourceGroupName = enclave.mode == 'existing' ? existingEnclaveSegments[4] : managedEnclaveResourceGroupName
var enclaveName = enclave.mode == 'managed' ? enclave.name : existingEnclaveSegments[8]

module existingEnclaveModule './modules/existingEnclaveStateReader.bicep' = if (enclave.mode == 'existing') {
  name: 'postgresqlExistingEnclave'
  scope: resourceGroup(existingEnclaveSubscriptionId, existingEnclaveResourceGroupName)
  params: {
    delegatedSubnetName: delegatedSubnetName
    enclaveName: enclaveName
    privateEndpointSubnetName: privateEndpointSubnetName
  }
}

var existingEnclaveMatchesLocation = enclave.mode == 'existing' ? toLower(existingEnclaveModule.outputs.location) == toLower(enclave.expectedConfiguration.location) : true
var existingEnclaveMatchesCommunity = enclave.mode == 'existing' ? toLower(existingEnclaveModule.outputs.communityResourceId) == toLower(enclave.expectedConfiguration.communityResourceId) : true
var existingEnclaveMatchesRbac = enclave.mode == 'existing' ? toLower(existingEnclaveModule.outputs.rbacInheritance) == toLower(enclave.expectedConfiguration.rbacInheritance) : true
var existingEnclaveMatchesVisibility = enclave.mode == 'existing' ? toLower(existingEnclaveModule.outputs.workloadResourceVisibility) == toLower(enclave.expectedConfiguration.workloadResourceVisibility) : true
var existingEnclaveMatchesSubnetCommunication = enclave.mode == 'existing' ? existingEnclaveModule.outputs.allowSubnetCommunication == false : true
var existingEnclaveMatchesDelegatedSubnet = enclave.mode == 'existing' ? toLower(existingEnclaveModule.outputs.delegatedSubnet.resourceId) == toLower(enclave.expectedConfiguration.network.delegatedSubnet.resourceId) && toLower(existingEnclaveModule.outputs.delegatedSubnet.addressPrefix) == toLower(enclave.expectedConfiguration.network.delegatedSubnet.addressPrefix) && int(existingEnclaveModule.outputs.delegatedSubnet.networkPrefixSize) == enclave.expectedConfiguration.network.delegatedSubnet.networkPrefixSize && toLower(existingEnclaveModule.outputs.delegatedSubnet.networkSecurityGroupResourceId) == toLower(enclave.expectedConfiguration.network.delegatedSubnet.networkSecurityGroupResourceId) && toLower(existingEnclaveModule.outputs.delegatedSubnet.subnetDelegation) == toLower(enclave.expectedConfiguration.network.delegatedSubnet.subnetDelegation) : true
var existingEnclaveMatchesPrivateEndpointSubnet = enclave.mode == 'existing' ? toLower(existingEnclaveModule.outputs.privateEndpointSubnet.resourceId) == toLower(enclave.expectedConfiguration.network.privateEndpointSubnet.resourceId) && toLower(existingEnclaveModule.outputs.privateEndpointSubnet.addressPrefix) == toLower(enclave.expectedConfiguration.network.privateEndpointSubnet.addressPrefix) && int(existingEnclaveModule.outputs.privateEndpointSubnet.networkPrefixSize) == enclave.expectedConfiguration.network.privateEndpointSubnet.networkPrefixSize && toLower(existingEnclaveModule.outputs.privateEndpointSubnet.networkSecurityGroupResourceId) == toLower(enclave.expectedConfiguration.network.privateEndpointSubnet.networkSecurityGroupResourceId) && toLower(existingEnclaveModule.outputs.privateEndpointSubnet.subnetDelegation) == toLower(enclave.expectedConfiguration.network.privateEndpointSubnet.subnetDelegation) : true
var existingEnclaveMatchesGovernedServices = enclave.mode == 'existing' ? toLower(string(existingEnclaveModule.outputs.governedServiceList)) == toLower(string(enclave.expectedConfiguration.governedServiceList)) : true
var existingEnclaveMatchesApprovalPolicies = enclave.mode == 'existing' ? toLower(existingEnclaveModule.outputs.approvalPolicies.connectionCreation) == toLower(enclave.expectedConfiguration.approvalPolicies.connectionCreation) && toLower(existingEnclaveModule.outputs.approvalPolicies.connectionUpdate) == toLower(enclave.expectedConfiguration.approvalPolicies.connectionUpdate) && toLower(existingEnclaveModule.outputs.approvalPolicies.enclaveEndpointUpdate) == toLower(enclave.expectedConfiguration.approvalPolicies.enclaveEndpointUpdate) && toLower(existingEnclaveModule.outputs.approvalPolicies.enclaveMaintenanceMode) == toLower(enclave.expectedConfiguration.approvalPolicies.enclaveMaintenanceMode) : true
var existingEnclaveCompatibility = existingEnclaveMatchesLocation && existingEnclaveMatchesCommunity && existingEnclaveMatchesRbac && existingEnclaveMatchesVisibility && existingEnclaveMatchesSubnetCommunication && existingEnclaveMatchesDelegatedSubnet && existingEnclaveMatchesPrivateEndpointSubnet && existingEnclaveMatchesGovernedServices && existingEnclaveMatchesApprovalPolicies

module existingEnclaveCompatibilityGate './modules/requiredTextSubscriptionGate.bicep' = if (enclave.mode == 'existing') {
  name: 'existingEnclaveCompatibilityGate'
  params: {
    requiredText: existingEnclaveCompatibility ? 'compatible' : ''
  }
  dependsOn: [
    existingEnclaveModule
  ]
}

var effectiveEnclaveResourceId = enclave.mode == 'managed' ? managedEnclaveModule.outputs.resourceId : existingEnclaveModule.outputs.resourceId
var effectiveEnclaveLocation = enclave.mode == 'managed' ? location : existingEnclaveModule.outputs.location
var effectiveEnclaveManagedResourceGroupName = enclave.mode == 'managed'
  ? managedEnclaveModule.outputs.managedResourceGroupName
  : existingEnclaveModule.outputs.managedResourceGroupName
var effectiveEnclaveVnetName = enclave.mode == 'managed'
  ? managedEnclaveModule.outputs.enclaveVnetName
  : existingEnclaveModule.outputs.vnetName
var effectiveEnclaveVnetResourceId = enclave.mode == 'managed'
  ? managedEnclaveModule.outputs.enclaveVnetResourceId
  : existingEnclaveModule.outputs.vnetResourceId
var managedEnclaveSubnetConfigurations = enclave.mode == 'managed' ? managedEnclaveModule.outputs.subnetConfigurations : []
var effectiveDelegatedSubnet = enclave.mode == 'managed'
  ? filter(managedEnclaveSubnetConfigurations, subnet => toLower(string(subnet.subnetName)) == toLower(delegatedSubnetName))[0]
  : existingEnclaveModule.outputs.delegatedSubnet
var effectivePrivateEndpointSubnet = enclave.mode == 'managed'
  ? filter(managedEnclaveSubnetConfigurations, subnet => toLower(string(subnet.subnetName)) == toLower(privateEndpointSubnetName))[0]
  : existingEnclaveModule.outputs.privateEndpointSubnet
var maintenancePrincipals = enclave.mode == 'managed' ? managedEnclaveMaintenancePrincipals : existingEnclaveModule.outputs.maintenancePrincipals

var workloadSegments = split(workload.mode == 'existing' ? workload.resourceId : '///////////', '/')
var workloadRegistrationEnclaveName = workload.mode == 'managed' ? enclaveName : workloadSegments[8]
var workloadName = workload.mode == 'managed' ? workload.name : workloadSegments[10]

module managedWorkloadModule '../../modules/common/missionWorkload.bicep' = if (workload.mode == 'managed') {
  name: 'postgresqlManagedWorkload'
  scope: resourceGroup(enclave.mode == 'managed' ? targetSubscriptionId : existingEnclaveSubscriptionId, enclave.mode == 'managed' ? managedEnclaveResourceGroupName : existingEnclaveResourceGroupName)
  params: {
    enclaveName: workloadRegistrationEnclaveName
    location: effectiveEnclaveLocation
    name: workloadName
    resourceGroupCollection: [
      workloadResourceGroupId
    ]
    tags: tags
  }
  dependsOn: [
    workloadResourceGroupModule
    managedEnclaveModule
    existingEnclaveCompatibilityGate
  ]
}

module existingWorkloadModule './modules/existingWorkloadStateReader.bicep' = if (workload.mode == 'existing') {
  name: 'postgresqlExistingWorkload'
  scope: resourceGroup(workloadSegments[2], workloadSegments[4])
  params: {
    enclaveName: workloadRegistrationEnclaveName
    workloadName: workloadName
  }
}

var existingWorkloadCompatibility = workload.mode == 'managed' ? true : string(existingWorkloadModule.outputs.resourceGroupCollection) == string(workload.expectedResourceGroupCollection)

module existingWorkloadCompatibilityGate './modules/requiredTextSubscriptionGate.bicep' = if (workload.mode == 'existing') {
  name: 'existingWorkloadCompatibilityGate'
  params: {
    requiredText: existingWorkloadCompatibility ? 'compatible' : ''
  }
  dependsOn: [
    existingWorkloadModule
  ]
}

var effectiveWorkloadResourceId = workload.mode == 'managed' ? managedWorkloadModule.outputs.resourceId : existingWorkloadModule.outputs.resourceId
var effectiveWorkloadResourceGroupId = workload.mode == 'managed' ? workloadResourceGroupId : workload.expectedResourceGroupCollection[0]

var cmkIdentityResourceGroupName = foundation.cmkIdentity.mode == 'managed' ? foundation.cmkIdentity.?resourceGroupName ?? workloadResourceGroupName : split(foundation.cmkIdentity.resourceId, '/')[4]
var cmkIdentityResourceGroupSubscriptionId = foundation.cmkIdentity.mode == 'managed' ? targetSubscriptionId : split(foundation.cmkIdentity.resourceId, '/')[2]
var cmkIdentityName = foundation.cmkIdentity.mode == 'managed'
  ? foundation.cmkIdentity.?name ?? 'uai-postgresql-cmk-${phaseToken}'
  : split(foundation.cmkIdentity.resourceId, '/')[8]

module cmkIdentityResourceGroupModule '../../modules/common/resourceGroup.bicep' = if (foundation.cmkIdentity.mode == 'managed' && cmkIdentityResourceGroupName != workloadResourceGroupName) {
  name: 'postgresqlCmkIdentityResourceGroup'
  params: {
    location: foundation.cmkIdentity.?location ?? location
    name: cmkIdentityResourceGroupName
    tags: tags
  }
}

module cmkIdentityModule '../../modules/common/userAssignedIdentity.bicep' = if (foundation.cmkIdentity.mode == 'managed') {
  name: 'postgresqlCmkIdentity'
  scope: resourceGroup(targetSubscriptionId, cmkIdentityResourceGroupName)
  params: {
    location: foundation.cmkIdentity.?location ?? location
    name: cmkIdentityName
    tags: tags
  }
  dependsOn: [
    workloadResourceGroupModule
    cmkIdentityResourceGroupModule
  ]
}

resource existingCmkIdentityResource 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = if (foundation.cmkIdentity.mode == 'existing') {
  name: cmkIdentityName
  scope: resourceGroup(cmkIdentityResourceGroupSubscriptionId, cmkIdentityResourceGroupName)
}

var existingCmkIdentityMatchesLocation = foundation.cmkIdentity.mode == 'existing' ? toLower(existingCmkIdentityResource.location) == toLower(foundation.cmkIdentity.expectedConfiguration.location) : true
var existingCmkIdentityMatchesPrincipal = foundation.cmkIdentity.mode == 'existing' ? toLower(existingCmkIdentityResource.properties.principalId) == toLower(foundation.cmkIdentity.expectedConfiguration.principalId) : true
var existingCmkIdentityMatchesClient = foundation.cmkIdentity.mode == 'existing' ? toLower(existingCmkIdentityResource.properties.clientId) == toLower(foundation.cmkIdentity.expectedConfiguration.clientId) : true
var existingCmkIdentityCompatibility = existingCmkIdentityMatchesLocation && existingCmkIdentityMatchesPrincipal && existingCmkIdentityMatchesClient

module existingCmkIdentityCompatibilityGate './modules/requiredTextSubscriptionGate.bicep' = if (foundation.cmkIdentity.mode == 'existing') {
  name: 'existingCmkIdentityCompatibilityGate'
  params: {
    requiredText: existingCmkIdentityCompatibility ? 'compatible' : ''
  }
}

var cmkIdentityResourceId = foundation.cmkIdentity.mode == 'managed' ? cmkIdentityModule.outputs.resourceId : existingCmkIdentityResource.id
var cmkIdentityPrincipalId = foundation.cmkIdentity.mode == 'managed' ? cmkIdentityModule.outputs.principalId : existingCmkIdentityResource.properties.principalId
var cmkIdentityClientId = foundation.cmkIdentity.mode == 'managed' ? cmkIdentityModule.outputs.clientId : existingCmkIdentityResource.properties.clientId

var keyVaultResourceGroupName = foundation.keyVault.mode == 'managed' ? foundation.keyVault.?resourceGroupName ?? workloadResourceGroupName : split(foundation.keyVault.resourceId, '/')[4]
var keyVaultSubscriptionId = foundation.keyVault.mode == 'managed' ? targetSubscriptionId : split(foundation.keyVault.resourceId, '/')[2]
var keyVaultName = foundation.keyVault.mode == 'managed'
  ? foundation.keyVault.?name ?? 'kvpg${phaseToken}'
  : split(foundation.keyVault.resourceId, '/')[8]

module keyVaultResourceGroupModule '../../modules/common/resourceGroup.bicep' = if (foundation.keyVault.mode == 'managed' && keyVaultResourceGroupName != workloadResourceGroupName) {
  name: 'postgresqlKeyVaultResourceGroup'
  params: {
    location: location
    name: keyVaultResourceGroupName
    tags: tags
  }
}

module keyVaultModule '../../modules/common/keyVault.bicep' = if (foundation.keyVault.mode == 'managed') {
  name: 'postgresqlKeyVault'
  scope: resourceGroup(targetSubscriptionId, keyVaultResourceGroupName)
  params: {
    location: location
    name: keyVaultName
    networkAclsBypass: 'None'
    skuName: foundation.keyVault.?skuName ?? 'premium'
    tags: tags
  }
  dependsOn: [
    workloadResourceGroupModule
    keyVaultResourceGroupModule
  ]
}

resource existingKeyVaultResource 'Microsoft.KeyVault/vaults@2023-07-01' existing = if (foundation.keyVault.mode == 'existing') {
  name: keyVaultName
  scope: resourceGroup(keyVaultSubscriptionId, keyVaultResourceGroupName)
}

var existingKeyVaultMatchesLocation = foundation.keyVault.mode == 'existing' ? toLower(existingKeyVaultResource.location) == toLower(foundation.keyVault.expectedConfiguration.location) : true
var existingKeyVaultMatchesTenant = foundation.keyVault.mode == 'existing' ? toLower(string(existingKeyVaultResource.properties.tenantId)) == toLower(foundation.keyVault.expectedConfiguration.tenantId) : true
var existingKeyVaultMatchesSku = foundation.keyVault.mode == 'existing' ? toLower(string(existingKeyVaultResource.properties.sku.name)) == toLower(foundation.keyVault.expectedConfiguration.skuName) : true
var existingKeyVaultMatchesNetwork = foundation.keyVault.mode == 'existing' ? toLower(string(existingKeyVaultResource.properties.publicNetworkAccess)) == toLower(foundation.keyVault.expectedConfiguration.publicNetworkAccess) && toLower(string(existingKeyVaultResource.properties.networkAcls.defaultAction)) == toLower(foundation.keyVault.expectedConfiguration.networkDefaultAction) && toLower(string(existingKeyVaultResource.properties.networkAcls.bypass)) == toLower(foundation.keyVault.expectedConfiguration.networkBypass) : true
var existingKeyVaultMatchesProtection = foundation.keyVault.mode == 'existing' ? bool(existingKeyVaultResource.properties.enablePurgeProtection) && bool(existingKeyVaultResource.properties.enableRbacAuthorization) && int(existingKeyVaultResource.properties.softDeleteRetentionInDays) == foundation.keyVault.expectedConfiguration.softDeleteRetentionDays : true
var existingKeyVaultCompatibility = existingKeyVaultMatchesLocation && existingKeyVaultMatchesTenant && existingKeyVaultMatchesSku && existingKeyVaultMatchesNetwork && existingKeyVaultMatchesProtection

module existingKeyVaultCompatibilityGate './modules/requiredTextSubscriptionGate.bicep' = if (foundation.keyVault.mode == 'existing') {
  name: 'existingKeyVaultCompatibilityGate'
  params: {
    requiredText: existingKeyVaultCompatibility ? 'compatible' : ''
  }
}

var keyVaultResourceId = foundation.keyVault.mode == 'managed' ? keyVaultModule.outputs.resourceId : existingKeyVaultResource.id
var keyVaultUri = foundation.keyVault.mode == 'managed' ? keyVaultModule.outputs.vaultUri : existingKeyVaultResource.properties.vaultUri

var keyName = foundation.key.mode == 'managed'
  ? foundation.key.?name ?? 'postgresql-cmk'
  : split(foundation.key.resourceId, '/')[10]

module keyModule '../../modules/common/keyVaultKey.bicep' = if (foundation.key.mode == 'managed') {
  name: 'postgresqlCmkKey'
  scope: resourceGroup(keyVaultSubscriptionId, keyVaultResourceGroupName)
  params: {
    keySize: foundation.key.?keySize ?? 3072
    keyTypeName: foundation.key.?keyType ?? 'RSA-HSM'
    name: keyName
    vaultName: keyVaultName
  }
  dependsOn: [
    keyVaultModule
  ]
}

resource existingKeyVaultParent 'Microsoft.KeyVault/vaults@2023-07-01' existing = if (foundation.key.mode == 'existing') {
  name: keyVaultName
  scope: resourceGroup(keyVaultSubscriptionId, keyVaultResourceGroupName)
}

resource existingKeyResource 'Microsoft.KeyVault/vaults/keys@2023-07-01' existing = if (foundation.key.mode == 'existing') {
  parent: existingKeyVaultParent
  name: keyName
}

var existingKeyVersionlessUri = 'https://${keyVaultName}${environment().suffixes.keyvaultDns}/keys/${keyName}'
var existingKeyMatchesEnabled = foundation.key.mode == 'existing' ? bool(existingKeyResource.properties.attributes.enabled) : true
var existingKeyMatchesType = foundation.key.mode == 'existing' ? toLower(string(existingKeyResource.properties.kty)) == toLower(foundation.key.expectedConfiguration.keyType) : true
var existingKeyMatchesSize = foundation.key.mode == 'existing' ? int(existingKeyResource.properties.keySize) == foundation.key.expectedConfiguration.keySize : true
var existingKeyMatchesUri = foundation.key.mode == 'existing' ? toLower(existingKeyVersionlessUri) == toLower(foundation.key.expectedConfiguration.versionlessKeyUri) : true
var existingKeyCompatibility = existingKeyMatchesEnabled && existingKeyMatchesType && existingKeyMatchesSize && existingKeyMatchesUri

module existingKeyCompatibilityGate './modules/requiredTextSubscriptionGate.bicep' = if (foundation.key.mode == 'existing') {
  name: 'existingKeyCompatibilityGate'
  params: {
    requiredText: existingKeyCompatibility ? 'compatible' : ''
  }
}

var cmkKeyUri = foundation.key.mode == 'managed' ? keyModule.outputs.versionlessKeyUri : existingKeyVersionlessUri

module keyVaultCmkRoleAssignmentModule '../../modules/common/roleAssignment.bicep' = {
  name: 'postgresqlCmkRoleAssignment'
  scope: resourceGroup(keyVaultSubscriptionId, keyVaultResourceGroupName)
  params: {
    parentResourceName: keyVaultName
    principalId: cmkIdentityPrincipalId
    principalTypeName: 'ServicePrincipal'
    roleDefinitionIdOrGuid: 'e147488a-f6f5-4113-8e2d-b22465e65bf6'
    scopeKind: 'keyVaultKey'
    scopeName: keyName
  }
  dependsOn: [
    cmkIdentityModule
    keyModule
    existingCmkIdentityCompatibilityGate
    existingKeyCompatibilityGate
  ]
}

var delegatedZoneResourceGroupName = foundation.privateDns.delegatedZone.mode == 'managed'
  ? foundation.privateDns.delegatedZone.?resourceGroupName ?? workloadResourceGroupName
  : split(foundation.privateDns.delegatedZone.resourceId, '/')[4]
var delegatedZoneSubscriptionId = foundation.privateDns.delegatedZone.mode == 'managed'
  ? targetSubscriptionId
  : split(foundation.privateDns.delegatedZone.resourceId, '/')[2]
var delegatedZoneName = foundation.privateDns.delegatedZone.mode == 'managed'
  ? foundation.privateDns.delegatedZone.?name ?? 'ave-${phaseToken}.${postgreSqlDnsSuffix}'
  : split(foundation.privateDns.delegatedZone.resourceId, '/')[8]

module delegatedDnsResourceGroupModule '../../modules/common/resourceGroup.bicep' = if (foundation.privateDns.delegatedZone.mode == 'managed' && delegatedZoneResourceGroupName != workloadResourceGroupName) {
  name: 'postgresqlDelegatedDnsResourceGroup'
  params: {
    location: location
    name: delegatedZoneResourceGroupName
    tags: tags
  }
}

module delegatedDnsZoneModule '../../modules/common/privateDnsZone.bicep' = if (foundation.privateDns.delegatedZone.mode == 'managed') {
  name: 'postgresqlDelegatedDnsZone'
  scope: resourceGroup(delegatedZoneSubscriptionId, delegatedZoneResourceGroupName)
  params: {
    name: delegatedZoneName
    tags: tags
  }
  dependsOn: [
    workloadResourceGroupModule
    delegatedDnsResourceGroupModule
  ]
}

resource existingDelegatedDnsZoneResource 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (foundation.privateDns.delegatedZone.mode == 'existing') {
  name: delegatedZoneName
  scope: resourceGroup(delegatedZoneSubscriptionId, delegatedZoneResourceGroupName)
}

var existingDelegatedDnsCompatibility = foundation.privateDns.delegatedZone.mode == 'managed' ? true : toLower(existingDelegatedDnsZoneResource.name) == toLower(foundation.privateDns.delegatedZone.expectedName)

module existingDelegatedDnsCompatibilityGate './modules/requiredTextSubscriptionGate.bicep' = if (foundation.privateDns.delegatedZone.mode == 'existing') {
  name: 'existingDelegatedDnsCompatibilityGate'
  params: {
    requiredText: existingDelegatedDnsCompatibility ? 'compatible' : ''
  }
}

var keyVaultZoneResourceGroupName = foundation.privateDns.keyVaultPrivateLinkZone.mode == 'managed'
  ? foundation.privateDns.keyVaultPrivateLinkZone.?resourceGroupName ?? workloadResourceGroupName
  : split(foundation.privateDns.keyVaultPrivateLinkZone.resourceId, '/')[4]
var keyVaultZoneSubscriptionId = foundation.privateDns.keyVaultPrivateLinkZone.mode == 'managed'
  ? targetSubscriptionId
  : split(foundation.privateDns.keyVaultPrivateLinkZone.resourceId, '/')[2]
var keyVaultZoneName = foundation.privateDns.keyVaultPrivateLinkZone.mode == 'managed'
  ? foundation.privateDns.keyVaultPrivateLinkZone.?name ?? keyVaultPrivateLinkZoneName
  : split(foundation.privateDns.keyVaultPrivateLinkZone.resourceId, '/')[8]

module keyVaultDnsResourceGroupModule '../../modules/common/resourceGroup.bicep' = if (foundation.privateDns.keyVaultPrivateLinkZone.mode == 'managed' && keyVaultZoneResourceGroupName != workloadResourceGroupName) {
  name: 'postgresqlKeyVaultDnsResourceGroup'
  params: {
    location: location
    name: keyVaultZoneResourceGroupName
    tags: tags
  }
}

module keyVaultDnsZoneModule '../../modules/common/privateDnsZone.bicep' = if (foundation.privateDns.keyVaultPrivateLinkZone.mode == 'managed') {
  name: 'postgresqlKeyVaultDnsZone'
  scope: resourceGroup(keyVaultZoneSubscriptionId, keyVaultZoneResourceGroupName)
  params: {
    name: keyVaultZoneName
    tags: tags
  }
  dependsOn: [
    workloadResourceGroupModule
    keyVaultDnsResourceGroupModule
  ]
}

resource existingKeyVaultDnsZoneResource 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (foundation.privateDns.keyVaultPrivateLinkZone.mode == 'existing') {
  name: keyVaultZoneName
  scope: resourceGroup(keyVaultZoneSubscriptionId, keyVaultZoneResourceGroupName)
}

var existingKeyVaultDnsCompatibility = foundation.privateDns.keyVaultPrivateLinkZone.mode == 'managed' ? true : toLower(existingKeyVaultDnsZoneResource.name) == toLower(foundation.privateDns.keyVaultPrivateLinkZone.expectedName)

module existingKeyVaultDnsCompatibilityGate './modules/requiredTextSubscriptionGate.bicep' = if (foundation.privateDns.keyVaultPrivateLinkZone.mode == 'existing') {
  name: 'existingKeyVaultDnsCompatibilityGate'
  params: {
    requiredText: existingKeyVaultDnsCompatibility ? 'compatible' : ''
  }
}

var effectiveEnclaveVnetId = enclave.mode == 'managed'
  ? managedEnclaveModule.outputs.enclaveVnetResourceId
  : effectiveEnclaveVnetResourceId

module delegatedDnsLinkModule '../../modules/common/privateDnsZoneVirtualNetworkLink.bicep' = {
  name: 'postgresqlDelegatedDnsLink'
  scope: resourceGroup(delegatedZoneSubscriptionId, delegatedZoneResourceGroupName)
  params: {
    linkName: 'link-${phaseToken}'
    tags: tags
    virtualNetworkResourceId: effectiveEnclaveVnetId
    zoneName: delegatedZoneName
  }
  dependsOn: [
    managedEnclaveModule
    existingEnclaveCompatibilityGate
    delegatedDnsZoneModule
    existingDelegatedDnsCompatibilityGate
  ]
}

module keyVaultDnsLinkModule '../../modules/common/privateDnsZoneVirtualNetworkLink.bicep' = {
  name: 'postgresqlKeyVaultDnsLink'
  scope: resourceGroup(keyVaultZoneSubscriptionId, keyVaultZoneResourceGroupName)
  params: {
    linkName: 'link-${phaseToken}'
    tags: tags
    virtualNetworkResourceId: effectiveEnclaveVnetId
    zoneName: keyVaultZoneName
  }
  dependsOn: [
    managedEnclaveModule
    existingEnclaveCompatibilityGate
    keyVaultDnsZoneModule
    existingKeyVaultDnsCompatibilityGate
  ]
}

module keyVaultPrivateEndpointModule '../../modules/common/privateEndpoint.bicep' = {
  name: 'postgresqlKeyVaultPrivateEndpoint'
  scope: resourceGroup(keyVaultSubscriptionId, keyVaultResourceGroupName)
  params: {
    location: effectiveEnclaveLocation
    name: '${keyVaultName}-pe'
    privateDnsZones: [
      {
        name: keyVaultZoneName
        privateDnsZoneResourceId: foundation.privateDns.keyVaultPrivateLinkZone.mode == 'managed'
          ? keyVaultDnsZoneModule.outputs.resourceId
          : existingKeyVaultDnsZoneResource.id
      }
    ]
    privateLinkConnection: {
      approvalMode: 'Auto'
      groupIds: [
        'vault'
      ]
      name: '${keyVaultName}-vault'
      privateLinkServiceResourceId: keyVaultResourceId
    }
    subnetResourceId: enclave.mode == 'managed' ? resourceId(targetSubscriptionId, effectiveEnclaveManagedResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', effectiveEnclaveVnetName, privateEndpointSubnetName) : effectivePrivateEndpointSubnet.resourceId
    tags: tags
  }
  dependsOn: [
    keyVaultModule
    existingKeyVaultCompatibilityGate
    keyVaultDnsLinkModule
  ]
}

output contractVersion string = '1.0'
output phaseA phaseAHandoffType = {
  contractVersion: '1.0'
  communityResourceId: communityResourceId
  delegatedPrivateDnsZoneResourceId: foundation.privateDns.delegatedZone.mode == 'managed' ? delegatedDnsZoneModule.outputs.resourceId : existingDelegatedDnsZoneResource.id
  delegatedSubnetAddressPrefix: enclave.mode == 'managed' ? '' : effectiveDelegatedSubnet.addressPrefix
  delegatedSubnetName: delegatedSubnetName
  delegatedSubnetNsgResourceId: enclave.mode == 'managed' ? '' : effectiveDelegatedSubnet.networkSecurityGroupResourceId
  delegatedSubnetResourceId: enclave.mode == 'managed'
    ? resourceId(targetSubscriptionId, effectiveEnclaveManagedResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', effectiveEnclaveVnetName, delegatedSubnetName)
    : effectiveDelegatedSubnet.resourceId
  enclaveManagedResourceGroupName: effectiveEnclaveManagedResourceGroupName
  enclaveOwnership: enclave.mode
  enclaveResourceId: effectiveEnclaveResourceId
  enclaveVnetName: effectiveEnclaveVnetName
  enclaveVnetResourceId: effectiveEnclaveVnetId
  keyVaultPrivateEndpointResourceId: keyVaultPrivateEndpointModule.outputs.resourceId
  keyVaultResourceId: keyVaultResourceId
  location: effectiveEnclaveLocation
  maintenanceMode: 'Advanced'
  maintenancePrincipals: maintenancePrincipals
  phaseADeploymentPrincipal: deploymentPrincipalForMission
  postgreSqlCmkIdentityClientId: cmkIdentityClientId
  postgreSqlCmkIdentityPrincipalId: cmkIdentityPrincipalId
  postgreSqlCmkIdentityResourceId: cmkIdentityResourceId
  postgreSqlCmkKeyUri: cmkKeyUri
  postgreSqlDnsSuffix: postgreSqlDnsSuffix
  postgreSqlPrivateLinkZoneName: 'privatelink.${postgreSqlDnsSuffix}'
  geoCmk: {
    mode: 'absent'
  }
  privateEndpointSubnetAddressPrefix: string(effectivePrivateEndpointSubnet.addressPrefix)
  privateEndpointSubnetName: privateEndpointSubnetName
  privateEndpointSubnetNsgResourceId: string(effectivePrivateEndpointSubnet.networkSecurityGroupResourceId)
  privateEndpointSubnetResourceId: string(effectivePrivateEndpointSubnet.resourceId)
  targetSubscriptionId: targetSubscriptionId
  workloadResourceGroupId: effectiveWorkloadResourceGroupId
  workloadResourceId: effectiveWorkloadResourceId
}
output workloadResourceGroupId string = effectiveWorkloadResourceGroupId
output workloadResourceId string = effectiveWorkloadResourceId
output delegatedPrivateDnsZoneResourceId string = foundation.privateDns.delegatedZone.mode == 'managed' ? delegatedDnsZoneModule.outputs.resourceId : existingDelegatedDnsZoneResource.id
output keyVaultPrivateEndpointResourceId string = keyVaultPrivateEndpointModule.outputs.resourceId
output keyVaultCmkRoleAssignmentId string = keyVaultCmkRoleAssignmentModule.outputs.roleAssignmentId
output telemetryEnabled bool = enableTelemetry
