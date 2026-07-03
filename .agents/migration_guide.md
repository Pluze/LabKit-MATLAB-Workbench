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

## Active Route: Declarative App Runtime

Status: design-first route in progress. Opened 2026-07-02 after launcher/app
startup traces showed blank app frames and delayed first render across multiple
apps; revised 2026-07-03 to make the fix a breaking framework/runtime
migration, not an app-local loading-indicator patch.

Current work order:

1. Finish this design route and commit it alone.
2. Update human docs, scoped agent rules, and app-builder guidance so all
   written contracts describe the same target.
3. Then implement framework/runtime code and migrate apps in small commits.
4. Defer CI polling until merge readiness; use local validation only when the
   touched source phase needs it.

### Architectural Diagnosis

LabKit currently has a declarative UI spec but not a declarative app runtime.
The practical shape is:

```text
launcher -> public app entrypoint -> package run.m
        -> run.m builds callbacks and state closures
        -> +ui/buildSpec.m declares controls with callback handles
        -> labkit.ui.app.create builds the workbench synchronously
        -> run.m binds tools, initializes state, writes debug samples,
           resets axes, refreshes plots, and performs first-render work
```

This mixes four responsibilities in package-root `run.m`: app definition,
state ownership, event dispatch, and startup scheduling. That worked as a
migration bridge, but it is the reason broad startup lag keeps reappearing.
Every app can accidentally put heavy work immediately after
`labkit.ui.app.create`, while the framework has no complete view of lifecycle,
readiness, first render, idle hydration, or safe callback gating.

The root problem is not that individual apps forgot to show a loading message.
The root problem is that app authors are asked to orchestrate framework-level
behavior by hand. The new architecture must move these behaviors into
`labkit.ui.app` and make app code mostly declarative.

### External Design Inputs

Use mature toolkit patterns as constraints on the design, not as an instruction
to change languages or rebuild LabKit around another stack:

- VS Code activates extensions from declared events such as command, view,
  language, custom editor, and startup-finished. Its startup `*` event is
  explicitly discouraged for user experience unless no narrower event works.
  LabKit should make expensive capability activation event-driven instead of
  eager-by-default. Source:
  https://code.visualstudio.com/api/references/activation-events.
- VS Code also separates extension code into an extension host, preserving a
  boundary between workbench runtime and extension behavior. LabKit should
  mirror the ownership boundary inside MATLAB: framework runtime schedules and
  guards app behavior, while app definitions describe behavior. Source:
  https://code.visualstudio.com/api/advanced-topics/extension-host.
- Angular `@defer` declares UI blocks whose loading can be triggered by idle,
  viewport, interaction, immediate, hover, or timer events with placeholder and
  loading states. LabKit should use the same idea for tabs, tools, previews,
  and debug artifact work. Source: https://angular.dev/guide/templates/defer.
- React `Suspense` makes readiness and fallback rendering explicit at a
  boundary. LabKit should make first-render readiness a framework-owned
  boundary, not an app-owned convention. Source:
  https://react.dev/reference/react/Suspense.
- React's state model ties state to positions in the UI tree. LabKit should
  preserve app state across staged hydration and avoid rebuilding state as an
  accidental side effect of UI reconfiguration. Source:
  https://react.dev/learn/preserving-and-resetting-state.
- Qt Quick `Loader` separates declared component identity from active
  instantiation. LabKit should adopt the activation concept while respecting
  MATLAB handle semantics: inactive regions may have framework placeholders,
  but app code should not hold fake MATLAB handles. Source:
  https://doc.qt.io/qt-6/qml-qtquick-loader.html.
- Flutter separates widgets, elements, render objects, layout, painting, and
  semantics. LabKit should keep app definition, runtime state, control
  construction, rendering, diagnostics, and effects as distinct layers rather
  than one large runner file. Source:
  https://docs.flutter.dev/resources/architectural-overview.
- Android's UI layer recommends UI state as the observable description of what
  the UI should render, with state holders mediating app data and UI. LabKit
  should make app state explicit and render from state through framework
  dispatch. Source: https://developer.android.com/topic/architecture/ui-layer.
- Redux and Elm Architecture use unidirectional flow: state/model, view,
  event/update. LabKit should absorb that principle without cloning their APIs:
  callbacks and startup phases dispatch named actions, actions update state,
  and rendering observes state. Sources:
  https://redux.js.org/tutorials/fundamentals/part-2-concepts-data-flow and
  https://guide.elm-lang.org/architecture/.

The design principle for LabKit is:

```text
apps declare intent; the framework owns lifecycle, dispatch, readiness,
busy state, staged activation, diagnostics, and safe effects
```

### Target Paradigm

The future app unit is an app definition, not a hand-written runner. The
definition is a plain MATLAB struct returned by app-owned code and consumed by
`labkit.ui.app.run`:

```matlab
function def = definition()
def = labkit.ui.app.define( ...
    "Id", "batch_crop", ...
    "Title", "Microscope Batch Image Crop", ...
    "InitialState", @batch_crop.state.initial, ...
    "Spec", @batch_crop.ui.buildSpec, ...
    "Actions", batch_crop.actions.table(), ...
    "Render", @batch_crop.view.render, ...
    "Startup", ["workspace", "preview"], ...
    "Hydrate", ["tools", "debugArtifacts"]);
end
```

App entrypoints become thin dispatch wrappers:

```matlab
function fig = labkit_BatchImageCrop_app(varargin)
request = labkit.ui.app.parseRequest(varargin{:});
fig = labkit.ui.app.dispatchRequest(request, ...
    "Requirements", @batch_crop.requirements, ...
    "Version", @batch_crop.version, ...
    "Run", @() labkit.ui.app.run(batch_crop.definition(), request));
end
```

This is intentionally a domain-specific language at MATLAB scale. It should be
plain structs and function handles, not MATLAB classes, generated code, or a
new language runtime. App authors declare:

- identity and version metadata
- initial state factory
- data-only UI spec builder
- action table
- render function
- optional startup and hydration phase names
- app-owned IO/ops/export functions called by actions

App authors do not declare or call:

- startup timers
- loading status controls
- callback wrappers
- busy flags
- figure appdata keys
- debug exception plumbing
- first-render completion
- hidden/minimized test behavior
- profiler/browser wakeup behavior

### Framework Runtime Contract

`labkit.ui.app.run(definition, request)` owns the runtime state machine:

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
- create the shell, status/readiness boundary, controls registry, diagnostics,
  close guard, and appdata registry
- generate callback closures from action ids and route all user events through
  one dispatcher
- gate actions while startup is pending, with documented exceptions for close
  and cancellation
- run startup phases after the shell has had a paint opportunity
- maintain a non-modal readiness surface that avoids flicker for fast starts
  and remains visible for slow starts
- run idle hydration for nonessential work such as inactive tabs, expensive
  tools, and debug artifact creation when tests do not require it earlier
- report startup/action exceptions through the debug context without modal
  browser or profiler surprises
- expose traceable phase timings for performance diagnosis

App-owned responsibilities:

- define state shape and defaults
- define user-facing labels, choices, units, formulas, plots, exports, and
  workflow decisions
- implement pure or side-effecting app operations in role packages such as
  `+state`, `+io`, `+ops`, `+view`, and `+export`
- provide render functions that translate prepared state into existing handles
- provide actions that return updated state and requested framework effects

### State, Actions, Render, Effects

The target flow is unidirectional:

```text
event/startup phase
  -> framework dispatch(actionId, payload)
  -> app action(state, payload, services)
  -> next state + effects
  -> framework applies effects
  -> app render(next state, ui, services)
```

Actions are named app-owned functions or table entries. They may request
effects; they should not directly schedule framework lifecycle behavior. The
initial effect set should stay small and MATLAB-friendly:

- `setBusy(message)`
- `clearBusy()`
- `alert(kind, message)`
- `chooseFile`, `chooseFolder`, and save prompts through existing LabKit
  dialog adapters
- `logDebug(message)`
- `requestRender(region)`
- `runLater(phaseName)` for framework-approved idle hydration

The framework may implement these with structs, not classes. The important
contract is that effects are visible to tests and guardrails; app callbacks do
not reach behind the framework to mutate readiness or timers.

### Staged UI And Activation

The first migration does not need true lazy MATLAB handle creation for every
control. It must, however, change ownership:

- visible shell and status surface appear before expensive app startup work
- first visible workspace region is rendered before nonessential hydration
- inactive tabs and optional tools may be hydrated on first tab selection or
  idle when the app definition marks them as deferred
- debug sample/artifact work is idle by default unless a test or app contract
  requires the artifact before first interaction
- profiler automation does not open browser UI unless the caller explicitly
  requests it

Later phases may add true lazy tab construction behind the same definition
contract. App definitions must not depend on synchronous access to every
inactive handle.

### Target Source Shape

The desired app package shape after migration is:

```text
apps/<family>/<app_slug>/labkit_<AppName>_app.m
apps/<family>/<app_slug>/+<app_slug>/definition.m
apps/<family>/<app_slug>/+<app_slug>/requirements.m
apps/<family>/<app_slug>/+<app_slug>/version.m
apps/<family>/<app_slug>/+<app_slug>/+state/initial.m
apps/<family>/<app_slug>/+<app_slug>/+actions/table.m
apps/<family>/<app_slug>/+<app_slug>/+actions/<actionName>.m
apps/<family>/<app_slug>/+<app_slug>/+ui/buildSpec.m
apps/<family>/<app_slug>/+<app_slug>/+view/render.m
apps/<family>/<app_slug>/+<app_slug>/+io/...
apps/<family>/<app_slug>/+<app_slug>/+ops/...
apps/<family>/<app_slug>/+<app_slug>/+export/...
```

Only create role packages the app actually needs. Do not introduce generic
`+helpers`, `+utils`, `+manager`, or fixed `+app` packages.

Package-root `run.m` is transitional debt. During migration it may bridge old
code into `definition.m`; after each app is migrated it should be removed or
reduced to a temporary compatibility shim called only by tests that have not
yet moved. The final target is that app entrypoints launch definitions through
the framework runtime directly.

### Breaking Cleanup Policy

This is allowed to be a breaking internal app-structure migration, but it must
not casually break public LabKit behavior:

- public app entrypoint names remain stable
- launcher discovery remains source-based through `apps/**/labkit_*_app.m`
- app workflow outputs, formulas, plots, export schemas, labels, and default
  settings remain app-owned and behavior-compatible unless separately approved
- old framework-private helper shapes may be deleted after all real app paths
  migrate
- old package-root runner orchestration should not be preserved as permanent
  compatibility debt
- guardrails should reject new eager runners once the new path is available

### Required Workstreams

1. Design route
   - Keep this active route aligned with current decisions before each phase.
   - Search or inspect mainstream framework patterns again when a design choice
     is uncertain, instead of relying only on local preference.
   - Commit the route update separately from code.

2. Documentation and authoring contracts
   - Update `docs/ui.md` with the runtime, readiness boundary, staged
     activation, diagnostics, and hidden/minimized behavior.
   - Update `docs/apps.md` with the new app definition shape, app package
     layout, state/action/render/effect flow, and migration examples.
   - Update `+labkit/AGENTS.md` and `apps/AGENTS.md` so future work cannot add
     app-local lifecycle scheduling or new eager runners.
   - Update `labkit-app-builder` so new apps start from `definition.m`, not
     package-root `run.m`.
   - Keep docs human-readable; agent execution rules stay in AGENTS/skills.

3. Framework runtime foundation
   - Add `labkit.ui.app.define` and `labkit.ui.app.run` as the app-facing
     public surface.
   - Keep lifecycle/readiness implementation private under
     `+labkit/+ui/+app/private`.
   - Move generated callbacks, action dispatch, startup gating, readiness
     state, idle hydration, debug exception reporting, and phase timing into
     the framework runtime.
   - Make hidden/minimized GUI tests visually quiet while preserving runtime
     readiness state.

4. Compatibility bridge
   - Keep `labkit.ui.app.create` only as legacy/compatibility surface during
     migration.
   - Provide a bridge so one app can migrate at a time without breaking
     launcher discovery or debug launch.
   - Do not expose `deferStartup`, `updateStartup`, or `finishStartup` as
     public APIs for app code; lifecycle is internal to the runtime.

5. App migration
   - Migrate all supported apps from package-root runner orchestration to
     app definitions.
   - Start with Batch Image Crop, FLIR Thermal, Curvature Measurement, and VT
     Resistance because traces showed slow first-render behavior there.
   - Then migrate the remaining supported apps by family, preserving outputs
     and workflow behavior.
   - Remove obsolete runner code after each migrated app has behavior coverage
     through the new path.

6. Guardrails and tests
   - Add definition validation tests for required fields, action ids, duplicate
     controls, startup phases, hidden-mode behavior, and exception reporting.
   - Update public surface tests for the new `define`/`run` API.
   - Update app-structure guardrails so new apps must provide `definition.m`
     and cannot add package-root eager `run.m` orchestration.
   - Add source guardrails for direct startup timer/readiness manipulation in
     app packages after the new runtime lands.

7. Evidence and merge readiness
   - Run focused local validation after executable changes.
   - Capture phase timings or trace evidence for at least two previously slow
     apps and one ordinary app.
   - Inspect CI only when the branch is ready to merge, per `AGENTS.md`.

### Small-Commit Discipline

Use small commits in this order unless a verified dependency forces a split:

1. `docs:` design route only.
2. `docs:` human docs, AGENTS, and app-builder guidance.
3. `feat:` framework definition/runtime skeleton plus tests.
4. `refactor:` first representative app migration.
5. `refactor:` remaining app-family migrations.
6. `test:` guardrails and validation expansion that depends on migrated code.
7. `perf:` measured startup improvements only if the commit's primary effect
   is lower user-visible latency.

Each commit message must use exactly one approved lowercase Conventional
Commit prefix from `AGENTS.md`.

### Non-Goals

- Do not migrate LabKit apps to web, Python, JavaScript, App Designer, or a
  different GUI toolkit.
- Do not create a monolithic app host that hides individual app entrypoints.
- Do not move app formulas, thresholds, plots, exports, workflow wording, or
  result schemas into `+labkit`.
- Do not introduce MATLAB classes for the runtime model.
- Do not expose raw timers, loading indicators, readiness flags, or lifecycle
  mutation APIs to app code.
- Do not add a generator before the definition DSL is proven by migrated apps.

### Validation Gates

- Design-only and docs-only commits do not require MATLAB validation.
- After framework runtime source changes: run the changed-file local plan,
  normally `matlab -batch "buildtool changed"`.
- Before merging implementation: run the source-aligned GUI/framework task
  selected from `docs/testing.md`, plus profile/trace evidence for the slow
  startup path.
- CI inspection is deferred until merge readiness according to `AGENTS.md`.

### Completion Criteria

- Every supported app launches through a framework-owned app definition.
- Package-root eager runner orchestration is removed or reduced to temporary
  compatibility shims with tracked retirement criteria.
- The framework owns lifecycle, generated callbacks, busy gating, readiness,
  staged startup, idle hydration, diagnostics, and startup phase timing.
- App packages only declare identity, state, spec, actions, render behavior,
  and app-owned IO/ops/export behavior.
- New docs, AGENTS rules, app-builder guidance, tests, and guardrails all
  describe the same architecture.
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

A healthy app definition declares orchestration only. App-owned helpers own
deterministic or explicitly side-effecting app behavior. Reusable framework
helpers own app-neutral mechanics that multiple apps share.

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
