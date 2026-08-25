# Documentation Architecture

```labkit-page
id: maintain-documentation
type: reference
audience: maintainer
summary: Maintain LabKit's reader model, authored source contracts, static renderer, generated navigation, and documentation validation boundary.
```

This manual defines the LabKit reader model, source contracts, static renderer, and validation boundary. Start at the [documentation home](../README.md) to use LabKit rather than maintain its documentation.

## Reader Model

Every page has one primary reader and one primary reading intent.

| Audience | Expected outcome |
| --- | --- |
| New user | Understand LabKit, install it, open an App, and obtain a first result. |
| App user | Complete, verify, recover, and report one supported laboratory task. |
| Scientific user | Interpret units, formulas, defaults, provenance, assumptions, validation, and limitations. |
| App developer | Build or extend an App against supported framework and library contracts. |
| Maintainer | Change, test, document, release, and diagnose the repository safely. |

The supported page types are:

| Page type | Reader question | Required shape |
| --- | --- | --- |
| `landing` | Where should I go? | Scope, choices, selection criteria, shortest next action. |
| `tutorial` | How do I obtain a first complete result? | Prerequisites, supplied inputs, ordered path, expected observations, next step. |
| `task` | How do I achieve this goal? | Goal, prerequisites, steps, verification, recovery, related concept/reference. |
| `concept` | Why does this work this way? | Context, model, assumptions, tradeoffs, consequences, related tasks. |
| `reference` | What exactly is supported? | Syntax or fields, values, defaults, units, errors, compatibility. |
| `troubleshooting` | What does this symptom mean? | Symptom, evidence, likely cause, corrective action, escalation boundary. |

A page can contain several section types when one reader needs them together. Split only when a child page has an independent reader goal, enough substance to stand alone, and a stable destination; page types are writing constraints, not a requirement to create one file per type.

## Fact Lifecycle

LabKit uses four independent fact owners:

1. Current manuals and MATLAB help describe behavior that is supported now.
2. Change records explain one accepted logical change without requiring a reader to reconstruct commits or pull requests.
3. GitHub Releases aggregate reader-visible changes in one published version and own the exact tag.
4. Pull requests, tests, CI, and workflows preserve delivery evidence.

Do not turn change records into commit logs or validation reports, release notes into repeated change narratives, or current manuals into a history of former implementations. The live documentation tree preserves accepted current behavior and the reasons behind meaningful changes without carrying old routes or obsolete schemas.

## Source Tree

```text
docs/
  README.md
  start/
    README.md
  apps/
    README.md
    <family>/README.md
    <family>/<app>/README.md
  develop/
    README.md
    app-authoring/
    framework/
    libraries/
  maintain/
    README.md
    testing.md
    documentation.md
    release.md
  reference/
    README.md
    schemas/
  upgrade/
    README.md
  changes/
    README.md
    <year>/
```

Executable renderer code and synthetic fixtures live under `tools/docs/`. Generated HTML and assets live only in the ignored `site/` tree or a deployment artifact. No executable MATLAB file belongs under `docs/`.

Moving a source changes its public route. Update current internal links and launcher destinations in the same change. LabKit does not generate redirects, legacy aliases, archived routes, or parallel retired navigation.

## Page Metadata

Every current narrative page contains exactly one `labkit-page` block immediately after its level-one title:

````text
[Level-one title: Connect a Mark-10 monitor]

```labkit-page
id: mark10-connect-monitor
type: task
audience: app-user
summary: Connect a supported gauge and verify live acquisition.
```
````

The parser accepts only the documented keys and values. `id`, `type`, `audience`, and `summary` are required. Current authority is implied. The route comes from the source path and is not a compatibility identity. App and package discovery derive current-page component ownership; authors do not repeat it here.

Legal audiences are `new-user`, `app-user`, `scientific-user`, `app-developer`, and `maintainer`. A Change page uses only `labkit-change`; its typed block implies page identity, type, authority, and reader defaults instead of duplicating `labkit-page`. Delivery evidence is intentionally not a documentation authority.

## Structured Changes

The change model is a small graph with chronological and component views, not a commit log.

### Change record

One accepted logical change owns one file under `docs/changes/<year>/`. Its metadata records:

```text
id: CHG-YYYYMMDD-lowercase-slug
date: YYYY-MM-DD
type: feat | fix | perf | refactor | test | docs | ci | chore
compatibility: compatible | action-required | breaking
component: component-id | old-version -> new-version
supersedes: CHG-YYYYMMDD-lowercase-slug
```

`component` and `supersedes` may repeat when the relationship is real. File existence means the change is accepted; there is no separate status lifecycle. A change body uses this exact order:

1. Why
2. What changed
3. Impact
4. Compatibility and limits

The Why section records the problem, constraints, accepted choice, and only the rejected alternatives needed to understand that choice. The rest explains the accepted net result. It does not reproduce commits, file inventories, commands, run identifiers, or every intermediate repair. When a later Change replaces an earlier choice, it names the earlier Change in `supersedes`; the renderer adds the inverse link so the reason chain is traversable in both directions.

The renderer validates every referenced Change ID and component, builds chronological, component, and supersession views, and lowers Change ranking in default task search. A newer Change owns its `supersedes` relation; the renderer generates the inverse link, so authors do not maintain both ends. GitHub Releases remain the sole published-version summary and tag source.

## App Documentation

One complete App manual is the default. It covers purpose and applicability, requirements and launch, the shortest successful workflow, inputs and outputs, calculations or protocols, programmatic use when supported, safety and privacy boundaries, recovery, limitations, and related topics. Keeping the workflow together lets a new user reach a result without navigating a documentation maze.

Split a task, concept, troubleshooting, or reference page out of the manual only when it has an independent reader goal, enough content to stand alone, and a stable reason to be linked directly. Shared framework behavior stays in developer framework docs.

A scientific or device page covers intended use, units, algorithm or protocol, implemented defaults, rationale, provenance, validation scope, limitations, and reporting requirements. Name the vendor document and revision for a device claim. Name the implementation owner for a software default. State explicitly when hardware behavior or scientific validity has not been established.

## Public API Reference

The renderer discovers public `labkit.*` functions and marked App-owned GUI-free APIs from current MATLAB source. The complete help block immediately after the declaration owns:

- supported syntax forms;
- inputs, options, fields, defaults, legal values, units, shapes, and empties;
- outputs and result fields;
- algorithms and numerical assumptions when applicable;
- errors or status-return failure behavior;
- executable examples or clearly labeled typical calls;
- related supported functions.

The command-line help and generated page share this one prose owner. The renderer adds navigation and presentation but does not invent missing API contracts.

App, family, and public-package routing is generated from launcher and package metadata. The build fails when a public item has no current reader destination. Handwritten routing tables may explain selection criteria, but they cannot be the sole discoverability source.

## Renderer Architecture

The renderer is a deterministic static compiler:

```text
Markdown + MATLAB help + launcher metadata
                              |
                        source adapters
                              |
                    normalized struct model
                              |
                         validators
                              |
                    page-type components
                              |
             HTML + assets + search + site manifest
```

Source adapters parse one source contract each. The normalized model contains pages, sections, components, API symbols, Changes, versions, and search documents. Keep it as validated MATLAB structs; do not introduce a class hierarchy.

Rendering components own the shared shell, breadcrumbs, version banner, reader/type label, Markdown nodes, API definitions, callouts, tables, previous and next task links, and footer. CSS and JavaScript are authored source assets under `tools/docs/assets/`, not large MATLAB string literals.

Search records include title, summary, headings, audience, page type, authority, component, version, keywords, and MATLAB symbol. Search defaults to current behavior; Change results remain an explicit filter rather than overwhelming task results. Search works on Pages and when the generated index is opened directly without a server.

## Presentation Contract

- Use semantic landmarks and one ordered heading hierarchy.
- Provide a skip link, visible keyboard focus, keyboard-operable navigation, table headings, meaningful image alternatives, and sufficient contrast.
- Keep the primary reading column within a comfortable line length.
- Wrap or scroll long code, symbols, paths, and error identifiers inside their own cells. They must never overlap neighboring content.
- Stack definition terms above descriptions when the available width is too narrow for two columns.
- Verify representative pages at 1440, 1024, 768, and 390 CSS pixels.
- Keep motion optional and respect reduced-motion preferences.

## Authoring Workflow

Begin with current source and tests. For an App, inspect its entrypoint, definition, user controls, state/options owner, input loader, output writer, public App APIs, scientific calculations, and focused tests. For a library, inspect its complete public surface and consumers.

Choose the fact owner before writing. Start from the page contract. Use the reader's vocabulary and exact UI labels. Lead with the outcome, keep one goal per task or section, and split explanation or exact reference only when the child page is independently useful.

Examples under `Example:` and Markdown blocks preceded by `<!-- labkit-runnable-example -->` execute in a clean session. Use only synthetic inputs and avoid dialogs, user files, or lasting UI and filesystem side effects. Use `Typical Call:` for sketches that cannot satisfy this contract.

## Validation

Documentation validation rejects:

- missing or illegal page metadata;
- duplicate semantic IDs or output routes;
- malformed current-page or Change metadata and Change section structure;
- unresolved current local links;
- missing App, family, or public-package reader destinations;
- local release-summary pages that duplicate GitHub Releases;
- Change records with missing required sections or unresolved predecessors;
- malformed HTML structure or prohibited agent/migration pages;
- non-deterministic generated files.

Run the smallest focused contract first and then `buildtool docsCheck`. Render the ignored local site when presentation changed and inspect representative HTML at the required viewport widths. Repeated rendering proves determinism; focused semantic and visual evidence proves correctness.

## Related Topics

- [Documentation Home](../README.md)
- [Architecture](../develop/app-authoring/architecture.md)
- [App Development](../develop/app-authoring/app-development.md)
- [Testing](testing.md)
- [Release Process](release.md)
