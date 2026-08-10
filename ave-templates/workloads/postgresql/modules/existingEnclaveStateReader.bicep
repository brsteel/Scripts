targetScope = 'resourceGroup'

@description('Name of the existing Microsoft Mission virtual enclave.')
@minLength(1)
param enclaveName string

@description('Expected PostgreSQL subnet name. Leave empty when the additive-update flow will create the subnet during this deployment.')
param postgreSqlSubnetName string = ''

@description('Expected private endpoint subnet name. Leave empty when the additive-update flow will create the subnet during this deployment.')
param privateEndpointSubnetName string = ''

resource enclaveResource 'Microsoft.Mission/virtualEnclaves@2026-03-01-preview' existing = {
  name: enclaveName
}

var subnetConfigurations = enclaveResource.properties.enclaveVirtualNetwork.subnetConfigurations
var postgreSqlSubnetMatches = empty(postgreSqlSubnetName) ? [] : filter(
  subnetConfigurations,
  subnet => toLower(string(subnet.subnetName)) == toLower(postgreSqlSubnetName)
)
var privateEndpointSubnetMatches = empty(privateEndpointSubnetName) ? [] : filter(
  subnetConfigurations,
  subnet => toLower(string(subnet.subnetName)) == toLower(privateEndpointSubnetName)
)
var normalizedApprovalSettings = {
  connectionCreation: string(enclaveResource.properties.?approvalSettings.?connectionCreation.?approvalPolicy ?? 'NotRequired') == 'Required'
    ? {
        approvalPolicy: 'Required'
        mandatoryApprovers: enclaveResource.properties.?approvalSettings.?connectionCreation.?mandatoryApprovers ?? []
        minimumApproversRequired: int(enclaveResource.properties.?approvalSettings.?connectionCreation.?minimumApproversRequired ?? 0)
      }
    : {
        approvalPolicy: 'NotRequired'
        mandatoryApprovers: []
        minimumApproversRequired: 0
      }
  connectionUpdate: string(enclaveResource.properties.?approvalSettings.?connectionUpdate.?approvalPolicy ?? 'NotRequired') == 'Required'
    ? {
        approvalPolicy: 'Required'
        mandatoryApprovers: enclaveResource.properties.?approvalSettings.?connectionUpdate.?mandatoryApprovers ?? []
        minimumApproversRequired: int(enclaveResource.properties.?approvalSettings.?connectionUpdate.?minimumApproversRequired ?? 0)
      }
    : {
        approvalPolicy: 'NotRequired'
        mandatoryApprovers: []
        minimumApproversRequired: 0
      }
  enclaveEndpointUpdate: string(enclaveResource.properties.?approvalSettings.?enclaveEndpointUpdate.?approvalPolicy ?? 'NotRequired') == 'Required'
    ? {
        approvalPolicy: 'Required'
        mandatoryApprovers: enclaveResource.properties.?approvalSettings.?enclaveEndpointUpdate.?mandatoryApprovers ?? []
        minimumApproversRequired: int(enclaveResource.properties.?approvalSettings.?enclaveEndpointUpdate.?minimumApproversRequired ?? 0)
      }
    : {
        approvalPolicy: 'NotRequired'
        mandatoryApprovers: []
        minimumApproversRequired: 0
      }
  enclaveMaintenanceMode: string(enclaveResource.properties.?approvalSettings.?enclaveMaintenanceMode.?approvalPolicy ?? 'NotRequired') == 'Required'
    ? {
        approvalPolicy: 'Required'
        mandatoryApprovers: enclaveResource.properties.?approvalSettings.?enclaveMaintenanceMode.?mandatoryApprovers ?? []
        minimumApproversRequired: int(enclaveResource.properties.?approvalSettings.?enclaveMaintenanceMode.?minimumApproversRequired ?? 0)
      }
    : {
        approvalPolicy: 'NotRequired'
        mandatoryApprovers: []
        minimumApproversRequired: 0
      }
}

output resourceId string = enclaveResource.id
output name string = enclaveResource.name
output location string = enclaveResource.location
output communityResourceId string = string(enclaveResource.properties.communityResourceId)
output managedResourceGroupName string = string(enclaveResource.properties.managedResourceGroupName)
output vnetName string = string(enclaveResource.properties.enclaveVirtualNetwork.networkName)
output vnetResourceId string = resourceId(subscription().subscriptionId, string(enclaveResource.properties.managedResourceGroupName), 'Microsoft.Network/virtualNetworks', string(enclaveResource.properties.enclaveVirtualNetwork.networkName))
output hasExplicitAllowSubnetCommunication bool = contains(enclaveResource.properties.enclaveVirtualNetwork, 'allowSubnetCommunication')
output allowSubnetCommunication bool = bool(enclaveResource.properties.enclaveVirtualNetwork.allowSubnetCommunication ?? true)
output hasExplicitBastionEnabled bool = contains(enclaveResource.properties, 'bastionEnabled')
output bastionEnabled bool = bool(enclaveResource.properties.?bastionEnabled ?? true)
output hasExplicitDiagnosticDestination bool = contains(enclaveResource.properties, 'enclaveDefaultSettings') && contains(enclaveResource.properties.enclaveDefaultSettings, 'diagnosticDestination')
output diagnosticDestination string = string(enclaveResource.properties.?enclaveDefaultSettings.?diagnosticDestination ?? 'Both')
output rbacInheritance string = string(enclaveResource.properties.rbacInheritance)
output workloadResourceVisibility string = string(enclaveResource.properties.workloadResourceVisibility)
output approvalSettings object = normalizedApprovalSettings
output governedServiceList array = enclaveResource.properties.?governedServiceList ?? []
output subnetConfigurations array = subnetConfigurations
output postgreSqlSubnet object = length(postgreSqlSubnetMatches) == 0 ? {
  addressPrefix: ''
  name: ''
  networkPrefixSize: 0
  networkSecurityGroupResourceId: ''
  resourceId: ''
  subnetDelegation: ''
} : {
  addressPrefix: string(postgreSqlSubnetMatches[0].addressPrefix)
  name: string(postgreSqlSubnetMatches[0].subnetName)
  networkPrefixSize: int(postgreSqlSubnetMatches[0].networkPrefixSize)
  networkSecurityGroupResourceId: string(postgreSqlSubnetMatches[0].networkSecurityGroupResourceId)
  resourceId: string(postgreSqlSubnetMatches[0].subnetResourceId)
  subnetDelegation: string(postgreSqlSubnetMatches[0].?subnetDelegation ?? '')
}
output privateEndpointSubnet object = length(privateEndpointSubnetMatches) == 0 ? {
  addressPrefix: ''
  name: ''
  networkPrefixSize: 0
  networkSecurityGroupResourceId: ''
  resourceId: ''
  subnetDelegation: ''
} : {
  addressPrefix: string(privateEndpointSubnetMatches[0].addressPrefix)
  name: string(privateEndpointSubnetMatches[0].subnetName)
  networkPrefixSize: int(privateEndpointSubnetMatches[0].networkPrefixSize)
  networkSecurityGroupResourceId: string(privateEndpointSubnetMatches[0].networkSecurityGroupResourceId)
  resourceId: string(privateEndpointSubnetMatches[0].subnetResourceId)
  subnetDelegation: string(privateEndpointSubnetMatches[0].?subnetDelegation ?? '')
}
output maintenancePrincipals array = enclaveResource.properties.?maintenanceModeConfiguration.?principals ?? []
