# Agent Promotion Checklist

Promote agents through a manual reviewed copy from the repository to `~/.copilot/agents`.

## Source agent

- Repository acceptance document is approved.
- Delegated authentication was demonstrated.
- Read-only enforcement is implemented below the prompt layer.
- At least five real-scope scenarios passed.
- Known recall, permission, and API limitations are recorded.
- No source write occurred.
- No retrieved content was committed.
- Temporary-data cleanup passed.
- Tool names and MCP configuration requirements are documented.
- Repository definition contains a reviewed version and validation date.
- The exact reviewed file is copied to `~/.copilot/agents`.
- User-profile copy records the same version.
- Direct invocation is smoke-tested after copying.

For M365, acceptance must cover Teams, Outlook, SharePoint, and Planner behavior before promotion.

## Customer status orchestrator

- At least two source agents are approved.
- Targeted source selection passed.
- Full-summary multi-source delegation passed.
- Partial failure, conflict, duplicate, cross-source-link, and no-result behavior passed.
- Citation preservation and coverage disclosure passed.
- Internal and customer-ready output modes passed.
- No direct connector tool is exposed to the orchestrator.
- Repository and user-profile copies record the same reviewed version.

Promotion is not a deployment mechanism. Repository files remain the reviewed source of truth, and later updates require another checklist pass.
