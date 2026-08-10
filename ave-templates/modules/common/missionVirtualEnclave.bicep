targetScope = 'resourceGroup'

type approvalPolicy = 'NotRequired' | 'Required'
type diagnosticDestination = 'Both' | 'CommunityOnly' | 'EnclaveOnly'
type governedServiceEnforcement = 'Disabled' | 'Enabled'
type governedServiceOption = 'Allow' | 'Deny' | 'ExceptionOnly' | 'NotApplicable'
type governedServiceId = 'AKS' | 'AppService' | 'AzureFirewalls' | 'ContainerRegistry' | 'CosmosDB' | 'DataConnectors' | 'Insights' | 'KeyVault' | 'Logic' | 'MicrosoftSQL' | 'Monitoring' | 'PostgreSQL' | 'PrivateDNSZones' | 'ServiceBus' | 'Storage'
type maintenanceJustification = 'Governance' | 'Networking' | 'Off'
type maintenanceMode = 'Advanced' | 'CanNotDelete' | 'General' | 'Off' | 'On'
type missionIdentityType = 'None' | 'SystemAssigned' | 'SystemAssigned,UserAssigned' | 'UserAssigned'
type monitoringDestinationType = 'CommunityWorkspace' | 'CustomWorkspace' | 'EnclaveWorkspace'
type principalType = 'Group' | 'ServicePrincipal' | 'User'
type toggleState = 'Disabled' | 'Enabled'

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
type subnetConfiguration = {
  subnetName: string
  networkPrefixSize: int
  subnetDelegation: string?
}

type customCidrNetworkConfiguration = {
  mode: 'CustomCidr'
  customCidrRange: string
  subnetConfigurations: subnetConfiguration[]
  allowSubnetCommunication: bool?
  networkName: string?
}

@sealed()
type managedSizeNetworkConfiguration = {
  mode: 'ManagedSize'
  networkSize: string
  subnetConfigurations: subnetConfiguration[]
  allowSubnetCommunication: bool?
  networkName: string?
}

@sealed()
@discriminator('mode')
type missionVirtualNetworkConfiguration = customCidrNetworkConfiguration | managedSizeNetworkConfiguration

@sealed()
type governedServiceItem = {
  enforcement: governedServiceEnforcement
  option: governedServiceOption
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
type enclaveDefaultSettingsModel = {
  diagnosticDestination: diagnosticDestination
}

@sealed()
type virtualEnclaveApprovalSettings = {
  connectionCreation: approvalSettingConfiguration?
  connectionUpdate: approvalSettingConfiguration?
  enclaveEndpointUpdate: approvalSettingConfiguration?
  enclaveMaintenanceMode: approvalSettingConfiguration?
}

@description('Virtual enclave resource name.')
param name string

@description('Azure region for the virtual enclave.')
param location string

@description('Parent community resource ID.')
param communityResourceId string

@description('Strongly typed enclave virtual network configuration.')
param networkConfiguration missionVirtualNetworkConfiguration

@description('Managed identity type for the enclave.')
param identityType missionIdentityType = 'SystemAssigned'

@description('User-assigned identity resource IDs when identityType includes UserAssigned.')
param userAssignedIdentityResourceIds string[] = []

@description('Tags applied to the enclave.')
param tags object = {}

@description('Whether Mission should enable Bastion for the enclave.')
param bastionEnabled bool = false

@description('Optional dedicated hub resource ID.')
param dedicatedHubResourceId string = ''

@description('Optional default diagnostic destination setting.')
param enclaveDefaultSettings enclaveDefaultSettingsModel?

@description('Optional approval settings.')
param approvalSettings virtualEnclaveApprovalSettings?

@description('Optional governed services.')
param governedServiceList governedServiceItem[] = []

@description('Optional maintenance mode configuration.')
param maintenanceModeConfiguration maintenanceModeConfigurationModel?

@description('Optional monitoring settings for diagnostics and flow logs.')
param monitoringSettings monitoringSettingsModel?

@description('Whether Azure RBAC inheritance remains enabled for workload resource groups.')
param rbacInheritance toggleState = 'Disabled'

@description('Whether workload resources remain visible through standard Azure RBAC.')
param workloadResourceVisibility toggleState = 'Disabled'

@description('Enclave-scope Mission RBAC assignments.')
param enclaveRoleAssignments roleAssignmentItem[] = []

@description('Workload-scope Mission RBAC assignments.')
param workloadRoleAssignments roleAssignmentItem[] = []

var usesUserAssignedIdentity = contains([
  'SystemAssigned,UserAssigned'
  'UserAssigned'
], identityType)

var userAssignedIdentityMap = toObject(userAssignedIdentityResourceIds, identityResourceId => identityResourceId, _ => {})

var subnetConfigurations = [for subnet in networkConfiguration.subnetConfigurations: union({
  networkPrefixSize: subnet.networkPrefixSize
  subnetName: subnet.subnetName
}, empty(subnet.subnetDelegation ?? '') ? {} : {
  subnetDelegation: subnet.subnetDelegation
})]

var enclaveVirtualNetwork = union({
  allowSubnetCommunication: networkConfiguration.allowSubnetCommunication ?? false
  subnetConfigurations: subnetConfigurations
}, networkConfiguration.mode == 'CustomCidr' ? {
  customCidrRange: networkConfiguration.customCidrRange
  networkSize: 'custom'
} : {
  networkSize: networkConfiguration.networkSize
}, empty(networkConfiguration.networkName ?? '') ? {} : {
  networkName: networkConfiguration.networkName
})

resource virtualEnclaveResource 'Microsoft.Mission/virtualEnclaves@2026-03-01-preview' = {
  name: name
  location: location
  identity: union({
    type: identityType
  }, usesUserAssignedIdentity ? {
    userAssignedIdentities: userAssignedIdentityMap
  } : {})
  tags: tags
  properties: union({
    bastionEnabled: bastionEnabled
    communityResourceId: communityResourceId
    enclaveVirtualNetwork: enclaveVirtualNetwork
    rbacInheritance: rbacInheritance
    workloadResourceVisibility: workloadResourceVisibility
  }, empty(dedicatedHubResourceId) ? {} : {
    dedicatedHubResourceId: dedicatedHubResourceId
  }, enclaveDefaultSettings == null ? {} : {
    enclaveDefaultSettings: enclaveDefaultSettings
  }, approvalSettings == null ? {} : {
    approvalSettings: approvalSettings
  }, length(enclaveRoleAssignments) == 0 ? {} : {
    enclaveRoleAssignments: enclaveRoleAssignments
  }, length(governedServiceList) == 0 ? {} : {
    governedServiceList: governedServiceList
  }, maintenanceModeConfiguration == null ? {} : {
    maintenanceModeConfiguration: maintenanceModeConfiguration
  }, monitoringSettings == null ? {} : {
    monitoringSettings: monitoringSettings
  }, length(workloadRoleAssignments) == 0 ? {} : {
    workloadRoleAssignments: workloadRoleAssignments
  })
}

output resourceId string = virtualEnclaveResource.id
output resourceName string = virtualEnclaveResource.name
output resourceLocation string = virtualEnclaveResource.location
output effectiveIdentityType string = identityType
