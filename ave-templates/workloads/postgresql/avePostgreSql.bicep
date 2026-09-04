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
  @description('CAF instance discriminator used by generated names. Omit to use 001; use a short alphanumeric value such as 002 or a01.')
  @minLength(1)
  @maxLength(5)
  instance: string?
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

type diagnosticDestinationType = 'Both' | 'CommunityOnly' | 'EnclaveOnly'

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
  @description('Subnet name. Omit to use the workload default. For an existing enclave, a live subnet with this name is reused additively.')
  @minLength(1)
  name: string?
  @description('Subnet prefix size. Omit to reuse the live prefix size when the subnet already exists, or the workload default (24) when it does not.')
  @minValue(1)
  networkPrefixSize: int?
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

// ─── Workload ─────────────────────────────────────────────────────────────────

type managedWorkloadType = {
  mode: 'managed'
  @minLength(1)
  name: string?
  @minLength(1)
  resourceGroupName: string?
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

type expectedPostgreSqlSkuType = {
  @minLength(1)
  name: string
  tier: 'Burstable' | 'GeneralPurpose' | 'MemoryOptimized'
}

type expectedPostgreSqlStorageType = {
  @minValue(32)
  storageSizeGB: int
  type: 'Premium_LRS' | 'PremiumV2_LRS'
  tier: string?
  @minValue(1)
  iops: int?
  @minValue(1)
  throughput: int?
  autoGrow: 'Enabled' | 'Disabled'
}

type expectedPostgreSqlBackupType = {
  @minValue(7)
  @maxValue(35)
  retentionDays: int
  geoRedundancy: 'Disabled'
}

type postgreSqlBackupType = {
  @minValue(7)
  @maxValue(35)
  retentionDays: int?
  geoRedundancy: 'Disabled'?
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
  version: string?
  availabilityZone: string?
  sku: postgreSqlSkuType?
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
  sku: expectedPostgreSqlSkuType
  storage: expectedPostgreSqlStorageType
  backup: expectedPostgreSqlBackupType
  highAvailability: postgreSqlHighAvailabilityType
  maintenanceWindow: maintenanceExpectationType
  delegatedSubnetResourceId: string
  privateDnsZoneResourceId: string
  activeDirectoryAuth: 'Enabled'
  passwordAuth: 'Disabled'
  tenantId: string
  serverIdentityResourceId: string
  cmkKeyUri: string
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

@description('Deployment defaults. Location and subscription omission resolve to the ARM deployment context; instance omission resolves to 001.')
param deploymentContext deploymentContextType = {}

@description('Deployment principal seeded into the Mission maintenance-principal set and used for the managed default Mission workload-scope Owner assignment for managed enclaves.')
param deploymentPrincipal deploymentPrincipalType

@description('Managed-or-existing Mission community definition.')
param community communityDefinitionType

@description('Mission virtual enclave. Omit resourceId to create a new enclave (addressSpaceCidr and all four approval settings are then required). Supply resourceId to target an existing enclave: its immutable properties are read and reused, and this workload\'s subnets, role assignments, and maintenance principals are unioned with the live state.')
param enclave enclaveDefinitionType

@description('Mission workload registration. Defaults to managed with Community-derived names; use existing to bind to an already-registered workload.')
param workload workloadDefinitionType = {
  mode: 'managed'
}

@description('Server identity, Key Vault, CMK key, and private DNS resources consumed by PostgreSQL Flexible Server. Defaults every child to managed mode.')
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

@description('Mission network finalization mode. Defaults to Managed, which creates requested community endpoints and enclave connections. Existing modes pass through or extend previously captured resource IDs.')
param networkFinalization networkFinalizationDefinitionType = {
  mode: 'Managed'
}

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
      instance: deploymentContext.?instance
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
