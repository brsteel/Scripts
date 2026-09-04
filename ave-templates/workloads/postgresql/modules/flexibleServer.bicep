targetScope = 'resourceGroup'

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

@description('PostgreSQL Flexible Server name.')
@minLength(3)
@maxLength(63)
param flexibleServerName string

@description('Azure region for the server.')
@minLength(1)
param location string

@description('Tags applied to the server.')
param tags object = {}

@description('PostgreSQL major version.')
@minLength(1)
param version string

@description('Optional primary availability zone.')
param availabilityZone string?

@description('Compute SKU.')
param sku postgreSqlSkuType

@description('Storage configuration.')
param storage postgreSqlStorageType = {}

@description('Automated backup configuration.')
param backup postgreSqlBackupType = {}

@description('High availability configuration.')
param highAvailability postgreSqlHighAvailabilityType = {
  mode: 'Disabled'
}

@description('Optional custom maintenance window.')
param maintenanceWindow postgreSqlMaintenanceWindowType?

@description('Tenant ID used for Microsoft Entra-only authentication.')
@minLength(1)
param administratorTenantId string

@description('Delegated subnet resource ID consumed by the server.')
@minLength(1)
param delegatedSubnetResourceId string

@description('Private DNS zone resource ID consumed by the server.')
@minLength(1)
param delegatedPrivateDnsZoneResourceId string

@description('Primary PostgreSQL server identity resource ID (used for CMK key access).')
@minLength(1)
param serverIdentityResourceId string

@description('Primary versionless CMK URI.')
@minLength(1)
param cmkKeyUri string

var resolvedSku = {
  name: sku.name
  tier: sku.?tier ?? 'GeneralPurpose'
}

var resolvedStorageType = storage.?type ?? 'Premium_LRS'
var resolvedStorage = union({
  autoGrow: resolvedStorageType == 'PremiumV2_LRS' ? 'Disabled' : (storage.?autoGrow ?? 'Enabled')
  storageSizeGB: storage.?storageSizeGB ?? 128
  type: resolvedStorageType
}, storage.?tier != null ? {
  tier: storage.tier
} : {}, storage.?iops != null ? {
  iops: storage.iops
} : {}, storage.?throughput != null ? {
  throughput: storage.throughput
} : {})

var resolvedBackup = {
  geoRedundancy: backup.?geoRedundancy ?? 'Disabled'
  retentionDays: backup.?retentionDays ?? 35
}

var resolvedHighAvailability = union({
  mode: highAvailability.mode
}, highAvailability.mode != 'Disabled' && !empty(highAvailability.?standbyAvailabilityZone ?? '') ? {
  standbyAvailabilityZone: highAvailability.standbyAvailabilityZone
} : {})

resource flexibleServerResource 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: flexibleServerName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${serverIdentityResourceId}': {}
    }
  }
  sku: resolvedSku
  properties: union({
    authConfig: {
      activeDirectoryAuth: 'Enabled'
      passwordAuth: 'Disabled'
      tenantId: administratorTenantId
    }
    backup: {
      backupRetentionDays: resolvedBackup.retentionDays
      geoRedundantBackup: resolvedBackup.geoRedundancy
    }
    createMode: 'Default'
    dataEncryption: {
      primaryKeyURI: cmkKeyUri
      primaryUserAssignedIdentityId: serverIdentityResourceId
      type: 'AzureKeyVault'
    }
    highAvailability: resolvedHighAvailability
    network: {
      delegatedSubnetResourceId: delegatedSubnetResourceId
      privateDnsZoneArmResourceId: delegatedPrivateDnsZoneResourceId
    }
    storage: resolvedStorage
    version: version
  }, availabilityZone != null ? {
    availabilityZone: availabilityZone
  } : {}, maintenanceWindow != null ? {
    maintenanceWindow: {
      customWindow: 'Enabled'
      dayOfWeek: maintenanceWindow.dayOfWeek
      startHour: maintenanceWindow.startHour
      startMinute: maintenanceWindow.startMinute
    }
  } : {})
}

output flexibleServerResourceId string = flexibleServerResource.id
output flexibleServerName string = flexibleServerResource.name
output fullyQualifiedDomainName string = flexibleServerResource.properties.fullyQualifiedDomainName
output effectiveSku postgreSqlSkuType = resolvedSku
output effectiveHighAvailability postgreSqlHighAvailabilityType = resolvedHighAvailability
output effectiveBackup postgreSqlBackupType = resolvedBackup
