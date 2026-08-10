// ──────────────────────────────────────────────────────────────────────────────
// Scenario: Existing Compatible / Reference-Only — existing enclave and community,
// reference-only network finalization, existing PostgreSQL Flexible Server.
//
// Deploy with:
//   az deployment sub create \
//     --location <region> \
//     --parameters ave-templates/workloads/postgresql/examples/postgresql-existing-compatible.bicepparam
//
// Replace every placeholder value (resource IDs, CIDRs, object IDs) before
// deploying. Do not edit avePostgreSql.bicep.
// ──────────────────────────────────────────────────────────────────────────────

using '../avePostgreSql.bicep'

param deploymentContext = {
  tags: {
    environment: 'production'
    workload: 'postgresql-existing'
  }
}

param deploymentPrincipal = {
  objectId: '11111111-1111-1111-1111-111111111111' // ← replace
  principalType: 'User'
}

// ─── Community ────────────────────────────────────────────────────────────────
// Existing community: supply the full resource ID.
param community = {
  mode: 'existing'
  resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-community/providers/Microsoft.Mission/communities/existing-community' // ← replace
}

// ─── Enclave ──────────────────────────────────────────────────────────────────
// ReferenceOnly: the deployment reads and validates the live enclave state but
// does not modify it. The expectedConfiguration must match the live state exactly
// (approval policies, subnet details, location, governed services, etc.).
param enclave = {
  mode: 'ReferenceOnly'
  resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-enclave/providers/Microsoft.Mission/virtualEnclaves/existing-enclave' // ← replace
  expectedConfiguration: {
    approvalSettings: {
      connectionCreation: {
        approvalPolicy: 'Required'
        mandatoryApprovers: [
          {
            approverEntraId: '55555555-5555-5555-5555-555555555555' // ← replace
          }
        ]
        minimumApproversRequired: 1
      }
      connectionUpdate: {
        approvalPolicy: 'Required'
        mandatoryApprovers: [
          {
            approverEntraId: '66666666-6666-6666-6666-666666666666' // ← replace
          }
        ]
        minimumApproversRequired: 1
      }
      enclaveEndpointUpdate: {
        approvalPolicy: 'Required'
        mandatoryApprovers: [
          {
            approverEntraId: '77777777-7777-7777-7777-777777777777' // ← replace
          }
        ]
        minimumApproversRequired: 1
      }
      enclaveMaintenanceMode: {
        approvalPolicy: 'Required'
        mandatoryApprovers: [
          {
            approverEntraId: '88888888-8888-8888-8888-888888888888' // ← replace
          }
        ]
        minimumApproversRequired: 1
      }
    }
    bastionEnabled: 'Enabled'
    communityResourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-community/providers/Microsoft.Mission/communities/existing-community' // ← replace
    diagnosticDestination: 'Both'
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
        serviceId: 'PostgreSQL'
      }
      {
        enforcement: 'Enabled'
        option: 'Allow'
        policyAction: 'Enforce'
        serviceId: 'PrivateDNSZones'
      }
    ]
    location: 'usgovvirginia' // ← replace with your Azure region
    network: {
      allowSubnetCommunication: 'Enabled'
      postgreSqlSubnet: {
        addressPrefix: '10.250.10.0/24' // ← replace
        name: 'snet-postgresql'         // ← replace
        networkPrefixSize: 24
        networkSecurityGroupResourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-managed/providers/Microsoft.Network/networkSecurityGroups/nsg-postgresql' // ← replace
        resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-managed/providers/Microsoft.Network/virtualNetworks/vnet-existing-enclave/subnets/snet-postgresql' // ← replace
        subnetDelegation: 'Microsoft.DBforPostgreSQL/flexibleServers'
      }
      privateEndpointSubnet: {
        addressPrefix: '10.250.20.0/24' // ← replace
        name: 'snet-private-endpoints'  // ← replace
        networkPrefixSize: 24
        networkSecurityGroupResourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-managed/providers/Microsoft.Network/networkSecurityGroups/nsg-private-endpoints' // ← replace
        resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-managed/providers/Microsoft.Network/virtualNetworks/vnet-existing-enclave/subnets/snet-private-endpoints' // ← replace
        subnetDelegation: ''
      }
    }
    rbacInheritance: 'Disabled'
    workloadResourceVisibility: 'Disabled'
  }
}

// ─── Workload ─────────────────────────────────────────────────────────────────
param workload = {
  mode: 'managed'
  name: 'pgworkload02'
  resourceGroupName: 'rg-contoso-existing-postgresql-workload' // ← replace
}

// ─── Foundation ───────────────────────────────────────────────────────────────
// All resources are existing. Supply the correct resource IDs and expected
// configuration values that match the live state.
param foundation = {
  cmkIdentity: {
    mode: 'existing'
    resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-workload/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uai-postgresql-cmk' // ← replace
    expectedConfiguration: {
      clientId: '33333333-3333-3333-3333-333333333333'   // ← replace
      location: 'usgovvirginia'                           // ← replace
      principalId: '44444444-4444-4444-4444-444444444444' // ← replace
    }
  }
  key: {
    mode: 'existing'
    resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-workload/providers/Microsoft.KeyVault/vaults/kvexisting/keys/postgresql-cmk' // ← replace
    expectedConfiguration: {
      enabled: 'Enabled'
      keySize: 3072
      keyType: 'RSA-HSM'
      versionlessKeyUri: 'https://kvexisting.vault.azure.net/keys/postgresql-cmk' // ← replace
    }
  }
  keyVault: {
    mode: 'existing'
    resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-workload/providers/Microsoft.KeyVault/vaults/kvexisting' // ← replace
    expectedConfiguration: {
      location: 'usgovvirginia' // ← replace
      networkBypass: 'None'
      networkDefaultAction: 'Deny'
      publicNetworkAccess: 'Disabled'
      purgeProtection: 'Enabled'
      rbacAuthorization: 'Enabled'
      skuName: 'premium'
      softDeleteRetentionDays: 90
      tenantId: '33333333-3333-3333-3333-333333333333' // ← replace with your tenant ID
    }
  }
  privateDns: {
    delegatedZone: {
      mode: 'existing'
      resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-workload/providers/Microsoft.Network/privateDnsZones/ave-example.postgres.database.usgovcloudapi.net' // ← replace
      expectedName: 'ave-example.postgres.database.usgovcloudapi.net' // ← replace
    }
    keyVaultPrivateLinkZone: {
      mode: 'existing'
      resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-workload/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.usgovcloudapi.net' // ← replace
      expectedName: 'privatelink.vaultcore.usgovcloudapi.net' // ← replace
    }
  }
}

// ─── Network finalization ──────────────────────────────────────────────────────
// ExistingReferenceOnly: pass through existing endpoint and connection resource IDs.
// No new Mission networking resources are created.
param networkFinalization = {
  mode: 'ExistingReferenceOnly'
  communityEndpointResourceIds: [
    '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-community/providers/Microsoft.Mission/communities/existing-community/communityEndpoints/ce-postgresql' // ← replace
  ]
  enclaveConnectionResourceIds: [
    '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-enclave/providers/Microsoft.Mission/enclaveConnections/conn-postgresql' // ← replace
  ]
}

param communityConnectivity = []

// ─── PostgreSQL Flexible Server ────────────────────────────────────────────────
// Existing server: supply the resource ID and the full expected configuration
// that must match the live state exactly.
param server = {
  mode: 'existing'
  resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-contoso-existing-postgresql-workload/providers/Microsoft.DBforPostgreSQL/flexibleServers/existing-postgresql' // ← replace
  expectedConfiguration: {
    activeDirectoryAuth: 'Enabled'
    administrators: [
      {
        objectId: '22222222-2222-2222-2222-222222222222' // ← replace
        principalName: 'dba-group@contoso.example'      // ← replace
        principalType: 'Group'
        tenantId: '33333333-3333-3333-3333-333333333333' // ← replace
      }
    ]
    backup: {
      geoRedundancy: 'Disabled'
      retentionDays: 35
    }
    cmkIdentityResourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-workload/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uai-postgresql-cmk' // ← replace
    cmkKeyUri: 'https://kvexisting.vault.azure.net/keys/postgresql-cmk' // ← replace
    configurations: []
    databases: [
      {
        name: 'appdb'
      }
    ]
    delegatedSubnetResourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-managed/providers/Microsoft.Network/virtualNetworks/vnet-existing-enclave/subnets/snet-postgresql' // ← replace
    deletionLock: 'CanNotDelete'
    diagnostics: {
      mode: 'Absent'
    }
    highAvailability: {
      mode: 'Disabled'
    }
    location: 'usgovvirginia' // ← replace
    maintenanceWindow: {
      mode: 'SystemManaged'
    }
    passwordAuth: 'Disabled'
    privateDnsZoneResourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-workload/providers/Microsoft.Network/privateDnsZones/ave-example.postgres.database.usgovcloudapi.net' // ← replace
    sku: {
      name: 'Standard_D4ds_v5'
      tier: 'GeneralPurpose'
    }
    storage: {
      storageSizeGB: 128
      type: 'Premium_LRS'
    }
    tenantId: '33333333-3333-3333-3333-333333333333' // ← replace
    version: '16'
  }
}
