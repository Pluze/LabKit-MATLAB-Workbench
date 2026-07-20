# App Development

LabKit apps are first-class deliverables. Each app owns its scientific
workflow, state, plots, result schema, and exports; the reusable framework owns
lifecycle and domain-neutral UI mechanics.

## Create An App

Start from the LabKit app template rather than copying a complete neighboring
app. Use the smallest nearby app only as a workflow example.

A static App begins with only the product entrypoint, definition, and layout
it actually uses:

```text
apps/<family>/<app_slug>/labkit_<AppName>_app.m
apps/<family>/<app_slug>/+<app_slug>/definition.m
apps/<family>/<app_slug>/+<app_slug>/+workbench/buildLayout.m
```

`labkit.app.Definition` supplies empty project/session and default presentation
behavior when optional components are omitted. Bind real business callbacks
directly from the layout. Add `+workbench/present.m` for derived visible state,
`createSession.m` for transient decoded/cache state, and `projectSpec.m` only
when the App owns durable data. That single project file contains local create,
validate, and migrate functions. Its migrate callback exists only after a
saved project schema has actually changed; Runtime owns the version loop.

Runtime and App architecture names remain versionless. Put facade/App
compatibility in the existing version and requirement metadata, and put saved
payload numbers only in `projectSpec` migration logic. Do not create
version-named packages, files, functions, types, tests, or manual sections.

The project validator owns only App-specific requirements: domain fields,
legal choices and ranges, cross-field relationships, source roles, and
scientific invariants. Runtime validates the five canonical project buckets
and standard portable source records before the callback runs. Do not repeat
those framework checks in each App.

Create additional packages only for concrete workflows that need them, for
example `+sourceFiles`, `+analysisRun`, `+resultFiles`, `+cropGeometry`, or
`+thermalFrames`. Avoid generic buckets such as `+actions`, `+ops`, `+io`,
`+helpers`, and `+utils`.

## Define The Runtime Contract

`definition.m` returns one immutable `labkit.app.Definition`. It is the App's
single product contract and names the public command, stable ID, display
metadata, App version, compatible LabKit facades, and workbench. Project
schema, session factory, presenter, post-layout start callback, and debug
sample are opt-in capabilities. Callbacks and renderers are owned directly by
their layout nodes.

The complete field tables, callback signatures, canonical project/session
buckets, presenter shape, and renderer contract are documented in
[Runtime and Lifecycle](../../framework/guides/runtime.md#definition-component-contract).
For a complete file-by-file implementation, follow
[Build a Complete App](complete-app.md).

The framework owns:

- startup, readiness, and busy state
- queued callback dispatch and rollback
- project save/load and recovery
- managed interactions and resources
- debug tracing and result manifests

The app owns durable `state.project`, transient `state.session`, semantic
callbacks, presentation models, and scientific behavior.

## Build The Workbench

`+workbench/buildLayout.m` returns a data-only `labkit.app.layout.*` tree.
Keep tabs, sections, and workspace pages in the same order users see them.
For a complex App, compose capability-owned layout fragments instead of
flattening every control into this file. It must not create graphics handles,
read files, run calculations, mutate state, or schedule startup work.

`+workbench/present.m` is the pure assembly bridge from canonical state to a
complete `labkit.app.view.Snapshot`. Compose feature-owned fragments with
`Snapshot.include`. Renderers live with the capability they draw, receive only
axes and a prepared model, and do not own workflow decisions.

Use the complete runtime value only at this assembly bridge and at callbacks
referenced directly by layout signals. Name it `applicationState`, unpack
`project` and `session` at the top, and call feature presenters with the exact
values they display. A feature presenter should look like
`present(results, selection, displayOptions)`, not `present(state)`.

A direct callback is the transaction adapter. Its signature is
`(applicationState, callbackContext)` for a button or
`(applicationState, typedEventValue, callbackContext)` for a value-bearing
signal. It may perform short, visible state mutation in workflow order, then
delegate calculations and writes through explicit inputs. Do not pass the
complete state or callback context into a generic second action layer.

## Name Workflow Code

Use concrete verb-object names such as:

```text
+sourceFiles/readSourceFiles.m
+analysisRun/collectAnalysisOptions.m
+analysisRun/computeAnalysisResults.m
+resultFiles/writeResultFiles.m
```

Keep callback-local glue local when extracting it would hide state mutation or
workflow order. Extract a helper when it owns a stable calculation, data
shape, file boundary, state transition, or reusable interaction contract.
File length alone is not an extraction reason.

## Data Loading And Task Lifecycle

Register large file selections with the least data needed for the first useful
preview. Decode the selected file on demand and defer full-batch work until the
user runs or exports when the workflow permits it.

Apps with preview, edit, run, or export stages should make dirty state and the
last successful task explicit. Pure helpers build deterministic task snapshots
and calculations; result writers receive explicit task data rather than
reading UI handles.

## Cross-App Data Contracts

Apps exchange saved, documented data contracts; production and debug code do
not call a sibling App package. A consumer owns its parser and error language,
so it can launch with only the framework and its own App root on the MATLAB
path. A producer owns serialization and schema validation. Keep one
producer-consumer integration test that invokes both Apps and proves the
current saved format remains compatible; keep consumer unit and debug fixtures
independent of the producer package so the shared test path cannot hide a
runtime dependency.

## Ownership Check

Keep these in the app:

- accepted formats, domain defaults, units, and thresholds
- formulas and scientific interpretation
- plots, labels, result columns, and export schemas
- workflow ordering, user messages, and logs

Move code into `+labkit` only when it is domain-neutral, independent of app
state, directly testable, used broadly, and makes the public API clearer. See
[Architecture](architecture.md#reusable-extraction-rule).

## Version And Requirements

`definition.m` owns supported LabKit facade ranges together with the App
command, display name, family, semantic version, and last change date. There
is no second metadata registry. App behavior changes update this definition,
the App documentation, and component-owned history in the same coherent
change.

## Validation

Use focused app tests while editing, then follow the stable gates in
[Testing](../maintain-and-release/testing.md). Automated GUI tests cover launch, layout, callbacks,
debug plumbing, and synthetic workflows; visual quality and manual interaction
feel still require a human MATLAB check.

## Related Reference

- [App catalog and workflows](../../apps/README.md)
- [App Framework](../../framework/README.md)
- [Architecture](architecture.md)
- [Testing](../maintain-and-release/testing.md)
