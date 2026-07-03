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
none
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
  Print, RHS Preview, Nerve Response Analysis, Batch Image Crop, Curvature
  Measurement, Focus Stack, DIC Postprocess, DIC Preprocess, FLIR Thermal,
  Image Enhance, and Image Match now prove the final
  workflow-first app package shape:
  `definitionActions.m`, `+appLifecycle/createInitialState.m`,
  `+userInterface/buildWorkbenchSpec.m`,
  `+userInterface/updateWorkbenchFromState.m`, workflow packages such as
  `+appState`, `+sourceFiles`, `+analysisRun`, `+cropGeometry`, and
  `+resultFiles`, with no legacy
  `+actions`, `+state`, `+ui`, `+view`, `+ops`, `+io`, or `+export`
  buckets.
- No app package still uses transitional `+state`, `+actions`, `+ui`,
  `+view`, `+ops`, `+io`, or `+export` adapter buckets.
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
- Current profiler/debug evidence on 2026-07-03 covered two previously slow
  apps and one ordinary app after the workflow-first migration:
  - RHS Preview ordinary startup:
    `artifacts/profile/current_rhs_preview_normal.json` reported no run error,
    about 27.2 s max total time, and
    `startupLifecycle>updateStateWithMessage` as the top editable self-time
    row at about 0.93 s.
  - FLIR Thermal ordinary startup:
    `artifacts/profile/current_flir_thermal_normal.json` reported no run
    error, about 24.8 s max total time, and the same readiness helper at about
    0.80 s editable self-time.
  - CIC ordinary startup:
    `artifacts/profile/current_cic_normal.json` reported no run error, about
    24.8 s max total time, and the same readiness helper at about 1.02 s
    editable self-time.
  - RHS Preview debug startup:
    `artifacts/profile/current_rhs_preview_debug.json` reported no run error,
    10 debug log lines, about 28.7 s max total time, `createContext` figure
    instrumentation at about 0.16 s editable self-time, and synthetic RHS
    sample writing at about 0.06 s editable self-time.
  - FLIR Thermal debug startup:
    `artifacts/profile/current_flir_thermal_debug.json` reported no run error,
    7 debug log lines, about 27.4 s max total time, and `createContext` figure
    instrumentation at about 0.14 s editable self-time.
- A final readiness coalescing check in
  `artifacts/profile/current_rhs_preview_normal_after_label_coalesce.json`
  reported no run error and about 26.5 s max total time. The remaining startup
  cost is dominated by MATLAB UI component creation, the framework shell
  construction path, timer/deferred startup mechanics, and test-path setup in
  profiled commands; no old package-root app runner or transitional adapter
  bucket remains in that path.
- Runtime hardening is now ordinary framework evolution, not active migration
  debt. Future action gating, payload helpers, busy/readiness refinements, or
  additional staged hydration should land only when a concrete app workflow or
  profiler/debug trace shows the need.

## Reopen Triggers

Open a new active route here only when current scans expose concrete debt:

- a package-root app `run.m` reappears, or a substantive change would add
  unrelated behavior to a budget-watchlist action table without a
  responsibility audit
- helper-quality audit reports new `inline-or-merge-candidate` rows after
  excluding valid contracts such as app entrypoints, `requirements.m`,
  `version.m`, workflow specs, state factories, input policies, test APIs,
  framework adapters, and action-driven side-effect boundaries
- a new app entry point appears without dedicated GUI coverage
- hidden workflow validation needs a new app-neutral driver operation or
  app-owned test hook to avoid OS/modal dialogs
- current JUnit timing or profiler evidence identifies a new test-performance
  hotspot whose fix would change runner behavior, validation policy, or
  app/workflow coverage
- migration exposes package-boundary drift that cannot be fixed locally
  without a new `+labkit` API decision

## Retired Route: Declarative App Runtime

Status: retired on 2026-07-03. The migration is complete in source,
guardrails, docs, and profiler/debug evidence. Reopen only from the triggers
above, not from this historical route.

The final app unit is a plain MATLAB definition struct consumed by
`labkit.ui.app.run`. App entrypoints remain thin public wrappers around
version/requirement checks, debug dispatch, and
`labkit.ui.app.run(<slug>.definition(), request)`.

The retained runtime contract is:

```text
definition -> validate -> create state -> build spec -> create shell
  -> render -> startup actions -> hydration actions -> steady interaction
```

Framework-owned responsibilities now live in `+labkit/+ui/+app`: definition
validation, callback generation, shell construction, readiness/busy state,
startup and hydration dispatch, debug exception reporting, phase timings, and
small test-visible effects. App-owned responsibilities stay under workflow
packages such as `+sourceFiles`, `+analysisRun`, `+cropGeometry`,
`+thermalFrames`, `+debugArtifacts`, and `+resultFiles`.

The completed migration used mature UI/runtime constraints as design pressure:
activation should be staged rather than eager; framework lifecycle and
app-specific workflow should have a clear ownership boundary; readiness and
fallback UI should be explicit framework concepts; state should be stable data
rendered by update code; callbacks and startup phases should dispatch named
actions; and the app shape should stay convention-first without generator or
class-hierarchy overhead.

Do not restore package-root eager runners, `+ui/runApp.m` lifecycle adapters,
or broad technical app buckets such as `+actions`, `+state`, `+ui`, `+view`,
`+ops`, `+io`, and `+export`. Current tests and guardrails own that contract.

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
