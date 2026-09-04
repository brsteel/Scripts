# Customer Status Output Contract

## Consolidation rules

- Keep facts separate from inference.
- Normalize identities and timestamps while retaining original source details in citations.
- Merge duplicate events and preserve citations from every corroborating source.
- Show conflicts rather than silently selecting one version.
- Assess conflict recency and authority without treating either as automatically decisive.
- Do not infer missing facts from silence or inaccessible sources.
- Continue after an isolated source failure and mark coverage as partial.

## Confidence

Use `High`, `Medium`, or `Low` confidence for health, sentiment, stale commitments, overdue actions, and other inferences.

Base confidence on:

- directness and clarity of evidence
- corroboration across independent records
- source authority
- recency
- search coverage and known recall limits
- unresolved conflicts

## Standard full status

### Executive status

Provide a concise account-level synthesis.

### Health

Use Green, Amber, or Red. Label this as an inference and include confidence plus evidence-based rationale.

### Wins

Material favorable outcomes and progress.

### Concerns and risks

Material issues, deteriorating signals, uncertainty, and impact.

### Commitments

Promises by the internal team or customer, with owner, date, and current evidence. Any stale or overdue state is an inference and must include confidence plus an evidence-based rationale for that item.

### Blockers

Current obstacles, owners, dependencies, and impact.

### Decisions

Material decisions and unresolved decision points.

### Conflicts

For every cross-source conflict, show both claims, timestamps, and citations. Assess recency and source authority without silently choosing a winner.

### Open questions

Questions that current evidence cannot answer.

### Next actions

Prioritized action, owner, due date, and evidence/status.

### Relationship and activity signals

Label sentiment or relationship interpretation as inference. Include confidence and supporting evidence.

### Source coverage

List:

- queried sources
- successful sources
- failed or unavailable sources
- sources not queried
- time/history coverage
- important search and permission limitations
- whether completeness is partial or unknown

### Citations

Include item-level citations for every material claim using the source-agent citation fields.

## Targeted questions

Answer the question directly, then provide relevant evidence, confidence for inference, and source coverage. Query only relevant validated sources and disclose which validated sources were not queried.

## Customer-ready mode

- Use only when explicitly requested.
- Remove internal-only judgments, candid relationship commentary, sensitive personal details, and operational notes unsuitable for external sharing.
- Preserve factual qualifications and citations that are appropriate to share.
- Display: `Review required before external sharing.`
