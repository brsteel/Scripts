# Azure DevOps Connector Acceptance

## Research and status

- State: Approved and integrated
- Approval: Approved by user on 2026-09-03
- Preferred candidate: Official remote Azure DevOps MCP with delegated Entra authentication
- Required controls: `X-MCP-Readonly: true` and only work item, board/iteration, and wiki read tools

Configuration:

- Remote endpoint: `https://mcp.dev.azure.com/piemini`
- Authentication: Delegated Microsoft Entra OAuth
- Toolsets: `wit,wiki,work`
- Read-only enforcement: Remote `X-MCP-Readonly: true` header
- Organization: `piemini`, fixed as non-secret workspace configuration
- Excluded: Repositories, pull requests, pipelines, releases, tests, Advanced Security, and migration tools
- Installation: None; Microsoft-hosted remote MCP
- An existing Azure DevOps CLI default initially suggested `msazure`, but the user supplied the actual target board.
- Target organization: `piemini`
- Target project: `Silver and Sovereign`
- Target team/backlog: `Customer Advocacy Engineering (CAE)` / Stories
- Target endpoint probe: MCP initialization returned HTTP 401 with a delegated OAuth challenge, confirming the official `piemini` endpoint is reachable and requires authentication.
- CLI fallback result: the installed Azure DevOps CLI is signed into a different Azure identity; the initial organization rejected it as not materialized.
- Agent Host compatibility: `.mcp.json` is stored in the `Scripts` workspace folder because Agent Host does not directly read `.vscode/mcp.json`, does not forward servers containing interactive `${input:...}` variables, and the directory containing a multi-root `.code-workspace` file is not itself a workspace folder.
- MCP discovery and delegated OAuth completed successfully after the approved servers were explicitly allowlisted.

The global Azure CLI login was not changed, no PAT was requested, and no source write occurred.

Record tested endpoint/version, delegated authentication, toolsets, coverage, blockers, alternatives, retry conditions, and validation results here. Do not include retrieved content or excerpts.

## Validation results

Validated on 2026-09-03 against:

- Organization: `piemini`
- Project: `Silver and Sovereign`
- Team: `Customer Advocacy Engineering (CAE)`
- Backlog: Stories

Passed scenarios:

- Target project and signed-in user's team membership discovery
- Backlog-level discovery and bounded Stories backlog enumeration
- Team iteration discovery, including current and future sprint classification
- Current-iteration work-item retrieval
- Bounded batch work-item metadata retrieval
- Project/team-scoped WIQL query with a result limit
- Work-item detail, relations, comments, and revision history
- Work-item search and exact zero-result behavior
- Work-item-type metadata discovery
- Wiki discovery returning an empty set, correctly establishing that the project has no wiki

Observed limitations:

- Broad full-text searches can have very high recall and must always be project-scoped, bounded, and followed by qualification.
- Backlog enumeration initially returns IDs and requires a second bounded metadata request.
- API URLs may be returned alongside browser links; user-facing citations should prefer browser links.
- The project has no wiki, so wiki scenarios are not applicable for this scope.
- The `my assigned work items` operation returned IDs without populated fields and requires bounded follow-up retrieval.

Safety results:

- Authentication used delegated Microsoft Entra OAuth.
- The remote server enforced `X-MCP-Readonly: true`.
- Only `wit`, `wiki`, and `work` toolsets were exposed.
- Repository, pull request, pipeline, release, test, migration, and security tools were not exposed or invoked.
- No mutation operation was exposed or invoked.
- No source write occurred.
- Retrieved content was not committed or added to acceptance artifacts.
- Tool-generated temporary retrieval files were deleted after validation.

## Required scenarios and gates

- [x] Five required real-scope scenarios passed
- [x] Delegated identity and remote read-only control verified
- [x] Repositories, pull requests, pipelines, releases, and tests excluded
- [x] Progressive retrieval, citations, minimization, limitations, cleanup
- [x] Zero writes and zero retrieved content in Git
- [x] Direct use and source-agent contract compliance
- [x] Explicit user approval
