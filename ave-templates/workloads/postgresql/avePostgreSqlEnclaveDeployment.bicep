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

type additiveSubnetRequestType = {
  @minLength(1)
  name: string
  networkPrefixSize: int
}

type approvalPolicyType = 'NotRequired' | 'Required'
type diagnosticDestinationType = 'Both' | 'CommunityOnly' | 'EnclaveOnly'
type toggleStateType = 'Disabled' | 'Enabled'

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

type governedServiceExpectationType = {
  enforcement: 'Enabled'
  option: 'Allow'
  policyAction: 'Enforce'
  serviceId: 'KeyVault' | 'PostgreSQL' | 'PrivateDNSZones'
}

type expectedEnclaveSubnetType = {
  addressPrefix: string
  name: string
  networkPrefixSize: int
  networkSecurityGroupResourceId: string
  resourceId: string
  subnetDelegation: string
}

type additiveExistingEnclaveExpectedType = {
  approvalSettings: approvalSettingsType
  bastionEnabled: toggleStateType
  communityResourceId: string
  diagnosticDestination: diagnosticDestinationType
  governedServiceList: governedServiceExpectationType[]
  location: string
  network: {
    allowSubnetCommunication: toggleStateType
  }
  rbacInheritance: 'Disabled'
  workloadResourceVisibility: 'Disabled'
}

type referenceOnlyExpectedEnclaveType = {
  approvalSettings: approvalSettingsType
  bastionEnabled: toggleStateType
  communityResourceId: string
  diagnosticDestination: diagnosticDestinationType
  governedServiceList: governedServiceExpectationType[]
  location: string
  network: {
    allowSubnetCommunication: toggleStateType
    postgreSqlSubnet: expectedEnclaveSubnetType
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
  approvalSettings: approvalSettingsType
  postgreSqlSubnet: subnetRequestType
  privateEndpointSubnet: subnetRequestType
  allowSubnetCommunication: bool?
  bastionEnabled: bool?
  diagnosticDestination: diagnosticDestinationType?
  enclaveRoleAssignments: missionRoleAssignmentType[]?
  workloadRoleAssignments: missionRoleAssignmentType[]?
  additionalMaintenancePrincipals: missionPrincipalType[]?
}

type existingPrivateEndpointSubnetReferenceType = {
  mode: 'Existing'
  expectedConfiguration: expectedEnclaveSubnetType
}

type additivePrivateEndpointSubnetRequestType = {
  mode: 'New'
  @minLength(1)
  name: string
  networkPrefixSize: int
}

@discriminator('mode')
type additivePrivateEndpointSubnetType = existingPrivateEndpointSubnetReferenceType | additivePrivateEndpointSubnetRequestType

type existingReferenceOnlyEnclaveType = {
  mode: 'ReferenceOnly'
  resourceId: string
  expectedConfiguration: referenceOnlyExpectedEnclaveType
}

type existingAdditiveSubnetUpdateEnclaveType = {
  mode: 'AdditiveSubnetUpdate'
  resourceId: string
  expectedConfiguration: additiveExistingEnclaveExpectedType
  postgreSqlSubnet: additiveSubnetRequestType
  privateEndpointSubnet: additivePrivateEndpointSubnetType
}

@discriminator('mode')
type enclaveDefinitionType = managedEnclaveType | existingReferenceOnlyEnclaveType | existingAdditiveSubnetUpdateEnclaveType

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
  postgreSqlCmkIdentityClientId: string
  postgreSqlCmkIdentityPrincipalId: string
  postgreSqlCmkIdentityResourceId: string
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

@description('Deployment principal placed into the Advanced maintenance-principal set for managed enclaves.')
param deploymentPrincipal deploymentPrincipalType

@description('Managed-or-existing Mission community.')
param community communityDefinitionType

@description('Managed or existing Mission enclave. Managed callers must explicitly declare all approval settings. Existing enclaves must explicitly choose ReferenceOnly or AdditiveSubnetUpdate behavior.')
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
var postgreSqlSubnetName = enclave.mode == 'managed'
  ? enclave.postgreSqlSubnet.?name ?? 'snet-postgresql'
  : enclave.mode == 'ReferenceOnly'
    ? enclave.expectedConfiguration.network.postgreSqlSubnet.name
    : enclave.postgreSqlSubnet.name
var privateEndpointSubnetName = enclave.mode == 'managed'
  ? enclave.privateEndpointSubnet.?name ?? 'snet-private-endpoints'
  : enclave.mode == 'ReferenceOnly'
    ? enclave.expectedConfiguration.network.privateEndpointSubnet.name
    : (enclave.privateEndpointSubnet.mode == 'Existing'
        ? enclave.privateEndpointSubnet.expectedConfiguration.name
        : enclave.privateEndpointSubnet.name)
var managedApprovalSettings = enclave.mode == 'managed' ? enclave.approvalSettings : null
var normalizedExpectedApprovalSettings = enclave.mode == 'managed' ? {} : {
  connectionCreation: enclave.expectedConfiguration.approvalSettings.connectionCreation.approvalPolicy == 'Required'
    ? {
        approvalPolicy: 'Required'
        mandatoryApprovers: enclave.expectedConfiguration.approvalSettings.connectionCreation.mandatoryApprovers
        minimumApproversRequired: enclave.expectedConfiguration.approvalSettings.connectionCreation.minimumApproversRequired
      }
    : {
        approvalPolicy: 'NotRequired'
        mandatoryApprovers: []
        minimumApproversRequired: 0
      }
  connectionUpdate: enclave.expectedConfiguration.approvalSettings.connectionUpdate.approvalPolicy == 'Required'
    ? {
        approvalPolicy: 'Required'
        mandatoryApprovers: enclave.expectedConfiguration.approvalSettings.connectionUpdate.mandatoryApprovers
        minimumApproversRequired: enclave.expectedConfiguration.approvalSettings.connectionUpdate.minimumApproversRequired
      }
    : {
        approvalPolicy: 'NotRequired'
        mandatoryApprovers: []
        minimumApproversRequired: 0
      }
  enclaveEndpointUpdate: enclave.expectedConfiguration.approvalSettings.enclaveEndpointUpdate.approvalPolicy == 'Required'
    ? {
        approvalPolicy: 'Required'
        mandatoryApprovers: enclave.expectedConfiguration.approvalSettings.enclaveEndpointUpdate.mandatoryApprovers
        minimumApproversRequired: enclave.expectedConfiguration.approvalSettings.enclaveEndpointUpdate.minimumApproversRequired
      }
    : {
        approvalPolicy: 'NotRequired'
        mandatoryApprovers: []
        minimumApproversRequired: 0
      }
  enclaveMaintenanceMode: enclave.expectedConfiguration.approvalSettings.enclaveMaintenanceMode.approvalPolicy == 'Required'
    ? {
        approvalPolicy: 'Required'
        mandatoryApprovers: enclave.expectedConfiguration.approvalSettings.enclaveMaintenanceMode.mandatoryApprovers
        minimumApproversRequired: enclave.expectedConfiguration.approvalSettings.enclaveMaintenanceMode.minimumApproversRequired
      }
    : {
        approvalPolicy: 'NotRequired'
        mandatoryApprovers: []
        minimumApproversRequired: 0
      }
}

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
    approvalSettings: managedApprovalSettings!
    bastionEnabled: enclave.?bastionEnabled ?? true
    communityResourceId: communityResourceId
    enclaveDefaultSettings: {
      diagnosticDestination: enclave.?diagnosticDestination ?? 'Both'
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
      allowSubnetCommunication: enclave.?allowSubnetCommunication ?? true
      customCidrRange: enclave.addressSpaceCidr
      mode: 'CustomCidr'
      subnetConfigurations: [
        {
          networkPrefixSize: enclave.postgreSqlSubnet.networkPrefixSize
          subnetDelegation: 'Microsoft.DBforPostgreSQL/flexibleServers'
          subnetName: postgreSqlSubnetName
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

var existingEnclaveSegments = split(enclave.mode != 'managed' ? enclave.resourceId : '/////////', '/')
var existingEnclaveSubscriptionId = enclave.mode != 'managed' ? existingEnclaveSegments[2] : targetSubscriptionId
var existingEnclaveResourceGroupName = enclave.mode != 'managed' ? existingEnclaveSegments[4] : managedEnclaveResourceGroupName
var enclaveName = enclave.mode == 'managed' ? enclave.name : existingEnclaveSegments[8]

module existingEnclaveModule './modules/existingEnclaveStateReader.bicep' = if (enclave.mode != 'managed') {
  name: 'postgresqlExistingEnclave'
  scope: resourceGroup(existingEnclaveSubscriptionId, existingEnclaveResourceGroupName)
  params: {
    enclaveName: enclaveName
    postgreSqlSubnetName: enclave.mode == 'ReferenceOnly' ? postgreSqlSubnetName : ''
    privateEndpointSubnetName: enclave.mode == 'ReferenceOnly'
      ? privateEndpointSubnetName
      : (enclave.privateEndpointSubnet.mode == 'Existing' ? privateEndpointSubnetName : '')
  }
}

var existingEnclaveMatchesLocation = enclave.mode != 'managed' ? toLower(existingEnclaveModule.outputs.location) == toLower(enclave.expectedConfiguration.location) : true
var existingEnclaveMatchesCommunity = enclave.mode != 'managed' ? toLower(existingEnclaveModule.outputs.communityResourceId) == toLower(enclave.expectedConfiguration.communityResourceId) : true
var existingEnclaveMatchesBastion = enclave.mode != 'managed' ? existingEnclaveModule.outputs.bastionEnabled == (enclave.expectedConfiguration.bastionEnabled == 'Enabled') : true
var existingEnclaveMatchesDiagnosticDestination = enclave.mode != 'managed' ? toLower(existingEnclaveModule.outputs.diagnosticDestination) == toLower(enclave.expectedConfiguration.diagnosticDestination) : true
var existingEnclaveMatchesRbac = enclave.mode != 'managed' ? toLower(existingEnclaveModule.outputs.rbacInheritance) == toLower(enclave.expectedConfiguration.rbacInheritance) : true
var existingEnclaveMatchesVisibility = enclave.mode != 'managed' ? toLower(existingEnclaveModule.outputs.workloadResourceVisibility) == toLower(enclave.expectedConfiguration.workloadResourceVisibility) : true
var existingEnclaveMatchesSubnetCommunication = enclave.mode != 'managed' ? existingEnclaveModule.outputs.allowSubnetCommunication == (enclave.expectedConfiguration.network.allowSubnetCommunication == 'Enabled') : true
var existingEnclaveMatchesPostgreSqlSubnet = enclave.mode == 'ReferenceOnly' ? toLower(existingEnclaveModule.outputs.postgreSqlSubnet.resourceId) == toLower(enclave.expectedConfiguration.network.postgreSqlSubnet.resourceId) && toLower(existingEnclaveModule.outputs.postgreSqlSubnet.addressPrefix) == toLower(enclave.expectedConfiguration.network.postgreSqlSubnet.addressPrefix) && int(existingEnclaveModule.outputs.postgreSqlSubnet.networkPrefixSize) == enclave.expectedConfiguration.network.postgreSqlSubnet.networkPrefixSize && toLower(existingEnclaveModule.outputs.postgreSqlSubnet.networkSecurityGroupResourceId) == toLower(enclave.expectedConfiguration.network.postgreSqlSubnet.networkSecurityGroupResourceId) && toLower(existingEnclaveModule.outputs.postgreSqlSubnet.subnetDelegation) == toLower(enclave.expectedConfiguration.network.postgreSqlSubnet.subnetDelegation) : true
var existingEnclaveMatchesPrivateEndpointSubnet = enclave.mode == 'ReferenceOnly'
  ? toLower(existingEnclaveModule.outputs.privateEndpointSubnet.resourceId) == toLower(enclave.expectedConfiguration.network.privateEndpointSubnet.resourceId) && toLower(existingEnclaveModule.outputs.privateEndpointSubnet.addressPrefix) == toLower(enclave.expectedConfiguration.network.privateEndpointSubnet.addressPrefix) && int(existingEnclaveModule.outputs.privateEndpointSubnet.networkPrefixSize) == enclave.expectedConfiguration.network.privateEndpointSubnet.networkPrefixSize && toLower(existingEnclaveModule.outputs.privateEndpointSubnet.networkSecurityGroupResourceId) == toLower(enclave.expectedConfiguration.network.privateEndpointSubnet.networkSecurityGroupResourceId) && toLower(existingEnclaveModule.outputs.privateEndpointSubnet.subnetDelegation) == toLower(enclave.expectedConfiguration.network.privateEndpointSubnet.subnetDelegation)
  : (enclave.mode == 'AdditiveSubnetUpdate' && enclave.privateEndpointSubnet.mode == 'Existing'
      ? toLower(existingEnclaveModule.outputs.privateEndpointSubnet.resourceId) == toLower(enclave.privateEndpointSubnet.expectedConfiguration.resourceId) && toLower(existingEnclaveModule.outputs.privateEndpointSubnet.addressPrefix) == toLower(enclave.privateEndpointSubnet.expectedConfiguration.addressPrefix) && int(existingEnclaveModule.outputs.privateEndpointSubnet.networkPrefixSize) == enclave.privateEndpointSubnet.expectedConfiguration.networkPrefixSize && toLower(existingEnclaveModule.outputs.privateEndpointSubnet.networkSecurityGroupResourceId) == toLower(enclave.privateEndpointSubnet.expectedConfiguration.networkSecurityGroupResourceId) && toLower(existingEnclaveModule.outputs.privateEndpointSubnet.subnetDelegation) == toLower(enclave.privateEndpointSubnet.expectedConfiguration.subnetDelegation)
      : true)
var existingEnclaveMatchesGovernedServices = enclave.mode != 'managed' ? toLower(string(existingEnclaveModule.outputs.governedServiceList)) == toLower(string(enclave.expectedConfiguration.governedServiceList)) : true
var existingConnectionCreationApproverIds = enclave.mode != 'managed' ? map(existingEnclaveModule.outputs.approvalSettings.connectionCreation.mandatoryApprovers, approver => toLower(string(approver.approverEntraId))) : []
var expectedConnectionCreationApproverIds = enclave.mode != 'managed' ? map(normalizedExpectedApprovalSettings.connectionCreation.mandatoryApprovers, approver => toLower(string(approver.approverEntraId))) : []
var existingConnectionUpdateApproverIds = enclave.mode != 'managed' ? map(existingEnclaveModule.outputs.approvalSettings.connectionUpdate.mandatoryApprovers, approver => toLower(string(approver.approverEntraId))) : []
var expectedConnectionUpdateApproverIds = enclave.mode != 'managed' ? map(normalizedExpectedApprovalSettings.connectionUpdate.mandatoryApprovers, approver => toLower(string(approver.approverEntraId))) : []
var existingEnclaveEndpointUpdateApproverIds = enclave.mode != 'managed' ? map(existingEnclaveModule.outputs.approvalSettings.enclaveEndpointUpdate.mandatoryApprovers, approver => toLower(string(approver.approverEntraId))) : []
var expectedEnclaveEndpointUpdateApproverIds = enclave.mode != 'managed' ? map(normalizedExpectedApprovalSettings.enclaveEndpointUpdate.mandatoryApprovers, approver => toLower(string(approver.approverEntraId))) : []
var existingEnclaveMaintenanceModeApproverIds = enclave.mode != 'managed' ? map(existingEnclaveModule.outputs.approvalSettings.enclaveMaintenanceMode.mandatoryApprovers, approver => toLower(string(approver.approverEntraId))) : []
var expectedEnclaveMaintenanceModeApproverIds = enclave.mode != 'managed' ? map(normalizedExpectedApprovalSettings.enclaveMaintenanceMode.mandatoryApprovers, approver => toLower(string(approver.approverEntraId))) : []
var existingEnclaveMatchesConnectionCreationApproval = enclave.mode != 'managed'
  ? toLower(existingEnclaveModule.outputs.approvalSettings.connectionCreation.approvalPolicy) == toLower(normalizedExpectedApprovalSettings.connectionCreation.approvalPolicy) && int(existingEnclaveModule.outputs.approvalSettings.connectionCreation.minimumApproversRequired) == normalizedExpectedApprovalSettings.connectionCreation.minimumApproversRequired && length(existingConnectionCreationApproverIds) == length(expectedConnectionCreationApproverIds) && length(filter(existingConnectionCreationApproverIds, approverId => !contains(expectedConnectionCreationApproverIds, approverId))) == 0 && length(filter(expectedConnectionCreationApproverIds, approverId => !contains(existingConnectionCreationApproverIds, approverId))) == 0
  : true
var existingEnclaveMatchesConnectionUpdateApproval = enclave.mode != 'managed'
  ? toLower(existingEnclaveModule.outputs.approvalSettings.connectionUpdate.approvalPolicy) == toLower(normalizedExpectedApprovalSettings.connectionUpdate.approvalPolicy) && int(existingEnclaveModule.outputs.approvalSettings.connectionUpdate.minimumApproversRequired) == normalizedExpectedApprovalSettings.connectionUpdate.minimumApproversRequired && length(existingConnectionUpdateApproverIds) == length(expectedConnectionUpdateApproverIds) && length(filter(existingConnectionUpdateApproverIds, approverId => !contains(expectedConnectionUpdateApproverIds, approverId))) == 0 && length(filter(expectedConnectionUpdateApproverIds, approverId => !contains(existingConnectionUpdateApproverIds, approverId))) == 0
  : true
var existingEnclaveMatchesEnclaveEndpointUpdateApproval = enclave.mode != 'managed'
  ? toLower(existingEnclaveModule.outputs.approvalSettings.enclaveEndpointUpdate.approvalPolicy) == toLower(normalizedExpectedApprovalSettings.enclaveEndpointUpdate.approvalPolicy) && int(existingEnclaveModule.outputs.approvalSettings.enclaveEndpointUpdate.minimumApproversRequired) == normalizedExpectedApprovalSettings.enclaveEndpointUpdate.minimumApproversRequired && length(existingEnclaveEndpointUpdateApproverIds) == length(expectedEnclaveEndpointUpdateApproverIds) && length(filter(existingEnclaveEndpointUpdateApproverIds, approverId => !contains(expectedEnclaveEndpointUpdateApproverIds, approverId))) == 0 && length(filter(expectedEnclaveEndpointUpdateApproverIds, approverId => !contains(existingEnclaveEndpointUpdateApproverIds, approverId))) == 0
  : true
var existingEnclaveMatchesEnclaveMaintenanceModeApproval = enclave.mode != 'managed'
  ? toLower(existingEnclaveModule.outputs.approvalSettings.enclaveMaintenanceMode.approvalPolicy) == toLower(normalizedExpectedApprovalSettings.enclaveMaintenanceMode.approvalPolicy) && int(existingEnclaveModule.outputs.approvalSettings.enclaveMaintenanceMode.minimumApproversRequired) == normalizedExpectedApprovalSettings.enclaveMaintenanceMode.minimumApproversRequired && length(existingEnclaveMaintenanceModeApproverIds) == length(expectedEnclaveMaintenanceModeApproverIds) && length(filter(existingEnclaveMaintenanceModeApproverIds, approverId => !contains(expectedEnclaveMaintenanceModeApproverIds, approverId))) == 0 && length(filter(expectedEnclaveMaintenanceModeApproverIds, approverId => !contains(existingEnclaveMaintenanceModeApproverIds, approverId))) == 0
  : true
var existingEnclaveMatchesApprovalSettings = existingEnclaveMatchesConnectionCreationApproval && existingEnclaveMatchesConnectionUpdateApproval && existingEnclaveMatchesEnclaveEndpointUpdateApproval && existingEnclaveMatchesEnclaveMaintenanceModeApproval
var additiveEnclaveHasRoundtrippableSharedSettings = enclave.mode != 'AdditiveSubnetUpdate'
  ? true
  : existingEnclaveModule.outputs.hasExplicitAllowSubnetCommunication && existingEnclaveModule.outputs.hasExplicitBastionEnabled && existingEnclaveModule.outputs.hasExplicitDiagnosticDestination
var additiveRequestedSubnetNames = enclave.mode != 'AdditiveSubnetUpdate'
  ? []
  : concat([
      toLower(enclave.postgreSqlSubnet.name)
    ], enclave.privateEndpointSubnet.mode == 'New' ? [
      toLower(enclave.privateEndpointSubnet.name)
    ] : [])
var additiveRequestedSubnetNamesAreDistinct = enclave.mode != 'AdditiveSubnetUpdate'
  ? true
  : (enclave.privateEndpointSubnet.mode != 'New' || toLower(enclave.postgreSqlSubnet.name) != toLower(enclave.privateEndpointSubnet.name))
var additiveRequestedSubnetNamesAreAvailable = enclave.mode != 'AdditiveSubnetUpdate'
  ? true
  : length(filter(
      existingEnclaveModule.outputs.subnetConfigurations,
      subnet => contains(additiveRequestedSubnetNames, toLower(string(subnet.subnetName)))
    )) == 0
var existingEnclaveCompatibility = existingEnclaveMatchesLocation && existingEnclaveMatchesCommunity && existingEnclaveMatchesBastion && existingEnclaveMatchesDiagnosticDestination && existingEnclaveMatchesRbac && existingEnclaveMatchesVisibility && existingEnclaveMatchesSubnetCommunication && existingEnclaveMatchesPostgreSqlSubnet && existingEnclaveMatchesPrivateEndpointSubnet && existingEnclaveMatchesGovernedServices && existingEnclaveMatchesApprovalSettings

module existingEnclaveCompatibilityGate './modules/requiredTextSubscriptionGate.bicep' = if (enclave.mode != 'managed') {
  name: 'existingEnclaveCompatibilityGate'
  params: {
    requiredText: existingEnclaveCompatibility ? 'compatible' : ''
  }
  dependsOn: [
    existingEnclaveModule
  ]
}

module additiveSubnetRequestGate './modules/requiredTextSubscriptionGate.bicep' = if (enclave.mode == 'AdditiveSubnetUpdate') {
  name: 'additiveSubnetRequestGate'
  params: {
    requiredText: additiveRequestedSubnetNamesAreDistinct && additiveRequestedSubnetNamesAreAvailable && additiveEnclaveHasRoundtrippableSharedSettings ? 'compatible' : ''
  }
  dependsOn: [
    existingEnclaveModule
  ]
}

module additiveEnclaveSubnetUpdateModule './modules/existingEnclaveAdditiveSubnetUpdater.bicep' = if (enclave.mode == 'AdditiveSubnetUpdate') {
  name: 'postgresqlExistingEnclaveAdditiveSubnetUpdate'
  scope: resourceGroup(existingEnclaveSubscriptionId, existingEnclaveResourceGroupName)
  params: {
    effectivePrivateEndpointSubnetName: privateEndpointSubnetName
    enclaveName: enclaveName
    postgreSqlSubnetName: enclave.postgreSqlSubnet.name
    postgreSqlSubnetNetworkPrefixSize: enclave.postgreSqlSubnet.networkPrefixSize
    privateEndpointSubnetName: enclave.privateEndpointSubnet.mode == 'New' ? enclave.privateEndpointSubnet.name : ''
    privateEndpointSubnetNetworkPrefixSize: enclave.privateEndpointSubnet.mode == 'New' ? enclave.privateEndpointSubnet.networkPrefixSize : 0
  }
  dependsOn: [
    additiveSubnetRequestGate
    existingEnclaveCompatibilityGate
  ]
}

var effectiveEnclaveResourceId = enclave.mode == 'managed'
  ? managedEnclaveModule.outputs.resourceId
  : (enclave.mode == 'ReferenceOnly' ? existingEnclaveModule.outputs.resourceId : additiveEnclaveSubnetUpdateModule.outputs.resourceId)
var effectiveEnclaveLocation = enclave.mode == 'managed'
  ? location
  : (enclave.mode == 'ReferenceOnly' ? existingEnclaveModule.outputs.location : additiveEnclaveSubnetUpdateModule.outputs.location)
var effectiveEnclaveManagedResourceGroupName = enclave.mode == 'managed'
  ? managedEnclaveModule.outputs.managedResourceGroupName
  : (enclave.mode == 'ReferenceOnly' ? existingEnclaveModule.outputs.managedResourceGroupName : additiveEnclaveSubnetUpdateModule.outputs.managedResourceGroupName)
var effectiveEnclaveVnetName = enclave.mode == 'managed'
  ? managedEnclaveModule.outputs.enclaveVnetName
  : (enclave.mode == 'ReferenceOnly' ? existingEnclaveModule.outputs.vnetName : additiveEnclaveSubnetUpdateModule.outputs.vnetName)
var effectiveEnclaveVnetResourceId = enclave.mode == 'managed'
  ? managedEnclaveModule.outputs.enclaveVnetResourceId
  : (enclave.mode == 'ReferenceOnly' ? existingEnclaveModule.outputs.vnetResourceId : additiveEnclaveSubnetUpdateModule.outputs.vnetResourceId)
var managedEnclaveSubnetConfigurations = enclave.mode == 'managed' ? managedEnclaveModule.outputs.subnetConfigurations : []
var effectivePostgreSqlSubnet = enclave.mode == 'managed'
  ? filter(managedEnclaveSubnetConfigurations, subnet => toLower(string(subnet.subnetName)) == toLower(postgreSqlSubnetName))[0]
  : (enclave.mode == 'ReferenceOnly' ? existingEnclaveModule.outputs.postgreSqlSubnet : additiveEnclaveSubnetUpdateModule.outputs.postgreSqlSubnet)
var effectivePrivateEndpointSubnet = enclave.mode == 'managed'
  ? filter(managedEnclaveSubnetConfigurations, subnet => toLower(string(subnet.subnetName)) == toLower(privateEndpointSubnetName))[0]
  : (enclave.mode == 'ReferenceOnly' ? existingEnclaveModule.outputs.privateEndpointSubnet : additiveEnclaveSubnetUpdateModule.outputs.privateEndpointSubnet)
var maintenancePrincipals = enclave.mode == 'managed'
  ? managedEnclaveMaintenancePrincipals
  : (enclave.mode == 'ReferenceOnly' ? existingEnclaveModule.outputs.maintenancePrincipals : additiveEnclaveSubnetUpdateModule.outputs.maintenancePrincipals)

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

output contractVersion string = '3.0'
output phaseA phaseAHandoffType = {
  contractVersion: '3.0'
  communityResourceId: communityResourceId
  delegatedPrivateDnsZoneResourceId: foundation.privateDns.delegatedZone.mode == 'managed' ? delegatedDnsZoneModule.outputs.resourceId : existingDelegatedDnsZoneResource.id
  enclaveManagedResourceGroupName: effectiveEnclaveManagedResourceGroupName
  enclaveOwnership: enclave.mode == 'managed' ? 'managed' : 'existing'
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
output telemetryEnabled bool = enableTelemetry
