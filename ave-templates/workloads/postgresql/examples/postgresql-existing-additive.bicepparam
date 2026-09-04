// ──────────────────────────────────────────────────────────────────────────────
// Scenario: Existing Enclave — Additive.
//
// Adds this workload's dedicated PostgreSQL and private-endpoint subnets, extra
// Mission role assignments, and extra maintenance-mode principals to an existing
// Mission virtual enclave, without disturbing anything another workload already
// configured on that enclave.
//
// Everything additive is unioned with live state; every immutable enclave
// property (location, address space, approval settings, Bastion, diagnostic
// destination, subnet communication, RBAC inheritance, workload visibility) is
// read from the live enclave and carried forward verbatim, so it does not have
// to be restated here.
//
// Deploy with:
//   az deployment sub create \
//     --location <region> \
//     --parameters ave-templates/workloads/postgresql/examples/postgresql-existing-additive.bicepparam
//
// Replace every placeholder value before deploying.
// Do not edit avePostgreSql.bicep.
// ──────────────────────────────────────────────────────────────────────────────

using '../avePostgreSql.bicep'

param deploymentContext = {
  // Distinguish this additional workload's generated resources from instance 001.
  instance: '002'
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
// resourceId is supplied, so the deployment targets an existing enclave and
// every additive collection below is unioned with the live state. Subnets are
// keyed by name, so re-running this deployment is idempotent; a name that
// already exists on the enclave with a different prefix size or delegation
// fails the deployment closed rather than silently overwriting.
//
// Immutable enclave properties are NOT restated here — they are read from the
// live enclave and carried forward as-is.
param enclave = {
  resourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mission-enclave/providers/Microsoft.Mission/virtualEnclaves/existing-enclave' // ← replace

  // This workload's own subnets, added additively alongside whatever other
  // workloads already placed on this enclave.
  postgreSqlSubnet: {
    name: 'snet-postgresql-workload02' // ← choose a unique name
    networkPrefixSize: 24
  }
  privateEndpointSubnet: {
    name: 'snet-private-endpoints-workload02' // ← choose a unique name
    networkPrefixSize: 24
  }

  // Unioned with the enclave's existing enclave-scope role assignments.
  enclaveRoleAssignments: [
    {
      roleDefinitionId: 'acdd72a7-3385-48ef-bd42-f606fba81ae7' // Reader
      principals: [
        {
          id: '99999999-9999-9999-9999-999999999999' // ← replace
          type: 'Group'
        }
      ]
    }
  ]

  // Unioned with the enclave's existing workload-scope role assignments.
  workloadRoleAssignments: [
    {
      roleDefinitionId: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635' // Owner
      principals: [
        {
          id: '11111111-1111-1111-1111-111111111111' // ← replace
          type: 'User'
        }
      ]
    }
  ]

  // Unioned with the live maintenance-mode principal set and the deployment
  // principal, so principals added by other workloads are preserved.
  additionalMaintenancePrincipals: [
    {
      id: '44444444-4444-4444-4444-444444444444' // ← replace
      type: 'Group'
    }
  ]
}

// ─── Workload ─────────────────────────────────────────────────────────────────
// Omitted: defaults to managed with names derived from existing-community.

// ─── Foundation ───────────────────────────────────────────────────────────────
// Omitted: all foundation selections default to managed mode.

// ─── Network finalization ──────────────────────────────────────────────────────
// ExistingReferenceOnly: reuse previously captured endpoint and connection IDs.
// Change to Managed (with communityConnectivity entries) to create new networking.
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
param server = {
  mode: 'managed'
  administrators: [
    {
      objectId: '22222222-2222-2222-2222-222222222222' // ← replace
      principalName: 'dba-group@contoso.example'      // ← replace
      principalType: 'Group'
      tenantId: '33333333-3333-3333-3333-333333333333' // ← replace
    }
  ]
}
