targetScope = 'subscription'

type deploymentContextType = {
  subscriptionId: string?
  location: string?
  @minLength(1)
  @maxLength(5)
  instance: string?
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
  @description('Subnet name. Omit to use the workload default. For an existing enclave, a live subnet with this name is reused additively.')
  @minLength(1)
  name: string?
  @description('Subnet prefix size. Omit to reuse the live prefix size when the subnet already exists, or the workload default (24) when it does not.')
  @minValue(1)
  networkPrefixSize: int?
}

type diagnosticDestinationType = 'Both' | 'CommunityOnly' | 'EnclaveOnly'

type mandatoryApproverType = {
  approverEntraId: string
}

type requiredApprovalSettingType = {
  approvalPolicy: 'Required'
  @minLength(1)
  mandatoryApprovers: mandatoryApproverType[]
  @minValue(1)
  minimumApproversRequired: int
}

type notRequiredApprovalSettingType = {
  approvalPolicy: 'NotRequired'
}

@discriminator('approvalPolicy')
type approvalSettingType = requiredApprovalSettingType | notRequiredApprovalSettingType

type approvalSettingsType = {
  connectionCreation: approvalSettingType
  connectionUpdate: approvalSettingType
  enclaveEndpointUpdate: approvalSettingType
  enclaveMaintenanceMode: approvalSettingType
}

// ─── Enclave ──────────────────────────────────────────────────────────────────
// One contract covers both scenarios. Supplying resourceId points the
// deployment at an existing enclave; omitting it creates a new one. Both flow
// through the same code path: additive collections are unioned with whatever
// the live enclave already declares (an empty base when creating), and
// immutable enclave properties are read from live state and carried forward
// verbatim instead of being asserted against a caller-supplied expectation.

type enclaveDefinitionType = {
  @description('Existing Mission virtual enclave resource ID. Omit to create a new enclave.')
  @minLength(1)
  resourceId: string?

  @description('Enclave name. Used only when creating a new enclave; the live name is used when resourceId is supplied.')
  @minLength(1)
  name: string?

  @description('Enclave resource group name. Used only when creating a new enclave; the resource group is parsed from resourceId otherwise.')
  @minLength(1)
  resourceGroupName: string?

  @description('Enclave address space. Required when creating a new enclave; read and reused from live state when resourceId is supplied.')
  @minLength(1)
  addressSpaceCidr: string?

  @description('All four Mission approval gates. Required when creating a new enclave; read and reused from live state when resourceId is supplied.')
  approvalSettings: approvalSettingsType?

  @description('Enclave subnet-to-subnet communication. Used only when creating a new enclave; read and reused from live state otherwise.')
  allowSubnetCommunication: bool?

  @description('Mission-managed Bastion. Used only when creating a new enclave; read and reused from live state otherwise.')
  bastionEnabled: bool?

  @description('Enclave default diagnostic destination. Used only when creating a new enclave; read and reused from live state otherwise.')
  diagnosticDestination: diagnosticDestinationType?

  @description('This workload\'s delegated PostgreSQL subnet request. Unioned into the enclave subnet set keyed by name.')
  postgreSqlSubnet: subnetRequestType?

  @description('This workload\'s private endpoint subnet request. Unioned into the enclave subnet set keyed by name.')
  privateEndpointSubnet: subnetRequestType?

  @description('Additional enclave-scope Mission role assignments. Always unioned with whatever the enclave already declares.')
  enclaveRoleAssignments: missionRoleAssignmentType[]?

  @description('Additional workload-scope Mission role assignments. Always unioned with whatever the enclave already declares.')
  workloadRoleAssignments: missionRoleAssignmentType[]?

  @description('Additional Mission maintenance-mode principals. Always unioned with the live principal set and the deployment principal.')
  additionalMaintenancePrincipals: missionPrincipalType[]?
}

type managedWorkloadType = {
  mode: 'managed'
  name: string?
  resourceGroupName: string?
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
  @description('Controls whether the Microsoft Graph "User.Read.All" application permission is granted to this managed identity through the Microsoft Graph Bicep extension. Defaults to Managed. Set to Skip only when the grant is applied out-of-band by an equivalent process. This is the template\'s intended permission for PostgreSQL Entra administrator creation; see the PostgreSQL workload README for the current, live-tested status of that dependency.')
  graphPermissionGrant: graphPermissionGrantType?
}

type existingIdentityType = {
  mode: 'existing'
  @description('Full resource ID of a pre-created user-assigned managed identity that has already been granted Microsoft Graph "User.Read.All" by a suitably privileged Entra administrator. This template never creates or grants Graph permissions for an existing identity.')
  resourceId: string
  expectedConfiguration: expectedIdentityType
}

@discriminator('mode')
type identityDefinitionType = managedIdentityType | existingIdentityType

type managedGraphPermissionGrantType = {
  mode: 'Managed'
}

type skipGraphPermissionGrantType = {
  mode: 'Skip'
}

@discriminator('mode')
type graphPermissionGrantType = managedGraphPermissionGrantType | skipGraphPermissionGrantType

type expectedKeyVaultType = {
  location: string
  networkBypass: 'AzureServices'
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
  serverIdentity: identityDefinitionType
  key: keyDefinitionType
  keyVault: keyVaultDefinitionType
  privateDns: privateDnsDefinitionType
}

type phaseAHandoffType = {
  contractVersion: '3.0'
  communityResourceId: string
  delegatedPrivateDnsZoneResourceId: string
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
  postgreSqlServerIdentityClientId: string
  postgreSqlServerIdentityPrincipalId: string
  postgreSqlServerIdentityResourceId: string
  postgreSqlCmkKeyUri: string
  postgreSqlDnsSuffix: string
  postgreSqlPrivateLinkZoneName: string
  postgreSqlSubnetAddressPrefix: string
  postgreSqlSubnetName: string
  postgreSqlSubnetNsgResourceId: string
  postgreSqlSubnetResourceId: string
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

@description('Deployment principal placed into the Advanced maintenance-principal set and used for the managed default Mission workload-scope Owner assignment for managed enclaves.')
param deploymentPrincipal deploymentPrincipalType

@description('Managed-or-existing Mission community.')
param community communityDefinitionType

@description('Mission enclave. Omit resourceId to create a new enclave (addressSpaceCidr and approvalSettings are then required). Supply resourceId to additively extend an existing enclave; its immutable properties are read and reused as-is.')
param enclave enclaveDefinitionType

@description('Managed-or-existing Mission workload registration. Defaults to managed with Community-derived names.')
param workload workloadDefinitionType = {
  mode: 'managed'
}

@description('Managed-or-existing server identity, Key Vault, key, and private DNS resources used by the PostgreSQL foundation. Defaults every child to managed mode.')
param foundation foundationDefinitionType = {
  serverIdentity: {
    mode: 'managed'
  }
  key: {
    mode: 'managed'
  }
  keyVault: {
    mode: 'managed'
  }
  privateDns: {
    delegatedZone: {
      mode: 'managed'
    }
    keyVaultPrivateLinkZone: {
      mode: 'managed'
    }
  }
}

@description('Enable the template outputs only; no runtime telemetry or generated artifacts are emitted.')
param enableTelemetry bool = true

var targetSubscriptionId = !empty(deploymentContext.?subscriptionId) ? deploymentContext.subscriptionId! : subscription().subscriptionId
var location = !empty(deploymentContext.?location) ? deploymentContext.location! : deployment().location
var resolvedInstance = !empty(deploymentContext.?instance) ? deploymentContext.instance! : '001'
var tags = deploymentContext.?tags ?? {}
var deploymentPrincipalForMission = {
  id: deploymentPrincipal.objectId
  type: deploymentPrincipal.principalType
}

// One flag drives the whole enclave flow. Everything downstream is written once
// and resolves correctly for both new and existing enclaves.
var enclaveResourceId = enclave.?resourceId ?? ''
var isExistingEnclave = !empty(enclaveResourceId)

var requestedWorkloadRoleAssignments = enclave.?workloadRoleAssignments ?? []
// Without at least one workload-scope assignment the deployment principal
// cannot administer the Mission workload resource group it is about to fill.
var effectiveWorkloadRoleAssignmentRequest = length(requestedWorkloadRoleAssignments) == 0
  ? [
      {
        principals: [
          deploymentPrincipalForMission
        ]
        roleDefinitionId: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
      }
    ]
  : requestedWorkloadRoleAssignments

var cloudDomain = replace(replace(environment().resourceManager, 'https://management.', ''), '/', '')
var postgreSqlDnsSuffix = 'postgres.database.${cloudDomain}'
var keyVaultDnsSuffix = environment().suffixes.keyvaultDns
var normalizedKeyVaultDnsSuffix = startsWith(keyVaultDnsSuffix, '.') ? substring(keyVaultDnsSuffix, 1) : keyVaultDnsSuffix
var keyVaultPrivateLinkZoneName = 'privatelink.${replace(normalizedKeyVaultDnsSuffix, 'vault.', 'vaultcore.')}'
var communitySegments = split(community.mode == 'existing' ? community.resourceId : '/subscriptions/${targetSubscriptionId}/resourceGroups/${community.resourceGroupName}/providers/Microsoft.Mission/communities/${community.name}', '/')
var communityName = community.mode == 'managed' ? community.name : last(split(community.resourceId, '/'))
var enclaveIdSegments = split(isExistingEnclave ? enclaveResourceId : '/////////', '/')
var enclaveSubscriptionId = isExistingEnclave ? enclaveIdSegments[2] : targetSubscriptionId
var enclaveResourceGroupName = isExistingEnclave
  ? enclaveIdSegments[4]
  : enclave.?resourceGroupName ?? 'rg-${take(communityName, 72 - length(resolvedInstance))}-pgsql-enclave-${resolvedInstance}'
var enclaveName = isExistingEnclave
  ? enclaveIdSegments[8]
  : enclave.?name ?? 've-${take(communityName, 54 - length(resolvedInstance))}-pgsql-${resolvedInstance}'
var managedWorkloadName = workload.mode == 'managed' ? workload.?name ?? 'wl-${take(communityName, 20 - length(resolvedInstance))}-pgsql-${resolvedInstance}' : ''
var managedWorkloadResourceGroupName = workload.mode == 'managed' ? workload.?resourceGroupName ?? 'rg-${take(communityName, 71 - length(resolvedInstance))}-pgsql-workload-${resolvedInstance}' : ''
var communityUniqueSuffix = take(uniqueString(targetSubscriptionId, communityName, resolvedInstance), 8)
var phaseToken = take(uniqueString(targetSubscriptionId, isExistingEnclave ? enclaveResourceId : enclaveName, workload.mode == 'managed' ? managedWorkloadName : workload.resourceId), 13)

var workloadResourceGroupId = workload.mode == 'managed'
  ? '/subscriptions/${targetSubscriptionId}/resourceGroups/${managedWorkloadResourceGroupName}'
  : workload.expectedResourceGroupCollection[0]
var workloadResourceGroupSegments = split(workloadResourceGroupId, '/')
var workloadResourceGroupSubscriptionId = workloadResourceGroupSegments[2]
var workloadResourceGroupName = workloadResourceGroupSegments[4]

module workloadResourceGroupModule '../../modules/common/resourceGroup.bicep' = if (workload.mode == 'managed') {
  name: 'postgresqlWorkloadResourceGroup'
  scope: subscription(targetSubscriptionId)
  params: {
    location: location
    name: workloadResourceGroupName
    tags: tags
  }
}

var managedCommunityResourceGroupName = community.mode == 'managed' ? community.resourceGroupName : ''
module communityResourceGroupModule '../../modules/common/resourceGroup.bicep' = if (community.mode == 'managed') {
  name: 'postgresqlCommunityResourceGroup'
  scope: subscription(targetSubscriptionId)
  params: {
    location: location
    name: managedCommunityResourceGroupName
    tags: tags
  }
}

var communityResourceGroupName = community.mode == 'managed' ? managedCommunityResourceGroupName : communitySegments[4]

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

// ─── Enclave: one resolution path for new and existing ───────────────────────
// `isExistingEnclave` is the only branch in the flow. When it is false the
// live-state bases below are empty arrays and template defaults, so every union
// degenerates to "just this workload's request" and the same expressions build
// a brand new enclave. When it is true the same expressions additively extend
// what is already there.

module enclaveStateReaderModule './modules/existingEnclaveStateReader.bicep' = if (isExistingEnclave) {
  name: 'postgresqlEnclaveState'
  scope: resourceGroup(enclaveSubscriptionId, enclaveResourceGroupName)
  params: {
    enclaveName: enclaveName
  }
}

func normalizeApprovalSetting(setting approvalSettingType) object =>
  setting.approvalPolicy == 'Required'
    ? {
        approvalPolicy: 'Required'
        mandatoryApprovers: setting.mandatoryApprovers
        minimumApproversRequired: setting.minimumApproversRequired
      }
    : {
        approvalPolicy: 'NotRequired'
        mandatoryApprovers: []
        minimumApproversRequired: 0
      }

var requestedApprovalSettings = enclave.?approvalSettings
var normalizedRequestedApprovalSettings = requestedApprovalSettings == null
  ? {}
  : {
      connectionCreation: normalizeApprovalSetting(requestedApprovalSettings!.connectionCreation)
      connectionUpdate: normalizeApprovalSetting(requestedApprovalSettings!.connectionUpdate)
      enclaveEndpointUpdate: normalizeApprovalSetting(requestedApprovalSettings!.enclaveEndpointUpdate)
      enclaveMaintenanceMode: normalizeApprovalSetting(requestedApprovalSettings!.enclaveMaintenanceMode)
    }

var emptySubnetProjection = {
  addressPrefix: ''
  name: ''
  networkPrefixSize: 0
  networkSecurityGroupResourceId: ''
  resourceId: ''
  subnetDelegation: ''
}

// This workload's own subnet requests. Names key the union, so re-running the
// same deployment neither duplicates nor renames anything.
var postgreSqlSubnetName = enclave.?postgreSqlSubnet.?name ?? 'snet-postgresql'
var privateEndpointSubnetName = enclave.?privateEndpointSubnet.?name ?? 'snet-private-endpoints'
var postgreSqlSubnetDelegation = 'Microsoft.DBforPostgreSQL/flexibleServers'
var requestedSubnetNames = [
  toLower(postgreSqlSubnetName)
  toLower(privateEndpointSubnetName)
]

var baseSubnetConfigurations = isExistingEnclave ? enclaveStateReaderModule.outputs.subnetConfigurations : []
var basePostgreSqlSubnetMatches = filter(baseSubnetConfigurations, subnet => toLower(string(subnet.subnetName)) == toLower(postgreSqlSubnetName))
var basePrivateEndpointSubnetMatches = filter(baseSubnetConfigurations, subnet => toLower(string(subnet.subnetName)) == toLower(privateEndpointSubnetName))
var postgreSqlSubnetAlreadyExists = length(basePostgreSqlSubnetMatches) != 0
var privateEndpointSubnetAlreadyExists = length(basePrivateEndpointSubnetMatches) != 0

// An omitted prefix size reuses whatever the live subnet already declares, so
// a redeploy that does not restate sizes converges instead of conflicting.
var requestedPostgreSqlSubnetPrefixSize = enclave.?postgreSqlSubnet.?networkPrefixSize ?? 0
var requestedPrivateEndpointSubnetPrefixSize = enclave.?privateEndpointSubnet.?networkPrefixSize ?? 0
var resolvedPostgreSqlSubnetPrefixSize = requestedPostgreSqlSubnetPrefixSize != 0
  ? requestedPostgreSqlSubnetPrefixSize
  : (postgreSqlSubnetAlreadyExists ? int(basePostgreSqlSubnetMatches[0].networkPrefixSize) : 24)
var resolvedPrivateEndpointSubnetPrefixSize = requestedPrivateEndpointSubnetPrefixSize != 0
  ? requestedPrivateEndpointSubnetPrefixSize
  : (privateEndpointSubnetAlreadyExists ? int(basePrivateEndpointSubnetMatches[0].networkPrefixSize) : 24)

var requestedSubnetConfigurations = [
  {
    networkPrefixSize: resolvedPostgreSqlSubnetPrefixSize
    subnetDelegation: postgreSqlSubnetDelegation
    subnetName: postgreSqlSubnetName
  }
  {
    networkPrefixSize: resolvedPrivateEndpointSubnetPrefixSize
    subnetName: privateEndpointSubnetName
  }
]
var retainedSubnetConfigurations = filter(baseSubnetConfigurations, subnet => !contains(requestedSubnetNames, toLower(string(subnet.subnetName))))
var resolvedSubnetConfigurations = concat(retainedSubnetConfigurations, requestedSubnetConfigurations)

// Fail closed when a live subnet of the same name is not the subnet this
// workload needs. Silently overwriting a foreign workload's subnet size or
// delegation would be destructive, and silently accepting it would hand
// PostgreSQL an incorrectly delegated subnet.
var postgreSqlSubnetIsCompatible = !postgreSqlSubnetAlreadyExists
  ? true
  : int(basePostgreSqlSubnetMatches[0].networkPrefixSize) == resolvedPostgreSqlSubnetPrefixSize && toLower(string(basePostgreSqlSubnetMatches[0].?subnetDelegation ?? '')) == toLower(postgreSqlSubnetDelegation)
var privateEndpointSubnetIsCompatible = !privateEndpointSubnetAlreadyExists
  ? true
  : int(basePrivateEndpointSubnetMatches[0].networkPrefixSize) == resolvedPrivateEndpointSubnetPrefixSize && empty(string(basePrivateEndpointSubnetMatches[0].?subnetDelegation ?? ''))
var requestedSubnetNamesAreDistinct = toLower(postgreSqlSubnetName) != toLower(privateEndpointSubnetName)

// A new enclave has no live state to inherit these two from.
var newEnclaveRequestIsComplete = isExistingEnclave
  ? true
  : !empty(enclave.?addressSpaceCidr ?? '') && requestedApprovalSettings != null

// The enclave must belong to the community this deployment provisions
// endpoints in; Phase B would otherwise target the wrong community.
var enclaveCommunityBindingIsValid = isExistingEnclave
  ? toLower(enclaveStateReaderModule.outputs.communityResourceId) == toLower(communityResourceId)
  : true

module enclaveRequestGate './modules/requiredTextSubscriptionGate.bicep' = {
  name: 'postgresqlEnclaveRequestGate'
  params: {
    requiredText: requestedSubnetNamesAreDistinct && postgreSqlSubnetIsCompatible && privateEndpointSubnetIsCompatible && newEnclaveRequestIsComplete && enclaveCommunityBindingIsValid ? 'compatible' : ''
  }
  dependsOn: [
    communityModule
    communityReferenceModule
    enclaveStateReaderModule
  ]
}

// Immutable and workload-agnostic properties: read-and-reuse for an existing
// enclave, caller request (or template default) when creating. Nothing is
// asserted against an expected value because nothing is being overwritten.
var resolvedEnclaveLocation = isExistingEnclave ? enclaveStateReaderModule.outputs.location : location
var resolvedEnclaveTags = isExistingEnclave ? union(enclaveStateReaderModule.outputs.tags, tags) : tags
var resolvedEnclaveIdentityType = isExistingEnclave ? enclaveStateReaderModule.outputs.identityType : 'None'
var resolvedEnclaveCommunityResourceId = isExistingEnclave ? enclaveStateReaderModule.outputs.communityResourceId : communityResourceId
var resolvedEnclaveApprovalSettings = isExistingEnclave ? enclaveStateReaderModule.outputs.approvalSettings : normalizedRequestedApprovalSettings
var resolvedEnclaveBastionEnabled = isExistingEnclave ? enclaveStateReaderModule.outputs.bastionEnabled : enclave.?bastionEnabled ?? true
var resolvedEnclaveDiagnosticDestination = isExistingEnclave ? enclaveStateReaderModule.outputs.diagnosticDestination : enclave.?diagnosticDestination ?? 'Both'
var resolvedAllowSubnetCommunication = isExistingEnclave ? enclaveStateReaderModule.outputs.allowSubnetCommunication : enclave.?allowSubnetCommunication ?? true
var resolvedCustomCidrRange = isExistingEnclave ? enclaveStateReaderModule.outputs.customCidrRange : enclave.?addressSpaceCidr ?? ''
var resolvedNetworkSize = isExistingEnclave ? enclaveStateReaderModule.outputs.networkSize : ''
var resolvedNetworkName = isExistingEnclave ? enclaveStateReaderModule.outputs.networkName : ''
var resolvedDedicatedHubResourceId = isExistingEnclave ? enclaveStateReaderModule.outputs.dedicatedHubResourceId : ''
var resolvedMonitoringSettings = isExistingEnclave ? enclaveStateReaderModule.outputs.monitoringSettings : {}

// Never customer-overridable. For an existing enclave the live value is reused
// verbatim, so this deployment can neither weaken nor strengthen the live
// posture as a side effect of adding a workload.
var resolvedRbacInheritance = isExistingEnclave ? enclaveStateReaderModule.outputs.rbacInheritance : 'Disabled'
var resolvedWorkloadResourceVisibility = isExistingEnclave ? enclaveStateReaderModule.outputs.workloadResourceVisibility : 'Disabled'

// Additive collections. `union()` deduplicates identical entries so repeat
// deployments converge. Two entries sharing a roleDefinitionId with different
// principal sets is a supported Mission shape and is left alone.
var baseEnclaveRoleAssignments = isExistingEnclave ? enclaveStateReaderModule.outputs.enclaveRoleAssignments : []
var baseWorkloadRoleAssignments = isExistingEnclave ? enclaveStateReaderModule.outputs.workloadRoleAssignments : []
var baseMaintenancePrincipals = isExistingEnclave ? enclaveStateReaderModule.outputs.maintenancePrincipals : []
var baseGovernedServiceList = isExistingEnclave ? enclaveStateReaderModule.outputs.governedServiceList : []
var resolvedEnclaveRoleAssignments = union(baseEnclaveRoleAssignments, enclave.?enclaveRoleAssignments ?? [])
var resolvedWorkloadRoleAssignments = union(baseWorkloadRoleAssignments, effectiveWorkloadRoleAssignmentRequest)
var maintenancePrincipals = union(baseMaintenancePrincipals, concat([
  deploymentPrincipalForMission
], enclave.?additionalMaintenancePrincipals ?? []))
var resolvedMaintenanceModeConfiguration = {
  justification: isExistingEnclave ? enclaveStateReaderModule.outputs.maintenanceJustification : 'Governance'
  mode: isExistingEnclave ? enclaveStateReaderModule.outputs.maintenanceMode : 'Advanced'
  principals: maintenancePrincipals
}

// Governed services are unioned by serviceId: whatever another workload
// governs is preserved, and the three services PostgreSQL requires are always
// present with this template's settings.
var requiredGovernedServiceIds = map(requiredGovernedServices, service => service.serviceId)
var retainedGovernedServices = filter(baseGovernedServiceList, service => !contains(requiredGovernedServiceIds, string(service.serviceId)))
var resolvedGovernedServiceList = concat(retainedGovernedServices, requiredGovernedServices)

// The enclave resource group necessarily already exists for an existing
// enclave (its resource ID names it) and may live in a subscription this
// deployment has no authority to create resource groups in. Resource-group
// creation is therefore scoped to the new-enclave case, where the template
// owns the name.
module enclaveResourceGroupModule '../../modules/common/resourceGroup.bicep' = if (!isExistingEnclave) {
  name: 'postgresqlEnclaveResourceGroup'
  scope: subscription(targetSubscriptionId)
  params: {
    location: location
    name: enclaveResourceGroupName
    tags: tags
  }
}

// One PUT. ARM resource creation is idempotent, so this single module call
// creates the enclave when it does not exist and additively updates it when it
// does, from exactly the same resolved contract in both cases.
module enclaveModule '../../modules/common/missionVirtualEnclave.bicep' = {
  name: 'postgresqlEnclave'
  scope: resourceGroup(enclaveSubscriptionId, enclaveResourceGroupName)
  params: {
    allowSubnetCommunication: resolvedAllowSubnetCommunication
    approvalSettings: resolvedEnclaveApprovalSettings
    bastionEnabled: resolvedEnclaveBastionEnabled
    communityResourceId: resolvedEnclaveCommunityResourceId
    customCidrRange: resolvedCustomCidrRange
    dedicatedHubResourceId: resolvedDedicatedHubResourceId
    diagnosticDestination: resolvedEnclaveDiagnosticDestination
    enclaveRoleAssignments: resolvedEnclaveRoleAssignments
    governedServiceList: resolvedGovernedServiceList
    identityType: resolvedEnclaveIdentityType
    location: resolvedEnclaveLocation
    maintenanceModeConfiguration: resolvedMaintenanceModeConfiguration
    monitoringSettings: resolvedMonitoringSettings
    name: enclaveName
    networkName: resolvedNetworkName
    networkSize: resolvedNetworkSize
    rbacInheritance: resolvedRbacInheritance
    subnetConfigurations: resolvedSubnetConfigurations
    tags: resolvedEnclaveTags
    workloadResourceVisibility: resolvedWorkloadResourceVisibility
    workloadRoleAssignments: resolvedWorkloadRoleAssignments
  }
  dependsOn: [
    communityModule
    communityReferenceModule
    enclaveRequestGate
    enclaveResourceGroupModule
    enclaveStateReaderModule
  ]
}

var effectiveEnclaveResourceId = enclaveModule.outputs.resourceId
var effectiveEnclaveLocation = enclaveModule.outputs.resourceLocation
var effectiveEnclaveManagedResourceGroupName = enclaveModule.outputs.managedResourceGroupName
var effectiveEnclaveVnetName = enclaveModule.outputs.enclaveVnetName
var effectiveEnclaveVnetResourceId = enclaveModule.outputs.enclaveVnetResourceId

// Post-PUT subnet projection: Mission reports the generated address prefix,
// subnet resource ID, and NSG for every subnet here, for new and pre-existing
// subnets alike.
var effectiveSubnetConfigurations = enclaveModule.outputs.subnetConfigurations
var effectivePostgreSqlSubnetMatches = filter(effectiveSubnetConfigurations, subnet => toLower(string(subnet.?subnetName ?? '')) == toLower(postgreSqlSubnetName))
var effectivePrivateEndpointSubnetMatches = filter(effectiveSubnetConfigurations, subnet => toLower(string(subnet.?subnetName ?? '')) == toLower(privateEndpointSubnetName))
var effectivePostgreSqlSubnet = length(effectivePostgreSqlSubnetMatches) == 0
  ? emptySubnetProjection
  : {
      addressPrefix: string(effectivePostgreSqlSubnetMatches[0].?addressPrefix ?? '')
      name: string(effectivePostgreSqlSubnetMatches[0].?subnetName ?? '')
      networkPrefixSize: int(effectivePostgreSqlSubnetMatches[0].?networkPrefixSize ?? 0)
      networkSecurityGroupResourceId: string(effectivePostgreSqlSubnetMatches[0].?networkSecurityGroupResourceId ?? '')
      resourceId: string(effectivePostgreSqlSubnetMatches[0].?subnetResourceId ?? '')
      subnetDelegation: string(effectivePostgreSqlSubnetMatches[0].?subnetDelegation ?? '')
    }
var effectivePrivateEndpointSubnet = length(effectivePrivateEndpointSubnetMatches) == 0
  ? emptySubnetProjection
  : {
      addressPrefix: string(effectivePrivateEndpointSubnetMatches[0].?addressPrefix ?? '')
      name: string(effectivePrivateEndpointSubnetMatches[0].?subnetName ?? '')
      networkPrefixSize: int(effectivePrivateEndpointSubnetMatches[0].?networkPrefixSize ?? 0)
      networkSecurityGroupResourceId: string(effectivePrivateEndpointSubnetMatches[0].?networkSecurityGroupResourceId ?? '')
      resourceId: string(effectivePrivateEndpointSubnetMatches[0].?subnetResourceId ?? '')
      subnetDelegation: string(effectivePrivateEndpointSubnetMatches[0].?subnetDelegation ?? '')
    }

// Mission's own SubnetConfiguration contract (all API versions through
// 2026-03-01-preview) exposes no NSG-rule customization surface, and the
// auto-generated per-subnet NSG denies all outbound traffic by default except
// for a narrow allow-list (KMS activation, intra-VNet, management). PostgreSQL
// Entra administrator creation requires outbound HTTPS to Microsoft Entra ID /
// Microsoft Graph (the `AzureActiveDirectory` service tag). Direct writes to
// the NSG in Mission's auto-generated managed resource group are unsupported
// and deny-blocked; the supported path is a declarative Mission community
// endpoint + enclave connection request, which Mission's exempt Connection
// Manager service principal uses to materialize the equivalent allow rule.
// See avePostgreSqlEnclaveNetworkFinalization.bicep (Phase B), which
// provisions this via the `communityConnectivity` parameter once Phase A's
// enclave resource ID is available.

var workloadSegments = split(workload.mode == 'existing' ? workload.resourceId : '///////////', '/')
var workloadRegistrationEnclaveName = workload.mode == 'managed' ? enclaveName : workloadSegments[8]
var workloadName = workload.mode == 'managed' ? managedWorkloadName : workloadSegments[10]

module managedWorkloadModule '../../modules/common/missionWorkload.bicep' = if (workload.mode == 'managed') {
  name: 'postgresqlManagedWorkload'
  scope: resourceGroup(enclaveSubscriptionId, enclaveResourceGroupName)
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
    enclaveModule
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

var serverIdentityResourceGroupName = foundation.serverIdentity.mode == 'managed' ? foundation.serverIdentity.?resourceGroupName ?? workloadResourceGroupName : split(foundation.serverIdentity.resourceId, '/')[4]
var serverIdentityResourceGroupSubscriptionId = foundation.serverIdentity.mode == 'managed' ? targetSubscriptionId : split(foundation.serverIdentity.resourceId, '/')[2]
var serverIdentityName = foundation.serverIdentity.mode == 'managed'
  ? foundation.serverIdentity.?name ?? 'id-${take(communityName, 114 - length(resolvedInstance))}-pgsql-${resolvedInstance}'
  : split(foundation.serverIdentity.resourceId, '/')[8]

module serverIdentityResourceGroupModule '../../modules/common/resourceGroup.bicep' = if (foundation.serverIdentity.mode == 'managed' && serverIdentityResourceGroupName != workloadResourceGroupName) {
  name: 'postgresqlServerIdentityResourceGroup'
  scope: subscription(targetSubscriptionId)
  params: {
    location: foundation.serverIdentity.?location ?? location
    name: serverIdentityResourceGroupName
    tags: tags
  }
}

module serverIdentityModule '../../modules/common/userAssignedIdentity.bicep' = if (foundation.serverIdentity.mode == 'managed') {
  name: 'postgresqlServerIdentity'
  scope: resourceGroup(targetSubscriptionId, serverIdentityResourceGroupName)
  params: {
    location: foundation.serverIdentity.?location ?? location
    name: serverIdentityName
    tags: tags
  }
  dependsOn: [
    workloadResourceGroupModule
    serverIdentityResourceGroupModule
  ]
}

// Grants the managed PostgreSQL server identity Microsoft Graph
// "User.Read.All", the template's intended permission so that PostgreSQL
// Entra administrator creation (Phase C) can resolve directory objects. Not
// applicable to 'existing' identities: the customer must grant this
// permission out-of-band before supplying the identity's resourceId. This
// grant is a separate prerequisite from, and not a substitute for, the
// administrator child resource's own API version/contract (see
// `flexibleServerChildren.bicep` and the PostgreSQL workload README "Server
// identity Microsoft Graph prerequisite" section).
var serverIdentityGraphPermissionGrantMode = foundation.serverIdentity.mode == 'managed' ? (foundation.serverIdentity.?graphPermissionGrant.?mode ?? 'Managed') : 'Skip'

// The newly created UAMI's Entra service principal object is not always
// immediately queryable via Microsoft Graph the instant ARM returns its
// principalId (eventual-consistency replication lag between the ARM and
// Graph planes). If this module's only dependency were the identity module
// itself, the Graph appRoleAssignedTo call could race that replication and
// fail with "Request_BadRequest: Not a valid reference update." Depending on
// keyVaultModule and keyModule defers this call until after Key Vault and
// (especially) RSA-HSM CMK key provisioning have completed, which reliably
// consumes enough wall-clock time for the replication to catch up when the
// Key Vault itself is being newly created.
//
// However, keyVaultModule and keyModule are both conditional on 'managed'
// mode: when foundation.keyVault.mode is 'existing' (reusing an already
// created Key Vault, e.g. the enclave's own Mission-managed vault),
// keyVaultModule never runs at all, and keyModule only adds a key to an
// already-existing vault — a much faster operation than provisioning a whole
// new Key Vault. That leaves too little elapsed wall-clock time for Graph
// replication, and the race resurfaces specifically in the existing-Key-Vault
// path (confirmed by live testing). keyVaultPrivateEndpointModule is
// unconditional in both the managed and existing Key Vault paths — a private
// endpoint (NIC, private link connection, DNS zone group) always has to be
// created for the workload's private connectivity to the Key Vault, and that
// is genuine network-resource provisioning that reliably takes real time
// regardless of which Key Vault mode is in effect. Depending on it here
// closes the gap the keyVaultModule/keyModule-only deferral left open. This
// is a scheduling-only dependency: keyVaultPrivateEndpointModule has no data
// dependency on the server identity or this Graph grant.
module serverIdentityGraphGrantModule './modules/serverIdentityGraphGrant.bicep' = if (foundation.serverIdentity.mode == 'managed' && serverIdentityGraphPermissionGrantMode == 'Managed') {
  name: 'postgresqlServerIdentityGraphGrant'
  scope: resourceGroup(targetSubscriptionId, serverIdentityResourceGroupName)
  params: {
    principalId: serverIdentityModule.outputs.principalId
  }
  dependsOn: [
    serverIdentityModule
    keyVaultModule
    keyModule
    keyVaultPrivateEndpointModule
  ]
}

resource existingServerIdentityResource 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = if (foundation.serverIdentity.mode == 'existing') {
  name: serverIdentityName
  scope: resourceGroup(serverIdentityResourceGroupSubscriptionId, serverIdentityResourceGroupName)
}

var existingServerIdentityMatchesLocation = foundation.serverIdentity.mode == 'existing' ? toLower(existingServerIdentityResource.location) == toLower(foundation.serverIdentity.expectedConfiguration.location) : true
var existingServerIdentityMatchesPrincipal = foundation.serverIdentity.mode == 'existing' ? toLower(existingServerIdentityResource.properties.principalId) == toLower(foundation.serverIdentity.expectedConfiguration.principalId) : true
var existingServerIdentityMatchesClient = foundation.serverIdentity.mode == 'existing' ? toLower(existingServerIdentityResource.properties.clientId) == toLower(foundation.serverIdentity.expectedConfiguration.clientId) : true
var existingServerIdentityCompatibility = existingServerIdentityMatchesLocation && existingServerIdentityMatchesPrincipal && existingServerIdentityMatchesClient

module existingServerIdentityCompatibilityGate './modules/requiredTextSubscriptionGate.bicep' = if (foundation.serverIdentity.mode == 'existing') {
  name: 'existingServerIdentityCompatibilityGate'
  params: {
    requiredText: existingServerIdentityCompatibility ? 'compatible' : ''
  }
}

var serverIdentityResourceId = foundation.serverIdentity.mode == 'managed' ? serverIdentityModule.outputs.resourceId : existingServerIdentityResource.id
var serverIdentityPrincipalId = foundation.serverIdentity.mode == 'managed' ? serverIdentityModule.outputs.principalId : existingServerIdentityResource.properties.principalId
var serverIdentityClientId = foundation.serverIdentity.mode == 'managed' ? serverIdentityModule.outputs.clientId : existingServerIdentityResource.properties.clientId

var keyVaultResourceGroupName = foundation.keyVault.mode == 'managed' ? foundation.keyVault.?resourceGroupName ?? workloadResourceGroupName : split(foundation.keyVault.resourceId, '/')[4]
var keyVaultSubscriptionId = foundation.keyVault.mode == 'managed' ? targetSubscriptionId : split(foundation.keyVault.resourceId, '/')[2]
var keyVaultName = foundation.keyVault.mode == 'managed'
  ? foundation.keyVault.?name ?? 'kv${take(replace(toLower(communityName), '-', ''), 14)}${communityUniqueSuffix}'
  : split(foundation.keyVault.resourceId, '/')[8]

module keyVaultResourceGroupModule '../../modules/common/resourceGroup.bicep' = if (foundation.keyVault.mode == 'managed' && keyVaultResourceGroupName != workloadResourceGroupName) {
  name: 'postgresqlKeyVaultResourceGroup'
  scope: subscription(targetSubscriptionId)
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
    networkAclsBypass: 'AzureServices'
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
    existingKeyVaultCompatibilityGate
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
    principalId: serverIdentityPrincipalId
    principalTypeName: 'ServicePrincipal'
    roleDefinitionIdOrGuid: 'e147488a-f6f5-4113-8e2d-b22465e65bf6'
    scopeKind: 'keyVaultKey'
    scopeName: keyName
  }
  dependsOn: [
    enclaveModule
    serverIdentityModule
    serverIdentityGraphGrantModule
    keyModule
    existingServerIdentityCompatibilityGate
    existingKeyVaultCompatibilityGate
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
  scope: subscription(targetSubscriptionId)
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
  scope: subscription(targetSubscriptionId)
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

var effectiveEnclaveVnetId = effectiveEnclaveVnetResourceId
var effectivePrivateEndpointSubnetResourceId = string(effectivePrivateEndpointSubnet.resourceId)
var expectedPrivateEndpointSubnetResourceId = '${effectiveEnclaveVnetId}/subnets/${privateEndpointSubnetName}'
var effectiveEnclaveVnetSegments = split(effectiveEnclaveVnetId, '/')
var workloadResourceGroupIdHasExpectedSegmentCount = length(workloadResourceGroupSegments) == 5
var enclaveVnetIdHasExpectedSegmentCount = length(effectiveEnclaveVnetSegments) == 9
var workloadResourceGroupIdHasValidShape = workloadResourceGroupIdHasExpectedSegmentCount
  ? toLower(workloadResourceGroupSegments[1]) == 'subscriptions' && toLower(workloadResourceGroupSegments[3]) == 'resourcegroups'
  : false
var enclaveVnetIdHasValidShape = enclaveVnetIdHasExpectedSegmentCount
  ? toLower(effectiveEnclaveVnetSegments[1]) == 'subscriptions' && toLower(effectiveEnclaveVnetSegments[3]) == 'resourcegroups' && toLower(effectiveEnclaveVnetSegments[5]) == 'providers' && toLower(effectiveEnclaveVnetSegments[6]) == 'microsoft.network' && toLower(effectiveEnclaveVnetSegments[7]) == 'virtualnetworks'
  : false
var privateEndpointSubnetMatchesExpectedResourceId = !empty(effectivePrivateEndpointSubnetResourceId) && toLower(effectivePrivateEndpointSubnetResourceId) == toLower(expectedPrivateEndpointSubnetResourceId)
var privateEndpointResourceGroupIsInVnetSubscription = startsWith(toLower(effectiveEnclaveVnetId), '/subscriptions/${toLower(workloadResourceGroupSubscriptionId)}/')
var privateEndpointPlacementIsValid = workloadResourceGroupIdHasValidShape && enclaveVnetIdHasValidShape && privateEndpointSubnetMatchesExpectedResourceId && privateEndpointResourceGroupIsInVnetSubscription

module existingPrivateEndpointResourceGroupReader './modules/existingResourceGroupStateReader.bicep' = if (workload.mode == 'existing') {
  name: 'existingPrivateEndpointResourceGroup'
  scope: subscription(workloadResourceGroupSubscriptionId)
  params: {
    resourceGroupName: workloadResourceGroupName
  }
}

module privateEndpointPlacementGate './modules/requiredTextSubscriptionGate.bicep' = {
  name: 'privateEndpointPlacementGate'
  params: {
    requiredText: privateEndpointPlacementIsValid && (workload.mode == 'managed' ? true : (toLower(existingPrivateEndpointResourceGroupReader.outputs.resourceId) == toLower(workloadResourceGroupId) && !empty(existingPrivateEndpointResourceGroupReader.outputs.location))) ? 'compatible' : ''
  }
  dependsOn: [
    existingPrivateEndpointResourceGroupReader
    workloadResourceGroupModule
  ]
}

// Link names are keyed by the (zone, VNet) pair rather than by workload, so
// this deployment converges to the same virtual-network-link resource
// whether it is the first workload to link a zone to this VNet or a later
// workload sharing an existing enclave's zone and VNet. Azure permits only
// one link between a given zone and a given VNet regardless of the link
// resource's name; keying the name by workload identity meant a second
// workload sharing the same zone+VNet pair collided on that one-link-per-pair
// rule while Bicep still treated it as creating a distinct, unrelated
// resource.
var delegatedZoneLinkName = 'link-${take(uniqueString(delegatedZoneName, effectiveEnclaveVnetId), 13)}'
var keyVaultZoneLinkName = 'link-${take(uniqueString(keyVaultZoneName, effectiveEnclaveVnetId), 13)}'

module delegatedDnsLinkModule '../../modules/common/privateDnsZoneVirtualNetworkLink.bicep' = {
  name: 'postgresqlDelegatedDnsLink'
  scope: resourceGroup(delegatedZoneSubscriptionId, delegatedZoneResourceGroupName)
  params: {
    linkName: delegatedZoneLinkName
    tags: tags
    virtualNetworkResourceId: effectiveEnclaveVnetId
    zoneName: delegatedZoneName
  }
  dependsOn: [
    enclaveModule
    delegatedDnsZoneModule
    existingDelegatedDnsCompatibilityGate
  ]
}

module keyVaultDnsLinkModule '../../modules/common/privateDnsZoneVirtualNetworkLink.bicep' = {
  name: 'postgresqlKeyVaultDnsLink'
  scope: resourceGroup(keyVaultZoneSubscriptionId, keyVaultZoneResourceGroupName)
  params: {
    linkName: keyVaultZoneLinkName
    tags: tags
    virtualNetworkResourceId: effectiveEnclaveVnetId
    zoneName: keyVaultZoneName
  }
  dependsOn: [
    enclaveModule
    keyVaultDnsZoneModule
    existingKeyVaultDnsCompatibilityGate
  ]
}

module keyVaultPrivateEndpointModule '../../modules/common/privateEndpoint.bicep' = {
  name: 'postgresqlKeyVaultPrivateEndpoint'
  scope: resourceGroup(workloadResourceGroupSubscriptionId, workloadResourceGroupName)
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
    subnetResourceId: effectivePrivateEndpointSubnetResourceId
    tags: tags
  }
  dependsOn: [
    keyVaultModule
    existingKeyVaultCompatibilityGate
    keyVaultDnsLinkModule
    privateEndpointPlacementGate
    workloadResourceGroupModule
  ]
}

output contractVersion string = '3.0'
output phaseA phaseAHandoffType = {
  contractVersion: '3.0'
  communityResourceId: communityResourceId
  delegatedPrivateDnsZoneResourceId: foundation.privateDns.delegatedZone.mode == 'managed' ? delegatedDnsZoneModule.outputs.resourceId : existingDelegatedDnsZoneResource.id
  enclaveManagedResourceGroupName: effectiveEnclaveManagedResourceGroupName
  enclaveOwnership: isExistingEnclave ? 'existing' : 'managed'
  enclaveResourceId: effectiveEnclaveResourceId
  enclaveVnetName: effectiveEnclaveVnetName
  enclaveVnetResourceId: effectiveEnclaveVnetId
  keyVaultPrivateEndpointResourceId: keyVaultPrivateEndpointModule.outputs.resourceId
  keyVaultResourceId: keyVaultResourceId
  location: effectiveEnclaveLocation
  maintenanceMode: 'Advanced'
  maintenancePrincipals: maintenancePrincipals
  phaseADeploymentPrincipal: deploymentPrincipalForMission
  postgreSqlServerIdentityClientId: serverIdentityClientId
  postgreSqlServerIdentityPrincipalId: serverIdentityPrincipalId
  postgreSqlServerIdentityResourceId: serverIdentityResourceId
  postgreSqlCmkKeyUri: cmkKeyUri
  postgreSqlDnsSuffix: postgreSqlDnsSuffix
  postgreSqlPrivateLinkZoneName: 'privatelink.${postgreSqlDnsSuffix}'
  postgreSqlSubnetAddressPrefix: string(effectivePostgreSqlSubnet.addressPrefix)
  postgreSqlSubnetName: postgreSqlSubnetName
  postgreSqlSubnetNsgResourceId: string(effectivePostgreSqlSubnet.networkSecurityGroupResourceId)
  postgreSqlSubnetResourceId: string(effectivePostgreSqlSubnet.resourceId)
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
output serverIdentityGraphPermissionGrantId string = foundation.serverIdentity.mode == 'managed' && serverIdentityGraphPermissionGrantMode == 'Managed' ? serverIdentityGraphGrantModule.outputs.appRoleAssignmentId : ''
output telemetryEnabled bool = enableTelemetry
