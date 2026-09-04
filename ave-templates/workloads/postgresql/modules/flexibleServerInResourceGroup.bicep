targetScope = 'resourceGroup'

type deploymentContextType = {
  location: string?
  @minLength(1)
  @maxLength(5)
  instance: string?
  tags: object?
}

type foundationPhaseAType = {
  contractVersion: '3.0'
  communityResourceId: string
  delegatedPrivateDnsZoneResourceId: string
  geoCmk: {
    mode: 'absent'
  }
  location: string
  postgreSqlServerIdentityResourceId: string
  postgreSqlCmkKeyUri: string
  postgreSqlSubnetResourceId: string
  targetSubscriptionId: string
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

@description('Deployment defaults. Location omission resolves to the serialized foundation location.')
param deploymentContext deploymentContextType

@description('Frozen Phase B foundation handoff. Network and CMK resources are consumed as inputs and are never mutated by this workload module.')
param foundation foundationType

@description('Managed-or-existing PostgreSQL Flexible Server definition.')
param server flexibleServerDefinitionType

var communityName = last(split(foundation.phaseA.communityResourceId, '/'))
var normalizedCommunityName = toLower(communityName)
var resolvedInstance = !empty(deploymentContext.?instance) ? deploymentContext.instance! : '001'
var communityUniqueSuffix = take(uniqueString(foundation.phaseA.targetSubscriptionId, communityName, resolvedInstance), 8)
var defaultServerName = 'pgsql-${take(normalizedCommunityName, 48)}-${communityUniqueSuffix}'
var defaultDatabaseName = 'db_${take(replace(normalizedCommunityName, '-', '_'), 53 - length(resolvedInstance))}_pgsql_${resolvedInstance}'
var resolvedServerName = server.mode == 'managed' ? server.?name ?? defaultServerName : ''
var resolvedLocation = server.?location ?? deploymentContext.?location ?? foundation.phaseA.location
var resolvedTags = deploymentContext.?tags ?? {}
var resolvedSku = server.mode == 'managed'
  ? (server.?sku ?? {
      name: 'Standard_D4ds_v4'
      tier: 'GeneralPurpose'
    })
  : server.expectedConfiguration.sku
var resolvedVersion = server.mode == 'managed' ? server.?version ?? '16' : server.expectedConfiguration.version
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
var resolvedAdministrators = server.mode == 'managed' ? server.administrators : []
var resolvedAdministratorTenantId = resolvedAdministrators[?0].?tenantId ?? ''
var resolvedDatabases = server.mode == 'managed'
  ? (server.?databases ?? [
      {
        name: defaultDatabaseName
      }
    ])
  : []

var existingServerSegments = split(server.?resourceId ?? '', '/')
var existingServerName = server.mode == 'existing' ? existingServerSegments[8] : ''

module managedFlexibleServer './flexibleServer.bicep' = if (server.mode == 'managed') {
  name: 'managedFlexibleServer'
  params: {
    administratorTenantId: resolvedAdministratorTenantId
    availabilityZone: server.?availabilityZone
    backup: resolvedBackup
    cmkKeyUri: foundation.phaseA.postgreSqlCmkKeyUri
    delegatedPrivateDnsZoneResourceId: foundation.phaseA.delegatedPrivateDnsZoneResourceId
    delegatedSubnetResourceId: foundation.phaseA.postgreSqlSubnetResourceId
    flexibleServerName: resolvedServerName
    highAvailability: resolvedHighAvailability
    location: resolvedLocation
    maintenanceWindow: server.?maintenanceWindow
    serverIdentityResourceId: foundation.phaseA.postgreSqlServerIdentityResourceId
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
    databases: resolvedDatabases
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
var existingServerMatchesAvailabilityZone = server.mode == 'existing' ? toLower(string(existingFlexibleServer.outputs.serverState.properties.availabilityZone ?? '')) == toLower(server.expectedConfiguration.?availabilityZone ?? '') : true
var existingServerMatchesSku = server.mode == 'existing' ? toLower(string(existingFlexibleServer.outputs.serverState.sku.name)) == toLower(server.expectedConfiguration.sku.name) && toLower(string(existingFlexibleServer.outputs.serverState.sku.tier)) == toLower(server.expectedConfiguration.sku.tier) : true
var existingServerMatchesStorageSize = server.mode == 'existing' ? int(existingFlexibleServer.outputs.serverState.properties.storage.storageSizeGB) == server.expectedConfiguration.storage.storageSizeGB : true
var existingServerMatchesStorageType = server.mode == 'existing' ? toLower(string(existingFlexibleServer.outputs.serverState.properties.storage.type)) == toLower(server.expectedConfiguration.storage.type) : true
var existingServerMatchesStorageAutoGrow = server.mode == 'existing' ? toLower(string(existingFlexibleServer.outputs.serverState.properties.storage.autoGrow)) == toLower(server.expectedConfiguration.storage.autoGrow) : true
var existingServerMatchesStorageTier = server.mode == 'existing' ? toLower(string(existingFlexibleServer.outputs.serverState.properties.storage.?tier ?? '')) == toLower(server.expectedConfiguration.storage.?tier ?? '') : true
var existingServerMatchesStorageIops = server.mode == 'existing' ? int(existingFlexibleServer.outputs.serverState.properties.storage.?iops ?? 0) == int(server.expectedConfiguration.storage.?iops ?? 0) : true
var existingServerMatchesStorageThroughput = server.mode == 'existing' ? int(existingFlexibleServer.outputs.serverState.properties.storage.?throughput ?? 0) == int(server.expectedConfiguration.storage.?throughput ?? 0) : true
var existingServerMatchesStorage = existingServerMatchesStorageSize && existingServerMatchesStorageType && existingServerMatchesStorageAutoGrow && existingServerMatchesStorageTier && existingServerMatchesStorageIops && existingServerMatchesStorageThroughput
var existingServerMatchesBackup = server.mode == 'existing' ? toLower(string(existingFlexibleServer.outputs.serverState.properties.backup.geoRedundantBackup)) == 'disabled' && toLower(server.expectedConfiguration.backup.geoRedundancy) == 'disabled' && int(existingFlexibleServer.outputs.serverState.properties.backup.backupRetentionDays) == server.expectedConfiguration.backup.retentionDays : true
var existingServerMatchesHighAvailability = server.mode == 'existing' ? toLower(string(existingFlexibleServer.outputs.serverState.properties.highAvailability.mode)) == toLower(server.expectedConfiguration.highAvailability.mode) && toLower(string(existingFlexibleServer.outputs.serverState.properties.highAvailability.?standbyAvailabilityZone ?? '')) == toLower(server.expectedConfiguration.highAvailability.?standbyAvailabilityZone ?? '') : true
var existingServerMatchesNetwork = server.mode == 'existing' ? toLower(string(existingFlexibleServer.outputs.serverState.properties.network.delegatedSubnetResourceId ?? '')) == toLower(server.expectedConfiguration.delegatedSubnetResourceId) && toLower(string(existingFlexibleServer.outputs.serverState.properties.network.privateDnsZoneArmResourceId ?? '')) == toLower(server.expectedConfiguration.privateDnsZoneResourceId) : true
var existingServerMatchesAuth = server.mode == 'existing' ? toLower(string(existingFlexibleServer.outputs.serverState.properties.authConfig.activeDirectoryAuth ?? '')) == toLower(server.expectedConfiguration.activeDirectoryAuth) && toLower(string(existingFlexibleServer.outputs.serverState.properties.authConfig.passwordAuth ?? '')) == toLower(server.expectedConfiguration.passwordAuth) && toLower(string(existingFlexibleServer.outputs.serverState.properties.authConfig.tenantId ?? '')) == toLower(server.expectedConfiguration.tenantId) : true
var existingServerIdentityEntries = server.mode == 'existing' ? items(existingFlexibleServer.outputs.serverState.identity.?userAssignedIdentities ?? {}) : []
var existingServerMatchesIdentityType = server.mode == 'existing' ? toLower(string(existingFlexibleServer.outputs.serverState.identity.?type ?? '')) == 'userassigned' : true
var existingServerMatchesIdentitySet = server.mode == 'existing' ? length(existingServerIdentityEntries) == 1 && toLower(existingServerIdentityEntries[0].key) == toLower(server.expectedConfiguration.serverIdentityResourceId) : true
var existingServerMatchesEncryptionType = server.mode == 'existing' ? toLower(string(existingFlexibleServer.outputs.serverState.properties.dataEncryption.?type ?? '')) == 'azurekeyvault' : true
var existingServerMatchesPrimaryCmk = server.mode == 'existing' ? toLower(string(existingFlexibleServer.outputs.serverState.properties.dataEncryption.primaryUserAssignedIdentityId ?? '')) == toLower(server.expectedConfiguration.serverIdentityResourceId) && toLower(string(existingFlexibleServer.outputs.serverState.properties.dataEncryption.primaryKeyURI ?? '')) == toLower(server.expectedConfiguration.cmkKeyUri) : true
var existingServerHasNoGeoCmk = server.mode == 'existing' ? empty(existingFlexibleServer.outputs.serverState.properties.dataEncryption.?geoBackupUserAssignedIdentityId ?? '') && empty(existingFlexibleServer.outputs.serverState.properties.dataEncryption.?geoBackupKeyURI ?? '') : true
var existingServerMatchesCmk = existingServerMatchesIdentityType && existingServerMatchesIdentitySet && existingServerMatchesEncryptionType && existingServerMatchesPrimaryCmk && existingServerHasNoGeoCmk
var existingServerUsesCustomMaintenance = server.mode == 'existing' ? toLower(string(existingFlexibleServer.outputs.serverState.properties.maintenanceWindow.?customWindow ?? 'Disabled')) == 'enabled' : false
var existingServerMatchesCustomMaintenanceValues = server.mode == 'existing' && server.expectedConfiguration.maintenanceWindow.mode == 'Custom' ? int(existingFlexibleServer.outputs.serverState.properties.maintenanceWindow.?dayOfWeek ?? -1) == server.expectedConfiguration.maintenanceWindow.dayOfWeek && int(existingFlexibleServer.outputs.serverState.properties.maintenanceWindow.?startHour ?? -1) == server.expectedConfiguration.maintenanceWindow.startHour && int(existingFlexibleServer.outputs.serverState.properties.maintenanceWindow.?startMinute ?? -1) == server.expectedConfiguration.maintenanceWindow.startMinute : true
var existingServerMatchesMaintenance = server.mode == 'existing' ? (server.expectedConfiguration.maintenanceWindow.mode == 'SystemManaged' ? !existingServerUsesCustomMaintenance : existingServerUsesCustomMaintenance && existingServerMatchesCustomMaintenanceValues) : true
var existingServerMatchesFoundationSubnet = server.mode == 'existing' ? toLower(server.expectedConfiguration.delegatedSubnetResourceId) == toLower(foundation.phaseA.postgreSqlSubnetResourceId) : true
var existingServerMatchesFoundationDns = server.mode == 'existing' ? toLower(server.expectedConfiguration.privateDnsZoneResourceId) == toLower(foundation.phaseA.delegatedPrivateDnsZoneResourceId) : true
var existingServerMatchesFoundationIdentity = server.mode == 'existing' ? toLower(server.expectedConfiguration.serverIdentityResourceId) == toLower(foundation.phaseA.postgreSqlServerIdentityResourceId) : true
var existingServerMatchesFoundationKey = server.mode == 'existing' ? toLower(server.expectedConfiguration.cmkKeyUri) == toLower(foundation.phaseA.postgreSqlCmkKeyUri) : true
var existingServerMatchesFoundation = existingServerMatchesFoundationSubnet && existingServerMatchesFoundationDns && existingServerMatchesFoundationIdentity && existingServerMatchesFoundationKey
var existingServerCompatibility = existingServerMatchesLocation && existingServerMatchesVersion && existingServerMatchesAvailabilityZone && existingServerMatchesSku && existingServerMatchesStorage && existingServerMatchesBackup && existingServerMatchesHighAvailability && existingServerMatchesNetwork && existingServerMatchesAuth && existingServerMatchesCmk && existingServerMatchesMaintenance && existingServerMatchesFoundation

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
