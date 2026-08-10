# Azure Enclaves service-catalog foundation

`ave-templates/` is a self-contained, offline-friendly Bicep source tree for foundational Azure Virtual Enclave building blocks plus a PostgreSQL workload profile. It is intentionally local-path only: no Azure Verified Module references, no registry imports, no remote URLs, and no Template Spec dependencies.

## Authoring model

- `modules/common/` contains lean, single-purpose building blocks.
- `workloads/postgresql/` contains the production entry point (`avePostgreSql.bicep`) and three internal phase modules. Customers do not edit these files.
- Customers author only a `.bicepparam` file that references `avePostgreSql.bicep`.

## Module inventory

- `modules/common/resourceGroup.bicep` - subscription-scoped resource group helper.
- `modules/common/userAssignedIdentity.bicep` - user-assigned managed identity.
- `modules/common/missionCommunity.bicep` - `Microsoft.Mission/communities@2026-03-01-preview` creation surface.
- `modules/common/missionCommunityReference.bicep` - existing Mission community reference surface.
- `modules/common/missionVirtualEnclave.bicep` - `Microsoft.Mission/virtualEnclaves@2026-03-01-preview` creation surface with typed network, approval, governance, monitoring, maintenance, identity, and Mission RBAC inputs.
- `modules/common/keyVault.bicep` - RBAC-only Key Vault with purge protection and private-only defaults.
- `modules/common/keyVaultKey.bicep` - CMK-oriented Key Vault key resource.
- `modules/common/storageAccount.bicep` - Storage account with HTTPS-only, TLS 1.2+, public network disabled by default, shared key disabled by default, blob public access disabled by default, and optional CMK wiring.
- `modules/common/privateDnsZone.bicep` - private DNS zone.
- `modules/common/privateDnsZoneVirtualNetworkLink.bicep` - private DNS zone to VNet link.
- `modules/common/privateEndpoint.bicep` - reusable private endpoint plus private DNS zone group.
- `modules/common/roleAssignment.bicep` - deterministic RBAC helper for resource-group, Key Vault, Key Vault key, storage account, and private DNS zone scopes.
- `modules/common/missionWorkload.bicep` - `Microsoft.Mission/virtualEnclaves/workloads@2026-03-01-preview` registration surface.
- `modules/common/missionCommunityEndpoint.bicep` - `Microsoft.Mission/communities/communityEndpoints@2026-03-01-preview` creation surface.
- `modules/common/missionEnclaveConnection.bicep` - `Microsoft.Mission/enclaveConnections@2026-03-01-preview` creation surface.

## Mission API and version policy

- Mission community and enclave modules are pinned to `2026-03-01-preview`, which was the latest publicly documented `Microsoft.Mission` API available on Microsoft Learn as of August 2026.
- Non-Mission resource providers use stable API versions where practical.
- If the Mission RP adds or removes properties in later previews, extend wrapper modules deliberately instead of silently broadening the common core.

## Security defaults

- Key Vault defaults to RBAC authorization, purge protection, denied-by-default networking, and public network access disabled.
- Storage defaults to HTTPS-only, TLS 1.2, denied-by-default networking, public network access disabled, shared key access disabled, and blob public access disabled.
- Mission enclave defaults keep broad visibility fail-closed while defaulting shared-network features on: `rbacInheritance = 'Disabled'`, `workloadResourceVisibility = 'Disabled'`, `allowSubnetCommunication = true`, `bastionEnabled = true`, and `diagnosticDestination = 'Both'` unless the caller overrides them.
- No module hardcodes cloud suffix tables; suffixes are derived from `environment()`.

## Workload profile guidance

Workload-specific profiles should:

1. Create or reference a Mission community.
2. Compose the enclave module with explicitly chosen subnet layouts, approvals, governed services, and monitoring destinations.
3. Layer service-specific resources beside the enclave core, reusing the Key Vault, CMK, private DNS, private endpoint, storage, identity, and RBAC helpers as needed.

## PostgreSQL workload profile

[workloads/postgresql/](./workloads/postgresql/) provides a complete, single-deployment PostgreSQL workload over the local common modules.

**Customers deploy one template and author one `.bicepparam` file.** Customers do not write or edit Bicep files and do not run phase deployments independently.

### Entry point

[avePostgreSql.bicep](./workloads/postgresql/avePostgreSql.bicep) is the production subscription-scope entry point. It orchestrates Phase A, Phase B, and Phase C internally through output dependencies, completing the entire supported PostgreSQL deployment in a single ARM deployment.

### Deployment command

```sh
az deployment sub create \
  --location <region> \
  --parameters ave-templates/workloads/postgresql/examples/<scenario>.bicepparam
```

### What-if

For a scenario parameter file, use:

```sh
az deployment sub what-if \
  --location <region> \
  --parameters ave-templates/workloads/postgresql/examples/<scenario>.bicepparam
```

Use `--parameters` only; the `.bicepparam` file already identifies the
production template through `using`. What-if remains useful for static ARM
shape, scopes, type errors, and obvious create/delete drift. It cannot resolve
Mission runtime `reference()` outputs, so downstream resources may be
Ignore/unknown or noisy Modify. It cannot prove existing/additive live
compatibility, a full PUT, or approvals. What-if success is never authorization
for an additive update. No deployment or what-if was run for these changes.

### Scenario parameter files

| Scenario | File |
| --- | --- |
| Secure new (fully managed) | [examples/postgresql-secure-new.bicepparam](./workloads/postgresql/examples/postgresql-secure-new.bicepparam) |
| Existing compatible (reference-only) | [examples/postgresql-existing-compatible.bicepparam](./workloads/postgresql/examples/postgresql-existing-compatible.bicepparam) |
| Existing enclave additive subnet | [examples/postgresql-existing-additive-subnet.bicepparam](./workloads/postgresql/examples/postgresql-existing-additive-subnet.bicepparam) |

### Internal modules (not customer deployment targets)

- [avePostgreSqlEnclaveDeployment.bicep](./workloads/postgresql/avePostgreSqlEnclaveDeployment.bicep) - Phase A: Mission community, enclave, workload, CMK identity, Key Vault, CMK, private DNS, and Key Vault private endpoint.
- [avePostgreSqlEnclaveNetworkFinalization.bicep](./workloads/postgresql/avePostgreSqlEnclaveNetworkFinalization.bicep) - Phase B: Mission community endpoints and enclave connections.
- [avePostgreSqlWorkloadDeployment.bicep](./workloads/postgresql/avePostgreSqlWorkloadDeployment.bicep) - Phase C: PostgreSQL Flexible Server.
- [PostgreSQL workload deployment guide](./workloads/postgresql/README.md) documents prerequisites, parameters, defaults, compatibility rules, and scenario guidance.

### Secure defaults

- PostgreSQL auth is Entra-only: `activeDirectoryAuth = Enabled`, `passwordAuth = Disabled`.
- Public network access is disabled by delegated-subnet private deployment; no public firewall rules are authored.
- Managed PostgreSQL enclaves default to `allowSubnetCommunication = true`, `bastionEnabled = true`, `diagnosticDestination = Both`, `rbacInheritance = Disabled`, and `workloadResourceVisibility = Disabled`, while governed services include PostgreSQL, Key Vault, and Private DNS Zones with `Allow/Enabled/Enforce`.
- Managed PostgreSQL enclave approval settings are applied during the initial enclave deployment. Callers must explicitly submit all four actions on every managed deployment; the recommended secure-new starting point is all four set to `NotRequired`. Reruns reapply the declared desired state, so any live `Required` policies must remain in parameters. `Required` approvals must include at least one mandatory approver object ID and `minimumApproversRequired >= 1`; `NotRequired` approvals normalize to an empty approver list with minimum `0`.
- If callers choose managed `Required` approvals for connection or endpoint actions, later Mission connectivity steps in the same orchestration can wait on external approval. The templates do not self-approve.
- DNS suffixes are derived from `environment()` and `environment().resourceManager`; no named-cloud lookup table is used.
- Managed Key Vault deployments are RBAC-only, purge-protected, private-only, and paired with a private endpoint plus private DNS.

### Existing enclave behavior and limitations

- The PostgreSQL profile never writes NSGs, route tables, service endpoints, or subnet properties. Mission owns those resources.
- Existing enclaves must explicitly choose `ReferenceOnly` or `AdditiveSubnetUpdate`.
- `ReferenceOnly` is the safe default. It cross-checks community binding, location, approval policy plus approver/count shape, Bastion, diagnostics destination, RBAC visibility posture, governed services, PostgreSQL subnet, and private-endpoint subnet before consuming the enclave.
- `AdditiveSubnetUpdate` inventories every live Mission subnet configuration, fails closed on subnet-name collisions, appends only genuinely new dedicated subnet requests, and sends the complete subnet union back through `Microsoft.Mission/virtualEnclaves@2026-03-01-preview`. Pure Bicep cannot issue the documented Mission PATCH for this subnet-union change, so the template validates and preserves the live writable contract through a full PUT instead of writing `Microsoft.Network/virtualNetworks/subnets` directly.
- The additive mode still relies on a preview RP shape and on ARM/Bicep successfully roundtripping the currently documented writable virtual-enclave properties. Treat it as a preview-path change surface and validate generated ARM before deployment.
- Multiple workloads can share an enclave only when the shared enclave settings remain compatible and each workload uses non-colliding dedicated PostgreSQL and private-endpoint subnets.
- Phase A/B handoff contracts are `3.0` and carry actual PostgreSQL/private-endpoint CIDR outputs from Mission for both managed and existing-enclave flows.

### Supporting resource idempotency

- Key Vault private endpoints use deterministic names (`${keyVaultName}-pe`).
- Private DNS VNet links use deterministic names (`link-${phaseToken}`).
- The CMK role assignment uses a deterministic GUID derived from scope, principal, role, and condition.
- Those resources intentionally use deterministic create/update semantics rather than separate managed/existing switches.

## Prerequisites

- Azure CLI or standalone Bicep CLI with `bicep build` support.
- No Azure authentication is required for static validation.

## Validation commands

Run from `ave-templates/`:

```powershell
# Build the production entry point (builds all three phase modules transitively)
bicep build .\workloads\postgresql\avePostgreSql.bicep

# Build the three phase modules individually
bicep build .\workloads\postgresql\avePostgreSqlEnclaveDeployment.bicep
bicep build .\workloads\postgresql\avePostgreSqlEnclaveNetworkFinalization.bicep
bicep build .\workloads\postgresql\avePostgreSqlWorkloadDeployment.bicep

# Validate the three scenario parameter files
bicep build-params .\workloads\postgresql\examples\postgresql-secure-new.bicepparam
bicep build-params .\workloads\postgresql\examples\postgresql-existing-compatible.bicepparam
bicep build-params .\workloads\postgresql\examples\postgresql-existing-additive-subnet.bicepparam
```

If `bicep lint` is available in the local CLI build, lint the same entry points.

## Offline and forking guarantee

Every module reference in this tree is a local relative path. Generated artifacts are not meant to be committed. Forks can validate and evolve the tree without external registries or network-dependent module restores, including the PostgreSQL workload profile.

For offline packaging or distribution, include:

- `ave-templates/workloads/postgresql/avePostgreSql.bicep` (production entry point)
- `ave-templates/workloads/postgresql/examples/*.bicepparam` (scenario parameter files)
- The complete `ave-templates/` folder (entry point depends on local module paths)

Do not include the compiled `.json` artifacts; regenerate them with `bicep build` in the target environment.
