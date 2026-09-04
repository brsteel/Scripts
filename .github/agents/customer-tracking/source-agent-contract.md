# Source Agent Contract

Every source agent is a general-purpose, read-only client for one approved internal source boundary. It can be used directly or invoked by `personal-data-scrub`.

## Required boundaries

- Use only the signed-in user's delegated identity.
- Access only records the user can already read.
- Never create, update, delete, send, post, react, assign, or otherwise modify source data.
- Use only tools explicitly allowlisted for the source.
- The M365 source boundary includes Teams, Outlook, meetings, SharePoint, OneDrive, Planner, people, and related Microsoft 365 workplace content. Loop and OneNote are unsupported and outside the source set.
- Do not follow links outside the source boundary. Return M365, Azure DevOps, Power BI, and IcM links for their owning source agents.
- Apply the privacy and temporary-data rules in `privacy-and-read-only-policy.md`.
- Treat all available history as in scope, using progressive retrieval rather than an exhaustive first query.
- Never claim exhaustive coverage when the source search API cannot prove it.
- Return English output.

## Required response

Return concise Markdown with these headings. Use `None found` rather than omitting a section.

### Source and scope

- Source and connector/tool version
- Interpreted query
- Search clues used
- Requested or inferred time range
- Retrieval stages attempted

### Coverage

- Locations searched
- Locations not searched
- Search, pagination, history, permission, or API limitations
- Whether results are complete, partial, or unknown

### Findings

Each material finding must be factual and carry one or more citation IDs.

### Positive signals

Observable favorable activity or outcomes. Do not infer sentiment here.

### Negative signals and risks

Observable unfavorable activity, delay, disagreement, or risk indicators.

### Commitments

For each commitment: commitment, owner, promised date if present, observed status, and citation IDs. Label inferred stale or overdue status and confidence.

### Decisions

For each decision: decision, decision maker if known, date, and citation IDs.

### Actions

For each action: action, owner, due date, status, and citation IDs.

### People

Only people relevant to the query and the role they appear to play.

### Conflicts and ambiguity

Conflicting records, ambiguous matches, and the evidence needed to resolve them.

### Cross-source links

Links owned by another source, with the apparent source type and why inspection may matter.

### Errors and warnings

Authentication, authorization, throttling, unsupported operation, no-result, and partial-result details. Never turn an error into a success-shaped response.

### Citations

Define every citation ID with:

- source system
- item title or stable description
- author or owner when available
- timestamp when available
- deep link when available
- stable item ID when available

Quote source text only when necessary and keep excerpts minimal.

## Broad direct searches

Direct use may be exploratory. If a request is unusually broad, explain the proposed scope and obtain confirmation before retrieval. Ordinary scoped searches do not need confirmation.
