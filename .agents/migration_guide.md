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
none
```

Current facts:

- MATLAB source inventory from current working-tree files:
  - total: 688 `.m` files, 59,660 lines
  - `apps/`: 392 files, 23,780 lines, max 649 lines
  - `+labkit/`: 174 files, 16,505 lines, max 647 lines
  - `tests/`: 119 files, 17,098 lines, max 649 lines
  - `labkit_launcher.m`: 1,722 lines and intentionally exempt
- Tracked files over the 650-line repository file budget:
  `labkit_launcher.m` only, by design, because it is the self-contained repair
  entry point.
- Package-root app `run.m` files currently range from 220 to 649 lines.
  Budget watchlist files are:
  - `apps/image_measurement/batch_crop/+batch_crop/run.m` at 649 lines
  - `apps/neurophysiology/rhs_preview/+rhs_preview/run.m` at 647 lines
  - `apps/image_measurement/image_enhance/+image_enhance/run.m` at 641 lines
  - `apps/image_measurement/image_match/+image_match/run.m` at 551 lines
  - `apps/image_measurement/curvature/+curvature/run.m` at 525 lines
  - `apps/dic/dic_preprocess/+dic_preprocess/run.m` at 522 lines
  - `apps/electrochem/vt_resistance/+vt_resistance/run.m` at 502 lines
  These are not active migration debt by line count alone. They are
  change-control triggers: do not add unrelated behavior to them without a
  responsibility audit or a cohesive app-owned extraction.
- `+labkit` implementation hotspots near the file budget are:
  - `+labkit/+ui/+app/private/buildFilePanelControl.m` at 647 lines
  - `+labkit/+ui/+app/private/buildControl.m` at 643 lines
  - `+labkit/+ui/+tool/createRuntime.m` at 636 lines
  - `+labkit/+ui/+diag/createContext.m` at 628 lines
  - `+labkit/+biosignal/private/detectEcgPeaksImpl.m` at 623 lines
- `tests/runner/labkitHelperQualityAudit.m` provides the Route A dry-run
  helper audit. It reports short helper file length, role package, function
  count, approximate call count, public/private status, direct unit-test
  references, allowed exception class, and a non-blocking recommendation.
- Current helper audit status:
  `labkitHelperQualityAudit(root, "MaxLines", 20)` reports zero
  `inline-or-merge-candidate` rows after the current cleanup. Keep it as a
  dry-run report; do not turn it into a blocking minimum-length rule unless it
  remains low-noise after future drift.
- Audit-driven cleanup history that defines the current helper-quality
  baseline:
  - `image_enhance.state.stepsForTask` and
    `image_enhance.state.itemStepsForExport` were merged into the existing
    export-task state contract instead of being inlined into the near-limit
    runner.
  - Batch Crop scale readiness/count micro helpers were merged into
    `batch_crop.state.scaleCalibrationSummary`, keeping the reusable
    `isScaleCalibrationSet` predicate while replacing two one-purpose loops
    with one tested state-summary contract.
  - RHS Preview indexed-duration and preview timing micro helpers were merged
    into `rhs_preview.ops.previewWindowBounds`, leaving clamping and
    summary-format helpers as behavior-specific contracts.
  - RHS Preview one-call event/pointer/wheel helpers were moved back into
    runner-local functions because they only serve runner callback
    interpretation.
  - DIC postprocess `ensureRgb`, Batch Crop `rectanglePosition`, and an unused
    CIC `formatMaybeNum` file were removed as cosmetic or stale short helpers.
  - Short `+export/write*.m` helpers are classified as
    `export-side-effect` exceptions because they isolate explicit file-write
    side effects.
- App `private/` debt: none.
- `+labkit` private helper contract debt: none.
- String-dispatch workflow adapters and app `+core/dispatch.m` routers: none.
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
- `tests/shared/labkitWorkflowDriver.m` provides the app-neutral hidden GUI
  workflow helper for registry reads, filePanel injection, semantic control
  invocation, enabled-state reads, table reads, text-area reads, filePanel
  state reads, preview child counts, and shared anchor-editor point injection.
- Every currently supported app entry point has dedicated app GUI coverage.
  `AppLaunchGuiTest` is a missing-coverage guardrail rather than broad smoke
  coverage.
- Workflow-backed app structural GUI tests have been trimmed so ordinary table
  columns, preview axes, redraw paths, and clear/refresh callbacks are covered
  by real workflow tests instead of duplicate launch-only assertions.
- Current `Workflow` tagged GUI coverage includes:
  - `GuiLayoutEisTest` and `GuiLayoutFocusStackTest` as the first DTA/image
    prototypes.
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
- a migration exposes package-boundary drift that cannot be fixed locally
  without a new `+labkit` API decision

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
