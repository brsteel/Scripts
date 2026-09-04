targetScope = 'resourceGroup'

type missionIdentityType = 'None' | 'SystemAssigned' | 'SystemAssigned,UserAssigned' | 'UserAssigned'
type approvalPolicy = 'NotRequired' | 'Required'
type firewallSku = 'Basic' | 'Premium' | 'Standard'
type governanceEnforcement = 'Disabled' | 'Enabled'
type governanceOption = 'Allow' | 'Deny' | 'ExceptionOnly' | 'NotApplicable'
type maintenanceJustification = 'Governance' | 'Networking' | 'Off'
type maintenanceMode = 'Advanced' | 'CanNotDelete' | 'General' | 'Off' | 'On'
type monitoringDestinationType = 'CommunityWorkspace' | 'CustomWorkspace' | 'EnclaveWorkspace'
type policyOverrideType = 'Enclave' | 'None'
type principalType = 'Group' | 'ServicePrincipal' | 'User'
type governedServiceId = 'AKS' | 'AppService' | 'AzureFirewalls' | 'ContainerRegistry' | 'CosmosDB' | 'DataConnectors' | 'Insights' | 'KeyVault' | 'Logic' | 'MicrosoftSQL' | 'Monitoring' | 'PostgreSQL' | 'PrivateDNSZones' | 'ServiceBus' | 'Storage'

@sealed()
type mandatoryApprover = {
  approverEntraId: string
}

@sealed()
type approvalSettingConfiguration = {
  approvalPolicy: approvalPolicy
  mandatoryApprovers: mandatoryApprover[]?
  @minValue(0)
  minimumApproversRequired: int?
}

@sealed()
type principal = {
  id: string
  type: principalType
}

@sealed()
type roleAssignmentItem = {
  principals: principal[]
  roleDefinitionId: string
  condition: string?
}

@sealed()
type governedServiceItem = {
  enforcement: governanceEnforcement
  option: governanceOption
  policyAction: 'AuditOnly' | 'Enforce' | 'None'
  serviceId: governedServiceId
}

@sealed()
type maintenanceModeConfigurationModel = {
  justification: maintenanceJustification
  mode: maintenanceMode
  principals: principal[]?
}

@sealed()
type monitoringDestination = {
  destinationType: monitoringDestinationType
  customWorkspaceResourceId: string?
  diagnosticSettingsName: string?
}

@sealed()
type monitoringSettingsModel = {
  diagnosticDestinations: monitoringDestination[]?
  flowLogDestination: monitoringDestination?
}

@sealed()
type approvalSettingsModel = {
  communityEndpointUpdate: approvalSettingConfiguration?
  communityMaintenanceMode: approvalSettingConfiguration?
  connectionCreation: approvalSettingConfiguration?
  connectionUpdate: approvalSettingConfiguration?
  enclaveCreation: approvalSettingConfiguration?
  enclaveEndpointUpdate: approvalSettingConfiguration?
  enclaveMaintenanceMode: approvalSettingConfiguration?
}

@description('Community resource name.')
param name string

@description('Azure region for the community.')
param location string

@description('Community tags.')
param tags object = {}

@description('Managed identity type for the community.')
param identityType missionIdentityType = 'None'

@description('User-assigned identity resource IDs when identityType includes UserAssigned.')
param userAssignedIdentityResourceIds string[] = []

@description('Single community address space.')
param addressSpace string = ''

@description('Community address spaces.')
param addressSpaces string[] = []

@description('Granular approval settings.')
param approvalSettings approvalSettingsModel?

@description('Community role assignments.')
param communityRoleAssignments roleAssignmentItem[] = []

@description('Community DNS servers.')
param dnsServers string[] = []

@description('Firewall SKU for the community.')
param communityFirewallSku firewallSku?

@description('Governed services attached to the community.')
param governedServiceList governedServiceItem[] = []

@description('Maintenance mode configuration for the community.')
param maintenanceModeConfiguration maintenanceModeConfigurationModel?

@description('Monitoring settings for diagnostics and flow logs.')
param monitoringSettings monitoringSettingsModel?

@description('Policy override mode.')
param policyOverride policyOverrideType?

var usesUserAssignedIdentity = contains([
  'SystemAssigned,UserAssigned'
  'UserAssigned'
], identityType)

var userAssignedIdentityMap = toObject(userAssignedIdentityResourceIds, identityResourceId => identityResourceId, _ => {})

resource communityResource 'Microsoft.Mission/communities@2026-03-01-preview' = {
  name: name
  location: location
  identity: union({
    type: identityType
  }, usesUserAssignedIdentity ? {
    userAssignedIdentities: userAssignedIdentityMap
  } : {})
  tags: tags
  properties: union({}, empty(addressSpace) ? {} : {
    addressSpace: addressSpace
  }, length(addressSpaces) == 0 ? {} : {
    addressSpaces: addressSpaces
  }, approvalSettings == null ? {} : {
    approvalSettings: approvalSettings
  }, length(communityRoleAssignments) == 0 ? {} : {
    communityRoleAssignments: communityRoleAssignments
  }, length(dnsServers) == 0 ? {} : {
    dnsServers: dnsServers
  }, communityFirewallSku == null ? {} : {
    firewallSku: communityFirewallSku
  }, length(governedServiceList) == 0 ? {} : {
    governedServiceList: governedServiceList
  }, maintenanceModeConfiguration == null ? {} : {
    maintenanceModeConfiguration: maintenanceModeConfiguration
  }, monitoringSettings == null ? {} : {
    monitoringSettings: monitoringSettings
  }, policyOverride == null ? {} : {
    policyOverride: policyOverride
  })
}

output resourceId string = communityResource.id
output resourceName string = communityResource.name
output resourceLocation string = communityResource.location
