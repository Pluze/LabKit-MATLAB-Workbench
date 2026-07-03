# Agent Migration Ledger

This is the agent-facing migration debt ledger for LabKit. It is not an
architecture manual, validation matrix, historical changelog, or general
roadmap.

Human-facing architecture and app behavior live in `docs/`. Exact validation
commands live in `docs/testing.md` and are routed through
`labkit-test-planner`. This ledger owns active migration debt facts,
retirement rules, and executable migration routes.

## How To Use This File

Use this file for migration debt, runner complexity, helper structure, app
workflow validation, app-owned package cleanup, or framework hook extraction.
A capable agent should be able to continue an active route from this file
without asking for a new plan.

Before executing a route:

1. Verify current facts with source scans; this snapshot can drift.
2. Preserve app-first ownership: workflow stays in apps, reusable mechanics
   move to `+labkit` only after the boundary test is clear.
3. Prefer behavior-backed refactors. A smaller file is not progress unless
   responsibilities become clearer and the real GUI/app path uses the helper.
4. Update this file only when migration debt is added, reduced, retired, or
   reprioritized.

When a route completes, shrink this file. Completed work should become source,
tests, docs, or guardrails, not permanent roadmap prose.

## Current Debt Snapshot

Last audited: 2026-07-03.

Active debt:

```text
Declarative app runtime full migration
```

Current facts:

- Source inventory from current working-tree files:
  - total: 813 `.m` files, 62,348 lines across `apps/`, `+labkit/`, and
    `tests/`
  - `apps/`: 464 files, 26,251 lines, max 602 lines
  - `+labkit/`: 210 files, 18,115 lines, max 592 lines
  - `tests/`: 139 files, 17,982 lines, max 600 lines
  - `labkit_launcher.m`: 1,547 lines and intentionally exempt
- Tracked files over the 650-line repository file budget:
  `labkit_launcher.m` only, by design.
- There are 17 supported app packages. All currently launch through
  `labkit.ui.app.run(<slug>.definition(), request)`.
- Chrono Overlay, EIS, VT Resistance, CIC, CSC, Response Review Stats, ECG
  Print, and RHS Preview now prove the final workflow-first app package shape:
  `definitionActions.m`, `+appLifecycle/createInitialState.m`,
  `+userInterface/buildWorkbenchSpec.m`,
  `+userInterface/updateWorkbenchFromState.m`, workflow packages such as
  `+sourceFiles`, `+analysisRun`, and `+resultFiles`, with no legacy
  `+actions`, `+state`, `+ui`, `+view`, `+ops`, `+io`, or `+export`
  buckets.
- The other 9 app packages still use transitional `+state`, `+actions`,
  `+ui`, and `+view` adapters. Treat those adapters as the next migration
  target, not as final behavior.
- Package-root app `run.m` orchestration has been retired. App structure
  guardrails now require `definition.m` and reject package-root app runners.
- `+labkit` implementation hotspots near the file budget:
  - `+labkit/+ui/+diag/createContext.m` at 649 lines
  - `+labkit/+ui/+tool/createRuntime.m` at 636 lines
  - `+labkit/+biosignal/private/detectEcgPeaksImpl.m` at 623 lines
  - `+labkit/+ui/+app/private/buildFilePanelControl.m` at 607 lines
  - `+labkit/+ui/+app/private/buildControl.m` at 539 lines
- Debug sample packs are complete and no longer an active migration route.
  Each app owns its generator, debug launch writes clean-room artifacts under
  `artifacts/debug/.../<SessionId>/`, and debug startup is otherwise empty.
- Helper-quality audit is a dry-run routing aid, not a blocking guardrail:
  `labkitHelperQualityAudit(root, "MaxLines", 20, "Scope", "all")`.
- App `private/` debt, `+labkit` private helper contract debt, and
  string-dispatch/core-router debt are clear.
- Shared mechanics already owned by `+labkit` include the layered
  `labkit.ui.app/spec/view/tool/diag` surface, image facade primitives,
  file-entry path/index helpers, output prompts, hidden-test-safe alerts,
  debug exception reporting, and close guards.
- GUI workflow coverage is real-workflow-first. `AppLaunchGuiTest` is a
  missing-coverage guardrail; do not re-expand structural GUI tests with
  launch-only assertions already covered by workflow or shared debug tests.
- Test performance profiling on 2026-07-02 exposed fixed GUI waits and
  repeated runner path scans; current tests route debounce/layout settling
  through GUI idle helpers and keep runner path setup to one path read per
  configuration pass.
- App startup profiling and debug traces on 2026-07-02 exposed broad
  user-facing startup debt: launcher double-click can produce a blank visible
  app frame while shared `labkit.ui.app.create`, app-owned initialization,
  tool attachment, and initial axes rendering continue on the UI thread.
- Follow-up startup profiling on 2026-07-03 after package-root runner
  retirement showed repeated readiness message flushes as the largest
  framework-owned startup hotspot in ordinary app launch. RHS Preview ordinary
  startup improved from about 27.5 s total with
  `startupLifecycle>updateStateWithMessage` at about 14.5 s to about 20.0 s
  total with that helper at about 8.3 s after limiting readiness UI flushes to
  the first visible status update and failure messages. Evidence artifacts:
  `artifacts/profile/profile_addpath(fullfile('tests','runner')); setupLabKitTestPath(); fig=labkit_RHSPreview_app; drawnow; pause(0_20260703_042616.json`
  and
  `artifacts/profile/profile_addpath(fullfile('tests','runner')); setupLabKitTestPath(); fig=labkit_RHSPreview_app; drawnow; pause(0_20260703_043156.json`.
- `labkit.ui.app.define` and `labkit.ui.app.run` exist. The current runtime
  validates definitions, creates state, generates callbacks, builds through
  `labkit.ui.app.create`, stores runtime state, renders after actions,
  dispatches startup and hydration phases, records phase timings, reports
  runtime action exceptions to debug context, and applies a small effect set:
  `logDebug`, `alert`, `setBusy`, and `clearBusy`.
- Remaining runtime gaps before full migration: complete action gating
  semantics, normalized payload helpers for common controls, a traceable
  readiness/busy surface for slow startup, and migration of app commands away
  from direct UI control reads.
- Current app runners and transitional definitions assume a complete
  `ui.controls` registry after shell construction. Staged startup must
  preserve that contract until each app has explicit startup and hydration
  phases.

## Reopen Triggers

Open a new active route here only when current scans expose concrete debt:

- a package-root app `run.m` reappears, or a substantive change would add
  unrelated behavior to a budget-watchlist transitional action table without a
  responsibility audit
- helper-quality audit reports new `inline-or-merge-candidate` rows after
  excluding valid contracts such as app entrypoints, `requirements.m`,
  `version.m`, transitional specs, state factories, input policies, test APIs,
  framework adapters, and transitional side-effect boundaries
- a new app entry point appears without dedicated GUI coverage
- hidden workflow validation needs a new app-neutral driver operation or
  app-owned test hook to avoid OS/modal dialogs
- current JUnit timing or profiler evidence identifies a new test-performance
  hotspot whose fix would change runner behavior, validation policy, or
  app/workflow coverage
- migration exposes package-boundary drift that cannot be fixed locally
  without a new `+labkit` API decision

## Active Route: Declarative App Runtime

Status: documentation alignment, runtime hydration/timing, and every
package-root runner transitional migration are committed or in progress on the
active branch. This is not a final state. The route remains open until
transitional adapters move to workflow-first packages and the profiler/debug
startup evidence confirms the new structure.

Opened 2026-07-02 after launcher/app startup traces showed blank app frames
and delayed first render across multiple apps. Revised 2026-07-03 to make the
fix a breaking framework/runtime migration, not an app-local loading-indicator
patch.

### Current Work Order

1. Keep docs and guardrails aligned with the current migration stage.
2. Close remaining runtime gaps in `labkit.ui.app.run`.
3. Migrate all remaining transitional definitions to workflow-first packages.
4. Harden guardrails incrementally from the Chrono Overlay representative
   shape without rejecting still-unmigrated apps before their phase starts.
5. Profile/debug slow startup paths, then optimize the new structure.
6. Defer CI polling until merge readiness; use local validation for touched
   source phases.

### Design Constraints

Use mature toolkit patterns as constraints, not as a mandate to change
language or toolkit:

- VS Code activation events: expensive capabilities should be activated by
  command, view, file, tab, startup-finished, or idle triggers instead of
  eager app startup.
- VS Code extension host: framework runtime and app behavior need a clear
  ownership boundary.
- Angular `@defer`, React `Suspense`, and Qt Quick `Loader`: readiness,
  fallback UI, and activation should be explicit framework concepts.
- React state preservation and Android UI layer guidance: app state should be
  the stable description rendered by UI update code, not a side effect of
  rebuilding controls.
- Redux and Elm Architecture: callbacks and startup phases dispatch named
  actions, actions update state, and rendering observes state.
- Rails and Home Assistant: keep a small convention-first app shape; add role
  files only when a real workflow needs them.

LabKit principle:

```text
apps declare intent; the framework owns lifecycle, dispatch, readiness,
busy state, staged activation, diagnostics, and safe effects
```

### Target App Shape

The final app unit is a plain MATLAB definition struct consumed by
`labkit.ui.app.run`:

```matlab
function def = definition()
def = labkit.ui.app.define( ...
    "Id", "batch_crop", ...
    "Title", "Microscope Batch Image Crop", ...
    "InitialState", @batch_crop.appLifecycle.createInitialState, ...
    "Spec", @batch_crop.userInterface.buildWorkbenchSpec, ...
    "Actions", batch_crop.definitionActions(), ...
    "Render", @batch_crop.userInterface.updateWorkbenchFromState, ...
    "Startup", ["workspace", "preview"], ...
    "Hydrate", ["tools", "debugArtifacts"]);
end
```

Target package layout:

```text
apps/<family>/<slug>/labkit_<Name>_app.m
apps/<family>/<slug>/+<slug>/definition.m
apps/<family>/<slug>/+<slug>/definitionActions.m
apps/<family>/<slug>/+<slug>/requirements.m
apps/<family>/<slug>/+<slug>/version.m
apps/<family>/<slug>/+<slug>/+appLifecycle/createInitialState.m
apps/<family>/<slug>/+<slug>/+userInterface/buildWorkbenchSpec.m
apps/<family>/<slug>/+<slug>/+userInterface/updateWorkbenchFromState.m
apps/<family>/<slug>/+<slug>/+sourceFiles/...
apps/<family>/<slug>/+<slug>/+analysisRun/...
apps/<family>/<slug>/+<slug>/+resultFiles/...
```

Only create workflow packages the app actually needs. Do not introduce generic
new packages such as `+actions`, `+renderers`, `+ops`, `+io`, `+export`,
`+helpers`, `+utils`, `+manager`, or fixed `+app` packages for final-shape app
code.

App entrypoints remain thin public wrappers around version/requirement checks,
debug dispatch, and `labkit.ui.app.run(<slug>.definition(), request)`.

### Runtime Contract

`labkit.ui.app.run(definition, request)` owns this state machine:

```text
define
  -> validateDefinition
  -> createShell
  -> createState
  -> buildSpec
  -> constructVisibleWorkbench
  -> paintReadinessBoundary
  -> dispatchStartupActions
  -> firstRenderReady
  -> idleHydration
  -> steadyInteraction
  -> closing
```

Framework-owned responsibilities:

- validate definition fields, action ids, duplicate control ids, and phase
  names before the UI becomes interactive
- create shell, readiness surface, controls registry, diagnostics, close
  guard, and appdata registry
- generate callbacks from action ids and route user events through one
  dispatcher
- gate actions while startup is pending, with documented exceptions for close
  and cancellation
- run startup phases after the shell has had a paint opportunity
- keep a non-modal readiness surface quiet for fast starts and visible for
  slow starts
- run idle hydration for nonessential work such as inactive tabs, expensive
  tools, and debug artifacts
- report startup/action exceptions through debug context
- expose traceable phase timings for performance diagnosis

App-owned responsibilities:

- define state shape and defaults
- define labels, choices, units, formulas, plots, exports, and workflow
  decisions
- implement app operations in concrete workflow packages such as
  `+sourceFiles`, `+analysisRun`, `+cropGeometry`, `+thermalFrames`, or
  `+resultFiles`
- translate prepared state into existing handles in UI update functions
- return updated state and requested effects from command handlers

Target flow:

```text
event/startup phase
  -> framework dispatch(commandId, payload)
  -> app workflow command(state, payload, services)
  -> next state + effects
  -> framework applies effects
  -> app UI update(next state, ui, services)
```

Initial framework effects should stay small and test-visible:
`setBusy`, `clearBusy`, `alert`, file/folder/save prompts through existing
dialog adapters, `logDebug`, `requestRender`, and framework-approved
`runLater(phaseName)`.

### Migration Policy

This may be a breaking internal app-structure migration, but public behavior
must stay stable unless separately approved:

- public app entrypoint names remain stable
- launcher discovery remains source-based through `apps/**/labkit_*_app.m`
- workflow outputs, formulas, plots, export schemas, labels, defaults, and
  settings remain app-owned and behavior-compatible
- old framework-private helper shapes may be deleted after real app paths
  migrate
- old package-root runner orchestration should not become permanent
  compatibility debt
- guardrails should reject new eager runners once the new path is available

Do not migrate LabKit apps to another language/toolkit, create a monolithic
host that hides entrypoints, move app formulas or schemas into `+labkit`,
introduce MATLAB classes for the runtime model, expose raw timers/readiness
flags to app code, or add a generator before the definition DSL is proven.

### Required Workstreams

1. Runtime foundation
   - Preserve `labkit.ui.app.define` and `labkit.ui.app.run`.
   - Keep lifecycle/readiness implementation private under
     `+labkit/+ui/+app/private`.
   - Complete action gating, normalized payload helpers, readiness/busy
     tracing, and test-visible effects.
   - Keep hidden/minimized GUI tests visually quiet while preserving runtime
     readiness state.

2. App migration
   - Package-root runner orchestration has been retired; keep new work on
     definitions and workflow-first packages.
   - Chrono Overlay, EIS, VT Resistance, CIC, CSC, Response Review Stats, ECG
     Print, and RHS Preview are representative workflow-first packages and
     should be used as small app references for the fixed lifecycle/UI surface
     and direct workflow package tests.
   - After runtime gaps are closed, migrate transitional definitions from
     `+state/+actions/+ui/+view` to workflow-first packages by app family.
   - Remove obsolete runner or adapter code after behavior coverage passes
     through the new path.

3. Guardrails and tests
   - Add validation tests for required fields, action ids, duplicate controls,
     startup phases, hidden-mode behavior, action gating, payload
     normalization, exception reporting, and phase timings.
   - Keep workflow-first structure checks transitional for unmigrated apps,
     while rejecting `+actions`, `+state`, `+ui`, `+view`, `+ops`, `+io`, and
     `+export` packages inside any app that has entered the workflow-first
     shape.
   - Add source guardrails for direct startup timer/readiness manipulation in
     app packages after the new runtime lands.

4. Performance and debug evidence
   - Run focused validation after executable changes.
   - Capture phase timings or trace evidence for at least two previously slow
     apps and one ordinary app.
   - Use profiler/debug evidence to optimize the new structure before squash
     merge.

### Small-Commit Discipline

Use small commits in this order unless a verified dependency forces a split:

1. `docs:` route, human docs, scoped AGENTS, and app-builder guidance.
2. `feat:` runtime gap closure plus focused runtime tests.
3. `refactor:` representative app migration.
4. `refactor:` remaining package-root runner retirement.
5. `refactor:` workflow-first package migration by app family.
6. `test:` guardrails and validation expansion.
7. `perf:` measured startup improvements when lower latency is the primary
   effect.

Push every coherent small commit on this branch after creation. Defer CI
inspection until merge readiness unless local changes require GitHub-side
evidence.

### Validation Gates

- Design-only and docs-only commits do not require MATLAB validation.
- After framework runtime source changes: run the changed-file local plan,
  normally `matlab -batch "buildtool changed"`.
- Before merging implementation: run the source-aligned GUI/framework task
  selected from `docs/testing.md`, plus profile/trace evidence for slow
  startup paths.
- CI inspection is deferred until merge readiness according to `AGENTS.md`.

### Completion Criteria

- Every supported app launches through a framework-owned app definition.
- Package-root eager runner orchestration is removed.
- The framework owns lifecycle, generated callbacks, busy gating, readiness,
  staged startup, idle hydration, diagnostics, exception reporting, and phase
  timing.
- App packages declare identity, state factory, spec builder, command handler
  registry, visible-state update, startup/hydration phase names, and app-owned
  workflow packages.
- Docs, AGENTS rules, app-builder guidance, tests, and guardrails describe the
  same architecture.
- Representative slow apps no longer show a blank app frame while opaque
  app-owned startup continues.
- The active route is shrunk or retired after the migration lands.

## Long-Term Compatibility Queue

The DTA facade intentionally keeps legacy bridge fields beside canonical
unit-explicit fields. This is compatibility debt, not current cleanup debt.

Do not remove fields such as chrono `t`, `Vf`, `Im`, `alignTime`,
`tAligned`, or EIS `Pt`, `Freq`, `Zreal`, `Zimag`, `negZimag` during ordinary
runner cleanup. A removal requires an explicit DTA major-version route after
electrochem apps and tests have moved to canonical fields.

## Migration Standard

Apps are first-class products. `+labkit` stays a small domain-neutral
foundation with UI, image, DTA, RHS, and biosignal facades. App-specific
calculations, summaries, plots, exports, workflow wording, file conventions,
and result schemas stay under the owning app tree.

Migration progress means:

- a responsibility boundary becomes clearer
- deterministic behavior becomes directly testable
- the real GUI or app path uses the extracted helper
- duplicate app-neutral mechanics are removed from apps
- total workflow cognitive load falls

Migration is not progress when it only moves a large block, creates tiny
cosmetic helpers, hides app workflow behind generic names, adds noisy
guardrails, or adds docs without retiring stale debt or clarifying an active
contract.

Use `labkit-boundary-guard` before promoting behavior to `+labkit`. Use
`labkit-test-planner` for validation routing and `docs/testing.md` for exact
commands.
