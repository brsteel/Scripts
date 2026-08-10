targetScope = 'subscription'

// ──────────────────────────────────────────────────────────────────────────────
// Production entry point for the AVE PostgreSQL workload.
//
// Customers author ONLY a .bicepparam file that targets this template.
// No Bicep editing or separate phase deployments are needed or supported.
//
// Internal orchestration: Phase A → Phase B → Phase C through output dependencies.
// ──────────────────────────────────────────────────────────────────────────────

// ─── Type re-exports from phase modules (kept in sync with phase contracts) ───

type deploymentContextType = {
  @description('Override the deployment subscription. Omit to use the current subscription.')
  subscriptionId: string?
  @description('Override the deployment location. Omit to use the ARM deployment location.')
  location: string?
  @description('Tags applied to all created resources.')
  tags: object?
}

type deploymentPrincipalType = {
  @description('Entra object ID of the deployment principal.')
  @minLength(1)
  objectId: string
  @description('Principal type of the deployment principal.')
  principalType: 'User' | 'Group' | 'ServicePrincipal'
}

// ─── Community ────────────────────────────────────────────────────────────────

type managedCommunityType = {
  mode: 'managed'
  @minLength(1)
  name: string
  @minLength(1)
  resourceGroupName: string
  addressSpace: string?
  addressSpaces: string[]?
  dnsServers: string[]?
}

type existingCommunityType = {
  mode: 'existing'
  @minLength(1)
  resourceId: string
}

@discriminator('mode')
type communityDefinitionType = managedCommunityType | existingCommunityType

// ─── Enclave ──────────────────────────────────────────────────────────────────

type approvalPolicyType = 'NotRequired' | 'Required'
type diagnosticDestinationType = 'Both' | 'CommunityOnly' | 'EnclaveOnly'
type toggleStateType = 'Disabled' | 'Enabled'

type mandatoryApproverType = {
  @minLength(1)
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

type subnetRequestType = {
  name: string?
  networkPrefixSize: int
}

type additiveSubnetRequestType = {
  @minLength(1)
  name: string
  networkPrefixSize: int
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

type managedEnclaveType = {
  mode: 'managed'
  @minLength(1)
  name: string
  @minLength(1)
  resourceGroupName: string
  @minLength(1)
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
  @minLength(1)
  resourceId: string
  expectedConfiguration: referenceOnlyExpectedEnclaveType
}

type existingAdditiveSubnetUpdateEnclaveType = {
  mode: 'AdditiveSubnetUpdate'
  @minLength(1)
  resourceId: string
  expectedConfiguration: additiveExistingEnclaveExpectedType
  postgreSqlSubnet: additiveSubnetRequestType
  privateEndpointSubnet: additivePrivateEndpointSubnetType
}

@discriminator('mode')
type enclaveDefinitionType = managedEnclaveType | existingReferenceOnlyEnclaveType | existingAdditiveSubnetUpdateEnclaveType

// ─── Workload ─────────────────────────────────────────────────────────────────

type managedWorkloadType = {
  mode: 'managed'
  @minLength(1)
  name: string
  @minLength(1)
  resourceGroupName: string
}

type existingWorkloadType = {
  mode: 'existing'
  @minLength(1)
  resourceId: string
  @minLength(1)
  expectedResourceGroupCollection: string[]
}

@discriminator('mode')
type workloadDefinitionType = managedWorkloadType | existingWorkloadType

// ─── Foundation (CMK, Key Vault, DNS) ─────────────────────────────────────────

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

// ─── Network finalization (Phase B) ───────────────────────────────────────────

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

// ─── Server (Phase C) ─────────────────────────────────────────────────────────

type postgreSqlSkuType = {
  @minLength(1)
  name: string
  tier: 'Burstable' | 'GeneralPurpose' | 'MemoryOptimized'?
}

type postgreSqlStorageType = {
  @minValue(32)
  storageSizeGB: int?
  type: 'Premium_LRS' | 'PremiumV2_LRS'?
  tier: string?
  @minValue(1)
  iops: int?
  @minValue(1)
  throughput: int?
  autoGrow: 'Enabled' | 'Disabled'?
}

type postgreSqlBackupType = {
  @minValue(7)
  @maxValue(35)
  retentionDays: int?
  geoRedundancy: 'Enabled' | 'Disabled'?
}

type postgreSqlHighAvailabilityType = {
  mode: 'ZoneRedundant' | 'SameZone' | 'Disabled'
  standbyAvailabilityZone: string?
}

type postgreSqlMaintenanceWindowType = {
  @minValue(0)
  @maxValue(6)
  dayOfWeek: int
  @minValue(0)
  @maxValue(23)
  startHour: int
  @minValue(0)
  @maxValue(59)
  startMinute: int
}

type postgreSqlAdministratorType = {
  @minLength(1)
  objectId: string
  @minLength(1)
  principalName: string
  principalType: 'User' | 'Group' | 'ServicePrincipal'
  @minLength(1)
  tenantId: string
}

type postgreSqlDatabaseType = {
  @minLength(1)
  name: string
  charset: string?
  collation: string?
}

type postgreSqlConfigurationType = {
  @minLength(1)
  name: string
  value: string
}

type diagnosticConfigurationType = {
  @minLength(1)
  workspaceResourceId: string
  settingName: string?
  logCategories: string[]
  metricCategories: string[]
}

type systemManagedMaintenanceExpectationType = {
  mode: 'SystemManaged'
}

type customMaintenanceExpectationType = {
  mode: 'Custom'
  @minValue(0)
  @maxValue(6)
  dayOfWeek: int
  @minValue(0)
  @maxValue(23)
  startHour: int
  @minValue(0)
  @maxValue(59)
  startMinute: int
}

@discriminator('mode')
type maintenanceExpectationType = systemManagedMaintenanceExpectationType | customMaintenanceExpectationType

type absentDiagnosticsExpectationType = {
  mode: 'Absent'
}

type configuredDiagnosticsExpectationType = {
  mode: 'Configured'
  workspaceResourceId: string
  settingName: string
  logCategories: string[]
  metricCategories: string[]
}

@discriminator('mode')
type diagnosticsExpectationType = absentDiagnosticsExpectationType | configuredDiagnosticsExpectationType

type managedFlexibleServerType = {
  mode: 'managed'
  name: string?
  location: string?
  @minLength(1)
  version: string
  availabilityZone: string?
  sku: postgreSqlSkuType
  storage: postgreSqlStorageType?
  backup: postgreSqlBackupType?
  highAvailability: postgreSqlHighAvailabilityType?
  maintenanceWindow: postgreSqlMaintenanceWindowType?
  @minLength(1)
  administrators: postgreSqlAdministratorType[]
  databases: postgreSqlDatabaseType[]?
  configurations: postgreSqlConfigurationType[]?
  diagnostics: diagnosticConfigurationType?
  deletionProtection: 'CanNotDelete' | 'None'?
}

type expectedFlexibleServerType = {
  location: string
  version: string
  availabilityZone: string?
  sku: postgreSqlSkuType
  storage: postgreSqlStorageType
  backup: postgreSqlBackupType
  highAvailability: postgreSqlHighAvailabilityType
  maintenanceWindow: maintenanceExpectationType
  delegatedSubnetResourceId: string
  privateDnsZoneResourceId: string
  activeDirectoryAuth: 'Enabled'
  passwordAuth: 'Disabled'
  tenantId: string
  cmkIdentityResourceId: string
  cmkKeyUri: string
  geoCmkIdentityResourceId: string?
  geoCmkKeyUri: string?
  @minLength(1)
  administrators: postgreSqlAdministratorType[]
  databases: postgreSqlDatabaseType[]
  configurations: postgreSqlConfigurationType[]
  diagnostics: diagnosticsExpectationType
  deletionLock: 'CanNotDelete' | 'Absent'
}

type existingFlexibleServerType = {
  mode: 'existing'
  @minLength(1)
  resourceId: string
  expectedConfiguration: expectedFlexibleServerType
}

@discriminator('mode')
type flexibleServerDefinitionType = managedFlexibleServerType | existingFlexibleServerType

// ─── Telemetry ────────────────────────────────────────────────────────────────

@description('Set to false to disable template telemetry emitted by Phase A.')
param enableTelemetry bool = true

// ─── Top-level parameters ─────────────────────────────────────────────────────

@description('Deployment defaults. Location and subscription omission resolve to the ARM deployment context.')
param deploymentContext deploymentContextType = {}

@description('Deployment principal seeded into the Mission maintenance-principal set for managed enclaves.')
param deploymentPrincipal deploymentPrincipalType

@description('Managed-or-existing Mission community definition.')
param community communityDefinitionType

@description('Managed or existing Mission enclave. Managed callers must explicitly declare all four approval settings. Existing enclaves must choose ReferenceOnly or AdditiveSubnetUpdate.')
param enclave enclaveDefinitionType

@description('Mission workload registration. Use managed to create a new workload resource group; use existing to bind to an already-registered workload.')
param workload workloadDefinitionType

@description('CMK identity, Key Vault, CMK key, and private DNS resources consumed by PostgreSQL Flexible Server.')
param foundation foundationDefinitionType

@description('Mission network finalization mode. Managed creates community endpoints and enclave connections. Existing modes pass through or extend previously captured resource IDs.')
param networkFinalization networkFinalizationDefinitionType

@description('Optional Mission community endpoint and enclave connection requests for Phase B. Leave empty when networkFinalization.mode is ExistingReferenceOnly.')
param communityConnectivity connectivityDefinitionType[] = []

@description('PostgreSQL Flexible Server definition.')
param server flexibleServerDefinitionType

// ─── Phase A: enclave, workload, CMK, DNS foundation ─────────────────────────

module phaseA './avePostgreSqlEnclaveDeployment.bicep' = {
  name: 'avePostgreSqlPhaseA'
  params: {
    community: community
    deploymentContext: deploymentContext
    deploymentPrincipal: deploymentPrincipal
    enableTelemetry: enableTelemetry
    enclave: enclave
    foundation: foundation
    workload: workload
  }
}

// ─── Phase B: network finalization ───────────────────────────────────────────

module phaseB './avePostgreSqlEnclaveNetworkFinalization.bicep' = {
  name: 'avePostgreSqlPhaseB'
  params: {
    communityConnectivity: communityConnectivity
    deploymentContext: {
      tags: deploymentContext.?tags
    }
    networkFinalization: networkFinalization
    phaseA: phaseA.outputs.phaseA
  }
}

// ─── Phase C: PostgreSQL Flexible Server ─────────────────────────────────────

module phaseC './avePostgreSqlWorkloadDeployment.bicep' = {
  name: 'avePostgreSqlPhaseC'
  params: {
    deploymentContext: deploymentContext
    foundation: phaseB.outputs.foundation
    server: server
  }
}

// ─── Outputs ──────────────────────────────────────────────────────────────────

output contractVersion string = phaseC.outputs.contractVersion
output flexibleServerResourceId string = phaseC.outputs.flexibleServerResourceId
output flexibleServerName string = phaseC.outputs.flexibleServerName
output fullyQualifiedDomainName string = phaseC.outputs.fullyQualifiedDomainName
output workloadResourceId string = phaseC.outputs.workloadResourceId
output workloadResourceGroupId string = phaseC.outputs.workloadResourceGroupId
output postgreSqlSubnetResourceId string = phaseC.outputs.postgreSqlSubnetResourceId
output delegatedPrivateDnsZoneResourceId string = phaseC.outputs.delegatedPrivateDnsZoneResourceId
output serverOwnership 'managed' | 'existing' = phaseC.outputs.serverOwnership
output effectiveSku postgreSqlSkuType = phaseC.outputs.effectiveSku
output effectiveHighAvailability postgreSqlHighAvailabilityType = phaseC.outputs.effectiveHighAvailability
output effectiveBackup postgreSqlBackupType = phaseC.outputs.effectiveBackup
output communityEndpointResourceIds string[] = phaseB.outputs.communityEndpointResourceIds
output enclaveConnectionResourceIds string[] = phaseB.outputs.enclaveConnectionResourceIds
output telemetryEnabled bool = phaseA.outputs.telemetryEnabled
