# LabKit Documentation Rules

These rules supplement the repository-wide documentation contract for authored
Markdown under `docs/`. Use `labkit-documentation-maintainer` for the operating
procedure when pages, public reference, history, rendering, links, navigation,
or deployment change.

## Sources and ownership

- Narrative pages, App manuals, and App APIs are discovered from paths,
  launcher metadata, and complete public MATLAB help contracts. `site/` is
  generated only by `tools/docs/renderLabKitDocs.m`, ignored locally, and
  rebuilt from `main` for GitHub Pages; never track or hand-edit generated
  HTML, CSS, JavaScript, search indexes, or navigation.
- Organize pages by reader task and component ownership: getting started,
  Apps, framework, libraries, development, reference, and history. Prefer
  contextual links and path-derived indexes over duplicated prose.
- Treat scoped `AGENTS.md` files as agent inputs, not narrative pages. Keep
  them out of documentation discovery and fail the documentation check if a
  corresponding generated HTML page appears.
- Add a page only for currently supported architecture or delivered behavior.
  While migration work is active, keep its plan and acceptance gates in the
  temporary `.agents/migration_guide.md` rather than published documentation.

## Reader contract

- Treat documentation as a reader interface, not a diff narrative or an
  accumulation sink. Every addition helps a reader perform a supported task,
  call a public API, understand current behavior, interpret an output, or
  recover from a documented failure.
- Do not restate private source structure, implementation order, test
  inventories, commit evidence, or completed migration plans. Put durable
  rationale and compatibility evidence in component history, and remove a
  delivered design page once the current manual and API reference own its
  useful behavior.
- One API page resolves to one public MATLAB function and covers syntax,
  inputs, outputs, options, defaults, legal values, units and assumptions when
  scientific, errors, examples, and related APIs. Private helpers have no
  public reference page.
- App manuals cover workflow, interaction, state and projects, outputs,
  GUI-free APIs, limitations, troubleshooting, and component history. Keep
  framework defaults in the framework manual rather than copying them into
  every App or family page.
- Canonical examples use exact production symbols and remain executable. Do
  not preserve approximate proposal or RFC syntax as current guidance.

## History and movement

- `docs/history/record-format.md` is the authority for structured history
  metadata, legal values, ordering, and narrative sections. Update history
  only for a versioned component change or meaningful project evolution, not
  mechanical regeneration, typo-only edits, or generated-site churn.
- When current documentation moves or retires, repair or remove stale inbound
  links, including links in published history. Keep a published record's ID,
  date, sequence, type, compatibility, component, scope, version transition,
  decision, and evidence unchanged.
- Use `maintainLabKitDocLinks(..., "Update", true)` after moving Markdown,
  review every rewrite, and run deterministic documentation generation checks.
  Generate the ignored local site only when local reading or visual inspection
  is useful.
