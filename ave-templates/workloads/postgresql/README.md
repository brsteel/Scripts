# PostgreSQL workload deployment guide

## Deployment model

Customers deploy exactly one template and author exactly one file:

| File authored by customer | Role |
| --- | --- |
| `examples/<scenario>.bicepparam` | Parameter file only — the single file customers create or copy |

| File owned by AVE (do not edit) | Role |
| --- | --- |
| [avePostgreSql.bicep](./avePostgreSql.bicep) | Production entry point — subscription-scope template that orchestrates Phase A → Phase B → Phase C through output dependencies |
| [avePostgreSqlEnclaveDeployment.bicep](./avePostgreSqlEnclaveDeployment.bicep) | Phase A internal module |
| [avePostgreSqlEnclaveNetworkFinalization.bicep](./avePostgreSqlEnclaveNetworkFinalization.bicep) | Phase B internal module |
| [avePostgreSqlWorkloadDeployment.bicep](./avePostgreSqlWorkloadDeployment.bicep) | Phase C internal module |

**Customers do not edit Bicep files and do not run phase deployments independently.**

## `managed` vs. `existing`

Most pluggable pieces of this template (`community`, `workload`, each
`foundation` child, `key`, and `server`) are discriminated unions with a `mode`
field set to either `managed` or `existing`. These two modes mean:

- **`managed`** — this template declares and creates the resource. On every
  deployment (including redeploys), the template re-applies the properties
  it declares for that resource, the same as any other Bicep/ARM resource.
  `managed` does **not** mean this template continuously watches, reconciles,
  or takes ongoing ownership of the resource after deployment completes —
  it only describes who authored the resource's declared configuration.
  Changes made outside this template (portal edits, another template, a
  script) are not detected or protected against; the next redeploy simply
  re-asserts whatever this template declares.
- **`existing`** — this template only reads and validates a resource that
  already exists elsewhere. It never creates, modifies, or deletes an
  `existing` resource. The customer supplies its resource ID, and the
  template checks the live resource's configuration against an
  `expectedConfiguration` to fail fast on a mismatch rather than silently
  proceeding against an incompatible resource.

`enclave` is the exception: it has **no `mode`**. See
[Enclave: one contract](#enclave-one-contract).

## Enclave: one contract

There is a single `enclave` parameter shape. What varies is whether you supply
`enclave.resourceId`:

- **Omit `resourceId`** — a new Mission virtual enclave is created. Supply
  `addressSpaceCidr` and all four `approvalSettings`; everything else defaults.
- **Supply `resourceId`** — the deployment targets that existing enclave and
  adds this workload to it without disturbing what other workloads already
  configured there.

Both cases run the **same** template logic. The difference is only what the
template reads before it writes:

| Category | New enclave (no `resourceId`) | Existing enclave (`resourceId` supplied) |
| --- | --- | --- |
| Immutable/shared properties (location, address space, approval settings, Bastion, diagnostic destination, subnet communication, RBAC inheritance, workload-resource visibility, community binding, monitoring, dedicated hub) | Taken from your parameters or secure defaults | **Read from live state and carried forward verbatim.** You do not restate them and the template does not assert an `expectedConfiguration` match. |
| Subnet configurations | Union of an empty base and this workload's two subnet requests | Union of the live subnet set and this workload's two subnet requests, **keyed by subnet name** |
| `enclaveRoleAssignments`, `workloadRoleAssignments`, `additionalMaintenancePrincipals` | Union of an empty base and your request | Union of the live values and your request |
| Governed services | The three required entries (Key Vault, PostgreSQL, Private DNS Zones) | Live entries retained, then the three required entries applied, **keyed by `serviceId`** |
| Enclave resource group | Created | Not created — it exists by definition of the resource ID |

Because every additive collection is a `union()` against a base that is simply
empty when creating, the "new" and "existing" paths are literally the same
code. Key semantics:

- **Subnets are keyed by name.** Redeploying the same parameters is idempotent:
  a subnet whose name already exists is reused, not duplicated. If
  `networkPrefixSize` is omitted, the live prefix size is reused when the
  subnet exists and `24` is used when it does not.
- **Subnet conflicts fail closed.** A requested subnet name that already exists
  on the enclave with a **different** prefix size, or with an incompatible
  delegation (the PostgreSQL subnet must be delegated to
  `Microsoft.DBforPostgreSQL/flexibleServers`; the private-endpoint subnet must
  have no delegation), stops the deployment before any write is attempted. The
  two requested subnet names must also differ from each other.
- **Community binding is still validated.** For an existing enclave, the live
  `communityResourceId` must match the community this deployment resolves,
  otherwise Phase B would create community endpoints in the wrong community.
- **Role assignments and principals use plain array union.** Identical entries
  are deduplicated; entries that share a `roleDefinitionId` but list different
  principals are both retained. No per-principal merging is attempted.
- **Approvals are never weakened.** Live approval settings on an existing
  enclave are reused as-is, so a redeploy cannot downgrade a `Required` gate.

Adding a *different* workload (for example AKS) to the same enclave later
follows the same contract: point at the enclave by `resourceId`, request its
own subnets and principals, and everything PostgreSQL configured is preserved
by the union.

## Deployment command

```sh
az deployment sub create \
  --location <region> \
  --parameters ave-templates/workloads/postgresql/examples/<scenario>.bicepparam
```

## Scenario parameter files

| Scenario | Parameter file | Description |
| --- | --- | --- |
| Secure new | [examples/postgresql-secure-new.bicepparam](./examples/postgresql-secure-new.bicepparam) | Fully managed community, enclave, workload, foundation, and server |
| Existing compatible | [examples/postgresql-existing-compatible.bicepparam](./examples/postgresql-existing-compatible.bicepparam) | Existing community and enclave, existing server |
| Existing additive | [examples/postgresql-existing-additive.bicepparam](./examples/postgresql-existing-additive.bicepparam) | Existing enclave with new dedicated subnets, role assignments, and maintenance principals added |

Copy the appropriate file, replace every placeholder value, and deploy. Do not copy or modify the `.bicep` source files.

## Required vs. defaulted parameters

### Always required (no default)

- `deploymentPrincipal.objectId`
- `deploymentPrincipal.principalType`
- `community` (mode plus required sub-fields)
- `enclave` (mode plus required sub-fields)
- `server` (mode plus required sub-fields)
- managed `enclave.approvalSettings` — all four actions must be declared explicitly on every deployment
- managed server `administrators`

### Defaulted (can omit)

- `deploymentContext` — defaults to `{}` (inherits ARM deployment location and subscription, resolves `instance` to `001`, and applies no tags)
- `workload` — defaults to `{ mode: 'managed' }` with Community-derived names
- `foundation` — defaults all five child selections to managed mode
- `networkFinalization` — defaults to `{ mode: 'Managed' }`
- `communityConnectivity` — defaults to `[]`
- `enableTelemetry` — defaults to `true`
- All optional sub-fields within each object (see Defaults matrix below)

### Community-derived naming

The template derives `communityName` from `community.name` in managed mode or
from the final segment of `community.resourceId` in existing mode. Overrides
remain available for every generated resource name. Defaults follow Microsoft's
[CAF resource naming guidance](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming),
[resource abbreviation recommendations](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations),
and [Azure resource name rules](https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules).

`deploymentContext.instance` is an optional CAF instance discriminator and
defaults to `001`. Use a distinct one-to-five-character alphanumeric value such
as `002` or `a01` for each generated workload/enclave name set in the same
Community. The instance is included directly in generated enclave, resource
group, workload, identity, and database names, and in the unique suffix hash for
Key Vault, PostgreSQL server, and enclave connection names. All names remain
individually overridable.

The defaults use `rg`, `id`, `kv`, `pgsql`, and `snet` for Azure resource types
and `cmt`, `ve`, `wl`, `ce`, and `ec` for Mission concepts. The Key Vault
private endpoint is the documented legacy `-pe` compatibility exception to
CAF's recommended `pep` abbreviation. Service names that require lowercase are
normalized. `take()` bounds names before suffixes:

- virtual enclave: `ve-<community>-pgsql-<instance>` (maximum 64)
- enclave resource group: `rg-<community>-pgsql-enclave-<instance>` (maximum 90)
- workload: `wl-<community>-pgsql-<instance>` (maximum 30)
- workload resource group: `rg-<community>-pgsql-workload-<instance>` (maximum 90)
- Server identity: `id-<community>-pgsql-<instance>` (maximum 128)
- Key Vault: `kv<community-without-hyphens><8-char-unique-suffix>` where the suffix hash includes the instance (maximum 24)
- Key Vault private endpoint: `<key-vault-name>-pe` (legacy deterministic suffix retained for redeployment compatibility; CAF generally recommends `pep`)
- server: `pgsql-<lowercase-community>-<8-char-unique-suffix>` (maximum 63)
- default database: `db_<lowercase_community>_pgsql_<instance>` (maximum 63)
- generated Mission endpoint/connection: `ce-pg-<8-character-hash>` / `ec-pg-<8-character-hash>`; only the connection hash includes the instance (maximum 64)

This folder contains a PostgreSQL workload profile built only from local Bicep modules. Phase A, Phase B, and Phase C are internal implementation details of [avePostgreSql.bicep](./avePostgreSql.bicep) and are not independent customer deployment targets.

## What this profile does

- Creates or references a Mission community and Mission virtual enclave.
- Registers a Mission workload for the PostgreSQL workload resource group.
- Creates or references the PostgreSQL server identity, Key Vault, CMK key, and private DNS zones required by PostgreSQL Flexible Server. For a managed server identity, also grants it Microsoft Graph `User.Read.All` through the Microsoft Graph Bicep extension before PostgreSQL Entra administrator creation.
- Creates a Key Vault private endpoint and private DNS VNet links with deterministic names.
- Creates or references PostgreSQL Flexible Server using Microsoft Entra-only authentication.
- When creating a new enclave (`enclave.resourceId` omitted), applies the caller's explicitly declared approval settings. Callers must submit all four actions, with the recommended secure-new starting point being all four set to `NotRequired`. For an existing enclave the live approval settings are read and reused.
- Never deploys passwords or local database administrator credentials.
- Never writes NSGs, route tables, routes, service endpoints, firewalls, or direct Mission-managed VNet/subnet resources.

## Prerequisite checklist

Minimum prerequisites depend on which `managed` versus `existing` options you choose.

### Always required

- Bicep CLI or Azure CLI with `bicep build`.
- A deployment principal with ARM permissions to deploy the selected scopes and child resources.
- At least one Microsoft Entra PostgreSQL administrator declaration for managed servers.
- Microsoft Graph `User.Read.All` for the PostgreSQL server identity (see [Server identity Microsoft Graph prerequisite](#server-identity-microsoft-graph-prerequisite) below). This template treats the grant as a required precondition and assigns it automatically for managed identities. This is a separate prerequisite from PostgreSQL Entra administrator creation (see the administrator API note below) — Azure RBAC roles alone (Owner, Contributor, User Access Administrator, Managed Identity Contributor, etc.) are not a substitute for this Microsoft Graph application permission.

### Server identity Microsoft Graph prerequisite

PostgreSQL Flexible Server's Microsoft Entra administrator creation calls Microsoft Graph to resolve directory objects. This template's intended design is that the PostgreSQL server's user-assigned managed identity — the single general-purpose identity attached to the server, used for both CMK key access and PostgreSQL's own Microsoft Graph/Entra administrator validation calls — holds the Microsoft Graph **application** permission `User.Read.All`, which this template automatically grants for a managed identity, before PostgreSQL Entra administrator creation runs. Microsoft Graph application permissions can only be granted through Microsoft Graph itself (or the Microsoft Graph Bicep extension) — never through Azure RBAC — and initial tenant consent cannot be self-bootstrapped by this template.

> **Resolved live-testing finding — administrator API version:** Microsoft has not published `User.Read.All` on the server identity as a documented, guaranteed-sufficient requirement for PostgreSQL Flexible Server Entra administrator creation, and this README does not claim it is; it remains the template's intended/best-effort Microsoft Graph permission for server identity directory-object resolution and is unrelated to the finding below. Separately, live Azure Government testing found that PostgreSQL Entra administrator creation failed with `AadAuthPrincipalCreationFailed: 0LP01 Outcome: 30` when the administrator child resource used the `Microsoft.DBforPostgreSQL/flexibleServers/administrators@2024-08-01` API together with its mixed-case `principalType` contract values (`User` / `Group` / `ServicePrincipal`). A direct ARM PUT against the `2025-08-01` administrators API using the upper-snake-case values (`USER` / `GROUP` / `SERVICE_PRINCIPAL`) succeeded, and `az postgres flexible-server ad-admin list` confirmed the administrator now exists. This template's administrator child resource has been updated to deploy at API `2025-08-01` and normalize the customer-facing `principalType` contract to these API-required values, so this is no longer an open or unresolved condition in this template. Diagnostic-only changes tried during that investigation (additional Graph roles beyond `User.Read.All`, an outbound Internet allow rule, and a combined system+user-assigned identity) were reverted and are not part of this template.

This template supports two mutually exclusive, supported prerequisite paths, selected through `foundation.serverIdentity`:

**Path A — Managed server identity (default), deployment identity pre-authorized for the Graph Bicep assignment**

- `foundation.serverIdentity.mode = 'managed'` (the default recommended posture).
- The template creates the server's user-assigned identity, then declaratively grants it Microsoft Graph `User.Read.All` using the [Microsoft Graph Bicep extension](https://learn.microsoft.com/en-us/graph/templates/bicep/overview-bicep-templates-for-graph) (`Microsoft.Graph/appRoleAssignedTo@v1.0`), before PostgreSQL Entra administrator creation runs.
- **Prerequisite**: the principal that runs this deployment must already be pre-consented by a suitably privileged Entra administrator (for example, a Privileged Role Administrator) with the Microsoft Graph **application** permissions `AppRoleAssignment.ReadWrite.All` and `Application.Read.All` (or an equivalent higher-privileged combination, such as `AppRoleAssignment.ReadWrite.All` + `Directory.Read.All`). These are Microsoft Graph API permissions on the deployment identity's service principal, not Azure RBAC roles, and they must be consented before the first deployment — this consent step cannot be automated by the template itself.
- Set `foundation.serverIdentity.graphPermissionGrant.mode = 'Skip'` only if an equivalent out-of-band process already performs this grant; omitting this override leaves the grant enabled by default.
- Supported in Azure Government (Microsoft Cloud for US Government) as well as global Azure; the Microsoft Graph Bicep extension and the well-known Microsoft Graph application ID/app role ID used by this template are the same across these clouds.

**Path B — Existing (customer-precreated) server identity**

- `foundation.serverIdentity.mode = 'existing'` with `foundation.serverIdentity.resourceId` set to the full Azure resource ID of a user-assigned managed identity the customer created and granted `User.Read.All` themselves, ahead of time, through Microsoft Graph (App registrations → API permissions → Microsoft Graph → Application permissions → `User.Read.All`, with admin consent granted).
- The template never creates this identity and never attempts a Microsoft Graph app-role grant for it — it is used as-is for PostgreSQL CMK encryption, Key Vault RBAC, and all downstream references.
- Use this path when the deployment identity cannot be pre-authorized for `AppRoleAssignment.ReadWrite.All`/`Application.Read.All`, or when organizational policy requires Microsoft Graph consent to be performed by a separate, dedicated process outside of infrastructure-as-code.

Choose exactly one path per deployment; do not combine `mode: 'managed'` with a manually pre-granted identity, and do not select `mode: 'existing'` without first completing the Microsoft Graph grant out of band.

### Existing infrastructure prerequisites when selected

Supply resource IDs for every selected `existing` object:

- Existing Community: `community.resourceId`
- Existing Enclave: `enclave.resourceId`
- Existing Mission workload registration: `workload.resourceId`
- Existing server identity: `foundation.serverIdentity.resourceId` (must already have Microsoft Graph `User.Read.All` granted; see [Server identity Microsoft Graph prerequisite](#server-identity-microsoft-graph-prerequisite))
- Existing Key Vault: `foundation.keyVault.resourceId`
- Existing Key Vault key: `foundation.key.resourceId`
- Existing delegated private DNS zone: `foundation.privateDns.delegatedZone.resourceId`
- Existing Key Vault private-link DNS zone: `foundation.privateDns.keyVaultPrivateLinkZone.resourceId`
- Existing PostgreSQL server: `server.resourceId`
- Existing Mission Phase B endpoint/connection IDs: `networkFinalization.communityEndpointResourceIds`, `networkFinalization.enclaveConnectionResourceIds`, or the approved-change variants

If `community.mode = 'existing'`, that existing Community is the minimum infrastructure prerequisite for the Mission side of the deployment.

### Identity and group checklist

These grants are separate. Reusing the same Entra group is allowed, but each
use is configured independently; the managed empty-array workload default
described below is the only implicit role assignment.

1. **Deployment principal**
   - Declared in `deploymentPrincipal`.
   - Seeds Mission maintenance principals, unioned with any principals the enclave already declares.
   - When `enclave.workloadRoleAssignments` is omitted or empty, it also receives the managed default Mission **workload-scope** assignment using Azure built-in Owner role definition `8e3af657-a8ff-443c-a75c-2fe8c4bcb635`. Owner is required because Mission creates a RoleInversion-Contributor deny assignment that blocks `Microsoft.Authorization/*/Write`, while this deployment must manage role assignments inside the workload resource group.
   - This default does **not** make the principal a Mission approver, Mission enclave-scope role assignee, standard Azure RBAC assignee, or PostgreSQL administrator.

2. **Mandatory approval approvers**
   - Declared inside `approvalSettings` for each `Required` action.
   - Each `Required` action needs:
     - `approvalPolicy: 'Required'`
     - one or more `mandatoryApprovers[].approverEntraId`
     - `minimumApproversRequired >= 1`
   - `NotRequired` needs no approver IDs and the module normalizes it to an empty list with minimum `0`.
   - When creating a new enclave, these declarations are applied on the enclave PUT. When targeting an existing enclave they are omitted entirely: the live approval settings are read and carried forward unchanged, so a redeploy can never downgrade a live `Required` gate.
   - If a new enclave sets `Required` for connection or endpoint actions, later Phase B connectivity work can wait on external approval. The template cannot self-approve.
   - For existing enclaves, the template never disables or weakens live approvals. If the existing enclave already requires approval for endpoint, connection, or subnet-union operations, deployment completion depends on external approver action within an ARM/RP timing window that is not publicly guaranteed. The template cannot self-approve, and deployment RBAC is not approval authority.
   - Separate actions exist for:
     - `connectionCreation`
     - `connectionUpdate`
     - `enclaveEndpointUpdate`
     - `enclaveMaintenanceMode`

3. **Enclave role-assignment principals**
   - Declared in `enclave.enclaveRoleAssignments[*].principals`.
   - Intended for Mission enclave-scope role assignments. Always unioned with the enclave's live collection.

4. **Workload role-assignment principals**
   - Declared in `enclave.workloadRoleAssignments[*].principals`.
   - Intended for Mission workload-scope role assignments.
   - A caller-supplied non-empty array is unioned with whatever the enclave already declares. If the array is omitted or empty, the template seeds the deployment principal with workload-scope Owner as described above. An explicit override must retain sufficient Authorization write permission if role assignments are managed.
   - `enclave.enclaveRoleAssignments` is unioned the same way and is never populated by this default.

5. **Maintenance principals**
   - Declared implicitly as `deploymentPrincipal` plus any `enclave.additionalMaintenancePrincipals`, unioned with the enclave's live principal set.
   - These are used in Mission `maintenanceModeConfiguration.principals`.
   - The maintenance-principal and role-assignment collections remain distinct even when the default places `deploymentPrincipal` in both.

6. **PostgreSQL administrators**
   - Declared in `server.administrators` for managed servers.
   - Each entry requires:
     - `objectId`
     - `principalName` (UPN, display name, or group name as appropriate)
     - `principalType`
     - `tenantId`

7. **Deployment automation / service principal permissions**
   - The automation identity that runs the deployment needs ARM permission to create or update the selected resources, including role assignments if those are included.
   - That automation identity is distinct from the PostgreSQL CMK managed identity.

8. **Server managed identity**
   - Declared in `foundation.serverIdentity`.
   - The single general-purpose user-assigned managed identity attached to the PostgreSQL Flexible Server, created or referenced for both CMK key access and PostgreSQL's own Microsoft Graph/Entra administrator validation calls.
   - Usually a managed identity, not a pre-created human user/group prerequisite.
   - Also requires Microsoft Graph `User.Read.All` — see [Server identity Microsoft Graph prerequisite](#server-identity-microsoft-graph-prerequisite).

### Grant model notes

These are separate layers of access:

- Mission approval approvers
- Mission maintenance principals
- Mission enclave/workload role assignments
- Azure ARM deployment permissions
- PostgreSQL data-plane administration

Do not assume one layer implies the others beyond the explicit managed
empty-array workload assignment default documented above.

### RBAC inheritance and workload visibility

Mission describes these properties as:

- `rbacInheritance`: controls whether standard Azure RBAC role inheritance applies to workload resource group(s)
- `workloadResourceVisibility`: specifies whether resources in workload resource group(s) are visible through standard RBAC

Practical implication:

- If either setting is `Disabled`, plan explicit access deliberately.
- Mission role assignments and standard Azure RBAC are separate mechanisms.
- The templates default managed PostgreSQL enclaves to `rbacInheritance = 'Disabled'` and `workloadResourceVisibility = 'Disabled'`, so readers/operators may need explicit assignment even if they can deploy the template.
- To prevent Mission's RoleInversion-Contributor deny assignment from blocking the `Microsoft.Authorization/*/Write` operations required to manage role assignments inside the workload resource group, an omitted or empty managed `workloadRoleAssignments` array defaults to a Mission workload-scope Owner assignment for `deploymentPrincipal`. A non-empty caller list is preserved unchanged, but it must retain sufficient Authorization write permission if role assignments are managed. This default does not create a standard Azure RBAC assignment at the subscription, resource-group, or resource scope.

## Internal orchestration (reference)

[avePostgreSql.bicep](./avePostgreSql.bicep) chains the three phase modules through Bicep output dependencies:

1. Phase A ([avePostgreSqlEnclaveDeployment.bicep](./avePostgreSqlEnclaveDeployment.bicep)) creates or validates the Mission community, enclave, workload, server identity, Key Vault, CMK key, private DNS zones, and Key Vault private endpoint. It emits a `phaseA` handoff object.
2. Phase B ([avePostgreSqlEnclaveNetworkFinalization.bicep](./avePostgreSqlEnclaveNetworkFinalization.bicep)) consumes the Phase A handoff and creates or references Mission community endpoints and enclave connections. It emits a `foundation` handoff object.
3. Phase C ([avePostgreSqlWorkloadDeployment.bicep](./avePostgreSqlWorkloadDeployment.bicep)) consumes the Phase B foundation handoff and creates or validates the PostgreSQL Flexible Server.

This chain is fully automated by the production template. Customers do not invoke phase modules directly.

## Parameter guide

All parameters below are top-level parameters on [avePostgreSql.bicep](./avePostgreSql.bicep). They map directly to the phase module contracts documented here for reference. Customers set these in their `.bicepparam` file.

## `deploymentContext` parameter

- `subscriptionId` - optional target subscription override
- `location` - optional deployment location
- `instance` - optional one-to-five-character CAF instance discriminator; defaults to `001`. Short numeric or alphanumeric values such as `002` or `a01` are recommended.
- `tags` - optional shared tags

### `deploymentPrincipal`

Required:

- `objectId`
- `principalType` = `User | Group | ServicePrincipal`

This principal is always a maintenance principal, unioned with any principals
the enclave already declares. It is also the default Mission workload-scope
Owner principal when `enclave.workloadRoleAssignments` is omitted or empty. The
role definition ID is `8e3af657-a8ff-443c-a75c-2fe8c4bcb635`. Owner is required
because Mission's RoleInversion-Contributor deny assignment blocks
`Microsoft.Authorization/*/Write` and the deployment manages role assignments
inside the workload resource group. A non-empty caller array is unioned with the
enclave's live collection, but it must retain sufficient Authorization write
permission if role assignments are managed; `enclaveRoleAssignments` is unioned
independently.

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

One shape, no `mode`. Omit `resourceId` to create; supply it to extend.

Create a new enclave:

```bicep
enclave: {
  // resourceId omitted → create a new enclave
  name: 'custom-enclave' // optional; defaults to ve-<community>-pgsql
  resourceGroupName: 'rg-custom-enclave' // optional
  addressSpaceCidr: '10.250.0.0/16' // required when creating
  approvalSettings: { // required when creating
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
  postgreSqlSubnet: { // optional object
    networkPrefixSize: 24 // optional
    name: 'snet-postgresql' // optional
  }
  privateEndpointSubnet: { // optional object
    networkPrefixSize: 24 // optional
    name: 'snet-private-endpoints' // optional
  }
  allowSubnetCommunication: true // optional
  bastionEnabled: true // optional
  diagnosticDestination: 'Both' // optional
  enclaveRoleAssignments: [] // optional
  workloadRoleAssignments: [] // optional; empty seeds deploymentPrincipal as workload-scope Owner
  additionalMaintenancePrincipals: [] // optional
}
```

Names, resource-group names, and subnet request objects are optional. Both
subnet prefix sizes default to `24`; subnet names default to `snet-postgresql`
and `snet-private-endpoints`. `addressSpaceCidr` and all four `approvalSettings`
are required when creating and have no default. The recommended secure-new
starting point is to submit all four actions explicitly as `NotRequired`.

To require approvals at creation time, replace the relevant action blocks with
`Required` policies:

```bicep
enclave: {
  name: 'contoso-enclave'
  resourceGroupName: 'rg-contoso-enclave'
  addressSpaceCidr: '10.250.0.0/16'
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
  }
  privateEndpointSubnet: {
    networkPrefixSize: 24
  }
}
```

Consume an existing enclave whose subnets this workload already uses:

```bicep
enclave: {
  resourceId: '/subscriptions/.../resourceGroups/.../providers/Microsoft.Mission/virtualEnclaves/existing-enclave'
  postgreSqlSubnet: {
    name: 'snet-postgresql'
  }
  privateEndpointSubnet: {
    name: 'snet-private-endpoints'
  }
}
```

Nothing else is declared: location, address space, approval settings, Bastion,
diagnostic destination, subnet communication, RBAC inheritance, workload
visibility, governed services, monitoring, and the community binding are all
read from the live enclave and carried forward unchanged. Because both subnets
already exist under those names with matching prefix sizes and delegations,
the resulting enclave PUT is a no-op.

Add a second workload's subnets, role assignments, and maintenance principals
to an existing enclave:

```bicep
enclave: {
  resourceId: '/subscriptions/.../resourceGroups/.../providers/Microsoft.Mission/virtualEnclaves/existing-enclave'
  postgreSqlSubnet: {
    name: 'snet-postgresql-workload02'
    networkPrefixSize: 24
  }
  privateEndpointSubnet: {
    name: 'snet-private-endpoints-workload02'
    networkPrefixSize: 24
  }
  enclaveRoleAssignments: [
    {
      roleDefinitionId: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
      principals: [
        {
          id: '99999999-9999-9999-9999-999999999999'
          type: 'Group'
        }
      ]
    }
  ]
  workloadRoleAssignments: [
    {
      roleDefinitionId: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
      principals: [
        {
          id: '11111111-1111-1111-1111-111111111111'
          type: 'User'
        }
      ]
    }
  ]
  additionalMaintenancePrincipals: [
    {
      id: '44444444-4444-4444-4444-444444444444'
      type: 'Group'
    }
  ]
}
```

Notes for existing enclaves:

- Subnets are unioned by name, so the two subnets above are appended alongside
  every subnet other workloads already placed on the enclave. Redeploying does
  not duplicate or mutate them.
- A requested subnet name that already exists with a different
  `networkPrefixSize`, or with an incompatible delegation, fails the deployment
  before any write. The two requested names must also differ from each other.
- Role assignments and maintenance principals are combined with a plain array
  `union()`. Identical entries deduplicate; entries sharing a
  `roleDefinitionId` with different principal lists are both kept.
- The live `communityResourceId` must match the community this deployment
  resolves, otherwise Phase B would create endpoints in the wrong community.
- Pure Bicep cannot issue the documented Mission PATCH for a subnet-union
  change, so the template inventories the live writable contract and sends the
  full union back through the Mission virtualEnclaves API with a full PUT. It
  never writes `Microsoft.Network/virtualNetworks/subnets` directly.
- The template never weakens or self-approves existing approval policies.
  Existing `Required` approvals can delay subnet, endpoint, or connection
  operations until an external approver acts.
- The enclave's resource group is not created or modified; it must already
  exist, which it does by definition of the supplied resource ID.

### `workload`

Managed:

```bicep
workload: {
  mode: 'managed'
  name: 'custom-workload' // optional
  resourceGroupName: 'rg-custom-workload' // optional
}
```

The entire parameter can be omitted. It defaults to `{ mode: 'managed' }`, with
`wl-<community>-pgsql` and `rg-<community>-pgsql-workload`.

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

- `serverIdentity`
- `keyVault`
- `key`
- `privateDns.delegatedZone`
- `privateDns.keyVaultPrivateLinkZone`

Each child supports `managed` or `existing`.
The entire `foundation` parameter can be omitted; every child then uses
`managed` mode. Supply the object only to override a managed setting or select
an existing resource.

Managed examples:

```bicep
foundation: {
  serverIdentity: {
    mode: 'managed'
    // Defaults to graphPermissionGrant.mode: 'Managed' — the deployment
    // creates the identity and grants it Microsoft Graph "User.Read.All"
    // through the Microsoft Graph Bicep extension. This requires the
    // deployment identity to be pre-authorized (see the Server identity
    // Microsoft Graph prerequisite section above). Set to 'Skip' only if an
    // equivalent out-of-band process already performs this grant.
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

Existing examples require resource IDs and expected configuration values. Use [postgresql-existing-compatible.bicepparam](./examples/postgresql-existing-compatible.bicepparam) as the reference shape. For `serverIdentity.mode = 'existing'`, the referenced identity must already have Microsoft Graph `User.Read.All` granted out of band — see [Server identity Microsoft Graph prerequisite](#server-identity-microsoft-graph-prerequisite).

## `networkFinalization` and `communityConnectivity` parameters

Module reference: [avePostgreSqlEnclaveNetworkFinalization.bicep](./avePostgreSqlEnclaveNetworkFinalization.bicep)

### Inputs

- `deploymentContext.instance` - optional, default `001`
- `deploymentContext.tags` - optional
- `phaseA` - required serialized output from Phase A
- `networkFinalization` - optional mode object, default `{ mode: 'Managed' }`
- `communityConnectivity` - optional connectivity requests, default `[]`

### `networkFinalization`

Managed:

```bicep
networkFinalization: {
  mode: 'Managed'
}
```

The managed block above is the default and can be omitted.

Existing reference-only:

```bicep
networkFinalization: {
  mode: 'ExistingReferenceOnly'
  communityEndpointResourceIds: [
    '/subscriptions/.../communityEndpoints/ce-postgresql'
  ]
  enclaveConnectionResourceIds: [
    '/subscriptions/.../enclaveConnections/ec-postgresql'
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

Every supplied existing endpoint and connection ID is read before Phase B emits
outputs. The gate requires the exact Mission resource type and ID, existence,
the Phase A community/enclave relationship, matching location, and a connection
destination among the validated endpoint IDs. Existing endpoints used by
`communityConnectivity` are validated before a managed connection is created.

### `communityConnectivity`

Each item defines:

- `connectionName` - optional
- `endpoint` - managed or existing
- `sourceSubnets` - required array of:
  - `DelegatedPostgreSql`
  - `PrivateEndpoints`

Generated endpoint names deliberately retain the already CAF-compliant legacy
`ce-pg-<same original hash>` formula to avoid endpoint renames. Endpoint defaults
therefore remain shareable across workload instances when the community, rules,
and array position are the same. New generated connection names use
`ec-pg-<hash>`, with the resolved instance included alongside the enclave,
endpoint, and source-subnet kinds in the hash. Distinct workload instances can
therefore share an enclave and endpoint without overwriting each other's default
connection. An explicit `connectionName` always takes precedence. Callers that
already deployed a generated `conn-pg-...` connection must set `connectionName`
to that legacy name before rerunning. No deployment was run as part of this
naming change.

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

### Required outbound rule for private-network Microsoft Entra authentication

Microsoft's official guidance for Microsoft Entra ID authentication with a
privately networked (VNet-integrated) Azure Database for PostgreSQL flexible
server states that private access requires "an outbound NSG rule that allows
traffic to the `AzureActiveDirectory` service tag" — see
[Configure Microsoft Entra authentication for Azure Database for PostgreSQL flexible server — Configure network requirements](https://learn.microsoft.com/en-us/azure/postgresql/security/security-entra-configure).
This profile never writes NSGs directly. Mission's auto-generated managed
resource group and the NSGs inside it are owned exclusively by Mission; direct
writes to network security rules in that managed resource group are
unsupported and blocked by a Mission deny assignment. The only supported path
is declarative: a Mission community endpoint plus an enclave connection
request, expressed through the same `communityConnectivity` contract used for
every other entry — a `ServiceTag` rule destined for `AzureActiveDirectory` on
TCP/443, sourced from the `DelegatedPostgreSql` subnet. Mission's own exempt
Connection Manager service principal (not this template or its deployment
identity) materializes the resulting NSG rule inside the managed resource
group once the community endpoint and enclave connection are approved.
Mission's fail-closed default denies everything not explicitly listed in a
rule collection, so adding this entry is additive and does not relax that
default-deny posture.

```bicep
communityConnectivity: [
  {
    endpoint: {
      mode: 'managed'
      ruleCollection: [
        {
          endpointRuleName: 'aad-entra-outbound'
          destinationType: 'ServiceTag'
          destination: 'AzureActiveDirectory'
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
    ]
  }
]
```

This entry must be supplied by the caller (it is not injected implicitly by
the template, consistent with `communityConnectivity` defaulting to `[]`) so
that redeploying the same `.bicepparam` regenerates this rule instead of
depending on an out-of-band, manually added live NSG rule. The recommended
production `.bicepparam` files include this entry.

## `server` parameter

Module reference: [avePostgreSqlWorkloadDeployment.bicep](./avePostgreSqlWorkloadDeployment.bicep)

### Inputs

- `deploymentContext.location` - optional
- `deploymentContext.instance` - optional, default `001`
- `deploymentContext.tags` - optional
- `foundation` - required serialized output from Phase B
- `server` - required managed or existing server object

### Managed server

```bicep
server: {
  mode: 'managed'
  name: 'pgsql-custom-name' // optional
  location: location // optional
  version: '16' // optional
  availabilityZone: '1' // optional
  sku: { // optional object
    name: 'Standard_D4ds_v4' // optional with the object omitted
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
  databases: [] // optional; explicit [] creates none
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

Omitting `version` and `sku` selects PostgreSQL `16` and
`Standard_D4ds_v4`/`GeneralPurpose`. Omitted storage, backup, and high
availability retain `128` GiB, `35` days, and `Disabled`. If `databases` is
omitted, the template creates one Community-derived lowercase database name;
an explicit `databases: []` creates none.

### Existing server

Existing-server mode is reference-only and requires:

- `resourceId`
- `expectedConfiguration`

That expected object is validated against:

- location
- version
- availability zone
- full SKU name and tier
- storage size, type, tier, IOPS, throughput, and autogrow (including absence
  for optional service properties)
- backup retention with geo redundancy fixed to `Disabled`
- high availability mode and standby zone
- maintenance mode/window
- delegated subnet resource ID
- private DNS zone resource ID
- Entra auth settings
- primary server identity resource ID, key URI, encryption mode, and the exact single
  user-assigned identity set
- absence of geo-backup CMK state
- equality to the Phase A subnet, DNS, identity, and key handoff

The existing-server contract intentionally excludes administrators, databases,
server configurations, diagnostic settings, and deletion locks. Those are
separate child or extension resources that ARM template expressions cannot
enumerate reliably enough to prove an exact set (including absence). The
template does not silently accept customer assertions for unreadable state;
those fields are not advertised for existing servers. Validate those resources
through a separate approved inventory process. Managed-server mode continues
to own and configure them.

See [postgresql-existing-compatible.bicepparam](./examples/postgresql-existing-compatible.bicepparam).

## Defaults matrix

Only values implemented in code are listed here.

### Phase A defaults

| Surface | Field | Default |
| --- | --- | --- |
| deploymentContext | subscriptionId | current subscription |
| deploymentContext | location | `deployment().location` |
| deploymentContext | instance | `001` |
| deploymentContext | tags | `{}` |
| community managed | addressSpace | `''` |
| community managed | addressSpaces | `[]` |
| community managed | dnsServers | `[]` |
| community managed | communityFirewallSku | `Standard` |
| community managed | policyOverride | `Enclave` |
| enclave (new) | name | `ve-${take(communityName, 54 - length(instance))}-pgsql-${instance}` |
| enclave (new) | resourceGroupName | `rg-${take(communityName, 72 - length(instance))}-pgsql-enclave-${instance}` |
| enclave | postgreSqlSubnet | `{}` |
| enclave | postgreSqlSubnet.name | `snet-postgresql` |
| enclave | postgreSqlSubnet.networkPrefixSize | `24` |
| enclave | privateEndpointSubnet | `{}` |
| enclave | privateEndpointSubnet.name | `snet-private-endpoints` |
| enclave | privateEndpointSubnet.networkPrefixSize | `24` |
| enclave (new) | allowSubnetCommunication | `true` |
| enclave (new) | bastionEnabled | `true` |
| enclave (new) | diagnosticDestination | `Both` |
| enclave | enclaveRoleAssignments | `[]` |
| enclave | workloadRoleAssignments | `deploymentPrincipal` as Mission workload-scope Owner (`8e3af657-a8ff-443c-a75c-2fe8c4bcb635`) when omitted or `[]`; a non-empty caller array is unioned with the live enclave's collection and must retain sufficient Authorization write permission if role assignments are managed |
| enclave | additionalMaintenancePrincipals | `[]` |
| enclave (new) | approvalSettings | **no default; required**. Recommended initial value is all four actions explicitly set to `NotRequired`. |
| workload | whole object | `{ mode: 'managed' }` |
| workload managed | name | `wl-${take(communityName, 20 - length(instance))}-pgsql-${instance}` |
| workload managed | resourceGroupName | `rg-${take(communityName, 71 - length(instance))}-pgsql-workload-${instance}` |
| foundation | whole object | all five child resources in `managed` mode |
| foundation.serverIdentity managed | resourceGroupName | workload resource group |
| foundation.serverIdentity managed | location | deployment location |
| foundation.serverIdentity managed | name | `id-${take(communityName, 114 - length(instance))}-pgsql-${instance}` |
| foundation.serverIdentity managed | graphPermissionGrant.mode | `Managed` (grants Microsoft Graph `User.Read.All` via the Microsoft Graph Bicep extension) |
| foundation.keyVault managed | resourceGroupName | workload resource group |
| foundation.keyVault managed | name | `kv${take(compactCommunityName, 14)}${take(uniqueString(targetSubscriptionId, communityName, instance), 8)}` |
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
| networkAclsBypass | `AzureServices` |
| ipRules | `[]` |
| virtualNetworkSubnetResourceIds | `[]` |
| soft delete | enabled |
| purge protection | enabled |
| RBAC authorization | enabled |

### Phase B defaults

| Surface | Field | Default |
| --- | --- | --- |
| deploymentContext | instance | `001` |
| deploymentContext | tags | `{}` |
| communityConnectivity | whole array | `[]` |
| managed endpoint | name | legacy-compatible `ce-pg-${take(uniqueString(communityResourceId, ruleCollection, index), 8)}` |
| managed endpoint | updateMode | `Manual` |
| managed connection | connectionName | `ec-pg-${take(uniqueString(enclaveResourceId, endpointResourceId, sourceSubnets, instance), 8)}` |
| managed/existing connection | sourceCidr | derived from Phase A subnet CIDRs |
| networkFinalization | whole object | `{ mode: 'Managed' }` |

### Phase C defaults

| Surface | Field | Default |
| --- | --- | --- |
| deploymentContext | location | Phase A location |
| deploymentContext | instance | `001` |
| deploymentContext | tags | `{}` |
| managed server | name | `pgsql-${take(lowercaseCommunityName, 48)}-${take(uniqueString(targetSubscriptionId, communityName, instance), 8)}` |
| managed server | location | `server.location ?? deploymentContext.location ?? foundation.phaseA.location` |
| managed server | version | `16` |
| managed server | sku | `{ name: 'Standard_D4ds_v4', tier: 'GeneralPurpose' }` |
| managed server sku | tier | `GeneralPurpose` |
| managed server storage | object | `{}` |
| managed server storage.type | `Premium_LRS` |
| managed server storage.storageSizeGB | `128` |
| managed server storage.autoGrow | `Enabled` except `PremiumV2_LRS` forces `Disabled` |
| managed server backup.geoRedundancy | `Disabled` |
| managed server backup.retentionDays | `35` |
| managed server highAvailability | `{ mode: 'Disabled' }` |
| managed server maintenanceWindow | omitted; platform-managed |
| managed server databases | one `db_<bounded_lowercase_community>_pgsql_<instance>` database; explicit `[]` creates none |
| managed server configurations | `[]` |
| managed server diagnostics | omitted |
| managed server deletionProtection | `CanNotDelete` |
| managed server administrators | **no default; at least one required** |

### Fields with no default that must be supplied

- `deploymentPrincipal.objectId`
- `deploymentPrincipal.principalType`
- managed `community.name`
- managed `community.resourceGroupName`
- new `enclave.addressSpaceCidr` (only when `enclave.resourceId` is omitted)
- new `enclave.approvalSettings` (only when `enclave.resourceId` is omitted; all four actions must be declared)
- existing `workload` mode-specific resource ID and expected resource-group collection
- existing-mode `resourceId` and expected configuration fields
- each Phase C managed server `administrators`

## Existing-resource compatibility and fail-closed behavior

### Existing enclave

Behavior:

- reads the full live writable enclave contract before any write
- carries immutable/shared properties forward verbatim (location, address
  space, approval settings, Bastion, diagnostic destination,
  `allowSubnetCommunication`, `rbacInheritance`, `workloadResourceVisibility`,
  community binding, monitoring, dedicated hub, tags, identity shape)
- unions subnet configurations by subnet name, so redeploys are idempotent and
  other workloads' subnets are preserved
- unions `enclaveRoleAssignments`, `workloadRoleAssignments`, and maintenance
  principals with the live collections
- unions governed services by `serviceId`, retaining live entries the template
  does not own
- performs the update through `Microsoft.Mission/virtualEnclaves@2026-03-01-preview`
- never writes `Microsoft.Network/virtualNetworks/subnets` directly
- never creates or modifies the enclave's resource group
- may still wait on external approval if the live enclave requires approval for
  the relevant Mission operation

Fails closed when:

- the requested PostgreSQL and private-endpoint subnet names are identical
- a requested subnet name already exists with a different `networkPrefixSize`
- the requested PostgreSQL subnet name already exists without the
  `Microsoft.DBforPostgreSQL/flexibleServers` delegation
- the requested private-endpoint subnet name already exists with a delegation
- the live enclave's `communityResourceId` does not match the community this
  deployment resolves

Immutable enclave properties are no longer asserted against a caller-supplied
`expectedConfiguration`; they are read and reused, so there is nothing to
mismatch.

Residual preview risk:

- this path depends on the current preview RP accepting the reconstructed
  writable property set
- validate generated ARM before deployment

### Existing workload registration

- compares `resourceGroupCollection` exactly to `expectedResourceGroupCollection`
- the Key Vault private endpoint is placed in the customer workload resource
  group, never in the Key Vault or Mission-managed resource group
- the workload resource group must exist in the enclave VNet/subnet
  subscription; cross-subscription existing-enclave requests fail closed unless
  an existing workload registration names such a customer-managed resource
  group

### Existing PostgreSQL server

- validates the expected configuration listed in the Phase C section above

### Geo-redundant backup

Geo-redundant backup is not supported by this profile because Phase A emits no
geo CMK. All managed and existing backup contracts accept only
`geoRedundancy: 'Disabled'`; `Enabled` is rejected at Bicep compile time.

## What-if limitations

Use what-if for static ARM shape, scopes, planned Azure resource declarations,
parameter/type errors, and obvious create/delete drift:

```sh
az deployment sub what-if \
  --location <region> \
  --parameters ave-templates/workloads/postgresql/examples/<scenario>.bicepparam
```

Because the `.bicepparam` file contains `using`, pass it with `--parameters`
only; do not also pass `--template-file`.

ARM what-if cannot resolve Mission runtime `reference()` outputs used between
the phases. Managed downstream resources can therefore appear as `Ignore`,
unknown, or noisy `Modify`. What-if cannot prove live compatibility for
existing/additive resources, cannot prove the safety of the additive full PUT,
and cannot predict Mission approvals. A successful what-if is never
authorization for an additive update; obtain the required review and approval
before deployment. No deployment or what-if was run as part of this change.

## Idempotent supporting resources

These resources are intentionally deterministic and do not use separate managed/existing switches solely for idempotency:

- Key Vault private endpoint: `${keyVaultName}-pe`; this legacy deterministic suffix is retained for redeployment compatibility even though CAF generally recommends `pep`, and explicit Key Vault names flow through
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
- Static validation requires no Azure deployment or resource mutation.
