# Agent Migration Ledger

This is the agent-facing migration debt ledger for LabKit. It is not an
architecture manual, validation matrix, historical changelog, or general
roadmap.

Human-facing architecture and app behavior live in `docs/`. Exact validation
commands live in `docs/testing.md` and are routed through
`labkit-test-planner`. This ledger owns active migration debt facts, retirement
rules, and executable migration routes.

## How To Use This File

Use this file when working on migration debt, runner complexity, helper
structure, app workflow validation, app-owned package cleanup, or framework
hook extraction. A capable agent should be able to continue an active route
from this file without asking for a new plan.

Before executing a route:

1. Verify the current facts with source scans. Do not trust this snapshot if
   files have changed.
2. Preserve app-first ownership: app workflow stays in apps; reusable mechanics
   move to `+labkit` only when the boundary test is clearly met.
3. Prefer behavior-backed refactors. A line-count drop is not progress unless
   responsibilities become clearer and the real GUI or app path calls the
   extracted helper.
4. Update this file only when migration debt is added, reduced, retired, or
   reprioritized.

When a route completes, shrink this file again. Completed work should become
source, tests, docs, or guardrails, not permanent roadmap prose.

## Current Debt Snapshot

Last audited: 2026-07-02.

Current active migration debt:

```text
LabKit front/back staged startup route
```

Current facts:

- MATLAB source inventory from current working-tree files:
  - total: 767 `.m` files, 66,325 lines across `apps/`, `+labkit/`, and `tests/`
  - `apps/`: 430 files, 28,455 lines, max 649 lines
  - `+labkit/`: 206 files, 18,878 lines, max 649 lines
  - `tests/`: 131 files, 18,992 lines, max 649 lines
  - `labkit_launcher.m`: 1,700 lines and intentionally exempt
- Tracked files over the 650-line repository file budget:
  `labkit_launcher.m` only, by design, because it is the self-contained repair
  entry point.
- Package-root app `run.m` files currently remain within budget. Budget
  watchlist files are:
  - `apps/image_measurement/batch_crop/+batch_crop/run.m` at 649 lines
  - `apps/image_measurement/flir_thermal/+flir_thermal/run.m` at 648 lines
  - `apps/neurophysiology/rhs_preview/+rhs_preview/run.m` at 648 lines
  - `apps/image_measurement/image_enhance/+image_enhance/run.m` at 642 lines
  - `apps/image_measurement/image_match/+image_match/run.m` at 563 lines
  These are not active migration debt by line count alone. They are
  change-control triggers: do not add unrelated behavior to them without a
  responsibility audit or a cohesive app-owned extraction.
- `+labkit` implementation hotspots near the file budget are:
  - `+labkit/+ui/+diag/createContext.m` at 649 lines
  - `+labkit/+ui/+tool/createRuntime.m` at 636 lines
  - `+labkit/+biosignal/private/detectEcgPeaksImpl.m` at 623 lines
  - `+labkit/+ui/+app/private/buildFilePanelControl.m` at 607 lines
  - `+labkit/+ui/+app/private/buildControl.m` at 539 lines
- Debug sample packs are complete and no longer an active migration route:
  each supported app owns its generator under the app tree, debug launch writes
  clean-room samples/manifests under `artifacts/debug/.../<SessionId>/`, and
  debug startup remains otherwise empty.
- Helper-quality audit is a dry-run routing aid, not a blocking guardrail:
  use `labkitHelperQualityAudit(root, "MaxLines", 20, "Scope", "all")` to
  identify new tiny-helper review candidates when related code is touched.
  Preserve legitimate small contracts such as public facades, state factories,
  input policies, export/dialog side effects, UI adapters, test APIs,
  framework adapters, and tested multi-call helpers.
- Current app `private/` debt, `+labkit` private helper contract debt, and
  string-dispatch/core-router migration debt are all clear.
- Supported app entry points launch through `labkit.ui.app.create` directly or
  app-owned package-root `run.m` orchestration. App specs stay in
  `+<app_slug>/+ui/buildSpec.m`; production behavior should route through
  role-based app-owned component packages, not generic helper buckets.
- Shared mechanics already owned by `+labkit` include the layered
  `labkit.ui.app/spec/view/tool/diag` surface, image facade primitives,
  file-entry path/index helpers, output prompts, hidden-test-safe alerts,
  debug exception reporting, and close guards. App-specific formulas,
  workflow wording, task snapshots, plotting, and export schemas stay app-owned.
- GUI workflow coverage is now real-workflow-first. `AppLaunchGuiTest` is a
  missing-coverage guardrail; do not re-expand structural GUI tests with
  launch-only assertions already covered by workflow tests or shared debug
  tests.
- Test performance profiling on 2026-07-02 showed two actionable timing
  layers: fixed GUI waits and repeated runner path scans. Current test
  contracts now route GUI debounce/layout settling through GUI idle helpers,
  keep runner path setup to one MATLAB path read per configuration pass, and
  report JUnit slow-test plus shard estimates through
  `scripts/summarize_junit.py`.
- App startup profiling and debug traces on 2026-07-02 exposed a separate
  user-facing startup debt: launcher double-click can produce a blank visible
  app frame while shared `labkit.ui.app.create`, app-owned runner
  initialization, tool attachment, and initial axes rendering continue on the
  MATLAB UI thread. The problem is broad across apps, not FLIR-specific.
- Current app runners assume `labkit.ui.app.create` synchronously returns a
  complete `ui.controls` registry. Any staged-startup migration must preserve
  that app-facing contract until each runner has moved to explicit lifecycle
  hooks or readiness handles.

## Reopen Triggers

Open a new active route here only when current scans expose concrete debt:

- an app `run.m` exceeds the 650-line hard budget, or a substantive change
  would add unrelated behavior to a budget-watchlist runner without a
  responsibility audit
- `labkitHelperQualityAudit(root, "MaxLines", 20)` reports new
  `inline-or-merge-candidate` rows after excluding valid contracts such as
  app entrypoints, `requirements.m`, `version.m`, `+ui/buildSpec.m`, state
  factories, input policies, test APIs, framework adapters, and
  `+export/write*.m` side-effect boundaries
- a new app entry point appears without dedicated GUI coverage, causing the
  `AppLaunchGuiTest` coverage guardrail to fail
- hidden workflow validation needs a new app-neutral driver operation or a new
  app-owned test hook to avoid a blocking OS/modal dialog
- current JUnit timing or profiler evidence identifies a new test-performance
  hotspot whose fix would change runner behavior, validation policy, or
  app/workflow coverage
- a migration exposes package-boundary drift that cannot be fixed locally
  without a new `+labkit` API decision

## Active Route: Front/Back Staged App Startup

Status: planned. Opened 2026-07-02 after launcher/app startup traces showed
blank app frames and delayed first render across multiple apps.

### External Models To Borrow

Do not invent a LabKit-only startup architecture from scratch. Use these
established GUI/frontend patterns as constraints, adapting them to MATLAB's
single UI thread and existing app runner contract:

- React `lazy` plus `Suspense`: defer component code until first render and
  keep a fallback boundary visible while the deferred component is unresolved.
  LabKit equivalent: build the visible workbench shell and a readiness surface
  before expensive controls/tools/plots are ready, then resolve sections as
  their handles exist.
  Source: https://react.dev/reference/react/lazy and
  https://react.dev/reference/react/Suspense.
- Angular `@defer`: load deferred blocks on idle, viewport, interaction,
  immediate-after-render, or timer triggers, with placeholder/loading states.
  LabKit equivalent: use first-visible-tab, user interaction, and idle/timer
  scheduling to decide which tab sections and tool panels are built first.
  Source: https://angular.dev/guide/templates/defer.
- VS Code activation events: activate expensive extensions after startup or
  only when a command/view/language requires them. LabKit equivalent: app
  tools, debug instrumentation, sample discovery, and non-visible tab widgets
  should not all activate before the first usable window.
  Source: https://code.visualstudio.com/api/references/activation-events.
- Qt Quick `Loader`: keep a component inactive so changing its source does not
  instantiate it until activation. LabKit equivalent: represent inactive tabs
  or tool hosts as placeholders with declared specs and delayed real MATLAB
  handle construction.
  Source: https://doc.qt.io/qt-6/qml-qtquick-loader.html.

### Objective

Make LabKit app launch feel immediate and deterministic across all supported
apps by splitting startup into:

1. shell-first frontend creation
2. staged control/tool/view construction
3. app-owned backend state initialization
4. first-render completion
5. idle or interaction-triggered hydration of nonessential UI

This route is about responsiveness and lifecycle shape, not hiding slow work
behind a modal spinner. The user should see a named app window with stable
loading/readiness state quickly, then see controls and initial preview become
ready in predictable phases.

### Current Facts To Preserve

- Public app entrypoint names and debug launch requests remain unchanged.
- App UI specs remain data-only under `+<app_slug>/+ui/buildSpec.m`.
- App-specific formulas, plots, workflow order, exports, alerts, and log text
  remain app-owned.
- `labkit.ui.app.create` is the current shared creation API and all supported
  app runners call it synchronously.
- App runners currently mutate `ui.controls.*`, attach tools, initialize app
  state, and often draw/reset axes immediately after `create` returns.
- Hidden/minimized GUI test modes must stay non-disruptive and must not open
  modal progress UI that blocks CI.
- Debug traces and profile artifacts are the evidence source for perceived
  startup gaps. Do not claim a phase is fixed without trace/profile evidence
  from at least one representative slow app and one ordinary app.

### Target Shape

Introduce a framework-owned lifecycle model under `labkit.ui.app`:

- `createShell` or an equivalent private stage builds the titled, visible
  workbench frame, selected tab container, workspace frame, and startup status
  surface before heavyweight child controls are built.
- `create` remains available during migration, but internally delegates to the
  staged lifecycle so existing apps keep launching.
- A startup session object tracks phases such as `shell`, `visibleControls`,
  `workspace`, `appInit`, `firstRender`, and `idleHydration`.
- A deferred task queue runs MATLAB UI work in small chunks through timer or
  drawnow-safe scheduling so the event loop can paint between chunks.
- Loading state has both delayed-show and minimum-visible behavior: it should
  not flash for fast apps, but once shown it must persist until the initial
  app-owned render and frontend paint boundary have completed.
- Non-visible control tabs and optional composed tools can be represented by
  placeholders first, then hydrated on first selection or idle timeout.
- A compatibility registry either returns real handles for eagerly built
  controls or explicit readiness/proxy records for deferred controls. Do not
  silently return empty handles to existing app code.
- App runners move backend work behind explicit lifecycle hooks, for example
  `onStartup`, `onFirstRender`, `onIdleHydrate`, or app-owned functions passed
  to a framework scheduler. Exact names are implementation details; the
  contract must be documented and tested.

### Required Workstreams

1. Baseline and measurement
   - Re-run launcher/app startup profiling with current `main` on at least:
     `labkit_BatchImageCrop_app`, `labkit_FLIRThermal_app`,
     `labkit_CurvatureMeasurement_app`, and one smaller electrochem app.
   - Record phase timings for launcher dispatch, public entrypoint,
     `labkit.ui.app.create`, tab/control build, workspace build, runner
     initialization, tool attachment, first axes reset/draw, debug
     instrumentation, manifest write, and first user-visible readiness.
   - Add or extend noninteractive trace vocabulary only if existing traces
     cannot distinguish these phases.

2. Framework lifecycle and status surface
   - Add the internal staged startup session and status surface under
     `+labkit/+ui/+app` with hidden-test-safe behavior.
   - Keep app-facing public API growth minimal and documented immediately
     after the function declarations when new public functions are added.
   - Replace ad hoc progress-dialog experiments with a framework lifecycle
     state that can be rendered in the shell or title/status area without
     blocking normal app creation.

3. Shell-first and visible-first construction
   - Ensure the app name, figure frame, selected tab host, workspace host, and
     startup state can paint before all controls are constructed.
   - Build the initially selected control tab and primary workspace first.
   - Defer inactive tabs, heavy file panels, composed tools, debug
     instrumentation, or nonessential status panels only after compatibility
     checks prove the runner does not immediately need those handles.

4. App backend lifecycle migration
   - Convert representative slow runners first, then fan out:
     Batch Image Crop, FLIR Thermal, Curvature Measurement, VT Resistance.
   - Move app-owned initial preview, reset axes, scale-bar/tool setup,
     sample/debug manifest operations, and expensive state preparation into
     explicit startup phases.
   - Preserve app-owned workflow results and visible controls. This is not a
     rewrite of scientific logic or app UX.

5. Lazy hydration and interaction readiness
   - Hydrate inactive tabs on first tab selection and optionally after an idle
     timeout when MATLAB is responsive.
   - Gate user actions until required controls and app state are ready, with a
     clear status message instead of a blank or partially interactive frame.
   - Avoid disabling the whole app longer than necessary. First visible
     controls should become usable as soon as their backend dependencies are
     ready.

6. Tests, profiling, and documentation
   - Add framework tests for startup session state, deferred task ordering,
     hidden/minimized behavior, delayed-show/minimum-visible loading rules,
     and compatibility with synchronous `labkit.ui.app.create`.
   - Add representative GUI workflow tests that prove app runners use the
     staged path without losing debug traces or first-render readiness.
   - Update `docs/ui.md`, `docs/apps.md`, scoped `AGENTS.md`, and this ledger
     only where the public lifecycle contract or agent routing changes.
   - Keep profile summaries and AGENT_SUMMARY artifacts for before/after
     evidence.

### Non-Goals

- Do not migrate LabKit apps to web, Python, JavaScript, App Designer, or a
  different GUI toolkit.
- Do not merge separate app entrypoints into one monolithic app.
- Do not move app formulas, plots, exports, workflow wording, or result schemas
  into `+labkit`.
- Do not make modal progress dialogs the primary solution.
- Do not lazy-build a control whose handle is required synchronously without
  first changing that runner to a readiness-aware contract.
- Do not force all apps into one large runner abstraction. Migrate common
  lifecycle mechanics into `+labkit`, while app orchestration stays app-owned.

### Validation Gates

- Focused framework checks after lifecycle API changes:
  `matlab -batch "buildtool changed"`.
- Broader GUI coverage before merging a staged-startup implementation:
  `matlab -batch "buildtool testGuiStructural"` and the source-aligned
  changed-file task selected by `buildtool changed`.
- Profile evidence must include before/after phase timings from at least two
  slow apps and one smaller app.
- Manual MATLAB GUI review is required for perceived startup feel because CI
  cannot judge blank-frame duration or loading-state polish.
- CI on the pushed branch must pass before merge.

### Blockers

- MATLAB timer/drawnow scheduling may not interrupt some native UI creation
  calls. If a build chunk blocks the UI thread until native construction
  returns, record the exact function and keep that chunk eager or redesign the
  surrounding placeholder.
- Existing runners may synchronously require handles from inactive tabs. Treat
  this as a runner migration task, not as permission to return invalid handles.
- Loading-state polish depends on real frontend paint timing. Use trace/profile
  evidence plus manual GUI observation; do not rely only on code inspection.

### Completion Criteria

- A supported app can open from the launcher into a visible, named,
  non-blank shell quickly, with clear readiness state through first render.
- Representative slow apps show reduced blank-frame duration and lower or
  better-distributed startup phase timing in profile artifacts.
- Existing app entrypoints, debug launch, launcher open flow, and workflow
  outputs remain compatible.
- Startup lifecycle contracts are documented in the owning docs and scoped
  AGENTS files.
- New tests cover framework lifecycle behavior and representative app runner
  migration.
- This active route is removed or shrunk to residual debt once the migration
  lands.

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

A healthy runner owns orchestration only. App-owned helpers own deterministic
or explicitly side-effecting app behavior. Reusable framework helpers own
app-neutral mechanics that multiple apps share.

Migration progress means:

- a responsibility boundary becomes clearer
- deterministic behavior becomes directly testable
- the real GUI or app path uses the extracted helper
- duplicate app-neutral mechanics are removed from apps
- the total cognitive load of the workflow falls

Use large-project governance principles when judging helper organization:

- Optimize for future readers and maintainers. A new file must make the
  workflow easier to understand at the call site, not merely shorter.
- Review complexity at multiple levels: expression, function, file, package,
  and public facade. File length is a backstop; nesting, local state, coupling,
  side effects, and unclear ownership are stronger extraction signals.
- Keep private interfaces private. App-owned implementation helpers stay under
  role packages, framework-private helpers stay under facade `private/`
  folders, and test-only helpers stay under `tests/`.
- Prefer locally consistent, tool-checkable rules over personal taste. If the
  rule cannot be audited with low false-positive risk, keep it as guidance and
  a dry-run report.

Migration is not progress when it only:

- moves a large block into another large file
- turns one obvious line into a one-line helper
- hides app-specific workflow behind a generic name
- adds guardrails that are noisier than the drift they prevent
- adds docs without retiring stale debt or clarifying an active contract

## Future Debt Rules

- If guardrails detect new migration debt, update this ledger and the affected
  source or tests together.
- If debt inventory is empty, prefer shrinking this ledger over adding roadmap
  prose, scripts, or new governance layers.
- Keep completed migrations as historical baselines only when they clarify a
  current guardrail invariant.
- Treat line-count budgets as backstops, not design goals.
- Do not add a minimum-line-count guardrail. Use the helper audit's boundary
  class, call count, test references, and review reason to distinguish cosmetic
  extraction from legitimate small contracts.
- Do not split a runner or long implementation file merely to lower its line
  count. Extract only a cohesive behavior contract whose name, tests, and real
  GUI/app call path make the new file independently meaningful.
- Use `labkit-boundary-guard` before promoting behavior to `+labkit`.
- Use `labkit-test-planner` for validation routing and `docs/testing.md` for
  exact commands.
