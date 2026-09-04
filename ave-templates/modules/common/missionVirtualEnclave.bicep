targetScope = 'resourceGroup'

// ──────────────────────────────────────────────────────────────────────────────
// Single `Microsoft.Mission/virtualEnclaves@2026-03-01-preview` upsert surface.
//
// ARM PUT is idempotent, so creating a new enclave and additively updating an
// existing one are the same operation: the caller resolves the complete
// writable contract (carrying live values forward for an existing enclave,
// supplying defaults for a new one) and this module issues exactly one PUT.
//
// Carry-forward inputs are intentionally loosely typed (`object`/`array`).
// They are frequently populated from a live-state read whose values are only
// known at deployment time, so compile-time shape assertions would be
// meaningless. Customer-authored shapes are validated by the entry-point
// template's parameter types instead.
// ──────────────────────────────────────────────────────────────────────────────

@description('Virtual enclave resource name.')
@minLength(1)
param name string

@description('Azure region for the virtual enclave. Carried forward from live state when the enclave already exists.')
@minLength(1)
param location string

@description('Tags applied to the enclave.')
param tags object = {}

@description('Managed identity type. The current Mission API contract supports only None; live values are carried forward verbatim.')
param identityType string = 'None'

@description('Parent community resource ID.')
@minLength(1)
param communityResourceId string

@description('Normalized approval settings for all four Mission approval gates.')
param approvalSettings object

@description('Whether Mission enables Bastion for the enclave.')
param bastionEnabled bool = true

@description('Default diagnostic destination setting.')
param diagnosticDestination string = 'Both'

@description('Whether Mission permits subnet-to-subnet communication inside the enclave virtual network.')
param allowSubnetCommunication bool = true

@description('Custom CIDR range for the enclave virtual network. Supply for CustomCidr enclaves; leave empty to fall back to networkSize.')
param customCidrRange string = ''

@description('Managed network size for the enclave virtual network. Ignored when customCidrRange is supplied.')
param networkSize string = ''

@description('Enclave virtual network name. Carried forward from live state; leave empty to let Mission generate it.')
param networkName string = ''

@description('Complete resolved subnet contract (live subnets carried forward, unioned by name with this workload\'s requests).')
param subnetConfigurations array

@description('Complete resolved governed-service list.')
param governedServiceList array = []

@description('Complete resolved maintenance mode configuration, including the unioned principal set.')
param maintenanceModeConfiguration object = {}

@description('Monitoring settings carried forward from live state.')
param monitoringSettings object = {}

@description('Dedicated hub resource ID carried forward from live state.')
param dedicatedHubResourceId string = ''

@description('Complete resolved enclave-scope Mission RBAC assignments.')
param enclaveRoleAssignments array = []

@description('Complete resolved workload-scope Mission RBAC assignments.')
param workloadRoleAssignments array = []

@description('Whether Azure RBAC inheritance remains enabled for workload resource groups.')
param rbacInheritance string = 'Disabled'

@description('Whether workload resources remain visible through standard Azure RBAC.')
param workloadResourceVisibility string = 'Disabled'

var enclaveVirtualNetwork = union({
  allowSubnetCommunication: allowSubnetCommunication
  subnetConfigurations: subnetConfigurations
}, empty(customCidrRange)
  ? (empty(networkSize) ? {} : {
      networkSize: networkSize
    })
  : {
      customCidrRange: customCidrRange
      networkSize: 'custom'
    }, empty(networkName) ? {} : {
  networkName: networkName
})

resource virtualEnclaveResource 'Microsoft.Mission/virtualEnclaves@2026-03-01-preview' = {
  name: name
  location: location
  identity: {
    type: identityType
  }
  tags: tags
  properties: union({
    approvalSettings: approvalSettings
    bastionEnabled: bastionEnabled
    communityResourceId: communityResourceId
    enclaveDefaultSettings: {
      diagnosticDestination: diagnosticDestination
    }
    enclaveVirtualNetwork: enclaveVirtualNetwork
    rbacInheritance: rbacInheritance
    workloadResourceVisibility: workloadResourceVisibility
  }, empty(dedicatedHubResourceId) ? {} : {
    dedicatedHubResourceId: dedicatedHubResourceId
  }, length(enclaveRoleAssignments) == 0 ? {} : {
    enclaveRoleAssignments: enclaveRoleAssignments
  }, length(governedServiceList) == 0 ? {} : {
    governedServiceList: governedServiceList
  }, empty(maintenanceModeConfiguration) ? {} : {
    maintenanceModeConfiguration: maintenanceModeConfiguration
  }, empty(monitoringSettings) ? {} : {
    monitoringSettings: monitoringSettings
  }, length(workloadRoleAssignments) == 0 ? {} : {
    workloadRoleAssignments: workloadRoleAssignments
  })
}

output resourceId string = virtualEnclaveResource.id
output resourceName string = virtualEnclaveResource.name
output resourceLocation string = virtualEnclaveResource.location
output effectiveIdentityType string = identityType
output managedResourceGroupName string = string(virtualEnclaveResource.properties.managedResourceGroupName)
output enclaveVnetName string = string(virtualEnclaveResource.properties.enclaveVirtualNetwork.networkName)
output enclaveVnetResourceId string = resourceId(subscription().subscriptionId, string(virtualEnclaveResource.properties.managedResourceGroupName), 'Microsoft.Network/virtualNetworks', string(virtualEnclaveResource.properties.enclaveVirtualNetwork.networkName))
output subnetConfigurations array = virtualEnclaveResource.properties.enclaveVirtualNetwork.subnetConfigurations
