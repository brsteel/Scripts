// ──────────────────────────────────────────────────────────────────────────────
// Scenario: Secure New — fully managed enclave, community, workload, and server.
//
// Deploy with:
//   az deployment sub create \
//     --location <region> \
//     --template-file ave-templates/workloads/postgresql/avePostgreSql.bicep \
//     --parameters ave-templates/workloads/postgresql/examples/postgresql-secure-new.bicepparam
//
// Replace every placeholder value (names, CIDRs, object IDs) before deploying.
// Do not edit avePostgreSql.bicep. Customers author only this .bicepparam file.
// ──────────────────────────────────────────────────────────────────────────────

using '../avePostgreSql.bicep'

// Deployment location is passed through the --location argument on the CLI; no
// override is required here unless you want to force a specific region.
param deploymentContext = {
  tags: {
    environment: 'production'
    workload: 'postgresql'
  }
}

// Object ID of the identity running the deployment. Used to seed the Mission
// maintenance-principal set for the managed enclave.
param deploymentPrincipal = {
  objectId: '11111111-1111-1111-1111-111111111111' // ← replace with real object ID
  principalType: 'User'
}

// ─── Community ────────────────────────────────────────────────────────────────
// Managed: a new Mission community is created in the named resource group.
// Switch to mode: 'existing' and supply resourceId to reuse an existing one.
param community = {
  mode: 'managed'
  name: 'contoso-community'
  resourceGroupName: 'rg-contoso-community'
}

// ─── Enclave ──────────────────────────────────────────────────────────────────
// Managed: a new Mission virtual enclave is created. All four approval settings
// must be declared explicitly on every deployment; they represent desired state.
// NotRequired is the recommended secure-new starting point. Switch individual
// actions to Required (with mandatoryApprovers and minimumApproversRequired) to
// enforce approval-gate workflows once the environment is established.
param enclave = {
  mode: 'managed'
  name: 'contoso-enclave'
  resourceGroupName: 'rg-contoso-enclave'
  addressSpaceCidr: '10.250.0.0/16' // ← choose a non-overlapping CIDR
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
  postgreSqlSubnet: {
    name: 'snet-postgresql'
    networkPrefixSize: 24
  }
  privateEndpointSubnet: {
    name: 'snet-private-endpoints'
    networkPrefixSize: 24
  }
}

// ─── Workload ─────────────────────────────────────────────────────────────────
param workload = {
  mode: 'managed'
  name: 'pgworkload01'
  resourceGroupName: 'rg-contoso-postgresql-workload'
}

// ─── Foundation (CMK identity, Key Vault, key, private DNS) ───────────────────
// All four sub-resources use managed mode, so the deployment creates them.
// Switch any to existing (with resourceId and expectedConfiguration) to reuse
// pre-provisioned resources.
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
// Managed: the deployment creates Mission community endpoints and enclave
// connections as declared in communityConnectivity.
param networkFinalization = {
  mode: 'Managed'
}

// Community endpoints and enclave connections to create. Empty array is valid
// when no outbound connectivity rules are needed at deployment time.
param communityConnectivity = []

// ─── PostgreSQL Flexible Server ────────────────────────────────────────────────
// Replace administrators[0] with your DBA group or user Entra object ID,
// principalName (UPN or display name), and tenantId.
param server = {
  mode: 'managed'
  version: '16'
  sku: {
    name: 'Standard_D4ds_v5'
    tier: 'GeneralPurpose'
  }
  storage: {
    storageSizeGB: 128
  }
  backup: {
    retentionDays: 35
  }
  highAvailability: {
    mode: 'ZoneRedundant'
  }
  administrators: [
    {
      objectId: '22222222-2222-2222-2222-222222222222' // ← replace
      principalName: 'dba-group@contoso.example'      // ← replace
      principalType: 'Group'
      tenantId: '33333333-3333-3333-3333-333333333333' // ← replace with tenant().tenantId or literal GUID
    }
  ]
  databases: [
    {
      name: 'appdb'
    }
  ]
}
