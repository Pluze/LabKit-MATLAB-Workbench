# LabKit Documentation Rules

These rules govern authored Markdown under `docs/`, public MATLAB help, and the reader-visible information architecture. Use `labkit-documentation-maintainer` for the operating procedure when content, reference, rendering, navigation, search, release notes, or change history changes.

## Reader and intent ownership

- Organize documentation first by reader destination and then by intent. The stable destinations are start, Apps, develop, maintain, reference, upgrade, and changes. Keep one stable topic per page; an App defaults to one complete manual, and a child page exists only for an independent reader goal with enough content to stand alone.
- Give every published narrative page one machine-readable page contract with a stable semantic ID, page type, audience, and summary. Current authority is implied by this block. App and package discovery own component relationships; paths choose routes, and moving a page intentionally changes its URL.
- Treat the documentation home and section indexes as routing pages. They explain what LabKit is, who the section serves, when to choose each path, and the shortest useful next action. They do not duplicate manuals or APIs.
- Keep one supported task together. State the goal, prerequisites, steps, expected result, verification, recovery, and next relevant topic. Split rationale or exact reference only when the resulting page is independently useful and stable.

## Four fact owners

- Current manuals and public MATLAB help own supported behavior, defaults, workflows, outputs, errors, limitations, and compatibility that apply now.
- Change records own each accepted logical change that a user or developer may need to understand without reconstructing Git history: its reason, net changes, affected workflows or contracts, compatibility, and known limits.
- GitHub Releases own user-visible changes for one published LabKit version, its exact tag, and the action, if any, required to upgrade or roll back. Link that source instead of copying release summaries into `docs/`.
- Pull requests, tests, CI, and workflow records own implementation sequence, validation inventories, hashes, review state, and other delivery evidence. Do not copy that evidence into current manuals, change records, or release notes.
- Do not preserve a statement because an earlier document contained it. Re-establish current claims from source, tests, or an authoritative external reference before moving them into the new system.

## Page contracts

- A tutorial produces one complete result and includes prerequisites, supplied or synthetic inputs, ordered actions, expected observations, and next steps.
- A task page starts from a concrete goal and includes prerequisites, the shortest supported procedure, verification, failure recovery, and related concepts or reference.
- A concept page explains behavior, ownership, tradeoffs, assumptions, and consequences without becoming a command inventory.
- A reference page defines exact syntax, fields, legal values, defaults, units, errors, and compatibility without teaching a broad workflow.
- A troubleshooting page is organized by observable symptom, likely cause, diagnostic evidence, corrective action, and conditions that require a bug report or operator intervention.
- An App manual states purpose, applicability, requirements, a shortest successful workflow, principal inputs and outputs, calculations or protocols, programmatic use when supported, safety and privacy boundaries, recovery, limitations, and related topics. Do not split it merely to satisfy page-type categories.
- A scientific or device page states intended use, units, formula or protocol, implemented defaults, rationale, provenance, validation scope, limitations, and reporting requirements. Distinguish implementation facts, scientific assumptions, vendor claims, and unvalidated behavior explicitly.
- A change record is deliberately small: why, what changed, impact, and compatibility or limits. Its Why section owns the problem, constraints, accepted choice, and relevant rejected alternatives. Metadata owns components, version transitions, and optional predecessor relationships. It is not a commit diary, test log, or second PR.

## Public reference

- Complete public MATLAB help immediately after the declaration is the sole authoring source for a public function page. Document every syntax, input, output, option, default, legal value, unit, shape, error, side effect, and related supported API that applies.
- Generate App and library catalogs from launcher and package metadata. A public App, family, or app-facing package must not depend on a handwritten routing list for discoverability; coverage validation rejects omissions.
- Private helpers have no public reference page. Private helper comments state callers, shapes, side effects, and assumptions in source only.
- `Example:` help and marked runnable Markdown examples execute in a clean MATLAB session with synthetic data. Use `Typical Call:` for interactive, device-, or user-file-dependent sketches.

## Movement, deletion, and generated output

- Move or delete documentation as a hard change. Update current internal source links and launcher destinations, but do not create redirects, route aliases, archived site pages, legacy navigation, or compatibility metadata.
- Remove obsolete current guidance after its still-valid facts have an accepted owner. Preserve accepted rationale in typed Change records and published version summaries in GitHub Releases, not in old manuals, retired schemas, or route-compatible archives.
- Keep scoped `AGENTS.md` and `.agents/migration_guide.md` out of documentation discovery and fail generation if either becomes a reader page.
- `site/` is ignored generated output. Build it only through `tools/docs/renderLabKitDocs.m`; never track or hand-edit generated HTML, CSS, JavaScript, search data, manifests, or navigation.

## Style and validation

- Write each ordinary prose paragraph on one physical source line and let editors and the rendered site wrap it visually. Do not insert hard line breaks for a target column width and do not use one-sentence-per-line style. Keep one physical line per list item and table row; preserve semantic line structure in headings, nested lists, block quotes, code, and other literal blocks.
- Lead with the reader's outcome. Use familiar product and laboratory terms; introduce an internal contract term only when the reader must act on it.
- Prefer short sections, concrete verbs, exact labels, and tables only for real field comparisons. Avoid diff narration, policy voice, implementation inventories, and repeated ownership slogans in user pages.
- Keep long symbols, error identifiers, paths, and table cells readable at desktop and mobile widths. Code may wrap or scroll; it must not overlap an adjacent description.
- Validate page contracts, required sections, source authority, App/package coverage, routes, local links, search classification, HTML structure, responsive representatives, and deterministic output before delivery.
