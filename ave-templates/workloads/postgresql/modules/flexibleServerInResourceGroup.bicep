targetScope = 'resourceGroup'

type deploymentContextType = {
  location: string?
  tags: object?
}

type foundationPhaseAType = {
  contractVersion: '3.0'
  delegatedPrivateDnsZoneResourceId: string
  geoCmk: {
    mode: 'absent' | 'configured'
    identityResourceId: string?
    keyUri: string?
  }
  location: string
  postgreSqlCmkIdentityResourceId: string
  postgreSqlCmkKeyUri: string
  postgreSqlSubnetResourceId: string
  workloadResourceId: string
}

type foundationType = {
  contractVersion: '3.0'
  phaseA: foundationPhaseAType
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

@description('Deployment defaults. Location omission resolves to the serialized foundation location.')
param deploymentContext deploymentContextType

@description('Frozen Phase B foundation handoff. Network and CMK resources are consumed as inputs and are never mutated by this workload module.')
param foundation foundationType

@description('Managed-or-existing PostgreSQL Flexible Server definition.')
param server flexibleServerDefinitionType

var resolvedServerName = server.?name ?? 'psql-${substring(uniqueString(foundation.phaseA.workloadResourceId), 0, 13)}'
var resolvedLocation = server.?location ?? deploymentContext.?location ?? foundation.phaseA.location
var resolvedTags = deploymentContext.?tags ?? {}
var resolvedSku = server.mode == 'managed' ? server.sku : server.expectedConfiguration.sku
var resolvedVersion = server.mode == 'managed' ? server.version : server.expectedConfiguration.version
var resolvedStorage = server.mode == 'managed'
  ? (server.?storage ?? {})
  : server.expectedConfiguration.storage
var resolvedBackup = server.mode == 'managed'
  ? (server.?backup ?? {})
  : server.expectedConfiguration.backup
var resolvedHighAvailability = server.mode == 'managed'
  ? (server.?highAvailability ?? {
      mode: 'Disabled'
    })
  : server.expectedConfiguration.highAvailability
var resolvedAdministrators = server.mode == 'managed'
  ? server.administrators
  : server.expectedConfiguration.administrators
var resolvedAdministratorTenantId = resolvedAdministrators[0].tenantId
var resolvedGeoCmk = foundation.phaseA.geoCmk.mode == 'configured' ? {
  identityResourceId: foundation.phaseA.geoCmk.identityResourceId ?? ''
  keyUri: foundation.phaseA.geoCmk.keyUri ?? ''
  mode: 'configured'
} : {
  mode: 'absent'
}

var existingServerSegments = split(server.?resourceId ?? '', '/')
var existingServerName = server.mode == 'existing' ? existingServerSegments[8] : ''

module managedFlexibleServer './flexibleServer.bicep' = if (server.mode == 'managed') {
  name: 'managedFlexibleServer'
  params: {
    administratorTenantId: resolvedAdministratorTenantId
    availabilityZone: server.?availabilityZone
    backup: resolvedBackup
    cmkIdentityResourceId: foundation.phaseA.postgreSqlCmkIdentityResourceId
    cmkKeyUri: foundation.phaseA.postgreSqlCmkKeyUri
    delegatedPrivateDnsZoneResourceId: foundation.phaseA.delegatedPrivateDnsZoneResourceId
    delegatedSubnetResourceId: foundation.phaseA.postgreSqlSubnetResourceId
    flexibleServerName: resolvedServerName
    geoCmk: resolvedGeoCmk
    highAvailability: resolvedHighAvailability
    location: resolvedLocation
    maintenanceWindow: server.?maintenanceWindow
    sku: resolvedSku
    storage: resolvedStorage
    tags: resolvedTags
    version: resolvedVersion
  }
}

module managedFlexibleServerChildren './flexibleServerChildren.bicep' = if (server.mode == 'managed') {
  name: 'managedFlexibleServerChildren'
  params: {
    administrators: resolvedAdministrators
    configurations: server.?configurations ?? []
    databases: server.?databases ?? []
    deletionProtection: server.?deletionProtection ?? 'CanNotDelete'
    diagnostics: server.?diagnostics
    flexibleServerName: resolvedServerName
  }
  dependsOn: [
    managedFlexibleServer
  ]
}

module existingFlexibleServer './existingFlexibleServerStateReader.bicep' = if (server.mode == 'existing') {
  name: 'existingFlexibleServerState'
  params: {
    flexibleServerName: existingServerName
  }
}

var existingServerMatchesLocation = server.mode == 'existing' ? toLower(existingFlexibleServer.outputs.serverState.location) == toLower(server.expectedConfiguration.location) : true
var existingServerMatchesVersion = server.mode == 'existing' ? toLower(string(existingFlexibleServer.outputs.serverState.properties.version)) == toLower(server.expectedConfiguration.version) : true
var existingServerMatchesSku = server.mode == 'existing' ? toLower(string(existingFlexibleServer.outputs.serverState.sku.name)) == toLower(server.expectedConfiguration.sku.name) && toLower(string(existingFlexibleServer.outputs.serverState.sku.tier ?? '')) == toLower(server.expectedConfiguration.sku.?tier ?? '') : true
var existingServerMatchesStorage = server.mode == 'existing' ? int(existingFlexibleServer.outputs.serverState.properties.storage.storageSizeGB ?? 0) == int(server.expectedConfiguration.storage.?storageSizeGB ?? 0) && toLower(string(existingFlexibleServer.outputs.serverState.properties.storage.type ?? '')) == toLower(server.expectedConfiguration.storage.?type ?? '') : true
var existingServerMatchesBackup = server.mode == 'existing' ? toLower(string(existingFlexibleServer.outputs.serverState.properties.backup.geoRedundantBackup ?? '')) == toLower(server.expectedConfiguration.backup.?geoRedundancy ?? '') && int(existingFlexibleServer.outputs.serverState.properties.backup.backupRetentionDays ?? 0) == int(server.expectedConfiguration.backup.?retentionDays ?? 0) : true
var existingServerMatchesHighAvailability = server.mode == 'existing' ? toLower(string(existingFlexibleServer.outputs.serverState.properties.highAvailability.mode ?? '')) == toLower(server.expectedConfiguration.highAvailability.mode) : true
var existingServerMatchesNetwork = server.mode == 'existing' ? toLower(string(existingFlexibleServer.outputs.serverState.properties.network.delegatedSubnetResourceId ?? '')) == toLower(server.expectedConfiguration.delegatedSubnetResourceId) && toLower(string(existingFlexibleServer.outputs.serverState.properties.network.privateDnsZoneArmResourceId ?? '')) == toLower(server.expectedConfiguration.privateDnsZoneResourceId) : true
var existingServerMatchesAuth = server.mode == 'existing' ? toLower(string(existingFlexibleServer.outputs.serverState.properties.authConfig.activeDirectoryAuth ?? '')) == toLower(server.expectedConfiguration.activeDirectoryAuth) && toLower(string(existingFlexibleServer.outputs.serverState.properties.authConfig.passwordAuth ?? '')) == toLower(server.expectedConfiguration.passwordAuth) && toLower(string(existingFlexibleServer.outputs.serverState.properties.authConfig.tenantId ?? '')) == toLower(server.expectedConfiguration.tenantId) : true
var existingServerMatchesCmk = server.mode == 'existing' ? toLower(string(existingFlexibleServer.outputs.serverState.properties.dataEncryption.primaryUserAssignedIdentityId ?? '')) == toLower(server.expectedConfiguration.cmkIdentityResourceId) && toLower(string(existingFlexibleServer.outputs.serverState.properties.dataEncryption.primaryKeyURI ?? '')) == toLower(server.expectedConfiguration.cmkKeyUri) : true
var existingServerMatchesMaintenance = server.mode == 'existing' ? (server.expectedConfiguration.maintenanceWindow.mode == 'SystemManaged' ? toLower(string(existingFlexibleServer.outputs.serverState.properties.maintenanceWindow.customWindow ?? 'Disabled')) != 'enabled' : int(existingFlexibleServer.outputs.serverState.properties.maintenanceWindow.dayOfWeek ?? -1) == server.expectedConfiguration.maintenanceWindow.dayOfWeek && int(existingFlexibleServer.outputs.serverState.properties.maintenanceWindow.startHour ?? -1) == server.expectedConfiguration.maintenanceWindow.startHour && int(existingFlexibleServer.outputs.serverState.properties.maintenanceWindow.startMinute ?? -1) == server.expectedConfiguration.maintenanceWindow.startMinute) : true
var existingServerCompatibility = existingServerMatchesLocation && existingServerMatchesVersion && existingServerMatchesSku && existingServerMatchesStorage && existingServerMatchesBackup && existingServerMatchesHighAvailability && existingServerMatchesNetwork && existingServerMatchesAuth && existingServerMatchesCmk && existingServerMatchesMaintenance

module existingServerCompatibilityGate './requiredTextResourceGroupGate.bicep' = if (server.mode == 'existing') {
  name: 'existingServerCompatibilityGate'
  params: {
    requiredText: existingServerCompatibility ? 'compatible' : ''
  }
  dependsOn: [
    existingFlexibleServer
  ]
}

output flexibleServerResourceId string = server.mode == 'managed'
  ? managedFlexibleServer.outputs.flexibleServerResourceId
  : existingFlexibleServer.outputs.flexibleServerResourceId
output flexibleServerName string = server.mode == 'managed'
  ? managedFlexibleServer.outputs.flexibleServerName
  : existingFlexibleServer.outputs.flexibleServerName
output fullyQualifiedDomainName string = server.mode == 'managed'
  ? managedFlexibleServer.outputs.fullyQualifiedDomainName
  : existingFlexibleServer.outputs.fullyQualifiedDomainName
output serverOwnership 'managed' | 'existing' = server.mode
output effectiveSku postgreSqlSkuType = server.mode == 'managed'
  ? managedFlexibleServer.outputs.effectiveSku
  : server.expectedConfiguration.sku
output effectiveHighAvailability postgreSqlHighAvailabilityType = server.mode == 'managed'
  ? managedFlexibleServer.outputs.effectiveHighAvailability
  : server.expectedConfiguration.highAvailability
output effectiveBackup postgreSqlBackupType = server.mode == 'managed'
  ? managedFlexibleServer.outputs.effectiveBackup
  : server.expectedConfiguration.backup
