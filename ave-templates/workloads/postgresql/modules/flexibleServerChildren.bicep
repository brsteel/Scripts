targetScope = 'resourceGroup'

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

@description('Name of the managed PostgreSQL Flexible Server.')
@minLength(3)
@maxLength(63)
param flexibleServerName string

@description('Complete Microsoft Entra administrator set owned by this deployment.')
@minLength(1)
param administrators postgreSqlAdministratorType[]

@description('Complete database set owned by this deployment.')
param databases postgreSqlDatabaseType[] = []

@description('Complete server configuration set owned by this deployment.')
param configurations postgreSqlConfigurationType[] = []

@description('Optional diagnostic setting owned by this deployment.')
param diagnostics diagnosticConfigurationType?

@description('Deletion protection choice for the managed server.')
@allowed([
  'CanNotDelete'
  'None'
])
param deletionProtection string = 'CanNotDelete'

var diagnosticSettingName = diagnostics.?settingName ?? 'diag-postgresql'
var diagnosticWorkspaceResourceId = diagnostics.?workspaceResourceId ?? ''
var diagnosticLogCategories = diagnostics.?logCategories ?? []
var diagnosticMetricCategories = diagnostics.?metricCategories ?? []

resource flexibleServerResource 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' existing = {
  name: flexibleServerName
}

// Live Azure Government testing (direct ARM PUT, confirmed by `az postgres
// flexible-server ad-admin list`) showed that the RP's Entra administrator
// creation call fails with AadAuthPrincipalCreationFailed ("0LP01: An
// unexpected error occurred while trying to validate user", Outcome: 30)
// against the 2024-08-01 administrators child API. A direct PUT against the
// 2025-08-01 administrators API, using the upper-snake-case principalType
// values below instead of the 2024-08-01 mixed-case contract values, was
// accepted and the administrator resource now exists. The customer-facing
// `postgreSqlAdministratorType.principalType` contract stays 'User' |
// 'Group' | 'ServicePrincipal' for backward compatibility; this map
// normalizes it to the exact values the 2025-08-01 API requires.
var administratorPrincipalTypeApiValue = {
  User: 'USER'
  Group: 'GROUP'
  ServicePrincipal: 'SERVICE_PRINCIPAL'
}

resource administratorResources 'Microsoft.DBforPostgreSQL/flexibleServers/administrators@2025-08-01' = [for administrator in administrators: {
  parent: flexibleServerResource
  name: administrator.objectId
  properties: {
    principalName: administrator.principalName
    principalType: administratorPrincipalTypeApiValue[administrator.principalType]
    tenantId: administrator.tenantId
  }
}]

resource databaseResources 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2024-08-01' = [for database in databases: {
  parent: flexibleServerResource
  name: database.name
  properties: union({}, database.?charset != null ? {
    charset: database.charset
  } : {}, database.?collation != null ? {
    collation: database.collation
  } : {})
  dependsOn: [
    administratorResources
  ]
}]

resource configurationResources 'Microsoft.DBforPostgreSQL/flexibleServers/configurations@2024-08-01' = [for configuration in configurations: {
  parent: flexibleServerResource
  name: configuration.name
  properties: {
    source: 'user-override'
    value: configuration.value
  }
  dependsOn: [
    administratorResources
  ]
}]

resource diagnosticSettingResource 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (diagnostics != null) {
  name: diagnosticSettingName
  scope: flexibleServerResource
  properties: {
    workspaceId: diagnosticWorkspaceResourceId
    logAnalyticsDestinationType: 'Dedicated'
    logs: [for category in diagnosticLogCategories: {
      category: category
      enabled: true
      retentionPolicy: {
        days: 0
        enabled: false
      }
    }]
    metrics: [for category in diagnosticMetricCategories: {
      category: category
      enabled: true
      retentionPolicy: {
        days: 0
        enabled: false
      }
    }]
  }
  dependsOn: [
    administratorResources
    configurationResources
    databaseResources
  ]
}

resource deletionLockResource 'Microsoft.Authorization/locks@2020-05-01' = if (deletionProtection == 'CanNotDelete') {
  name: 'postgresql-delete-lock'
  scope: flexibleServerResource
  properties: {
    level: 'CanNotDelete'
    notes: 'Protects the PostgreSQL Flexible Server from deletion. Remove only through an approved change procedure.'
  }
  dependsOn: [
    administratorResources
    configurationResources
    databaseResources
    diagnosticSettingResource
  ]
}

output diagnosticSettingResourceId string = diagnostics != null ? diagnosticSettingResource.id : ''
output deletionLockResourceId string = deletionProtection == 'CanNotDelete' ? deletionLockResource.id : ''
