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

Last audited: 2026-06-30.

Current active migration debt:

```text
runner complexity and helper quality migration
GUI workflow acceptance validation migration
```

Current facts:

- MATLAB source inventory from tracked files:
  - total: 696 `.m` files, 58,443 lines
  - `apps/`: 405 files, 23,817 lines, max 646 lines
  - `+labkit/`: 174 files, 16,469 lines, max 647 lines
  - `tests/`: 114 files, 15,880 lines, max 649 lines
  - `labkit_launcher.m`: 1,722 lines and intentionally exempt
- Tracked files over the 650-line repository file budget:
  `labkit_launcher.m` only, by design, because it is the self-contained repair
  entry point.
- Package-root app `run.m` files currently range from 220 to 646 lines.
  Hotspots are:
  - `apps/image_measurement/batch_crop/+batch_crop/run.m` at 646 lines
  - `apps/image_measurement/image_enhance/+image_enhance/run.m` at 643 lines
  - `apps/neurophysiology/rhs_preview/+rhs_preview/run.m` at 614 lines
  - `apps/image_measurement/image_match/+image_match/run.m` at 551 lines
  - `apps/image_measurement/curvature/+curvature/run.m` at 525 lines
  - `apps/dic/dic_preprocess/+dic_preprocess/run.m` at 522 lines
  - `apps/electrochem/vt_resistance/+vt_resistance/run.m` at 502 lines
- `+labkit` implementation hotspots near the file budget are:
  - `+labkit/+ui/+app/private/buildFilePanelControl.m` at 647 lines
  - `+labkit/+ui/+app/private/buildControl.m` at 643 lines
  - `+labkit/+ui/+tool/createRuntime.m` at 636 lines
  - `+labkit/+ui/+diag/createContext.m` at 628 lines
  - `+labkit/+biosignal/private/detectEcgPeaksImpl.m` at 623 lines
- Short app helper inventory, excluding app entrypoints, `requirements.m`,
  `version.m`, package-root `run.m`, and `+ui/buildSpec.m`:
  - 55 app helpers are 1-10 lines
  - 97 app helpers are 11-20 lines
  - 79 app helpers are 21-40 lines
  - many short files are useful role contracts, but some are likely cosmetic
    extraction created by line-budget pressure.
- Repeated micro-helper families to audit before adding more helpers include
  `ternary.m`, `onOff.m`, `supportedImageExtensions.m`, `imageDialogFilter.m`,
  one-off `optionValue`, `fieldOrDefault`, `numericScalar`, small display-name
  helpers, and tiny pass-through wrappers.
- `tests/runner/labkitHelperQualityAudit.m` provides the Route A dry-run
  helper audit. It reports short helper file length, role package, function
  count, approximate call count, public/private status, direct unit-test
  references, allowed exception class, and a non-blocking recommendation.
- First audit-driven cleanup: `image_enhance.state.stepsForTask` and
  `image_enhance.state.itemStepsForExport` were merged into the existing
  export-task state contract instead of being inlined into the near-limit
  runner.
- Second audit-driven cleanup: Batch Crop scale readiness/count micro helpers
  were merged into `batch_crop.state.scaleCalibrationSummary`, keeping the
  reusable `isScaleCalibrationSet` predicate while replacing two one-purpose
  loops with one tested state-summary contract.
- Dense non-image cleanup prototype: RHS Preview indexed-duration and preview
  timing micro helpers were merged into `rhs_preview.ops.previewWindowBounds`,
  leaving clamping and summary-format helpers as behavior-specific contracts.
- App `private/` debt: none.
- `+labkit` private helper contract debt: none.
- String-dispatch workflow adapters and app `+core/dispatch.m` routers: none.
- No active runner maps exist.
- Supported app entry points launch through `labkit.ui.app.create` directly or
  through app-owned package-root `run.m` orchestration.
- Apps keep ordinary data-only specs in
  `+<app_slug>/+ui/buildSpec.m`, route extracted production code through
  role-based app-owned component packages, and avoid generic helper buckets.
- The public app-facing UI surface is the layered
  `labkit.ui.app/spec/view/tool/diag` foundation documented in `docs/ui.md`.
- File-entry path and item-index extraction are framework view helpers:
  apps use `labkit.ui.view.filePaths` and `labkit.ui.view.fileIndices`
  instead of parsing filePanel event structs locally.
- App-owned save dialogs that need safe output-file handling use
  `labkit.ui.app.promptOutputFile`; app-owned output-folder dialogs now use
  `labkit.ui.app.promptOutputFolder`.
- App-owned alerts use `labkit.ui.app.showAlert`, preserving normal modal
  behavior while recording and skipping the modal in hidden GUI test mode.
- Package-root app runners that catch `MException` and continue report through
  the framework debug context before alerts or recovery logs.
- Image workflow apps keep run/export/measurement task snapshots and
  deterministic fingerprints under app-owned `+state` helpers.
- Fingerprinted image export/run workflows currently wire dirty or incomplete
  fingerprint state to `labkit.ui.app.setCloseGuard`.
- `buildtool gui` already runs hidden noninteractive MATLAB GUI tests through
  the official runner and must remain the public broad GUI validation entry
  point.
- Current app GUI tests are mostly launch, layout, callback, and debug-trace
  checks; they do not yet consistently prove that each app can complete its
  core user task flow with synthetic inputs and exports.
- `tests/shared/labkitWorkflowDriver.m` provides the first app-neutral hidden
  GUI workflow helper for registry reads, filePanel injection, semantic control
  invocation, enabled-state reads, table reads, text-area reads, and filePanel
  state reads.
- `GuiLayoutEisTest` and `GuiLayoutFocusStackTest` have the first `Workflow`
  tagged representative app tests, covering one DTA/electrochem app and one
  image app with synthetic inputs.
- `GuiLayoutRhsPreviewTest` adds the first RHS/large-file representative
  workflow test, covering synthetic RHS indexing, automatic preview drawing,
  preview channel table population, and filter-file discovery.
- `GuiLayoutEcgPrintTest` covers wearable ECG workflow: synthetic CSV recording
  load, channel discovery, ROI analysis, summary-table refresh, and waveform,
  noise, SNR, and template plot redraw.
- `GuiLayoutDicPreprocessTest` covers DIC preprocess workflow: synthetic
  reference/moving image load, automatic alignment, false-color preview
  selection, summary/detail refresh, and preview redraw.
- `GuiLayoutDicPostprocessTest` covers DIC postprocess workflow: synthetic
  Ncorr MAT/reference/mask load, overlay generation, strain-summary table
  refresh, summary-text refresh, and EXX/EYY overlay redraw.
- `GuiLayoutBatchCropTest` covers a second image workflow shape: synthetic
  image load, center confirmation, default output-folder export, manifest
  creation, and crop-file creation.
- `GuiLayoutVtResistanceTest` covers another electrochem workflow shape:
  chrono fixture load, automatic resistance analysis, result-table refresh,
  summary-field refresh, and plot redraw.
- `GuiLayoutCicTest` covers CIC electrochem workflow: chrono fixture load,
  automatic charge/safety analysis, result-table refresh, summary-field
  refresh, and voltage/current plot redraw.
- `GuiLayoutChronoOverlayTest` covers multi-file chrono overlay workflow:
  fixture load, file-list refresh, voltage/current plot redraw, and X-axis
  unit switching.
- `GuiLayoutCscTest` covers CSC electrochem workflow: CV/CT fixture load,
  scan-rate and curve-choice refresh, automatic Q/CSC comparison readouts, and
  top/bottom plot redraw.
- `GuiLayoutImageEnhanceTest` covers image enhancement workflow: synthetic
  image load, default tool application, history-table refresh, default
  output-folder export, manifest creation, and enhanced-file creation.
- `GuiLayoutImageMatchTest` covers image reference-match workflow: synthetic
  reference/source image load, default reference-match application,
  history-table refresh, preview redraw, default output-folder export,
  manifest creation, and matched-file creation.
- `GuiLayoutCurvatureTest` covers curvature workflow: synthetic image load,
  active curve-editor point injection through the shared workflow driver,
  curvature fit, curve-length measurement, result-table/detail refresh, and
  image/overlay redraw.
- `GuiLayoutNerveResponseAnalysisTest` covers nerve-response workflow:
  synthetic filter-record JSON load, filtered analysis, missing-RHS issue
  reporting, summary/detail refresh, preview redraw, and JSON export.
- `GuiLayoutResponseReviewStatsTest` covers response-review workflow:
  synthetic segment CSV load, automatic metric calculation, summary/detail
  refresh, summary/aligned preview redraw, and metrics CSV export.
- Workflow-backed app structural GUI tests have been trimmed so ordinary table
  columns, preview axes, redraw paths, and clear/refresh callbacks are covered
  by real workflow tests instead of duplicate launch-only assertions.
- `AppLaunchGuiTest` is now a missing-coverage guardrail instead of broad app
  smoke coverage; supported app entry points must have dedicated GUI coverage.

## Active Route A: Runner Complexity And Helper Quality

Objective:

Replace line-count-driven extraction with responsibility-driven runner cleanup.
The goal is smaller, clearer `run.m` orchestration without proliferating tiny
files that exist only to satisfy the 650-line guardrail.

Target shape:

- Package-root `run.m` owns app lifecycle orchestration:
  launch/debug wiring, state coordination, callback adapters, user alerts, log
  wording, refresh order, dirty flags, small preview caches, and close-guard
  state.
- App-owned helpers own stable behavior contracts:
  deterministic state snapshots, IO normalization, file discovery, pure
  computation, export writers/manifests, view model data, and focused custom
  UI/tool glue.
- Helper files are extracted because they clarify a responsibility and can be
  tested or reused by the real app path, not because a file is close to a line
  limit.
- Existing tiny helper files are audited by call-site value. Some should stay
  as named app contracts; some should merge into a neighboring cohesive helper;
  some should be inlined into the owning runner or buildSpec when that makes
  the workflow easier to read.

Runner size policy:

- The 650-line repository file budget remains a hard backstop.
- Treat 500 lines as a review threshold for app `run.m`: new substantive logic
  should be accompanied by a responsibility audit.
- Treat 625 lines as a migration threshold: do not add more behavior to that
  runner until a cohesive block has moved to an app-owned package or a reusable
  framework hook.
- Do not create a new helper solely to reduce a file below a threshold. If a
  small helper is extracted, the migration or commit handoff must identify the
  behavior contract it protects.
- A runner below 500 lines can still be too complex when it mixes unrelated
  responsibilities, blocks workflow testing with OS dialogs, repeats a shared
  framework mechanism, or keeps deterministic calculations inside callbacks.

Helper extraction rubric:

Keep code in the runner, as a nested local function, or inline at the call site
when most of these are true:

- the code is under roughly 20 lines and has one or two call sites
- the helper only formats a trivial label, returns a constant list, checks a
  single boolean, or wraps one framework call
- the helper name is broader than the behavior it contains
- the helper has no useful independent test surface
- keeping it near the callback makes state changes or workflow order easier to
  understand

Keep or create an app-owned helper when most of these are true:

- the helper has an app-specific but stable contract that can be named clearly
- it is deterministic or isolates one explicit side effect such as export or
  file discovery
- it owns a data shape used by multiple callbacks, tests, or workflow phases
- it can be tested directly without launching a GUI
- moving it makes the runner orchestration read more clearly
- it prevents a known regression class such as unsafe path shapes, unsanitized
  numeric state, stale task fingerprints, duplicate export work, or malformed
  output records

Promote behavior to `+labkit` only when `labkit-boundary-guard` criteria are
met:

- domain-neutral name
- no app units, thresholds, result columns, plot wording, or export schema
- no app state reads or mutations
- independently testable
- used by at least two real apps or clearly owned by a facade
- improves the app-facing API rather than broadening a vague helper surface

Allowed short-file exceptions:

- public app entrypoints, `requirements.m`, `version.m`, and public facade
  functions that are intentionally one-function APIs
- `+ui/buildSpec.m` local builders when they keep visual order readable
- tiny factories such as `emptyItem` or task defaults when tests and app code
  both consume the named shape
- file filters or extension lists while they are still app-specific input
  policy
- small test helpers under `tests/shared/` that are direct test-facing APIs
- private framework adapter helpers when splitting prevents duplicated
  callback or UI-control internals

Workstreams:

1. Use `labkitHelperQualityAudit(root, "MaxLines", 20)` to classify current
   app helpers under 20 lines into:
   keep as contract, merge with neighboring helper, inline into caller, or
   candidate reusable framework hook. Record only unresolved debt here; do not
   preserve the full historical spreadsheet in docs.
2. Continue cleanup on current hotspots only when the next change removes a
   real responsibility split or duplicate app-neutral mechanic. Dense image
   apps are represented by `image_enhance` and `batch_crop`; dense non-image
   work is represented by `rhs_preview`. Do not keep adding prototype passes
   solely to lower file counts.
3. For helpers duplicated across app siblings, prefer family-local app-owned
   consolidation only when the shared behavior is still app/workflow-specific.
   Do not create family-level public helper packages. If the behavior is
   domain-neutral and app-facing, evaluate it for `+labkit`.
4. Add or update tests after code cleanup:
   - direct unit tests for app-owned deterministic helpers
   - focused GUI tests only when callback wiring or visible app behavior
     changes
   - project guardrails only after the rule is proven and low-noise
5. After several cleanup passes, replace the dry-run helper audit with
   a low-noise guardrail only if it can distinguish cosmetic micro-extraction
   from legitimate small public contracts.

Non-goals:

- Do not enforce a minimum helper length.
- Do not inline short helpers that are public API, stable task/data factories,
  or directly tested behavior contracts.
- Do not move app-specific formulas, thresholds, result schemas, plot labels,
  export columns, or workflow wording into `+labkit`.
- Do not compress MATLAB function bodies or use one-line functions to satisfy
  line budgets.

Completion criteria:

- Dense runners above the migration threshold have responsibility maps and
  no longer grow by adding unrelated behavior.
- Short helper files have been reviewed with an explicit keep/merge/inline
  decision for the current hotspots.
- New helper extraction is justified by contract, tests, call-site clarity, or
  reusable boundary value, not by line count alone.
- Any new guardrail catches cosmetic helper extraction without failing
  legitimate small APIs or test-facing helper functions.

## Active Route B: GUI Workflow Acceptance Validation

Objective:

Migrate app-level GUI validation from mostly structural launch/layout checks to
hidden, synthetic-data workflow acceptance checks that prove a user can
complete each app's core task flow. The target is not scientific correctness
proof. Correctness stays in app-owned GUI-free unit tests.

Prerequisite status:

The workflow-test blockers that previously required a separate hook migration
are retired: filePanel path/index helpers, output file/folder prompt helpers,
hidden-test-safe alert routing, debug reporting for caught callback exceptions,
finite-scalar numeric assignment guardrails, and close guards for current
fingerprinted image workflows are all in source and tests.

Target shape:

- Keep the official MATLAB test framework and build tasks. Do not create a
  parallel runner, custom pass/fail tree, or app-specific test command surface.
- Keep `buildtool gui` hidden by default. Workflow acceptance tests must create
  real MATLAB figures, controls, callbacks, and layout trees while avoiding
  visible windows and blocking OS dialogs.
- Add a small `tests/shared` semantic GUI workflow driver only for
  app-neutral mechanics such as reading the `labkitUiRegistry`, invoking
  semantic actions, injecting `filePanel` and folder-prompt providers, checking
  enabled state, reading status text, reading log text, and counting preview
  children.
- Keep synthetic fixture generation, expected workflow sequence, performance
  budget, export assertions, and result-schema expectations in the owning app's
  tests.
- Let completed app workflow tests absorb smoke-launch coverage for that app
  and most low-value exact layout assertions. Keep only essential structural
  checks for semantic controls, standard shell shape, debug trace, and visible
  commands that are not exercised by the workflow.
- Keep framework GUI tests under `tests/cases/gui/labkit/` and gesture tests
  under `tests/cases/gui/gesture/`; app workflow acceptance does not replace
  reusable UI, busy-state, filePanel, debug, runtime, drag, scroll, or tool
  lifecycle coverage.
- Keep app request compatibility and framework API return-shape checks in
  contract/unit suites. Workflow GUI tests consume those contracts; they do not
  replace them.

Migration workstreams:

1. Keep workflow acceptance at supported-app coverage. New supported app entry
   points must add dedicated GUI coverage instead of relying on
   `AppLaunchGuiTest`.
2. Extend `tests/shared/labkitWorkflowDriver.m` only for app-neutral semantic
   operations proven by real workflow tests. Avoid vague helpers that guess app
   meaning from button labels or combine unrelated concepts such as status text
   and selected-list text.
3. Add app-owned hooks only when a real workflow path otherwise opens a modal
   alert, OS file chooser, or output chooser that would stall hidden GUI tests.
   Keep normal public app entry points unchanged.
4. Record larger manual or scheduled stress cases only when a supported app has
   a concrete workflow risk that is too large for default hidden CI.
5. Update `docs/testing.md` and `tests/AGENTS.md` only if the validation
   contract changes again. Do not update user-facing app docs for internal test
   hooks.

Non-goals:

- Do not verify scientific validity or complete visual quality through GUI
  workflow acceptance tests.
- Do not move app-specific workflow, synthetic data semantics, performance
  thresholds, export schemas, or result assertions into `+labkit`.
- Do not make OS-coordinate mouse automation the primary test mechanism.
- Do not require every app to run large stress scenarios in default CI.
- Do not preserve exact component counts when semantic workflow and key control
  assertions cover the same risk with less brittleness.

Validation gates:

- Prototype and migration changes must run through the affected app GUI suite
  first, then the source-aligned `buildtool changed` or relevant
  `runLabKitTests("Suites", ...)` scope.
- Before broad handoff, `buildtool gui` must still run hidden by default and
  include workflow acceptance without stealing focus.
- Any routing, tag, or validation-policy change must update the project build
  guardrails that check known tags, task catalog shape, and GUI hidden mode.

Completion criteria:

- Representative robustness paths cover cancel/reload/reset/idempotent export
  where applicable.
- Framework UI, gesture, contract, and GUI-free unit tests remain in their
  current ownership lanes.

## Long-Term Compatibility Queue

The DTA facade intentionally keeps legacy bridge fields beside canonical
unit-explicit fields. This is compatibility debt, not current cleanup debt.

Do not remove fields such as chrono `t`, `Vf`, `Im`, `alignTime`,
`tAligned`, or EIS `Pt`, `Freq`, `Zreal`, `Zimag`, `negZimag` during ordinary
runner cleanup. A removal requires an explicit DTA major-version route after
electrochem apps and tests have moved to canonical fields.

## Migration Standard

Apps are first-class products. `+labkit` stays a small domain-neutral
foundation with UI, DTA, RHS, and biosignal facades. App-specific calculations,
summaries, plots, exports, workflow wording, file conventions, and result
schemas stay under the owning app tree.

A healthy runner owns orchestration only. App-owned helpers own deterministic
or explicitly side-effecting app behavior. Reusable framework helpers own
app-neutral mechanics that multiple apps share.

Migration progress means:

- a responsibility boundary becomes clearer
- deterministic behavior becomes directly testable
- the real GUI or app path uses the extracted helper
- duplicate app-neutral mechanics are removed from apps
- the total cognitive load of the workflow falls

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
- Do not add a minimum-line-count guardrail until the short-helper audit can
  distinguish cosmetic extraction from legitimate small contracts.
- Use `labkit-boundary-guard` before promoting behavior to `+labkit`.
- Use `labkit-test-planner` for validation routing and `docs/testing.md` for
  exact commands.
