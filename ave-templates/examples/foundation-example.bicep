targetScope = 'subscription'

@description('Subscription-scope compile-only example for the portable Azure Enclaves common modules.')
param location string = deployment().location

@description('Resource group created for the example composition.')
param resourceGroupName string

@description('Tags shared across created resources.')
param tags object = {}

@description('Set to true to create a new Mission community. Leave false to reference an existing one in the same resource group scope.')
param createCommunity bool = false

@description('Community name used when createCommunity = true.')
param communityName string = 'contoso-ave-community'

@description('Existing community name used when createCommunity = false.')
param existingCommunityName string = 'existing-ave-community'

@description('Virtual enclave name.')
param enclaveName string = 'contoso-ave-enclave'

@description('User-assigned identity name for customer-managed encryption patterns.')
param userAssignedIdentityName string = 'contoso-ave-uai'

@description('Key Vault name.')
param keyVaultName string = 'contosoavekv001'

@description('CMK name.')
param keyName string = 'storage-cmk'

@description('Storage account name.')
param storageAccountName string = 'contosoavestorage001'

@description('Existing virtual network resource ID to link to the private DNS zones.')
param privateDnsLinkedVirtualNetworkResourceId string

@description('Existing subnet resource ID that hosts private endpoints.')
param privateEndpointSubnetResourceId string

@description('Optional Log Analytics workspace resource ID for custom Mission diagnostics.')
param customMonitoringWorkspaceResourceId string = ''

var keyVaultDnsSuffix = environment().suffixes.keyvaultDns
var storagePrivateDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'
var normalizedKeyVaultDnsSuffix = startsWith(keyVaultDnsSuffix, '.') ? substring(keyVaultDnsSuffix, 1) : keyVaultDnsSuffix
var keyVaultPrivateDnsZoneName = 'privatelink.${replace(normalizedKeyVaultDnsSuffix, 'vault.', 'vaultcore.')}'
var customMonitoringDestinations = empty(customMonitoringWorkspaceResourceId) ? [] : [
  {
    destinationType: 'CustomWorkspace'
    customWorkspaceResourceId: customMonitoringWorkspaceResourceId
    diagnosticSettingsName: 'mission-foundation'
  }
]
var communityResourceId = createCommunity ? communityModule!.outputs.resourceId : communityReferenceModule!.outputs.resourceId

module resourceGroupModule '../modules/common/resourceGroup.bicep' = {
  name: 'resourceGroup'
  params: {
    name: resourceGroupName
    location: location
    tags: tags
  }
}

module communityModule '../modules/common/missionCommunity.bicep' = if (createCommunity) {
  name: 'community'
  scope: resourceGroup(subscription().subscriptionId, resourceGroupName)
  params: {
    name: communityName
    location: location
    tags: tags
    communityFirewallSku: 'Standard'
    policyOverride: 'Enclave'
  }
  dependsOn: [
    resourceGroupModule
  ]
}

module communityReferenceModule '../modules/common/missionCommunityReference.bicep' = if (!createCommunity) {
  name: 'communityReference'
  scope: resourceGroup(subscription().subscriptionId, resourceGroupName)
  params: {
    name: existingCommunityName
  }
  dependsOn: [
    resourceGroupModule
  ]
}

module userAssignedIdentityModule '../modules/common/userAssignedIdentity.bicep' = {
  name: 'userAssignedIdentity'
  scope: resourceGroup(subscription().subscriptionId, resourceGroupName)
  params: {
    name: userAssignedIdentityName
    location: location
    tags: tags
  }
  dependsOn: [
    resourceGroupModule
  ]
}

module keyVaultModule '../modules/common/keyVault.bicep' = {
  name: 'keyVault'
  scope: resourceGroup(subscription().subscriptionId, resourceGroupName)
  params: {
    name: keyVaultName
    location: location
    skuName: 'premium'
    tags: tags
  }
  dependsOn: [
    resourceGroupModule
  ]
}

module keyVaultKeyModule '../modules/common/keyVaultKey.bicep' = {
  name: 'keyVaultKey'
  scope: resourceGroup(subscription().subscriptionId, resourceGroupName)
  params: {
    vaultName: keyVaultName
    name: keyName
  }
  dependsOn: [
    keyVaultModule
  ]
}

module storageAccountModule '../modules/common/storageAccount.bicep' = {
  name: 'storageAccount'
  scope: resourceGroup(subscription().subscriptionId, resourceGroupName)
  params: {
    name: storageAccountName
    location: location
    tags: tags
    encryption: {
      keySource: 'Microsoft.Keyvault'
      keyName: keyName
      keyVaultUri: keyVaultModule.outputs.vaultUri
      userAssignedIdentityResourceId: userAssignedIdentityModule.outputs.resourceId
    }
  }
  dependsOn: [
    keyVaultKeyModule
  ]
}

module storageKeyVaultAccessRoleAssignmentModule '../modules/common/roleAssignment.bicep' = {
  name: 'storageKeyVaultAccessRoleAssignment'
  scope: resourceGroup(subscription().subscriptionId, resourceGroupName)
  params: {
    scopeKind: 'keyVault'
    scopeName: keyVaultName
    principalId: userAssignedIdentityModule.outputs.principalId
    principalTypeName: 'ServicePrincipal'
    roleDefinitionIdOrGuid: 'e147488a-f6f5-4113-8e2d-b22465e65bf6'
  }
  dependsOn: [
    keyVaultModule
  ]
}

module keyVaultPrivateDnsZoneModule '../modules/common/privateDnsZone.bicep' = {
  name: 'keyVaultPrivateDnsZone'
  scope: resourceGroup(subscription().subscriptionId, resourceGroupName)
  params: {
    name: keyVaultPrivateDnsZoneName
    tags: tags
  }
  dependsOn: [
    resourceGroupModule
  ]
}

module keyVaultPrivateDnsLinkModule '../modules/common/privateDnsZoneVirtualNetworkLink.bicep' = {
  name: 'keyVaultPrivateDnsLink'
  scope: resourceGroup(subscription().subscriptionId, resourceGroupName)
  params: {
    zoneName: keyVaultPrivateDnsZoneName
    linkName: 'link-${uniqueString(keyVaultPrivateDnsZoneName, privateDnsLinkedVirtualNetworkResourceId)}'
    virtualNetworkResourceId: privateDnsLinkedVirtualNetworkResourceId
    tags: tags
  }
  dependsOn: [
    keyVaultPrivateDnsZoneModule
  ]
}

module storagePrivateDnsZoneModule '../modules/common/privateDnsZone.bicep' = {
  name: 'storagePrivateDnsZone'
  scope: resourceGroup(subscription().subscriptionId, resourceGroupName)
  params: {
    name: storagePrivateDnsZoneName
    tags: tags
  }
  dependsOn: [
    resourceGroupModule
  ]
}

module storagePrivateDnsLinkModule '../modules/common/privateDnsZoneVirtualNetworkLink.bicep' = {
  name: 'storagePrivateDnsLink'
  scope: resourceGroup(subscription().subscriptionId, resourceGroupName)
  params: {
    zoneName: storagePrivateDnsZoneName
    linkName: 'link-${uniqueString(storagePrivateDnsZoneName, privateDnsLinkedVirtualNetworkResourceId)}'
    virtualNetworkResourceId: privateDnsLinkedVirtualNetworkResourceId
    tags: tags
  }
  dependsOn: [
    storagePrivateDnsZoneModule
  ]
}

module keyVaultPrivateEndpointModule '../modules/common/privateEndpoint.bicep' = {
  name: 'keyVaultPrivateEndpoint'
  scope: resourceGroup(subscription().subscriptionId, resourceGroupName)
  params: {
    name: '${keyVaultName}-pe'
    location: location
    subnetResourceId: privateEndpointSubnetResourceId
    privateLinkConnection: {
      approvalMode: 'Auto'
      groupIds: [
        'vault'
      ]
      name: '${keyVaultName}-vault'
      privateLinkServiceResourceId: keyVaultModule.outputs.resourceId
    }
    privateDnsZones: [
      {
        name: keyVaultPrivateDnsZoneName
        privateDnsZoneResourceId: keyVaultPrivateDnsZoneModule.outputs.resourceId
      }
    ]
    tags: tags
  }
}

module storagePrivateEndpointModule '../modules/common/privateEndpoint.bicep' = {
  name: 'storagePrivateEndpoint'
  scope: resourceGroup(subscription().subscriptionId, resourceGroupName)
  params: {
    name: '${storageAccountName}-pe'
    location: location
    subnetResourceId: privateEndpointSubnetResourceId
    privateLinkConnection: {
      approvalMode: 'Auto'
      groupIds: [
        'blob'
      ]
      name: '${storageAccountName}-blob'
      privateLinkServiceResourceId: storageAccountModule.outputs.resourceId
    }
    privateDnsZones: [
      {
        name: storagePrivateDnsZoneName
        privateDnsZoneResourceId: storagePrivateDnsZoneModule.outputs.resourceId
      }
    ]
    tags: tags
  }
}

module virtualEnclaveModule '../modules/common/missionVirtualEnclave.bicep' = {
  name: 'virtualEnclave'
  scope: resourceGroup(subscription().subscriptionId, resourceGroupName)
  params: {
    name: enclaveName
    location: location
    communityResourceId: communityResourceId
    identityType: 'UserAssigned'
    userAssignedIdentityResourceIds: [
      userAssignedIdentityModule.outputs.resourceId
    ]
    tags: tags
    bastionEnabled: false
    rbacInheritance: 'Disabled'
    workloadResourceVisibility: 'Disabled'
    enclaveDefaultSettings: {
      diagnosticDestination: 'EnclaveOnly'
    }
    governedServiceList: [
      {
        enforcement: 'Enabled'
        option: 'Allow'
        policyAction: 'Enforce'
        serviceId: 'KeyVault'
      }
      {
        enforcement: 'Enabled'
        option: 'Allow'
        policyAction: 'Enforce'
        serviceId: 'Storage'
      }
    ]
    approvalSettings: {
      connectionCreation: {
        approvalPolicy: 'Required'
        minimumApproversRequired: 1
      }
      connectionUpdate: {
        approvalPolicy: 'Required'
        minimumApproversRequired: 1
      }
      enclaveEndpointUpdate: {
        approvalPolicy: 'Required'
        minimumApproversRequired: 1
      }
      enclaveMaintenanceMode: {
        approvalPolicy: 'Required'
        minimumApproversRequired: 1
      }
    }
    monitoringSettings: {
      diagnosticDestinations: customMonitoringDestinations
    }
    networkConfiguration: {
      mode: 'CustomCidr'
      customCidrRange: '10.250.0.0/16'
      allowSubnetCommunication: false
      subnetConfigurations: [
        {
          subnetName: 'control'
          networkPrefixSize: 24
        }
        {
          subnetName: 'workload'
          networkPrefixSize: 24
        }
      ]
    }
  }
}

output communityResourceId string = communityResourceId
output virtualEnclaveResourceId string = virtualEnclaveModule.outputs.resourceId
output keyVaultResourceId string = keyVaultModule.outputs.resourceId
output keyVaultKeyUri string = keyVaultKeyModule.outputs.versionlessKeyUri
output storageAccountResourceId string = storageAccountModule.outputs.resourceId
output storageKeyVaultRoleAssignmentId string = storageKeyVaultAccessRoleAssignmentModule.outputs.roleAssignmentId
output keyVaultPrivateEndpointId string = keyVaultPrivateEndpointModule.outputs.resourceId
output storagePrivateEndpointId string = storagePrivateEndpointModule.outputs.resourceId
