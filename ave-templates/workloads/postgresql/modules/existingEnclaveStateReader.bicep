targetScope = 'resourceGroup'

@description('Name of the existing Microsoft Mission virtual enclave.')
@minLength(1)
param enclaveName string

@description('Expected PostgreSQL delegated subnet name.')
@minLength(1)
param delegatedSubnetName string

@description('Expected private endpoint subnet name.')
@minLength(1)
param privateEndpointSubnetName string

resource enclaveResource 'Microsoft.Mission/virtualEnclaves@2026-03-01-preview' existing = {
  name: enclaveName
}

var subnetConfigurations = enclaveResource.properties.enclaveVirtualNetwork.subnetConfigurations
var delegatedSubnet = filter(
  subnetConfigurations,
  subnet => toLower(string(subnet.subnetName)) == toLower(delegatedSubnetName)
)[0]
var privateEndpointSubnet = filter(
  subnetConfigurations,
  subnet => toLower(string(subnet.subnetName)) == toLower(privateEndpointSubnetName)
)[0]

output resourceId string = enclaveResource.id
output name string = enclaveResource.name
output location string = enclaveResource.location
output communityResourceId string = string(enclaveResource.properties.communityResourceId)
output managedResourceGroupName string = string(enclaveResource.properties.managedResourceGroupName)
output vnetName string = string(enclaveResource.properties.enclaveVirtualNetwork.networkName)
output vnetResourceId string = resourceId(subscription().subscriptionId, string(enclaveResource.properties.managedResourceGroupName), 'Microsoft.Network/virtualNetworks', string(enclaveResource.properties.enclaveVirtualNetwork.networkName))
output allowSubnetCommunication bool = bool(enclaveResource.properties.enclaveVirtualNetwork.allowSubnetCommunication ?? false)
output rbacInheritance string = string(enclaveResource.properties.rbacInheritance)
output workloadResourceVisibility string = string(enclaveResource.properties.workloadResourceVisibility)
output approvalPolicies object = {
  connectionCreation: string(enclaveResource.properties.?approvalSettings.?connectionCreation.?approvalPolicy ?? '')
  connectionUpdate: string(enclaveResource.properties.?approvalSettings.?connectionUpdate.?approvalPolicy ?? '')
  enclaveEndpointUpdate: string(enclaveResource.properties.?approvalSettings.?enclaveEndpointUpdate.?approvalPolicy ?? '')
  enclaveMaintenanceMode: string(enclaveResource.properties.?approvalSettings.?enclaveMaintenanceMode.?approvalPolicy ?? '')
}
output governedServiceList array = enclaveResource.properties.?governedServiceList ?? []
output delegatedSubnet object = {
  addressPrefix: string(delegatedSubnet.addressPrefix)
  name: string(delegatedSubnet.subnetName)
  networkPrefixSize: int(delegatedSubnet.networkPrefixSize)
  networkSecurityGroupResourceId: string(delegatedSubnet.networkSecurityGroupResourceId)
  resourceId: string(delegatedSubnet.subnetResourceId)
  subnetDelegation: string(delegatedSubnet.?subnetDelegation ?? '')
}
output privateEndpointSubnet object = {
  addressPrefix: string(privateEndpointSubnet.addressPrefix)
  name: string(privateEndpointSubnet.subnetName)
  networkPrefixSize: int(privateEndpointSubnet.networkPrefixSize)
  networkSecurityGroupResourceId: string(privateEndpointSubnet.networkSecurityGroupResourceId)
  resourceId: string(privateEndpointSubnet.subnetResourceId)
  subnetDelegation: string(privateEndpointSubnet.?subnetDelegation ?? '')
}
output maintenancePrincipals array = enclaveResource.properties.?maintenanceModeConfiguration.?principals ?? []
