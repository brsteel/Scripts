targetScope = 'subscription'

type deploymentContextType = {
  location: string?
  tags: object?
}

type phaseAType = {
  contractVersion: '2.0'
  delegatedPrivateDnsZoneResourceId: string
  geoCmk: {
    mode: 'absent'
  }
  location: string
  postgreSqlCmkIdentityResourceId: string
  postgreSqlCmkKeyUri: string
  postgreSqlDnsSuffix: string
  postgreSqlPrivateLinkZoneName: string
  postgreSqlSubnetResourceId: string
  targetSubscriptionId: string
  workloadResourceGroupId: string
  workloadResourceId: string
}

type foundationType = {
  contractVersion: '2.0'
  communityEndpointResourceIds: string[]
  enclaveConnectionResourceIds: string[]
  phaseA: phaseAType
}

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

@description('Deployment defaults. Location omission resolves to the Phase A foundation location.')
param deploymentContext deploymentContextType = {}

@description('Frozen Phase B foundation handoff. Network and CMK resources are consumed as inputs and are never mutated by this workload template.')
param foundation foundationType

@description('Managed-or-existing PostgreSQL Flexible Server definition.')
param server flexibleServerDefinitionType

var workloadResourceGroupSegments = split(foundation.phaseA.workloadResourceGroupId, '/')
var workloadSubscriptionId = workloadResourceGroupSegments[2]
var workloadResourceGroupName = workloadResourceGroupSegments[4]
var cloudDomain = replace(replace(environment().resourceManager, 'https://management.', ''), '/', '')
var derivedPostgreSqlDnsSuffix = 'postgres.database.${cloudDomain}'
var derivedPostgreSqlPrivateLinkZoneName = 'privatelink.${derivedPostgreSqlDnsSuffix}'
var foundationCloudIsValid = toLower(foundation.phaseA.postgreSqlDnsSuffix) == toLower(derivedPostgreSqlDnsSuffix) && toLower(foundation.phaseA.postgreSqlPrivateLinkZoneName) == toLower(derivedPostgreSqlPrivateLinkZoneName)
var existingServerScopeIsValid = server.mode == 'managed' || toLower(server.resourceId) == toLower('${foundation.phaseA.workloadResourceGroupId}/providers/Microsoft.DBforPostgreSQL/flexibleServers/${last(split(server.resourceId, '/'))}')

module workloadDeployment './modules/flexibleServerInResourceGroup.bicep' = if (foundationCloudIsValid && existingServerScopeIsValid) {
  name: 'postgresqlWorkload'
  scope: resourceGroup(workloadSubscriptionId, workloadResourceGroupName)
  params: {
    deploymentContext: deploymentContext
    foundation: foundation
    server: server
  }
}

module foundationCloudGate './modules/requiredTextSubscriptionGate.bicep' = {
  name: 'postgresqlFoundationCloudGate'
  params: {
    requiredText: foundationCloudIsValid && existingServerScopeIsValid ? 'compatible' : ''
  }
}

output contractVersion string = '2.0'
output flexibleServerResourceId string = workloadDeployment.outputs.flexibleServerResourceId
output flexibleServerName string = workloadDeployment.outputs.flexibleServerName
output fullyQualifiedDomainName string = workloadDeployment.outputs.fullyQualifiedDomainName
output workloadResourceId string = foundation.phaseA.workloadResourceId
output workloadResourceGroupId string = foundation.phaseA.workloadResourceGroupId
output postgreSqlSubnetResourceId string = foundation.phaseA.postgreSqlSubnetResourceId
output delegatedPrivateDnsZoneResourceId string = foundation.phaseA.delegatedPrivateDnsZoneResourceId
output serverOwnership 'managed' | 'existing' = workloadDeployment.outputs.serverOwnership
output effectiveSku postgreSqlSkuType = workloadDeployment.outputs.effectiveSku
output effectiveHighAvailability postgreSqlHighAvailabilityType = workloadDeployment.outputs.effectiveHighAvailability
output effectiveBackup postgreSqlBackupType = workloadDeployment.outputs.effectiveBackup
