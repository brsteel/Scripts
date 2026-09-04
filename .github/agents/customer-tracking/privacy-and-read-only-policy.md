# Privacy and Read-Only Policy

## Data boundary

The agents inspect only the organization's internal records about interactions and work. They must never access a customer's tenant, environment, credentials, systems, or private data stores.

## Identity and authorization

- Use interactive delegated authentication as the current user.
- Reuse supported VS Code or Microsoft sign-in. Otherwise use an approved browser or device-code flow.
- Never use app-only access, service principals, backend identities, shared credentials, or stored bearer tokens.
- Never copy tokens, cookies, session caches, client secrets, or credential material into the repository, prompts, reports, or agent definitions.
- Let the OS or approved tool manage authentication securely.
- Respect conditional access, MFA, source permissions, and access failures.

## Read-only enforcement

- Source-system access is strictly read-only.
- Prefer server-side read-only controls and read-only delegated scopes.
- If a tool can write and cannot enforce a read-only boundary, do not expose it directly.
- An approved local wrapper may expose a small audited allowlist of read operations.
- Prompt instructions alone are not an acceptable read-only security boundary.
- Any create, update, delete, send, post, reaction, assignment, permission change, or other mutation is a hard failure.

## Least-data handling

- Search only for the requested purpose and customer-related internal scope.
- Ignore unrelated matches even when the signed-in user can read them.
- Minimize personal and sensitive details.
- Prefer paraphrase over quotation. Quote only the minimum needed for evidence.
- Do not return unrelated participants, attachments, or conversation context.
- Do not use retrieved content to enrich unrelated tasks.

### Accepted Work IQ limitation

Work IQ `ask` can return uncited internal reference metadata in its structured payload even when the visible answer is bounded or `NOT_FOUND`. This behavior is accepted for the M365 connector by explicit user decision on 2026-09-03. The M365 agent must ignore uncited references, never reproduce them, and disclose this connector limitation. This exception does not permit repository persistence or source-system writes.

## Temporary data

- Prefer in-memory processing.
- If full records or converted files must be written, use a dedicated OS temporary directory outside the repository.
- Do not place retrieved records in workspace files, source control, test fixtures, terminal transcripts intended for persistence, or reports.
- Delete temporary records immediately after the requested response and citation set are complete.
- Report cleanup failures explicitly and provide the remaining absolute temporary path.

## Persistence

- Never save a summary automatically.
- When the user requests a saved summary, ask for both format and destination.
- Connector acceptance files may record dates, tested capabilities, redacted identifiers, pass/fail outcomes, and limitations.
- Never commit source excerpts, even sanitized excerpts.

## Customer-ready output

Customer-ready mode is opt-in. Remove internal-only judgments and sensitive commentary, and display: `Review required before external sharing.`
