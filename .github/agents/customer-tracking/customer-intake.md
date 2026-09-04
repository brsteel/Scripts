# Customer Intake Contract

## Accepted input

Accept any combination of:

- free-form text
- customer or account name
- email domains
- abbreviations and alternate names
- project or engagement codenames
- relevant people
- known Team, channel, site, project, plan, workspace, report, or item links and IDs
- local documents in any format supported by approved local conversion tools

No field is mandatory except enough context to conduct a meaningful search.

## Normalized scope

Extract:

- canonical customer/account label
- names, aliases, abbreviations, and codenames
- domains and email addresses
- internal and external people explicitly associated with the scope
- source-specific links and stable IDs
- quoted phrases and likely search terms
- exclusions and negative search terms
- requested question, output mode, and time range

Keep source-specific identifiers assigned to their owning source agent.

## Ambiguity

Ask for clarification only when an ambiguity could cause an incorrect or unusually broad search. Otherwise retain alternatives as search clues and require source agents to report match confidence.

## File extraction

- Process files locally.
- Extract text and inert metadata only.
- Never execute macros, scripts, active content, external links, or embedded objects.
- Never upload a file to a third-party conversion service.
- Fail explicitly on encrypted, corrupted, unsupported, or unsafe files.
- Store conversion output only in the approved OS temporary directory and delete it after the response is complete.

