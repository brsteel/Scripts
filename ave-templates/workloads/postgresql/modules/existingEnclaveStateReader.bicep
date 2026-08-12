targetScope = 'resourceGroup'

// ──────────────────────────────────────────────────────────────────────────────
// Reads the live, writable contract of an existing Microsoft Mission virtual
// enclave so the caller can carry it forward unchanged through the single
// enclave upsert path.
//
// This module never asserts an "expected configuration". Immutable and
// caller-irrelevant enclave properties are read and reused as-is; additive
// collections (subnets, Mission role assignments, maintenance principals,
// governed services) are returned as the base that the caller unions its own
// requests into.
//
// The module is only instantiated when an enclave resource ID was supplied.
// When a new enclave is being created the caller substitutes empty bases, so
// there is nothing to union and the same downstream expressions apply.
// ──────────────────────────────────────────────────────────────────────────────

@description('Name of the existing Microsoft Mission virtual enclave.')
@minLength(1)
param enclaveName string

resource enclaveResource 'Microsoft.Mission/virtualEnclaves@2026-03-01-preview' existing = {
  name: enclaveName
}

var liveProperties = enclaveResource.properties
var liveEnclaveVirtualNetwork = liveProperties.enclaveVirtualNetwork
var liveSubnetConfigurations = liveEnclaveVirtualNetwork.subnetConfigurations
var liveMaintenanceModeConfiguration = liveProperties.?maintenanceModeConfiguration ?? {}

// Mission returns read-only projections (addressPrefix, subnetResourceId,
// networkSecurityGroupResourceId) alongside the writable subnet contract. Only
// the writable triple may be sent back on a PUT.
var normalizedSubnetConfigurations = map(liveSubnetConfigurations, subnet => union({
  networkPrefixSize: int(subnet.networkPrefixSize)
  subnetName: string(subnet.subnetName)
}, empty(string(subnet.?subnetDelegation ?? '')) ? {} : {
  subnetDelegation: string(subnet.subnetDelegation)
}))

var normalizedApprovalSettings = {
  connectionCreation: string(liveProperties.?approvalSettings.?connectionCreation.?approvalPolicy ?? 'NotRequired') == 'Required'
    ? {
        approvalPolicy: 'Required'
        mandatoryApprovers: liveProperties.?approvalSettings.?connectionCreation.?mandatoryApprovers ?? []
        minimumApproversRequired: int(liveProperties.?approvalSettings.?connectionCreation.?minimumApproversRequired ?? 0)
      }
    : {
        approvalPolicy: 'NotRequired'
        mandatoryApprovers: []
        minimumApproversRequired: 0
      }
  connectionUpdate: string(liveProperties.?approvalSettings.?connectionUpdate.?approvalPolicy ?? 'NotRequired') == 'Required'
    ? {
        approvalPolicy: 'Required'
        mandatoryApprovers: liveProperties.?approvalSettings.?connectionUpdate.?mandatoryApprovers ?? []
        minimumApproversRequired: int(liveProperties.?approvalSettings.?connectionUpdate.?minimumApproversRequired ?? 0)
      }
    : {
        approvalPolicy: 'NotRequired'
        mandatoryApprovers: []
        minimumApproversRequired: 0
      }
  enclaveEndpointUpdate: string(liveProperties.?approvalSettings.?enclaveEndpointUpdate.?approvalPolicy ?? 'NotRequired') == 'Required'
    ? {
        approvalPolicy: 'Required'
        mandatoryApprovers: liveProperties.?approvalSettings.?enclaveEndpointUpdate.?mandatoryApprovers ?? []
        minimumApproversRequired: int(liveProperties.?approvalSettings.?enclaveEndpointUpdate.?minimumApproversRequired ?? 0)
      }
    : {
        approvalPolicy: 'NotRequired'
        mandatoryApprovers: []
        minimumApproversRequired: 0
      }
  enclaveMaintenanceMode: string(liveProperties.?approvalSettings.?enclaveMaintenanceMode.?approvalPolicy ?? 'NotRequired') == 'Required'
    ? {
        approvalPolicy: 'Required'
        mandatoryApprovers: liveProperties.?approvalSettings.?enclaveMaintenanceMode.?mandatoryApprovers ?? []
        minimumApproversRequired: int(liveProperties.?approvalSettings.?enclaveMaintenanceMode.?minimumApproversRequired ?? 0)
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
output tags object = enclaveResource.?tags ?? {}
output identityType string = string(enclaveResource.?identity.?type ?? 'None')
output communityResourceId string = string(liveProperties.communityResourceId)
output managedResourceGroupName string = string(liveProperties.managedResourceGroupName)
output vnetName string = string(liveEnclaveVirtualNetwork.networkName)
output vnetResourceId string = resourceId(subscription().subscriptionId, string(liveProperties.managedResourceGroupName), 'Microsoft.Network/virtualNetworks', string(liveEnclaveVirtualNetwork.networkName))

output networkName string = string(liveEnclaveVirtualNetwork.?networkName ?? '')
output customCidrRange string = string(liveEnclaveVirtualNetwork.?customCidrRange ?? '')
output networkSize string = string(liveEnclaveVirtualNetwork.?networkSize ?? '')
output allowSubnetCommunication bool = bool(liveEnclaveVirtualNetwork.?allowSubnetCommunication ?? true)
output subnetConfigurations array = normalizedSubnetConfigurations

output bastionEnabled bool = bool(liveProperties.?bastionEnabled ?? true)
output diagnosticDestination string = string(liveProperties.?enclaveDefaultSettings.?diagnosticDestination ?? 'Both')
output rbacInheritance string = string(liveProperties.?rbacInheritance ?? 'Disabled')
output workloadResourceVisibility string = string(liveProperties.?workloadResourceVisibility ?? 'Disabled')
output dedicatedHubResourceId string = string(liveProperties.?dedicatedHubResourceId ?? '')
output monitoringSettings object = liveProperties.?monitoringSettings ?? {}
output approvalSettings object = normalizedApprovalSettings
output governedServiceList array = liveProperties.?governedServiceList ?? []
output enclaveRoleAssignments array = liveProperties.?enclaveRoleAssignments ?? []
output workloadRoleAssignments array = liveProperties.?workloadRoleAssignments ?? []
output maintenancePrincipals array = liveMaintenanceModeConfiguration.?principals ?? []
output maintenanceJustification string = string(liveMaintenanceModeConfiguration.?justification ?? 'Governance')
output maintenanceMode string = string(liveMaintenanceModeConfiguration.?mode ?? 'Advanced')
