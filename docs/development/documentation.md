# Documentation Architecture

This page defines how LabKit documentation is authored, organized, rendered,
and validated. It is a maintainer reference; readers looking for an app or a
MATLAB function should start at the [documentation home](../README.md).

## Design Goals

LabKit documentation must support four distinct reading tasks:

- learn a workflow from a complete example;
- complete a specific task without reading architecture material;
- understand why a framework or scientific operation behaves as it does;
- look up exact MATLAB syntax, argument rules, fields, units, and errors.

The organization follows the successful division visible in MATLAB and Qt
documentation: product and module landing pages orient the reader, task pages
teach workflows, concept pages explain behavior, and one page per callable
entity provides exact reference. A single long narrative must not try to serve
all four purposes.

## Source Tree

`docs/` contains only author-maintained, human-readable documentation data:

```text
docs/
  README.md
  getting-started/
  apps/
    <family>/README.md
    <family>/<app>/README.md
    <family>/<app>/<topic>.md
    <family>/history/
  framework/
    README.md
    <topic>.md
    history/
  libraries/
    README.md
    <facade>/README.md
    <facade>/<topic>.md
    <facade>/history/
  how-to/
  development/
  history/README.md
  catalogs/
  site.json
```

Executable renderer code and synthetic-asset generators live under
`tools/docs/`. Generated HTML, CSS, JavaScript, and search data live under
`site/`. No executable `.m` file belongs under `docs/`, and no generated file
under `site/` is edited by hand.

## Page Types

### Product landing page

The documentation home answers what LabKit is, who each major section is for,
and where a reader should begin. It is a routing page, not a project history,
launcher manual, or API dump.

### Tutorial

A tutorial leads a new reader through one complete, successful result. It
states prerequisites, sample/input expectations, ordered actions, the expected
result, and the next relevant topic. Tutorials may teach one path and defer
alternatives.

### How-to guide

A how-to guide begins with a concrete goal and gives the shortest reliable
procedure. It includes prerequisites, commands or actions, verification, and
failure recovery. Background explanation is linked, not repeated.

### App family page

A family page explains the shared experimental domain, compares sibling apps,
shows how their files or outputs connect, and links the relevant reusable
libraries. It must not contain detailed instructions for one app.

### App manual

Every public app owns one manual at
`docs/apps/<family>/<app>/README.md`. Its normal section order is:

1. purpose and applicability;
2. requirements and launch;
3. supported inputs and file interpretation;
4. a shortest successful workflow;
5. controls and interaction modes;
6. parameters, defaults, legal values, and units;
7. calculations, algorithms, and scientific assumptions;
8. outputs and result schemas;
9. project state, autosave, recovery, and overwrite behavior;
10. use without the GUI;
11. errors, limitations, troubleshooting, related topics, and history.

Sections that genuinely do not apply may be omitted. Applicable information
must not be hidden in an app catalog, family overview, changelog, or source
comment. Complex apps add focused topic pages beside the manual rather than
turning the manual into an unstructured notebook.

### Framework module page

The framework landing page presents ownership and module relationships. Topic
pages then document lifecycle, definition, callbacks, state transactions,
busy behavior, file selection, persistence, layout, plotting, interactions,
debugging, and extension rules. Each topic identifies:

- the problem and owning package;
- the observable behavior guaranteed to apps;
- the normal call sequence;
- public types or functions grouped by role;
- examples, failure behavior, and related topics.

Private runtime mechanics are explained only when necessary to understand a
public behavior; private functions do not receive reference pages.

### Library module page

Each `labkit.*` facade has a module landing page comparable to a MATLAB
toolbox or Qt module page. It states scope, dependencies, data model, grouped
public functions, common call sequences, numerical/scientific semantics,
compatibility, errors, examples, and related apps. Exact per-function syntax
is linked to generated reference pages.

### Function reference page

Every public function has one generated page. The MATLAB help block immediately
after its declaration is the only authoring source and documents, as
applicable:

- all supported syntax forms;
- concise description and observable behavior;
- each input, name-value option, and struct field;
- defaults, legal values, units, shape, type, and empty-value behavior;
- each output and its fields;
- algorithms, scientific definitions, and numerical assumptions;
- thrown errors or status-return failure behavior;
- a copyable example;
- related functions and the owning app or module.

Function reference must not promise an overload, field, or default that the
current implementation and tests do not support.

### History record

History is component-owned. A record explains what changed, why it matters,
compatibility, affected components, and validation evidence. It is not an
instruction manual and must link to the current page that describes the final
behavior. The global history page is only an index. History metadata schema 2
requires a global positive-integer `sequence`; values are unique and
contiguous, and a new record normally takes the previous maximum plus one. The
renderer orders the timeline by descending sequence rather than inferring
same-day order from a title, filename, filesystem timestamp, or Git checkout.

## Structured Sources

The documentation model is assembled from four source classes:

| Source | Authority |
| --- | --- |
| `docs/site.json` | Top-level page identity, kind, navigation, order, output path, keywords, and component association. |
| `docs/catalogs/apps.json` | App families, commands, source folders, manual pages, descriptions, and search terms. |
| `docs/catalogs/api.json` | App-owned functions intentionally supported as public non-GUI APIs. |
| Markdown and MATLAB help blocks | Narrative content and callable contracts. |

Catalog data must not be copied into another catalog merely for rendering.
Narrative pages may summarize it for readers, but catalog consistency and
links are validated against the owning structured source.

## Authoring From Current Code

Documentation changes begin from the current implementation, not from old
prose. For an app manual, inspect at least its entrypoint, runtime definition,
workbench layout, state/options owner, input loader, output writer, public
app-owned APIs, and focused tests. For a library, inspect its complete public
surface and tests. Existing documentation and history may identify questions
to investigate, but they are not evidence that a behavior still exists.

User-visible labels, defaults, supported file types, state fields, output
columns, formulas, units, and error behavior must match their current code
owners. If code and documentation disagree, resolve the product contract
rather than documenting both as alternatives.

### Public Function Help

A public function help block is part of the tested API. It states public call
syntax, behavior, inputs, outputs, option fields, defaults, legal values, and
errors or side effects where they matter. The documentation guardrail compares
the names in the function signature with the `Inputs` and `Outputs` sections
and requires option-bearing APIs to describe named fields. Generated API pages
use this same help block, so the command-line `help` view and HTML reference do
not have separate prose owners.

Code under an `Example:` heading is an executable contract. The test runner
extracts that code from the function header and executes it in MATLAB. Use
`Typical Call:` when a useful sketch depends on a user's data file, an existing
app/session variable, or an interactive dialog. Such a sketch becomes an
`Example:` only after it has self-contained synthetic setup and passes the
example runner.

A self-contained MATLAB block in an app manual may be preceded by
`<!-- labkit-runnable-example -->`. The documentation contract extracts and
executes every marked block in a clean test setup. Mark only examples that use
synthetic data, require no dialogs or user files, and avoid lasting file or UI
side effects. Unmarked blocks may demonstrate a typical call with a user's own
file, but every variable and placeholder must still be explained by the nearby
text.

## Cross-References

Use relative Markdown links between narrative sources. Link the first useful
mention of an app, framework topic, library, or related guide. Function names
use fully qualified MATLAB symbols so the renderer can link them to generated
API pages.

Every app manual links its family, related apps, relevant libraries, public
app APIs, and component history when records exist. Every library landing
links representative apps. Related links should help the reader continue a
task; they are not a list of every page sharing a keyword.

The renderer rejects unresolved local Markdown targets. External links remain
ordinary HTTPS links and are not copied into the site.

## Rendering And Search

`tools/docs/renderLabKitDocs.m` reads the structured model, renders all
narrative and API pages, builds navigation and related links, and writes the
static site to `site/`. The renderer uses MATLAB only and introduces no
third-party runtime dependency.

Search is a generated static index containing titles, headings, descriptions,
keywords, components, MATLAB symbols, and help text. It works from GitHub
Pages and when `site/index.html` is opened directly from disk; it must not
depend on a local web server or a fetch request.

Generated pages carry a generated-file marker. Regeneration builds a complete
temporary tree, then synchronizes its files into `site/`: changed files are
updated, obsolete files and empty directories are removed, and the canonical
`site/` directory itself is preserved. Keeping that root stable avoids numbered
conflict copies when the repository is stored in a synchronized folder.

## Build And Validate

Use the documentation build and consistency tasks listed in
[Testing](testing.md). The build regenerates the tracked site; the consistency
check renders independently and compares that result with `site/`. Project
documentation tests additionally check page/catalog uniqueness, source and
output existence, API coverage, local links, direct-file search, generated
markers, and prohibited retired paths.

Before committing documentation work:

1. review the Markdown diff for claims not backed by current code;
2. regenerate `site/`;
3. run the focused documentation guardrail;
4. open representative app, module, API, history, and search pages;
5. commit source and generated output together.

## Related Topics

- [Documentation Home](../README.md)
- [Architecture](architecture.md)
- [App Development](app-development.md)
- [Testing](testing.md)
- [Release Process](release.md)
