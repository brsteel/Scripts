# PostgreSQL workload deployment guide

This folder contains a PostgreSQL workload profile built only from local Bicep modules:

- [avePostgreSqlEnclaveDeployment.bicep](./avePostgreSqlEnclaveDeployment.bicep) - Phase A
- [avePostgreSqlEnclaveNetworkFinalization.bicep](./avePostgreSqlEnclaveNetworkFinalization.bicep) - Phase B
- [avePostgreSqlWorkloadDeployment.bicep](./avePostgreSqlWorkloadDeployment.bicep) - Phase C
- [avePostgreSqlEnclaveApprovalActivation.bicep](./avePostgreSqlEnclaveApprovalActivation.bicep) - final governance-hardening stage for newly managed enclaves

Use a thin orchestration `.bicep` to chain these modules together and pass serialized outputs between stages. Do not treat the Phase A or Phase B handoff objects as independently authored static contracts unless you are intentionally replaying previously captured outputs with the exact current contract shape.

## What this profile does

- Creates or references a Mission community and Mission virtual enclave.
- Registers a Mission workload for the PostgreSQL workload resource group.
- Creates or references the CMK identity, Key Vault, CMK key, and private DNS zones required by PostgreSQL Flexible Server.
- Creates a Key Vault private endpoint and private DNS VNet links with deterministic names.
- Creates or references PostgreSQL Flexible Server using Microsoft Entra-only authentication.
- For newly managed enclaves, creates the enclave first with all approval actions `NotRequired`, then activates the customer's final desired approval settings only after Phase C succeeds.
- Never deploys passwords or local database administrator credentials.
- Never writes NSGs, route tables, routes, service endpoints, firewalls, or direct Mission-managed VNet/subnet resources.

## Prerequisite checklist

Minimum prerequisites depend on which `managed` versus `existing` options you choose.

### Always required

- Bicep CLI or Azure CLI with `bicep build`.
- A deployment principal with ARM permissions to deploy the selected scopes and child resources.
- At least one Microsoft Entra PostgreSQL administrator declaration for managed servers.

### Existing infrastructure prerequisites when selected

Supply resource IDs for every selected `existing` object:

- Existing Community: `community.resourceId`
- Existing Enclave: `enclave.resourceId`
- Existing Mission workload registration: `workload.resourceId`
- Existing CMK identity: `foundation.cmkIdentity.resourceId`
- Existing Key Vault: `foundation.keyVault.resourceId`
- Existing Key Vault key: `foundation.key.resourceId`
- Existing delegated private DNS zone: `foundation.privateDns.delegatedZone.resourceId`
- Existing Key Vault private-link DNS zone: `foundation.privateDns.keyVaultPrivateLinkZone.resourceId`
- Existing PostgreSQL server: `server.resourceId`
- Existing Mission Phase B endpoint/connection IDs: `networkFinalization.communityEndpointResourceIds`, `networkFinalization.enclaveConnectionResourceIds`, or the approved-change variants

If `community.mode = 'existing'`, that existing Community is the minimum infrastructure prerequisite for the Mission side of the deployment.

### Identity and group checklist

These grants are separate. Reusing the same Entra group is allowed, but each use must still be declared in the relevant object.

1. **Deployment principal**
   - Declared in `deploymentPrincipal`.
   - Used only to seed Mission maintenance principals for managed enclaves.
   - Does **not** automatically become a Mission approver, Mission RBAC assignee, Azure RBAC assignee, or PostgreSQL administrator unless also declared in those places.

2. **Mandatory approval approvers**
   - Declared inside `approvalSettings` for each `Required` action.
   - Each `Required` action needs:
     - `approvalPolicy: 'Required'`
     - one or more `mandatoryApprovers[].approverEntraId`
     - `minimumApproversRequired >= 1`
   - `NotRequired` needs no approver IDs and the module normalizes it to an empty list with minimum `0`.
   - For newly managed enclaves, these declarations are the **final desired** approval settings. Phase A intentionally creates the enclave with all actions `NotRequired`, and the final hardening stage activates the desired settings after the PostgreSQL workload is in place.
   - For existing enclaves, the template never disables or weakens live approvals. If the existing enclave already requires approval for endpoint, connection, or additive-subnet operations, deployment completion depends on external approver action within an ARM/RP timing window that is not publicly guaranteed. The template cannot self-approve, and deployment RBAC is not approval authority.
   - Separate actions exist for:
     - `connectionCreation`
     - `connectionUpdate`
     - `enclaveEndpointUpdate`
     - `enclaveMaintenanceMode`

3. **Enclave role-assignment principals**
   - Declared in `enclave.enclaveRoleAssignments[*].principals`.
   - Intended for Mission enclave-scope role assignments.

4. **Workload role-assignment principals**
   - Declared in `enclave.workloadRoleAssignments[*].principals`.
   - Intended for Mission workload-scope role assignments.

5. **Maintenance principals**
   - Declared implicitly as `deploymentPrincipal` plus any `enclave.additionalMaintenancePrincipals` for managed enclaves.
   - These are used in Mission `maintenanceModeConfiguration.principals`.
   - They are not the same as Azure RBAC or Mission role assignments.

6. **PostgreSQL administrators**
   - Declared in `server.administrators` for managed servers, or `server.expectedConfiguration.administrators` for existing-server validation.
   - Each entry requires:
     - `objectId`
     - `principalName` (UPN, display name, or group name as appropriate)
     - `principalType`
     - `tenantId`

7. **Deployment automation / service principal permissions**
   - The automation identity that runs the deployment needs ARM permission to create or update the selected resources, including role assignments if those are included.
   - That automation identity is distinct from the PostgreSQL CMK managed identity.

8. **CMK managed identity**
   - Declared in `foundation.cmkIdentity`.
   - Created or referenced for PostgreSQL encryption.
   - Usually a managed identity, not a pre-created human user/group prerequisite.

### Grant model notes

These are separate layers of access:

- Mission approval approvers
- Mission maintenance principals
- Mission enclave/workload role assignments
- Azure ARM deployment permissions
- PostgreSQL data-plane administration

Do not assume one layer implies the others.

### RBAC inheritance and workload visibility

Mission describes these properties as:

- `rbacInheritance`: controls whether standard Azure RBAC role inheritance applies to workload resource group(s)
- `workloadResourceVisibility`: specifies whether resources in workload resource group(s) are visible through standard RBAC

Practical implication:

- If either setting is `Disabled`, plan explicit access deliberately.
- Mission role assignments and standard Azure RBAC are separate mechanisms.
- The templates default managed PostgreSQL enclaves to `rbacInheritance = 'Disabled'` and `workloadResourceVisibility = 'Disabled'`, so readers/operators may need explicit assignment even if they can deploy the template.

## How to use the staged orchestration

Use one orchestration file that chains outputs:

1. Phase A emits `phaseA.outputs.phaseA`
2. Phase B consumes that and emits `phaseB.outputs.foundation`
3. Phase C consumes `phaseB.outputs.foundation`
4. For newly managed enclaves, the final hardening stage consumes `phaseA.outputs.phaseA` plus a Phase C output and activates the final approval settings

See:

- [examples/postgresql-secure-new-example.bicep](./examples/postgresql-secure-new-example.bicep)
- [examples/postgresql-existing-compatible-example.bicep](./examples/postgresql-existing-compatible-example.bicep)
- [examples/postgresql-existing-additive-subnet-example.bicep](./examples/postgresql-existing-additive-subnet-example.bicep)

Recommended workflow:

- author a thin orchestration `.bicep`
- optionally author a `.bicepparam` file for top-level parameters like location, names, IDs, and tags
- build the orchestration, not the phase modules in isolation for deployment

If the final approval-activation stage fails after Phase C succeeds, ARM does not roll back the already-created PostgreSQL workload resources. Treat that result as an incomplete governance-hardening deployment and rerun or remediate idempotently.

## Phase A parameter guide

Module: [avePostgreSqlEnclaveDeployment.bicep](./avePostgreSqlEnclaveDeployment.bicep)

### `deploymentContext`

- `subscriptionId` - optional target subscription override
- `location` - optional deployment location
- `tags` - optional shared tags

### `deploymentPrincipal`

Required:

- `objectId`
- `principalType` = `User | Group | ServicePrincipal`

### `community`

Managed:

```bicep
community: {
  mode: 'managed'
  name: 'contoso-community'
  resourceGroupName: 'rg-contoso-community'
  addressSpace: '10.10.0.0/16' // optional
  addressSpaces: [] // optional
  dnsServers: [] // optional
}
```

Existing:

```bicep
community: {
  mode: 'existing'
  resourceId: '/subscriptions/.../resourceGroups/.../providers/Microsoft.Mission/communities/existing-community'
}
```

### `enclave`

Managed:

```bicep
enclave: {
  mode: 'managed'
  name: 'contoso-enclave'
  resourceGroupName: 'rg-contoso-enclave'
  addressSpaceCidr: '10.250.0.0/16'
  // Final desired approval settings. Phase A creates the new enclave with all
  // actions NotRequired, then the final hardening stage activates this object.
  approvalSettings: {
    connectionCreation: {
      approvalPolicy: 'Required'
      mandatoryApprovers: [
        {
          approverEntraId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
        }
      ]
      minimumApproversRequired: 1
    }
    connectionUpdate: {
      approvalPolicy: 'NotRequired'
    }
    enclaveEndpointUpdate: {
      approvalPolicy: 'NotRequired'
    }
    enclaveMaintenanceMode: {
      approvalPolicy: 'Required'
      mandatoryApprovers: [
        {
          approverEntraId: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
        }
      ]
      minimumApproversRequired: 1
    }
  }
  postgreSqlSubnet: {
    networkPrefixSize: 24
    name: 'snet-postgresql' // optional
  }
  privateEndpointSubnet: {
    networkPrefixSize: 24
    name: 'snet-private-endpoints' // optional
  }
  allowSubnetCommunication: true // optional
  bastionEnabled: true // optional
  diagnosticDestination: 'Both' // optional
  enclaveRoleAssignments: [] // optional
  workloadRoleAssignments: [] // optional
  additionalMaintenancePrincipals: [] // optional
}
```

Existing reference-only:

```bicep
enclave: {
  mode: 'ReferenceOnly'
  resourceId: '/subscriptions/.../resourceGroups/.../providers/Microsoft.Mission/virtualEnclaves/existing-enclave'
  expectedConfiguration: {
    approvalSettings: {
      connectionCreation: {
        approvalPolicy: 'Required'
        mandatoryApprovers: [
          {
            approverEntraId: '...'
          }
        ]
        minimumApproversRequired: 1
      }
      connectionUpdate: {
        approvalPolicy: 'NotRequired'
      }
      enclaveEndpointUpdate: {
        approvalPolicy: 'NotRequired'
      }
      enclaveMaintenanceMode: {
        approvalPolicy: 'Required'
        mandatoryApprovers: [
          {
            approverEntraId: '...'
          }
        ]
        minimumApproversRequired: 1
      }
    }
    bastionEnabled: 'Enabled'
    communityResourceId: '/subscriptions/.../resourceGroups/.../providers/Microsoft.Mission/communities/existing-community'
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
    location: location
    network: {
      allowSubnetCommunication: 'Enabled'
      postgreSqlSubnet: {
        addressPrefix: '10.250.10.0/24'
        name: 'snet-postgresql'
        networkPrefixSize: 24
        networkSecurityGroupResourceId: '/subscriptions/.../providers/Microsoft.Network/networkSecurityGroups/nsg-postgresql'
        resourceId: '/subscriptions/.../providers/Microsoft.Network/virtualNetworks/vnet-existing-enclave/subnets/snet-postgresql'
        subnetDelegation: 'Microsoft.DBforPostgreSQL/flexibleServers'
      }
      privateEndpointSubnet: {
        addressPrefix: '10.250.20.0/24'
        name: 'snet-private-endpoints'
        networkPrefixSize: 24
        networkSecurityGroupResourceId: '/subscriptions/.../providers/Microsoft.Network/networkSecurityGroups/nsg-private-endpoints'
        resourceId: '/subscriptions/.../providers/Microsoft.Network/virtualNetworks/vnet-existing-enclave/subnets/snet-private-endpoints'
        subnetDelegation: ''
      }
    }
    rbacInheritance: 'Disabled'
    workloadResourceVisibility: 'Disabled'
  }
}
```

Existing additive subnet update:

```bicep
enclave: {
  mode: 'AdditiveSubnetUpdate'
  resourceId: '/subscriptions/.../resourceGroups/.../providers/Microsoft.Mission/virtualEnclaves/existing-enclave'
  expectedConfiguration: {
    approvalSettings: {
      connectionCreation: {
        approvalPolicy: 'Required'
        mandatoryApprovers: [
          {
            approverEntraId: '...'
          }
        ]
        minimumApproversRequired: 1
      }
      connectionUpdate: {
        approvalPolicy: 'NotRequired'
      }
      enclaveEndpointUpdate: {
        approvalPolicy: 'NotRequired'
      }
      enclaveMaintenanceMode: {
        approvalPolicy: 'Required'
        mandatoryApprovers: [
          {
            approverEntraId: '...'
          }
        ]
        minimumApproversRequired: 1
      }
    }
    bastionEnabled: 'Enabled'
    communityResourceId: '/subscriptions/.../resourceGroups/.../providers/Microsoft.Mission/communities/existing-community'
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
    location: location
    network: {
      allowSubnetCommunication: 'Enabled'
    }
    rbacInheritance: 'Disabled'
    workloadResourceVisibility: 'Disabled'
  }
  postgreSqlSubnet: {
    name: 'snet-postgresql-workload02'
    networkPrefixSize: 24
  }
  privateEndpointSubnet: {
    mode: 'New'
    name: 'snet-private-endpoints-workload02'
    networkPrefixSize: 24
  }
}
```

Notes for additive mode:

- New subnet names must not collide with any existing Mission subnet configuration.
- The template inventories the live enclave subnet collection and sends the full union back through the Mission virtualEnclaves API.
- Existing subnet CIDRs, delegation, and names are preserved; this mode only adds genuinely new entries.
- If you choose `privateEndpointSubnet.mode = 'Existing'`, replace the new-subnet block above with:

  ```bicep
  privateEndpointSubnet: {
    mode: 'Existing'
    expectedConfiguration: {
      resourceId: '/subscriptions/<subId>/resourceGroups/<managed-rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<pe-subnet>'
      addressPrefix: '10.42.2.0/24'
      networkPrefixSize: 24
      networkSecurityGroupResourceId: '/subscriptions/<subId>/resourceGroups/<managed-rg>/providers/Microsoft.Network/networkSecurityGroups/<pe-nsg>'
      subnetDelegation: ''
    }
  }
  ```

### `workload`

Managed:

```bicep
workload: {
  mode: 'managed'
  name: 'pgworkload01'
  resourceGroupName: 'rg-contoso-postgresql-workload'
}
```

Existing:

```bicep
workload: {
  mode: 'existing'
  resourceId: '/subscriptions/.../resourceGroups/.../providers/Microsoft.Mission/virtualEnclaves/existing-enclave/workloads/existing-workload'
  expectedResourceGroupCollection: [
    '/subscriptions/.../resourceGroups/rg-contoso-postgresql-workload'
  ]
}
```

### `foundation`

Contains these child selections:

- `cmkIdentity`
- `keyVault`
- `key`
- `privateDns.delegatedZone`
- `privateDns.keyVaultPrivateLinkZone`

Each child supports `managed` or `existing`.

Managed examples:

```bicep
foundation: {
  cmkIdentity: {
    mode: 'managed'
  }
  keyVault: {
    mode: 'managed'
    skuName: 'premium' // optional
  }
  key: {
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
```

Existing examples require resource IDs and expected configuration values. Use [postgresql-existing-compatible-example.bicep](./examples/postgresql-existing-compatible-example.bicep) as the reference shape.

## Phase B parameter guide

Module: [avePostgreSqlEnclaveNetworkFinalization.bicep](./avePostgreSqlEnclaveNetworkFinalization.bicep)

### Inputs

- `deploymentContext.tags` - optional
- `phaseA` - required serialized output from Phase A
- `networkFinalization` - required mode object
- `communityConnectivity` - optional connectivity requests, default `[]`

### `networkFinalization`

Managed:

```bicep
networkFinalization: {
  mode: 'Managed'
}
```

Existing reference-only:

```bicep
networkFinalization: {
  mode: 'ExistingReferenceOnly'
  communityEndpointResourceIds: [
    '/subscriptions/.../communityEndpoints/ce-postgresql'
  ]
  enclaveConnectionResourceIds: [
    '/subscriptions/.../enclaveConnections/conn-postgresql'
  ]
}
```

Existing approved endpoint/connection additions:

```bicep
networkFinalization: {
  mode: 'ExistingApprovedEndpointChanges'
  existingCommunityEndpointResourceIds: [
    '/subscriptions/.../communityEndpoints/existing-endpoint'
  ]
  existingEnclaveConnectionResourceIds: [
    '/subscriptions/.../enclaveConnections/existing-connection'
  ]
}
```

### `communityConnectivity`

Each item defines:

- `connectionName` - optional
- `endpoint` - managed or existing
- `sourceSubnets` - required array of:
  - `DelegatedPostgreSql`
  - `PrivateEndpoints`

Managed endpoint example:

```bicep
communityConnectivity: [
  {
    endpoint: {
      mode: 'managed'
      ruleCollection: [
        {
          endpointRuleName: 'pgsql'
          destinationType: 'FQDN'
          destination: 'example.contoso.com'
          protocols: [
            'TCP'
          ]
          ports: '443'
        }
      ]
      updateMode: 'Manual' // optional
    }
    sourceSubnets: [
      'DelegatedPostgreSql'
      'PrivateEndpoints'
    ]
  }
]
```

Source subnet handling:

- `DelegatedPostgreSql` uses the Phase A PostgreSQL subnet CIDR
- `PrivateEndpoints` uses the Phase A private-endpoint subnet CIDR
- specifying both produces a comma-separated CIDR list

## Phase C parameter guide

Module: [avePostgreSqlWorkloadDeployment.bicep](./avePostgreSqlWorkloadDeployment.bicep)

### Inputs

- `deploymentContext.location` - optional
- `deploymentContext.tags` - optional
- `foundation` - required serialized output from Phase B
- `server` - required managed or existing server object

### Managed server

```bicep
server: {
  mode: 'managed'
  name: 'psql-custom-name' // optional
  location: location // optional
  version: '16'
  availabilityZone: '1' // optional
  sku: {
    name: 'Standard_D4ds_v5'
    tier: 'GeneralPurpose' // optional
  }
  storage: {
    storageSizeGB: 128 // optional
    type: 'Premium_LRS' // optional
    autoGrow: 'Enabled' // optional
  }
  backup: {
    retentionDays: 35 // optional
    geoRedundancy: 'Disabled' // optional
  }
  highAvailability: {
    mode: 'Disabled' // optional object, defaults to Disabled
  }
  maintenanceWindow: {
    dayOfWeek: 0
    startHour: 4
    startMinute: 0
  } // optional
  administrators: [
    {
      objectId: '22222222-2222-2222-2222-222222222222'
      principalName: 'dba-group@contoso.example'
      principalType: 'Group'
      tenantId: tenant().tenantId
    }
  ]
  databases: [] // optional
  configurations: [] // optional
  diagnostics: {
    workspaceResourceId: '/subscriptions/.../providers/Microsoft.OperationalInsights/workspaces/law'
    settingName: 'diag-postgresql' // optional
    logCategories: [
      'PostgreSQLLogs'
    ]
    metricCategories: [
      'AllMetrics'
    ]
  } // optional
  deletionProtection: 'CanNotDelete' // optional
}
```

### Existing server

Existing-server mode is reference-only and requires:

- `resourceId`
- `expectedConfiguration`

That expected object is validated against:

- location
- version
- sku
- storage
- backup
- high availability
- maintenance mode/window
- delegated subnet resource ID
- private DNS zone resource ID
- Entra auth settings
- CMK identity and key URI
- administrators
- databases
- configurations
- diagnostics expectation
- delete lock expectation

See [postgresql-existing-compatible-example.bicep](./examples/postgresql-existing-compatible-example.bicep).

## Final approval activation stage

Module: [avePostgreSqlEnclaveApprovalActivation.bicep](./avePostgreSqlEnclaveApprovalActivation.bicep)

Use this only for `phaseA.enclaveOwnership = 'managed'`.

Required inputs:

- `phaseA`: the Phase A handoff object from the same orchestration chain
- `workloadCompletion.flexibleServerResourceId`: a Phase C output used to serialize this stage after workload deployment

Behavior:

- reads the live Mission enclave after Phase C
- preserves the live writable enclave settings through a full Mission `virtualEnclaves@2026-03-01-preview` PUT
- updates only `approvalSettings`
- fails closed if the live enclave does not explicitly expose the shared writable settings that must be round-tripped safely

One-shot orchestration note:

- if this stage fails, the deployment is not fully governance-hardened even though the PostgreSQL server and earlier infrastructure may already exist
- rerun after correcting approver IDs, permissions, RP approval state, or preview-RP issues

## Defaults matrix

Only values implemented in code are listed here.

### Phase A defaults

| Surface | Field | Default |
| --- | --- | --- |
| deploymentContext | subscriptionId | current subscription |
| deploymentContext | location | `deployment().location` |
| deploymentContext | tags | `{}` |
| community managed | addressSpace | `''` |
| community managed | addressSpaces | `[]` |
| community managed | dnsServers | `[]` |
| community managed | communityFirewallSku | `Standard` |
| community managed | policyOverride | `Enclave` |
| enclave managed | postgreSqlSubnet.name | `snet-postgresql` |
| enclave managed | privateEndpointSubnet.name | `snet-private-endpoints` |
| enclave managed | allowSubnetCommunication | `true` |
| enclave managed | bastionEnabled | `true` |
| enclave managed | diagnosticDestination | `Both` |
| enclave managed | enclaveRoleAssignments | `[]` |
| enclave managed | workloadRoleAssignments | `[]` |
| enclave managed | additionalMaintenancePrincipals | `[]` |
| enclave managed | approvalSettings | **no default; required as final desired policy** |
| enclave managed runtime behavior | initial Mission approval payload during Phase A | all actions forced to `NotRequired` with empty approvers / minimum `0` |
| workload managed | name | **no default** |
| workload managed | resourceGroupName | **no default** |
| foundation.cmkIdentity managed | resourceGroupName | workload resource group |
| foundation.cmkIdentity managed | location | deployment location |
| foundation.cmkIdentity managed | name | `uai-postgresql-cmk-${phaseToken}` |
| foundation.keyVault managed | resourceGroupName | workload resource group |
| foundation.keyVault managed | name | `kvpg${phaseToken}` |
| foundation.keyVault managed | skuName | `premium` |
| foundation.key managed | name | `postgresql-cmk` |
| foundation.key managed | keyType | `RSA-HSM` |
| foundation.key managed | keySize | `3072` |
| foundation.privateDns.delegatedZone managed | resourceGroupName | workload resource group |
| foundation.privateDns.delegatedZone managed | name | `ave-${phaseToken}.${postgreSqlDnsSuffix}` |
| foundation.privateDns.keyVaultPrivateLinkZone managed | resourceGroupName | workload resource group |
| foundation.privateDns.keyVaultPrivateLinkZone managed | name | derived `privatelink.<keyvault suffix>` |
| template | enableTelemetry | `true` |

### Common managed Key Vault defaults used by Phase A

| Field | Default |
| --- | --- |
| tenantId | `subscription().tenantId` |
| enabledForTemplateDeployment | `false` |
| enabledForDiskEncryption | `false` |
| enabledForDeployment | `false` |
| enablePublicNetworkAccess | `false` |
| softDeleteRetentionInDays | `90` |
| networkAclsBypass | `None` |
| ipRules | `[]` |
| virtualNetworkSubnetResourceIds | `[]` |
| purge protection | enabled |
| RBAC authorization | enabled |

### Phase B defaults

| Surface | Field | Default |
| --- | --- | --- |
| deploymentContext | tags | `{}` |
| communityConnectivity | whole array | `[]` |
| managed endpoint | name | `ce-pg-${hash}` |
| managed endpoint | updateMode | `Manual` |
| managed connection | connectionName | `conn-pg-${hash}` |
| managed/existing connection | sourceCidr | derived from Phase A subnet CIDRs |
| networkFinalization | mode | **no default; required** |

### Phase C defaults

| Surface | Field | Default |
| --- | --- | --- |
| deploymentContext | location | Phase A location |
| deploymentContext | tags | `{}` |
| managed server | name | `psql-${substring(uniqueString(foundation.phaseA.workloadResourceId), 0, 13)}` |
| managed server | location | `server.location ?? deploymentContext.location ?? foundation.phaseA.location` |
| managed server sku | tier | `GeneralPurpose` |
| managed server storage | object | `{}` |
| managed server storage.type | `Premium_LRS` |
| managed server storage.storageSizeGB | `128` |
| managed server storage.autoGrow | `Enabled` except `PremiumV2_LRS` forces `Disabled` |
| managed server backup.geoRedundancy | `Disabled` |
| managed server backup.retentionDays | `35` |
| managed server highAvailability | `{ mode: 'Disabled' }` |
| managed server maintenanceWindow | omitted; platform-managed |
| managed server databases | `[]` |
| managed server configurations | `[]` |
| managed server diagnostics | omitted |
| managed server deletionProtection | `CanNotDelete` |
| managed server version | **no default** |
| managed server sku.name | **no default** |
| managed server administrators | **no default; at least one required** |

### Final approval activation defaults

| Surface | Field | Default |
| --- | --- | --- |
| approval activation | workloadCompletion.flexibleServerResourceId | **no default; required in one-shot orchestration** |
| approval activation | final approval settings | carried from Phase A `enclave.approvalSettings` |

### Fields with no default that must be supplied

- `deploymentPrincipal.objectId`
- `deploymentPrincipal.principalType`
- managed `community.name`
- managed `community.resourceGroupName`
- managed `enclave.name`
- managed `enclave.resourceGroupName`
- managed `enclave.addressSpaceCidr`
- managed `enclave.approvalSettings` (final desired approval policy)
- managed `enclave.postgreSqlSubnet.networkPrefixSize`
- managed `enclave.privateEndpointSubnet.networkPrefixSize`
- managed or existing `workload` mode-specific required IDs/names
- existing-mode `resourceId` and expected configuration fields
- Phase B `networkFinalization`
- each Phase C managed server `version`, `sku.name`, and `administrators`

## Existing-resource compatibility and fail-closed behavior

### Existing enclave reference-only mode

Fails closed unless all expected values match:

- community binding
- location
- approval policy plus mandatory-approver/count shape
- Bastion enabled state
- diagnostic destination
- `rbacInheritance`
- `workloadResourceVisibility`
- `allowSubnetCommunication`
- PostgreSQL subnet details
- private-endpoint subnet details
- governed service list

### Existing enclave additive subnet update mode

Behavior:

- inventories all existing Mission subnet configurations
- rejects requests whose new subnet names collide with live names
- adds only new subnet definitions
- preserves the live enclave identity, tags, approvals, diagnostics, network shape, governed services, maintenance configuration, and Mission role-assignment collections in the Mission PUT payload
- performs the update through `Microsoft.Mission/virtualEnclaves@2026-03-01-preview`
- never writes `Microsoft.Network/virtualNetworks/subnets` directly
- may still wait on external approval if the live enclave requires approval for the relevant Mission operation

Residual preview risk:

- this path depends on the current preview RP accepting the reconstructed writable property set
- additive mode fails closed if the live enclave does not explicitly expose `allowSubnetCommunication`, `bastionEnabled`, or `enclaveDefaultSettings.diagnosticDestination`, because the template will not synthesize or widen those shared settings during the Mission PUT
- validate generated ARM before deployment

### Existing workload registration

- compares `resourceGroupCollection` exactly to `expectedResourceGroupCollection`

### Existing PostgreSQL server

- validates the expected configuration listed in the Phase C section above

## Idempotent supporting resources

These resources are intentionally deterministic and do not use separate managed/existing switches solely for idempotency:

- Key Vault private endpoint: `${keyVaultName}-pe`
- delegated-zone VNet link: `link-${phaseToken}`
- Key Vault private-link zone VNet link: `link-${phaseToken}`
- CMK role assignment GUID: derived from scope, principal, role, and condition

## Authentication and secret model

- PostgreSQL is Microsoft Entra-only.
- `activeDirectoryAuth = Enabled`
- `passwordAuth = Disabled`
- No passwords or database secrets are prerequisites for this workload.

## Offline / forkable behavior

- All module references are local relative paths.
- No remote module registry, Template Spec, or AVM dependency is used.
- No Azure deployment, `what-if`, login, or resource mutation is performed by this documentation work.
