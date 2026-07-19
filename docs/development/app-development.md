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
apps/<family>/<app_slug>/+<app_slug>/+userInterface/buildWorkbenchLayout.m
```

`runtime.define` supplies an empty version-1 project, empty session, empty
action registry, and empty presenter model when those components are omitted.
Add `definitionActions.m` for interactions, a presenter for dynamic views,
`createSession.m` for transient decoded/cache state, and `projectSpec.m` only
when the App owns durable data. That single project file contains local create,
validate, and migrate functions. Its migrate callback exists only after a saved
project schema has actually changed; Runtime owns the version loop.

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

`definition.m` returns a plain struct created by
`labkit.ui.runtime.define`. It is the App's single product contract and names
the public command, stable ID, display metadata, App version, compatible
LabKit facades, and layout builder. Project schema, session factory, action
registry, presenter, renderers, and startup event are opt-in capabilities.

The complete field tables, callback signatures, canonical project/session
buckets, presenter shape, and renderer contract are documented in
[Runtime and Lifecycle](../framework/runtime.md#definition-component-contract).
For a complete file-by-file implementation, follow
[Build a Complete App](complete-app.md).

The framework owns:

- startup, readiness, and busy state
- queued callback dispatch and rollback
- project save/load and recovery
- managed interactions and resources
- debug tracing and result manifests

The app owns durable `state.project`, transient `state.session`, workflow
handlers, presentation models, and scientific behavior.

## Build The Workbench

`+userInterface/buildWorkbenchLayout.m` returns a data-only
`labkit.ui.layout.*` tree. Keep tab, section, and workspace builders in the
same order users see them. It must not create graphics handles, read files,
run calculations, mutate state, or schedule startup work.

`+userInterface/presentWorkbench.m` is the pure bridge from canonical state to
semantic control properties, prepared plot models, and managed interaction
specs. Renderers draw prepared models and should not own workflow decisions.

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
[Testing](testing.md). Automated GUI tests cover launch, layout, callbacks,
debug plumbing, and synthetic workflows; visual quality and manual interaction
feel still require a human MATLAB check.

## Related Reference

- [App catalog and workflows](../apps/README.md)
- [App Framework](../framework/README.md)
- [Architecture](architecture.md)
- [Testing](testing.md)
