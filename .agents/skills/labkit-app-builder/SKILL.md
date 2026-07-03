---
name: labkit-app-builder
description: "Use for building or refactoring a LabKit MATLAB GUI app from legacy MATLAB scripts/functions, rough reference code, command-line/debug scripts, existing GUI code, SOPs, experiment protocols, workflow notes, or prose descriptions. Trigger when creating a new app, migrating old analysis code into apps/, translating a manual lab workflow into an interactive GUI, or deciding what legacy algorithm/science/calculation to keep while redesigning app flow around labkit.ui/image/dta/rhs/biosignal facades."
---

# LabKit App Builder

## Goal

Turn existing analysis code or a written lab procedure into a maintainable LabKit app without turning LabKit into a monolithic platform.

The target shape is:

- one launchable app entry point under `apps/<category>/`
- reusable UI/data boilerplate behind `labkit.ui`, `labkit.image`, `labkit.dta`, `labkit.rhs`, or `labkit.biosignal`
- domain formulas, plot choices, result fields, export schemas, and workflow wording owned by the app
- app-owned helper packages under `apps/<family>/<app_slug>/+<app_slug>/...`
  when the app needs extracted production helpers
- synthetic tests for core calculations and export contracts

## Required Read Order

Start with a quick pass:

1. `AGENTS.md`
2. `apps/AGENTS.md`
3. The legacy source, SOP text, and closest existing LabKit app

Use a deep pass only for the boundary being touched:

- read `+labkit/AGENTS.md` if any reusable helper or facade may change
- read `tests/AGENTS.md` if adding tests or fixtures
- read `docs/apps.md` for public app shape or entrypoint changes
- read `docs/ui.md` for shell, layout, controls, axes, callbacks, or debug UI
- read `docs/image.md`, `docs/dta.md`, `docs/rhs.md`, or `docs/biosignal.md` only for those facade-backed apps

Do not copy local paths, real filenames, sample labels, subject names, timestamps, device IDs, or proprietary row values into tracked files.

## Intake Pass

Inspect the legacy code or SOP before designing. Treat legacy code as evidence, not as the desired app architecture. Build a private working map with:

- accepted inputs and file families
- user actions and order of operations
- parameters, defaults, and units
- calculations and thresholds
- plot views and annotations
- result summaries and export columns
- failure cases and failed-row behavior
- sample/demo files that must not be committed
- duplicate parser, UI, plotting, or export boilerplate

For SOP-only tasks, ask for missing scientific definitions only when they cannot be inferred safely. Do not invent formulas, thresholds, pass/fail criteria, or export schemas.

## Preserve Science, Redesign Flow

Legacy scripts often contain command-line staging, debug phases, ad hoc plotting, workspace plumbing, hard-coded paths, and run-order assumptions that were useful while developing the analysis. Do not copy that runtime flow into the app.

Extract and preserve:

- scientific assumptions and definitions
- formulas, thresholds, units, and default parameters
- signal/image/data transformations that affect results
- result fields, export columns, and status meanings that users rely on
- parser or file-format edge cases that explain real input variability

Redesign or discard:

- "run section 1, then section 2" command-line workflows
- debug-only flags, figures, pauses, printouts, and intermediate saves
- base-workspace variables, globals, `assignin`, `evalin`, and manual workspace setup
- hard-coded local paths, sample filenames, and output folders
- repeated file dialogs, one-off demo branches, and exploratory plot variants
- control flow that reflects debugging history rather than user intent

The app flow should be designed from the lab user's task: load inputs, set meaningful options, preview enough state to trust the analysis, run or refresh deterministically, inspect results, and export stable outputs.

## Triage Legacy Code

Classify every meaningful part:

- **Promote to facade** only when domain-neutral, independently testable, and useful beyond one workflow.
- **Keep app-local** for formulas, units, thresholds, labels, result fields, export tables, workflow-specific plots, and callback order.
- **Convert to app GUI** for manual steps that should become controls, previews, summaries, or export actions.
- **Convert to tests** for known numeric outcomes, parser edge cases, export column order, and previously fragile behavior.
- **Delete or ignore** one-off demo paths, local defaults, workspace plumbing, ad hoc scripts, generated outputs, sample files, and duplicated helper code already covered by LabKit facades.

When preserving legacy behavior, keep output names, column order, units, numeric tolerances, and status wording stable unless the user explicitly asks to change them.

## Design Brief Before Coding

Write a short app design brief before implementation:

```text
App name and category:
Input kind and reader/facade:
Session or app state shape:
Controls and defaults:
Core calculations:
Legacy behavior preserved:
Legacy flow intentionally discarded:
Plots and annotations:
Summary fields:
Export files and columns:
Synthetic tests:
Manual GUI checks:
Docs to update:
```

Use the closest existing app as the starting pattern, then reduce it to the actual workflow. Do not start from a large copy-only template.

## New App Cold Start

For a new app, create the standard app shape directly and use only the
smallest genuinely similar existing app as a reference. The first committed
version should already express the real workflow: app definition, state,
actions, render behavior, results, exports, and usage text should be specific
to the new app.

Keep app discovery source-based through `apps/**/labkit_*_app.m`; app
manifests, registries, per-app build tasks, and governance apps are outside
the app model. App-owned `version.m` files provide visible version and
update-date metadata without becoming dependency manifests. App-owned
`definition.m` files provide the framework runtime contract without becoming a
central registry.

## Implementation Pattern

Build the app in this order:

1. Add or update app-local `requirements.m` and `version.m`, then keep the
   public app entry point as a thin dispatch wrapper. It should pass metadata
   to `labkit.ui.app.dispatchRequest`, launch
   `labkit.ui.app.run(<app_slug>.definition(), request)`, and apply the app
   version title to the returned figure.
2. Add `+<app_slug>/definition.m` using `labkit.ui.app.define`. It should name
   app id/title, initial state factory, data-only spec builder, action table,
   render function, startup phases, and optional hydration phases. Do not put
   IO, computation, MATLAB handle creation, timers, loading controls, or
   framework readiness mutation in `definition.m`.
3. Put the data-only spec in `+<app_slug>/+ui/buildSpec.m`; the framework
   runtime generates callback handles and passes them into the spec builder.
4. Add app-owned `+state/initial.m`, `+actions/table.m`, focused action
   handlers, and `+view/render.m`. Actions update app state and request
   framework effects; render helpers update existing controls from prepared
   state without IO, heavy computation, or exports.
5. Keep the top of nontrivial `buildSpec.m` files shallow: the app constructor
   should name the control-tab tree and workspace, while local builder
   functions define each tab, section, and workspace region. Prefer this
   source shape over adding formatter scripts or shared UI templates; the
   purpose is to make the page hierarchy readable without turning app-owned UI
   wording into framework configuration. Order functions as `buildSpec`, tab
   tree, tab builders, section builders in visual order, workspace builder,
   small helper builders, then `callbackValue`.
6. Keep `buildSpec.m` free of MATLAB handle creation, `labkit.ui.app.create`,
   state mutation, IO, computation, export writing, nested callback
   implementations, and row/column layout mechanics. Use a named
   `+ui/build<Thing>.m` custom builder only for a justified interaction that the
   ordinary spec grammar cannot represent.
7. Wire file loading through the appropriate facade or app-local reader.
8. Store state in one app struct; avoid globals, base workspace state, and hidden local paths.
9. Rebuild the user workflow around stable controls, previews, summaries,
   semantic control ids, and exports; do not reproduce command-line debug
   staging.
10. Move GUI-free calculations below the app `end` as app-local functions.
11. Extract production helpers into role-based app-owned package components when
   the app is too large for a readable single entry point:
   `+state` for defaults/factories, `+io` for file discovery/readers/filters,
   `+ops` for GUI-free transforms, `+view` for table/detail/display data, and
   `+export` for output writers/manifests. Create only the packages the app
   actually needs.
12. Avoid boundary-blurring helper names such as `helpers.m`, `utils.m`,
   `common.m`, `misc.m`, `callbacks.m`, `manager.m`, `processor.m`,
   `layout.m`, and `createUI.m`; name files by stable role or output instead.
13. For active runner or app-private migrations, use `labkit-migration-planner`
   to audit the current debt map and update `.agents/migration_guide.md`.
14. Do not add new package-root eager `run.m` orchestration, `private/`
   runners, `*Workflow.m` string-dispatch adapters, fixed `+app` package
   names, or app-local public helper packages.
15. Render prepared data through UI 2.0 named view helpers or existing
   `labkit.ui.tool.*` helpers; keep analysis out of UI helpers.
16. Add export builders before CSV/PNG writing so output contracts can be tested.
17. Add focused tests with synthetic fixtures or minimal generated data.
18. Update human docs for user-facing behavior and scoped `AGENTS.md` only when rules change.

## Validation

Use `labkit-test-planner` to choose source-aligned validation. It should route
to `docs/testing.md` for exact build-task names and GUI/non-GUI pairings.

For reusable facade changes, also use `labkit-boundary-guard`.

Report automated tests separately from manual GUI validation. Do not claim full workflow validation from non-GUI tests.
