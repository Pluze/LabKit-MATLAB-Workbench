---
name: labkit-app-builder
description: "Use to create or substantially refactor a LabKit MATLAB app from scripts, functions, protocols, existing GUIs, workflow notes, or prose requirements."
---

# LabKit App Builder

## Read and intake

Read `AGENTS.md`, `apps/AGENTS.md`, the source/protocol, the closest genuinely
similar app, and affected app docs/tests. Read `+labkit/AGENTS.md` only if a
facade may change and `tests/AGENTS.md` when creating fixtures or test policy.

Before coding, map:

- accepted inputs and file variability;
- user actions and order;
- parameters, defaults, units, formulas, and thresholds;
- plots, annotations, results, exports, and failed-row behavior;
- state that must persist versus transient view/cache state;
- sensitive examples that must become synthetic fixtures.

Treat legacy code as evidence, not the target architecture. Preserve science,
units, result/export contracts, and relied-upon status meanings unless the user
requests change. Discard workspace plumbing, hard-coded paths, debug staging,
globals, `evalin/assignin`, repeated dialogs, pauses, and exploratory branches.
Do not invent missing scientific definitions.

If the user asks to correct behavior in an existing App, keep the current App
shape and public boundary unless the defect itself proves a boundary change is
necessary. Do not relabel a bug fix or UX correction as a refactor, and do not
use the full architecture build sequence to justify unrelated cleanup.

## Design

Write a short working brief with app/family, inputs, project/session shape,
controls, calculations, preserved compatibility, intentionally discarded flow,
previews, results, exports, tests, and manual GUI checks.

Begin with the smallest complete shape:

```text
labkit_<Name>_app.m
+<slug>/definition.m
+<slug>/+userInterface/buildWorkbenchLayout.m
```

Add only capabilities the product needs:

```text
+<slug>/stateHandlers.m
+<slug>/projectSpec.m
+<slug>/createSession.m
+<slug>/+userInterface/presentWorkbench.m
+<slug>/+userInterface/<renderer>.m
+<slug>/+<workflowCapability>/...
```

The entrypoint only calls `definition().launch(...)`. `definition.m` owns identity,
version, requirements, layout, and references to optional capabilities.
`stateHandlers.m` returns only semantic `labkit.app.StateHandler` values
for App-owned business behavior; `labkit.app.layout.*` bindings and runtime
lifecycle behavior require no placeholder handlers. One `projectSpec.m`
returns a `labkit.app.project.Schema` owning
local create, validate, and
version-aware migrate functions when durable state exists; Runtime owns the
migration loop. Root `createSession.m` uses the fixed `(project,context)`
signature and rebuilds only App-specific transient data; opaque source paths
are resolved with `context.resolveSourcePaths`. Layout nodes are data-only;
`labkit.app.view.Snapshot` is a pure state-to-view mapping.

On the App SDK paved road, bind ordinary project/session fields directly in
`labkit.app.layout.*`, let `labkit.app.Definition` collect signal handlers,
omit `StrictCapabilities` unless strict auditing is needed, and let runtime
defaults complete the view snapshot. Add a StateHandler and view operation
only for real business effects or derived UI state.

Do not add separate `requirements.m`, `version.m`, generic `+appLifecycle` or
`+appState` packages, per-version migration files, or a `StartupHandler` that
only constructs default state. Add a semantically named Start function only
for real post-layout request or resource initialization.

Use concrete workflow packages such as `sourceFiles`, `analysisRun`,
`cropGeometry`, or `resultFiles`. Keep small callback glue local. Do not create
technical buckets, package-root runners, alternate interaction runtimes,
control mutation facades, or helpers merely to meet a line budget. Public SDK
names must state their capability directly; do not add general buckets such as
`Manager`, `Service`, `Helper`, or `Data`.

## Build order

1. Define identity, version, requirements, layout, and only the optional
   project/session capabilities the App needs.
2. Declare the semantic layout and action registry.
3. Implement GUI-free readers/calculations/result builders with synthetic
   tests.
4. Implement the presenter, registered renderers, and managed interactions.
5. Keep selection cheap and batch loading lazy; separate preview-resolution
   work from original-resolution Run/Export.
6. Add portable project references, relinking, current-envelope save, and only
   the read-only compatibility imports/migrations actually required.
7. Test calculations, state transitions, renderers, and exports directly.
   Run the bounded GUI workflow once after those smaller checks are stable;
   do not use a long end-to-end GUI method as the edit-fail-edit loop.
8. Update the App definition version, manual, and component history.

Use `labkit-boundary-guard` before adding a public facade API,
record active compatibility retirement directly in `.agents/migration_guide.md`,
and use `labkit-test-planner` for validation. Report preserved science, changed flow,
files, tests, manual checks, and anything intentionally left app-local.
