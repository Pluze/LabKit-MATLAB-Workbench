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

## Design

Write a short working brief with app/family, inputs, project/session shape,
controls, calculations, preserved compatibility, intentionally discarded flow,
previews, results, exports, tests, and manual GUI checks.

Use this current shape:

```text
labkit_<Name>_app.m
+<slug>/definition.m
+<slug>/definitionActions.m
+<slug>/requirements.m
+<slug>/version.m
+<slug>/+appLifecycle/createProject.m
+<slug>/+appLifecycle/createSession.m
+<slug>/+appLifecycle/validateProject.m
+<slug>/+userInterface/buildWorkbenchLayout.m
+<slug>/+userInterface/presentWorkbench.m
+<slug>/+<workflowCapability>/...
```

The entrypoint only launches. `definition.m` only declares the runtime graph.
`definitionActions.m` registers semantic commands and coordinates app-owned
workflow code. Lifecycle owns durable/transient schemas and compatibility
hooks. Layout is data-only; presentation is a pure state-to-view mapping.

Use concrete workflow packages such as `sourceFiles`, `analysisRun`,
`cropGeometry`, or `resultFiles`. Keep small callback glue local. Do not create
technical buckets, package-root runners, alternate interaction runtimes,
control mutation facades, or helpers merely to meet a line budget.

## Build order

1. Define requirements, version, identity, project/session schema, and project
   validation.
2. Declare the semantic layout and action registry.
3. Implement GUI-free readers/calculations/result builders with synthetic
   tests.
4. Implement the presenter, registered renderers, and managed interactions.
5. Keep selection cheap and batch loading lazy; separate preview-resolution
   work from original-resolution Run/Export.
6. Add portable project references, relinking, current-envelope save, and only
   the read-only compatibility imports/migrations actually required.
7. Test calculation/export contracts directly and the bounded GUI workflow
   semantically.
8. Update the app manual, version, and component history.

Use `labkit-boundary-guard` before adding a public facade API,
record active compatibility retirement directly in `.agents/migration_guide.md`,
and use `labkit-test-planner` for validation. Report preserved science, changed flow,
files, tests, manual checks, and anything intentionally left app-local.
