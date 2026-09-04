# Power BI Connector Acceptance

## Research and status

- State: Approved and integrated with documented limitations
- Approval: Approved by user on 2026-09-03
- Preferred candidate: Official remote Power BI MCP preview
- Known initial limits: Tenant enablement and semantic-model Build permission may be required; actual report/dashboard/export coverage must be proven

Configuration:

- Endpoint: `https://api.fabric.microsoft.com/v1/mcp/powerbi`
- Authentication: Delegated Microsoft Entra OAuth through VS Code's preregistered client
- Available tools: Execute Query, Get Semantic Model Schema, Get Report Metadata, Generate Query
- Read-only boundary: The official remote server exposes query and metadata operations only
- Required access: Build permission on the semantic model
- Tenant requirement: Power BI admin must enable the remote MCP preview setting
- RLS: Enforced for delegated user authentication
- Unsupported: Workspace discovery, dashboard metadata, export, refresh, publish, sharing, and all mutations
- Generate Query: Optional; requires Power BI Copilot licensing/capacity
- Startup note: The original long-running Agent Host could list the newly configured server but could not attach it because MCP capabilities are fixed when that agent chat starts. Power BI validation was moved to a new chat in the same session so the approved server is loaded at startup.

Official references:

- https://learn.microsoft.com/power-bi/developer/mcp/remote-mcp-server-get-started
- https://learn.microsoft.com/power-bi/developer/mcp/remote-mcp-server-tools
- https://learn.microsoft.com/power-bi/developer/mcp/remote-mcp-server-external-clients

Record endpoint/version, delegated authentication, tenant requirements, tool coverage, read-only enforcement, blockers, alternatives, retry conditions, and validation results here. Do not include retrieved content or excerpts.

## Validation results

Validated on 2026-09-03:

- The official remote server connected through delegated Microsoft Entra OAuth.
- A user-provided report correctly returned an artifact-access denial.
- A second user-provided report returned report/workspace/semantic-model metadata.
- The identified semantic model returned its schema.
- Generate Query was explicitly approved for one bounded test but returned a service-processing error on two attempts.
- A manually authored, schema-grounded DAX query returned one aggregate scalar row and no row-level data.
- No dashboard, workspace discovery, export, refresh, publish, sharing, or mutation operations were available or invoked.

Observed limitations:

- A user must provide a report or semantic-model ID; the remote server does not discover workspaces or artifacts.
- Report access alone might not provide the artifact/Build access required by MCP.
- Generate Query depends on Power BI Copilot licensing/capacity and was unavailable during validation.
- This connector cannot satisfy dashboard or export requests.
- Preview tool definitions and response formats can change.

Safety results:

- Delegated user authentication only; no service principal or app-only identity.
- RLS and Power BI permissions govern query results.
- Metadata-first progressive retrieval was used.
- Query output was bounded to one aggregate scalar and excluded row-level data and identifiers.
- No write-capable operation was exposed or invoked.
- No retrieved content was committed or copied into this record.
- Tool-generated temporary metadata files were deleted.

## Required scenarios and gates

- [x] Five required real-scope scenarios passed
- [x] Delegated identity and enforced read-only access
- [x] Metadata, semantic query, report, dashboard, and export claims individually verified
- [x] Progressive retrieval, citations, minimization, limitations, cleanup
- [x] Zero writes and zero retrieved content in Git
- [x] Direct use and source-agent contract compliance
- [x] Explicit user approval
