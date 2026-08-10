# Azure Enclaves service-catalog foundation

`ave-templates/` is a self-contained, offline-friendly Bicep source tree for foundational Azure Virtual Enclave building blocks. It is intentionally local-path only: no Azure Verified Module references, no registry imports, no remote URLs, and no Template Spec dependencies.

## Authoring model

- `modules/common/` contains lean, single-purpose building blocks.
- `examples/` contains compile-only compositions that demonstrate how workload profiles should wrap and compose the common core.
- Consumers are expected to fork or copy this tree, then add workload-specific wrappers beside it rather than editing shared core modules in place.

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

## Mission API and version policy

- Mission community and enclave modules are pinned to `2026-03-01-preview`, which was the latest publicly documented `Microsoft.Mission` API available on Microsoft Learn as of August 2026.
- Non-Mission resource providers use stable API versions where practical.
- If the Mission RP adds or removes properties in later previews, extend wrapper modules deliberately instead of silently broadening the common core.

## Security defaults

- Key Vault defaults to RBAC authorization, purge protection, denied-by-default networking, and public network access disabled.
- Storage defaults to HTTPS-only, TLS 1.2, denied-by-default networking, public network access disabled, shared key access disabled, and blob public access disabled.
- Mission enclave defaults are fail-closed for broad visibility and inheritance: `rbacInheritance = 'Disabled'`, `workloadResourceVisibility = 'Disabled'`, and `allowSubnetCommunication = false` unless the caller opts in.
- No module hardcodes cloud suffix tables; suffixes are derived from `environment()`.

## Workload profile guidance

Workload-specific profiles should:

1. Create or reference a Mission community.
2. Compose the enclave module with explicitly chosen subnet layouts, approvals, governed services, and monitoring destinations.
3. Layer service-specific resources beside the enclave core, reusing the Key Vault, CMK, private DNS, private endpoint, storage, identity, and RBAC helpers as needed.

This foundation intentionally does **not** ship a workload-specific PostgreSQL or AKS product template yet.

## Prerequisites

- Azure CLI or standalone Bicep CLI with `bicep build` support.
- No Azure authentication is required for static validation.

## Validation commands

Run from [ave-templates/](C:/repostitories/Scripts.worktrees/azure-enclaves-service-catalog-module/ave-templates):

```powershell
bicep build .\examples\foundation-example.bicep
bicep build .\modules\common\missionCommunity.bicep
bicep build .\modules\common\missionVirtualEnclave.bicep
```

If `bicep lint` is available in the local CLI build, lint the same entry points.

## Offline and forking guarantee

Every module reference in this tree is a local relative path. Generated artifacts are not meant to be committed. Forks can validate and evolve the tree without external registries or network-dependent module restores.
