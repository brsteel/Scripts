// ──────────────────────────────────────────────────────────────────────────────
// Scenario: Existing Compatible — existing enclave and community, reference-only
// network finalization, existing PostgreSQL Flexible Server.
//
// The enclave is targeted by resourceId; its live configuration is read and
// reused, and this workload's subnets already exist on it, so the enclave PUT
// is an idempotent no-op.
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
// resourceId is supplied, so the deployment targets an existing enclave. Live
// state is read and carried forward verbatim for immutable properties
// (location, address space, approval settings, Bastion, diagnostic destination,
// subnet communication, RBAC inheritance, workload visibility). The only values
// declared here are this workload's own subnet names, which are unioned into
// the enclave's live subnet set keyed by name. Because the subnets below
// already exist on the enclave with these names, this is a no-op reuse; if they
// did not exist they would be added additively.
param enclave = {
  resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-enclave/providers/Microsoft.Mission/virtualEnclaves/existing-enclave' // ← replace
  postgreSqlSubnet: {
    name: 'snet-postgresql' // ← replace with the live delegated subnet name
  }
  privateEndpointSubnet: {
    name: 'snet-private-endpoints' // ← replace with the live private endpoint subnet name
  }
}

// ─── Workload ─────────────────────────────────────────────────────────────────
// Pin the managed workload registration to the resource group containing the
// existing server. The workload name remains independently defaulted.
param workload = {
  mode: 'managed'
  resourceGroupName: 'rg-contoso-existing-postgresql-workload' // ← replace
}

// ─── Foundation ───────────────────────────────────────────────────────────────
// All resources are existing. Supply the correct resource IDs and expected
// configuration values that match the live state.
param foundation = {
  // Existing mode: this identity must already have been granted the Microsoft
  // Graph "User.Read.All" application permission by a suitably privileged
  // Entra administrator before this deployment runs. This template never
  // creates or grants Graph permissions for an existing identity; Azure RBAC
  // alone is not sufficient for PostgreSQL Entra administrator creation.
  serverIdentity: {
    mode: 'existing'
    resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-workload/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-existing-community-pgsql-cmk' // ← replace
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
      networkBypass: 'AzureServices'
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
    '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-enclave/providers/Microsoft.Mission/enclaveConnections/ec-postgresql' // ← replace
  ]
}

// ─── PostgreSQL Flexible Server ────────────────────────────────────────────────
// Existing server: supply the resource ID and the full expected configuration
// that must match the live state exactly.
param server = {
  mode: 'existing'
  resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-contoso-existing-postgresql-workload/providers/Microsoft.DBforPostgreSQL/flexibleServers/existing-postgresql' // ← replace
  expectedConfiguration: {
    activeDirectoryAuth: 'Enabled'
    backup: {
      geoRedundancy: 'Disabled'
      retentionDays: 35
    }
    serverIdentityResourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-workload/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-existing-community-pgsql-cmk' // ← replace
    cmkKeyUri: 'https://kvexisting.vault.azure.net/keys/postgresql-cmk' // ← replace
    delegatedSubnetResourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-managed/providers/Microsoft.Network/virtualNetworks/vnet-existing-enclave/subnets/snet-postgresql' // ← replace
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
      name: 'Standard_D4ds_v4'
      tier: 'GeneralPurpose'
    }
    storage: {
      autoGrow: 'Enabled'
      storageSizeGB: 128
      type: 'Premium_LRS'
    }
    tenantId: '33333333-3333-3333-3333-333333333333' // ← replace
    version: '16'
  }
}
