targetScope = 'resourceGroup'

type roleAssignmentPrincipalType = 'Device' | 'ForeignGroup' | 'Group' | 'ServicePrincipal' | 'User'
type roleAssignmentScopeKind = 'keyVault' | 'keyVaultKey' | 'privateDnsZone' | 'resourceGroup' | 'storageAccount'

@description('Scope kind for the role assignment.')
param scopeKind roleAssignmentScopeKind = 'resourceGroup'

@description('Role definition GUID or fully qualified role definition resource ID.')
param roleDefinitionIdOrGuid string

@description('Object ID of the principal receiving the role assignment.')
param principalId string

@description('Principal type for the role assignment.')
param principalTypeName roleAssignmentPrincipalType = 'ServicePrincipal'

@description('Primary resource name for the requested scope. For resourceGroup scope this parameter is ignored.')
param scopeName string = ''

@description('Parent resource name used when scopeKind = keyVaultKey.')
param parentResourceName string = ''

@description('Optional Azure RBAC condition string. When provided, conditionVersion is pinned to 2.0.')
param condition string = ''

var normalizedRoleDefinitionId = startsWith(roleDefinitionIdOrGuid, '/')
  ? roleDefinitionIdOrGuid
  : subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionIdOrGuid)

resource keyVaultResource 'Microsoft.KeyVault/vaults@2023-07-01' existing = if (scopeKind == 'keyVault') {
  name: scopeName
}

resource keyVaultParentResource 'Microsoft.KeyVault/vaults@2023-07-01' existing = if (scopeKind == 'keyVaultKey') {
  name: parentResourceName
}

resource keyVaultKeyResource 'Microsoft.KeyVault/vaults/keys@2023-07-01' existing = if (scopeKind == 'keyVaultKey') {
  parent: keyVaultParentResource
  name: scopeName
}

resource storageAccountResource 'Microsoft.Storage/storageAccounts@2024-01-01' existing = if (scopeKind == 'storageAccount') {
  name: scopeName
}

resource privateDnsZoneResource 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (scopeKind == 'privateDnsZone') {
  name: scopeName
}

var resourceGroupScopeId = resourceGroup().id
var keyVaultScopeId = scopeKind == 'keyVault' ? keyVaultResource.id : ''
var keyVaultKeyScopeId = scopeKind == 'keyVaultKey' ? keyVaultKeyResource.id : ''
var storageAccountScopeId = scopeKind == 'storageAccount' ? storageAccountResource.id : ''
var privateDnsZoneScopeId = scopeKind == 'privateDnsZone' ? privateDnsZoneResource.id : ''
var assignmentScopeId = scopeKind == 'resourceGroup'
  ? resourceGroupScopeId
  : scopeKind == 'keyVault'
    ? keyVaultScopeId
    : scopeKind == 'keyVaultKey'
      ? keyVaultKeyScopeId
      : scopeKind == 'storageAccount'
        ? storageAccountScopeId
        : privateDnsZoneScopeId

var roleAssignmentProperties = union({
  principalId: principalId
  principalType: principalTypeName
  roleDefinitionId: normalizedRoleDefinitionId
}, empty(condition) ? {} : {
  condition: condition
  conditionVersion: '2.0'
})

resource resourceGroupRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (scopeKind == 'resourceGroup') {
  name: guid(assignmentScopeId, principalId, normalizedRoleDefinitionId, condition)
  properties: roleAssignmentProperties
}

resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (scopeKind == 'keyVault') {
  scope: keyVaultResource
  name: guid(assignmentScopeId, principalId, normalizedRoleDefinitionId, condition)
  properties: roleAssignmentProperties
}

resource keyVaultKeyRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (scopeKind == 'keyVaultKey') {
  scope: keyVaultKeyResource
  name: guid(assignmentScopeId, principalId, normalizedRoleDefinitionId, condition)
  properties: roleAssignmentProperties
}

resource storageAccountRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (scopeKind == 'storageAccount') {
  scope: storageAccountResource
  name: guid(assignmentScopeId, principalId, normalizedRoleDefinitionId, condition)
  properties: roleAssignmentProperties
}

resource privateDnsZoneRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (scopeKind == 'privateDnsZone') {
  scope: privateDnsZoneResource
  name: guid(assignmentScopeId, principalId, normalizedRoleDefinitionId, condition)
  properties: roleAssignmentProperties
}

output roleAssignmentId string = scopeKind == 'resourceGroup'
  ? resourceGroupRoleAssignment.id
  : scopeKind == 'keyVault'
    ? keyVaultRoleAssignment.id
    : scopeKind == 'keyVaultKey'
      ? keyVaultKeyRoleAssignment.id
      : scopeKind == 'storageAccount'
        ? storageAccountRoleAssignment.id
        : privateDnsZoneRoleAssignment.id
output resolvedRoleDefinitionId string = normalizedRoleDefinitionId
output resolvedScopeId string = assignmentScopeId
