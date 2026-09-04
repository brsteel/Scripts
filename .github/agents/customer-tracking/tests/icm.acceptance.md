# IcM Connector Acceptance

## Research and status

- State: Approved, promoted, and direct-agent smoke-tested
- Approval: Approved by the user on 2026-09-03
- Product: Microsoft internal IcM MCP Server
- Endpoint: `https://icm-mcp-prod.azure-api.net/v1/`
- Authentication: Interactive delegated Microsoft Entra identity; existing IcM permissions apply
- Installation: None; Microsoft-hosted remote endpoint
- Network: Microsoft corporate network or VPN may be required
- Endpoint probe: HTTP 401 with valid OAuth protected-resource metadata and delegated scope `api://icmmcpapi-prod/mcp.tools`
- Current startup behavior: VS Code remains at `Starting` without showing authentication. The official troubleshooting path requires a full VS Code restart.
- Post-restart result: Agent Host authenticated and reported `connected (ready)` even though the MCP list UI continued to show `Starting`.
- Live tool inventory confirmed both read operations and write-capable incident lifecycle/discussion operations.
- The agent now lists only named read tools. Acknowledge, mitigate, resolve, reactivate, transfer, assistance, update, severity, discussion, and insight posting tools are excluded.
- Delegated user context retrieval succeeded and returned only teams available to the signed-in user. Personal contact fields returned by this operation were not persisted and must not be reproduced by the agent.
- Bounded assigned-user and team searches succeeded. The team search honored the requested page size and returned a continuation token; the agent must not imply first-page completeness.
- A bounded incident detail lookup, customer-impact summary, support-request count, and discussion retrieval succeeded.
- A related services/regions/clouds operation returned an explicit permission denial. This validated partial-coverage behavior: the denial did not invalidate successful incident and impact retrieval.
- Exact searches using an assigned-user condition and a unique nonexistent marker returned successful empty result sets.
- The MCP detail response did not include an IcM portal URL. The canonical incident URL pattern was validated through the IcM authentication redirect and can be constructed from the stable incident ID.
- No write-capable tool was invoked. No retrieved incident, discussion, customer, contact, or support-request content was written to the repository.
- One oversized tool response was temporarily stored by the runtime outside the repository and deleted after validation.
- Version 1.0.0 was copied to the user agent directory, and its SHA-256 hash matched the reviewed repository source.
- A fresh-chat direct invocation found the promoted agent and completed a bounded exact-marker search with zero results and no write invocation.

Authoritative internal documentation:

- https://eng.ms/docs/products/icm/developers/icmassistant/mcpserver/overview

Known safety issue:

- The published V1 surface is primarily read-only, but a flighted `post_discussion_entry` write-back tool can exist.
- The source agent must use an explicit reviewed read-only tool allowlist and must never receive discussion posting or incident lifecycle mutation tools.

## Required scenarios and gates

- [x] Live tool inventory reviewed and every write-capable tool excluded
- [x] Delegated identity and existing IcM authorization verified
- [x] Incident query and bounded detail retrieval
- [x] Team/service/impact or related-context retrieval
- [x] Exact no-result behavior
- [x] Permission, partial-result, and service-error behavior
- [x] Item-level citations and portal deep links
- [x] Zero writes and no retrieved content persisted
- [x] Direct source-agent invocation
- [x] Explicit user approval
