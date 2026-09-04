# EngHub Connector Acceptance

## Research and status

- State: Disabled pending server-side OAuth repair
- Approval: Not approved
- Product: Microsoft internal Engineering Hub MCP Server
- Endpoint: `https://mcp.eng.ms/`
- Authentication: Interactive delegated Microsoft Entra organizational identity
- Installation: None; Microsoft-hosted remote endpoint
- OAuth resource: `https://mcp.eng.ms`
- OAuth scope: `api://29f3c95d-3262-44e4-b1c4-de5ba513b6c0/.default`
- Former MCP name in local configuration: `enghub-mcp`
- Configuration status: Removed from user and repository MCP configuration on 2026-09-03 because the global allowlist allowed the blocked server to attach when using `personal-data-scrub`.
- Autostart, gallery installation, and external MCP discovery remain disabled.
- Starting or restarting the server reaches Microsoft Authentication, but delegated token acquisition fails with `AADSTS500011`.
- The server advertises resource `https://mcp.eng.ms` while advertising scope `api://29f3c95d-3262-44e4-b1c4-de5ba513b6c0/.default`. Entra reports that the advertised URL resource principal is not registered in the Microsoft tenant.
- The `/mcp` route returns HTTP 404, and route-specific protected-resource discovery returns the same URL resource metadata.
- Restarting the unchanged configuration repeats the failure. Resolution requires the EngHub MCP owner to correct its OAuth protected-resource metadata or tenant application registration.
- Do not inject bearer tokens, client IDs, tenant IDs, or authorization headers as a workaround.

Authoritative inputs:

- User-supplied endpoint: https://mcp.eng.ms/
- User-supplied internal capability page: https://eng.ms/docs/cloud-ai-platform/azure-cxp/cxp-cre/foundation/governance/capabilities-tools/capabilities/sre/reliabilityengineering
- Endpoint OAuth protected-resource metadata

## Required scenarios and gates

- [ ] Delegated authentication and live connectivity
- [ ] Live tool inventory reviewed and every write-capable tool excluded
- [ ] Engineering documentation search with bounded results
- [ ] Exact page fetch from an EngHub URL
- [ ] Service resolution and navigation behavior, if exposed
- [ ] Exact no-result behavior
- [ ] Permission, partial-result, and service-error behavior
- [ ] Item-level citations and EngHub deep links
- [ ] Zero writes and no retrieved content persisted
- [ ] Direct source-agent invocation
- [ ] Explicit user approval
