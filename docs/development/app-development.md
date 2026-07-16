# App Development

LabKit apps are first-class deliverables. Each app owns its scientific
workflow, state, plots, result schema, and exports; the reusable framework owns
lifecycle and domain-neutral UI mechanics.

## Create An App

Start from the LabKit app template rather than copying a complete neighboring
app. Use the smallest nearby app only as a workflow example.

A typical app begins with this fixed surface:

```text
apps/<family>/<app_slug>/labkit_<AppName>_app.m
apps/<family>/<app_slug>/+<app_slug>/definition.m
apps/<family>/<app_slug>/+<app_slug>/definitionActions.m
apps/<family>/<app_slug>/+<app_slug>/requirements.m
apps/<family>/<app_slug>/+<app_slug>/version.m
apps/<family>/<app_slug>/+<app_slug>/+appLifecycle/createProject.m
apps/<family>/<app_slug>/+<app_slug>/+appLifecycle/createSession.m
apps/<family>/<app_slug>/+<app_slug>/+appLifecycle/validateProject.m
apps/<family>/<app_slug>/+<app_slug>/+userInterface/buildWorkbenchLayout.m
apps/<family>/<app_slug>/+<app_slug>/+userInterface/presentWorkbench.m
```

Create additional packages only for concrete workflows that need them, for
example `+sourceFiles`, `+analysisRun`, `+resultFiles`, `+cropGeometry`, or
`+thermalFrames`. Avoid generic buckets such as `+actions`, `+ops`, `+io`,
`+helpers`, and `+utils`.

## Define The Runtime Contract

`definition.m` returns a plain struct created by
`labkit.ui.runtime.define`. It names the app id, project schema, optional
session factory, layout builder, action registry, presenter, renderers, and
optional startup event.

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

`requirements.m` declares supported LabKit facade ranges.
`version.m` declares the app command, display name, family, semantic version,
and last change date. App behavior changes update the version, app
documentation, and component-owned history record in the same coherent change.

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
