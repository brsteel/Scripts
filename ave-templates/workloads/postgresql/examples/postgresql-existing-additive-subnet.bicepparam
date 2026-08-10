// ──────────────────────────────────────────────────────────────────────────────
// Scenario: Existing Enclave — Additive Subnet Update.
//
// Adds new PostgreSQL and private-endpoint subnets to an existing Mission
// virtual enclave without modifying NSGs, route tables, or any other
// Mission-managed network resources.
//
// Deploy with:
//   az deployment sub create \
//     --location <region> \
//     --template-file ave-templates/workloads/postgresql/avePostgreSql.bicep \
//     --parameters ave-templates/workloads/postgresql/examples/postgresql-existing-additive-subnet.bicepparam
//
// Replace every placeholder value before deploying.
// Do not edit avePostgreSql.bicep.
// ──────────────────────────────────────────────────────────────────────────────

using '../avePostgreSql.bicep'

param deploymentContext = {
  tags: {
    environment: 'production'
    workload: 'postgresql-existing-additive'
  }
}

param deploymentPrincipal = {
  objectId: '11111111-1111-1111-1111-111111111111' // ← replace
  principalType: 'User'
}

// ─── Community ────────────────────────────────────────────────────────────────
param community = {
  mode: 'existing'
  resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-community/providers/Microsoft.Mission/communities/existing-community' // ← replace
}

// ─── Enclave ──────────────────────────────────────────────────────────────────
// AdditiveSubnetUpdate: the deployment appends new dedicated subnets to the
// existing enclave via a full PUT of the currently readable contract. It does NOT
// write Microsoft.Network/virtualNetworks/subnets directly.
//
// The expectedConfiguration must match the live enclave state exactly. Subnet-name
// collisions with existing subnets are rejected by the template before any change
// is attempted.
//
// All four approval settings must be declared. For existing enclaves that have
// Required approvals, deployment completion depends on external approver action.
param enclave = {
  mode: 'AdditiveSubnetUpdate'
  resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-enclave/providers/Microsoft.Mission/virtualEnclaves/existing-enclave' // ← replace
  expectedConfiguration: {
    approvalSettings: {
      connectionCreation: {
        approvalPolicy: 'NotRequired'
      }
      connectionUpdate: {
        approvalPolicy: 'NotRequired'
      }
      enclaveEndpointUpdate: {
        approvalPolicy: 'NotRequired'
      }
      enclaveMaintenanceMode: {
        approvalPolicy: 'NotRequired'
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
    location: 'usgovvirginia' // ← replace
    network: {
      allowSubnetCommunication: 'Enabled'
    }
    rbacInheritance: 'Disabled'
    workloadResourceVisibility: 'Disabled'
  }
  // New subnet names must not collide with any existing subnet names on the enclave.
  postgreSqlSubnet: {
    name: 'snet-postgresql-workload02'     // ← choose a unique name
    networkPrefixSize: 24
  }
  privateEndpointSubnet: {
    mode: 'New'
    name: 'snet-private-endpoints-workload02' // ← choose a unique name
    networkPrefixSize: 24
  }
}

// ─── Workload ─────────────────────────────────────────────────────────────────
param workload = {
  mode: 'managed'
  name: 'pgworkload03'
  resourceGroupName: 'rg-contoso-existing-additive-postgresql-workload' // ← replace
}

// ─── Foundation ───────────────────────────────────────────────────────────────
// Managed foundation resources are created alongside the new workload.
param foundation = {
  cmkIdentity: {
    mode: 'managed'
  }
  key: {
    mode: 'managed'
  }
  keyVault: {
    mode: 'managed'
  }
  privateDns: {
    delegatedZone: {
      mode: 'managed'
    }
    keyVaultPrivateLinkZone: {
      mode: 'managed'
    }
  }
}

// ─── Network finalization ──────────────────────────────────────────────────────
// ExistingReferenceOnly: reuse previously captured endpoint and connection IDs.
// Change to Managed (with communityConnectivity entries) to create new networking.
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
param server = {
  mode: 'managed'
  version: '16'
  sku: {
    name: 'Standard_D4ds_v5'
    tier: 'GeneralPurpose'
  }
  administrators: [
    {
      objectId: '22222222-2222-2222-2222-222222222222' // ← replace
      principalName: 'dba-group@contoso.example'      // ← replace
      principalType: 'Group'
      tenantId: '33333333-3333-3333-3333-333333333333' // ← replace
    }
  ]
}
