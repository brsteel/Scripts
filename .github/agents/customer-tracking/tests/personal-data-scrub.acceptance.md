# Personal Data Scrub Orchestrator Acceptance

## Status

- State: Approved, promoted, and smoke-tested
- Approved sources: M365, Azure DevOps, Power BI, IcM
- Unsupported sources: Loop, OneNote

## Real-scope validation

Validated on 2026-09-03 with a previously supplied customer clue:

- [x] M365 and Azure DevOps were queried concurrently with the same bounded scope.
- [x] M365 returned cited, material evidence with time-coverage limitations.
- [x] Azure DevOps returned an exact no-result without affecting the M365 result.
- [x] Power BI was not queried because no customer-relevant report or semantic-model ID was supplied.
- [x] Source selection and unqueried-source disclosure behaved as designed.
- [x] Candidate duplicate records within one M365 thread were grouped by source item rather than presented as separate events.
- [x] Facts and inferred signals were separated.
- [x] No source write occurred.
- [x] Retrieved content was not committed.
- [x] Tool-generated temporary retrieval files were deleted.

This record intentionally contains no retrieved excerpts, names, item IDs, or deep links.

## Remaining scenarios

- [x] Synthetic same-event merge requires all cross-source citations
- [x] Synthetic conflict has a dedicated section requiring both claims, timestamps, citations, recency, and authority
- [x] Synthetic source failures remain isolated and force partial-coverage disclosure without absence inference
- [x] Synthetic stale commitment requires an inference label, confidence, and item-level rationale
- [x] Synthetic customer-ready output removes internal/sensitive commentary and uses the exact review warning
- [x] Synthetic full output requires all standard sections, per-source coverage, and item-level citation retention
- [x] Direct `customer-status` invocation after its original promotion
- [x] Explicit integration approval

The synthetic contract review found no blocking failures. It identified two structural risks: cross-source conflicts lacked a dedicated output section, and stale/overdue commitments did not explicitly require item-level rationale. Both contracts were tightened before marking these scenarios passed.

## Promotion

- User approved integration and promotion on 2026-09-03.
- Version 1.0.0 of `customer-status`, `m365`, `ado`, and `powerbi` was copied to the user agent directory with shared contracts.
- Source and promoted SHA-256 hashes matched.
- VS Code customization discovery found all four promoted agents.
- Direct `customer-status` smoke testing correctly listed M365, Azure DevOps, and Power BI as approved and Loop and OneNote as unsupported without querying sources.

## IcM integration

- User approved IcM integration and promotion on 2026-09-03.
- IcM version 1.0.0 passed delegated authentication, bounded search/detail/discussion retrieval, exact no-result behavior, partial permission handling, canonical portal-link validation, and zero-write checks.
- `customer-status` version 1.1.0 includes IcM in its explicit source-agent allowlist and requires it for full status requests.
- The updated orchestrator, IcM agent, and shared source contract were copied to the user agent directory with matching SHA-256 hashes.
- A fresh-chat direct IcM invocation completed a bounded exact-marker no-result query and confirmed that no write tool was invoked.

## Agent rename

- The orchestrator was renamed from `customer-status` to `personal-data-scrub` on 2026-09-03.
- Version 1.2.0 records the renamed user-facing agent identity without changing its validated retrieval or consolidation behavior.
- The renamed agent and updated shared source contract were promoted with matching SHA-256 hashes, and the obsolete `customer-status.agent.md` user-level file was removed.
- Direct discovery of the renamed agent requires a VS Code reload because the running Agent Host retains its pre-rename agent catalog.
