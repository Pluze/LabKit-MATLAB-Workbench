# Documentation System

[Development index](README.md) | [Testing](testing.md)

LabKit keeps author-written documentation and generated presentation separate.
The source set is optimized for maintainers and machine readers; the generated
site is optimized for browsing, cross-reference, and search.

## Information Architecture

The documentation follows four reading modes used by mature technical
documentation sets:

- tutorials help a new user complete a first successful workflow;
- how-to guides solve a specific task;
- explanations describe architecture, behavior, and scientific meaning;
- reference pages support exact lookup of apps, files, fields, and APIs.

The App Framework is above the reusable domain libraries because it owns app
lifecycle, callbacks, state, presentation, file input, and interaction. App
families organize user workflows. API reference is organized by callable code
entity rather than by GUI screen.

## Source Of Truth

Only these inputs are edited:

| Source | Ownership |
| --- | --- |
| `docs/**/*.md` | Narrative tutorials, guides, explanations, and app pages. |
| `docs/site.json` | Page identity, navigation, output paths, and search keywords. |
| `docs/catalogs/api.json` | Explicit app-owned public API surface. |
| `docs/**/history/*.md` | Component-owned change rationale and evidence. |
| Public MATLAB help blocks | Function signature and callable contract. |

The renderer under `tools/docs/` uses only MATLAB and emits the complete
static site under `site/`. Files under `site/` are tracked release artifacts,
not authoring sources. Every generated HTML page contains a generated-file
marker. Never edit HTML, CSS, JavaScript, or the search index under `site/`
directly; regenerate them from the source set.

See [Testing](testing.md) for the documentation build and reproducibility
commands.

## API Reference Policy

All non-private `labkit.*` functions are part of the documented reusable
surface. App-owned APIs are documented only when they appear in
`docs/catalogs/api.json`. The explicit catalog prevents callback glue and
implementation helpers from being mistaken for supported scientific APIs.

Important scientific functions should document:

1. syntax and purpose;
2. inputs, outputs, option fields, defaults, and legal values;
3. scientific definitions, units, assumptions, and numerical behavior;
4. errors and failure-result behavior;
5. a GUI-free MATLAB example;
6. related functions and the owning app workflow.

Private helpers do not receive detailed site pages. They retain concise source
contracts that identify callers, shapes, side effects, and assumptions.

## App Documentation Policy

Every app has one landing page that answers what the app is for, how to launch
it, supported inputs, expected outputs, and the shortest successful workflow.
Larger apps add task guides and explanation pages for interactive tools,
project formats, recovery, algorithms, scientific semantics, and app-owned
APIs. Family pages connect apps that operate in the same experimental domain.

GUI instructions and programmatic examples link to each other instead of
duplicating full API contracts. Pages must describe visible interaction modes
where the user acts, including point placement, deletion, dragging, zoom
preservation, confirmation, and cancellation behavior.

## Generated Site Contract

The generated site is deterministic for the same repository content. It
contains navigation, responsive styling, individual public API pages, source
links, related-API links, and a static search index. Search covers page titles,
headings, keywords, MATLAB symbols, help contracts, app names, and scientific
terms.

GitHub Pages publishes the tracked `site/` tree. A stale or manually modified
site is a validation failure rather than a second documentation truth.

History records are rendered as searchable pages and linked automatically from
every component named in their metadata. The project therefore has no root
aggregate changelog and no separate release-history parser.
