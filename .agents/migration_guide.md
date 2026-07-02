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

Last audited: 2026-07-01.

Current active migration debt:

```text
none
```

Current facts:

- MATLAB source inventory from current working-tree files:
  - total: 690 `.m` files, 60,054 lines
  - `apps/`: 376 files, 23,437 lines, max 649 lines
  - `+labkit/`: 191 files, 17,056 lines, max 647 lines
  - `tests/`: 120 files, 17,284 lines, max 649 lines
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
- Current tracked MATLAB inventory: 690 files and 60,073 total lines after the
  helper-audit expansion. The largest owned areas are `apps/` with 376 files
  and 23,437 lines, `+labkit/` with 191 files and 17,056 lines, and `tests/`
  with 120 files and 17,413 lines. Treat these as drift baselines, not targets.
- `tests/runner/labkitHelperQualityAudit.m` provides the Route A dry-run
  helper audit. It reports short helper file length, top-level scope, role
  package, function count, approximate call count, public/private status,
  direct unit-test references, boundary class, allowed exception class,
  non-blocking recommendation, and review reason.
- Current helper audit status:
  `labkitHelperQualityAudit(root, "MaxLines", 20, "Scope", "all")` reports
  70 `keep-boundary`, 79 `review-contract`, 10
  `review-one-call-contract`, 1 `review`, and zero
  `inline-or-merge-candidate` rows after the current cleanup. Keep it as a
  dry-run report; do not turn it into a blocking minimum-length rule.
- Helper-quality interpretation:
  - `keep-boundary`: valid small file because the name protects a public
    facade, state factory/contract, input policy, export/dialog side effect,
    UI adapter, test API, or runner API.
  - `review-contract`: short helper has direct tests or multiple call sites;
    revisit only when the owning behavior changes.
  - `review-one-call-contract`: one-call role helper with a plausible boundary
    signal, such as view formatting or framework-private implementation.
    Review for cohesion before inlining or expanding it.
  - `review`: one-call short helper without a strong boundary signal. Prefer
    merging it into the nearest cohesive app-owned contract during the next
    touch unless inspection proves a durable contract.
  - `inline-or-merge-candidate`: one-call tiny helper without tests, multiple
    call sites, or boundary signal. This is the main helper-debt trigger.
- Current non-automatic review queue from the all-scope helper audit:
  `batch_crop.state.canvasCacheKey`, framework-private `getReadonlyText`,
  `refreshListboxItems`, `defaultPulseOptions`, `createReadOnlyTextField`, DIC
  postprocess `strainToRgb` and `trimStrainEdgeMask`, and one-call
  curvature/focus-stack view formatting helpers. These are not blockers;
  inspect them when related code is touched.
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
  - Unused duplicate `image_enhance.view.displayImageNames` and
    `image_match.view.displayImageNames` files were deleted after the expanded
    helper audit showed no real call sites.
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
- Generic image source filters, path normalization, display names, source
  image reads, RGB double conversion, preview resizing, mean filtering, basic
  enhancement primitives, and image writes now live in `labkit.image` and are
  documented in `docs/image.md`. Image workflow semantics remain app-owned.
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
  `AppLaunchGuiTest` is a missing-coverage guardrail rather than broad launch
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

## Active Route: Debug Synthetic Sample Packs

Status: active but paused at user checkpoint on 2026-07-02. Stop after
recording this checkpoint unless the user explicitly resumes implementation.
Work is on branch `codex-debug-sample-packs`; `codex/debug-sample-packs`
could not be created locally because Git could not create the nested ref path.
Before resuming, inspect `git status --short --branch` and the current diff.
The workspace contains partial uncommitted work for the shared debug session
contract, electrochem/image/DIC sample generators, early tests, and a design
correction that removes debug auto-loading. Do not assume the current diff is
complete, validated, or ready to commit.

### Goal Prompt

Objective: make every supported app useful in `app("debug")` mode without
changing the app's initial state. A debug launch should create a deterministic,
clean-room synthetic sample pack under the app's debug artifact session,
record a manifest, retain trace/history/output folders, and leave the UI/data
state equivalent to normal startup so the user can debug their own real data
without synthetic inputs already loaded.

Current user instructions to preserve:

- Debug mode must not automatically load or select generated synthetic files.
  Users may open debug mode to diagnose problems in their own files, so app
  state after debug launch must match ordinary startup except for debug
  instrumentation, trace files, generated sample-pack artifacts, and log text
  pointing to those artifacts.
- Synthetic debug files still matter: generate valid representative files,
  malformed files, and format-valid edge/problem files under a controlled
  debug session path. The manifest should make them discoverable for manual or
  automated boundary testing.
- Use real local lab folders only as structural references when explicitly
  provided by the user. Do not put those reference paths, filenames, metadata,
  or other sensitive details into tracked project files, commit messages, PR
  text, or generated tracked artifacts. Temporary notes may live only under
  ignored `artifacts/` or memory.
- Generated files should be detailed and physically meaningful, not tiny
  fictional headers. Prefer realistic sampling density, metadata/container
  structure, noise, drift, channel layouts, image texture, and parser-relevant
  auxiliary fields within reasonable runtime limits.
- Continue on a separate branch and make small logical commits at stable
  checkpoints. The user explicitly deferred full test/CI cleanup until the
  implementation is complete and ready for a squash PR; do not spend this
  intermediate phase chasing full-suite failures unless a quick check is needed
  to avoid compounding a local syntax or format mistake.
- The artifact-writing locations should remain easy to understand, track, and
  inspect. Keep `artifacts/` organized by stable categories and ensure debug
  sample output is grouped under the owning app/session.

Operating principles:

- Preserve public app launch contracts. `app("debug")` remains the only public
  debug form and accepts no options.
- Keep sample semantics app-owned. Shared `+labkit` code may provide only
  domain-neutral debug artifact/session mechanics.
- Generate files from clean-room structural knowledge. Do not copy raw lab
  files, open-dataset files, filenames, local paths, timestamps, device IDs,
  serials, subject labels, experiment labels, or recognizable metadata.
- Local real-data folders may be inspected as structural references only when
  the user provides them. Keep those paths and any derived sensitive details
  out of tracked project files; if temporary notes are needed, put them under
  ignored `artifacts/` or memory, not source, tests, docs, commits, or PR text.
- Use generic synthetic labels such as `DEVICE`, `PrimaryChannel`, `debug
  recording`, and `capture start`.
- Simulate each app's real IO, not only a happy-path CSV. A sample pack should
  exercise the same parser/facade and filePanel shape that users use.
- Synthetic files should be detailed enough to exercise realistic workflow
  behavior, not just the shortest parser-acceptable header. Within reasonable
  runtime and repository-size limits, generate physically plausible signals,
  images, metadata/container structures, sampling density, noise, drift,
  multi-channel or multi-record layouts, and instrument-like auxiliary fields
  based on structural understanding of real data.
- Each app's sample pack should include a small boundary set, not just ideal
  examples: valid representative files, intentionally malformed files, and
  format-valid edge cases that may expose parser, app-logic, visualization, or
  export boundary behavior. Debug launch should generate and record these
  files, but must not load them into app state.
- Debug launch must not auto-load inputs, select files, set app output folders,
  auto-run analysis steps, overwrite existing user data, or auto-export final
  results. Synthetic files are discoverable through the trace/log/manifest and
  can be manually loaded by the user when desired.
- Existing hidden GUI workflow tests remain test-facing; production debug
  sample generation must not depend on `tests/shared`.

Current facts to preserve:

- The working branch was `main` aligned with `origin/main` at the start of
  this route.
- Recent development added or refined image workflows, FLIR thermal support,
  GUI callback debounce behavior, and host-bound validation guidance.
- Debug dispatch is owned by `labkit.ui.app.dispatchRequest`; diagnostics are
  owned by `labkit.ui.diag.createContext`.
- Existing debug traces and crash/active-operation reports live under
  `artifacts/debug/...` and must keep recording callback failures and freeze
  context.
- FilePanel debug traces intentionally record semantic ids and counts, not raw
  local user paths.
- Test fixtures already prove minimal synthetic DTA, RHS, FLIR RJPEG, image,
  DIC, ECG, and neurophysiology workflow structures, but those fixture writers
  are not production APIs.

Target debug artifact shape:

```text
artifacts/debug/<RunName>/<AppName>/<SessionId>/
  trace.log
  active_operation.txt
  crash_report.txt
  manifest.json
  samples/
  outputs/
```

If no `LABKIT_RUN_NAME` is set, omit the `<RunName>` segment. The session id
should be unique per launch. `manifest.json` should record the app name,
sample-pack type/version, generated sample groups, output folder, and only
repo/debug-artifact paths or generic labels.

Required shared design:

- Extend the debug context with app-neutral fields such as `artifactFolder`,
  `sampleFolder`, `outputFolder`, `manifestFile`, and a manifest writer such
  as `recordArtifacts`.
- Derive those folders from the debug trace location so normal app launches,
  official test runs, and fallback temp artifacts stay consistent.
- Keep every writer under `artifacts/` easy to browse: category folders should
  be stable (`test-results`, `coverage`, `logs`, `debug`, `gui`,
  `code-check`, `release`, or `doc-assets`), run names should namespace
  official runs, debug launches should use
  `debug/<RunName>/<AppName>/<SessionId>/`, and each debug session should keep
  fixed file/folder names (`trace.log`, `active_operation.txt`,
  `crash_report.txt`, `manifest.json`, `samples/`, `outputs/`). If a writer
  needs a new artifact location, add it through the owned artifact-path helper
  or document why app-local output is not a runner artifact.
- Document the session folder contract in `docs/ui.md` and update the
  `labkit.ui` facade version if the debug context public struct changes.
- Keep shared code free of experiment-domain concepts such as DTA, RHS, ECG,
  FLIR, DIC, or sample-pack contents.

Required app-owned sample packs:

Terminology: use `representativeFiles` for valid files that users can manually
load from the generated sample folder. Do not use `preloadFiles` or test names
that imply debug launch modifies app state.

| App | Real IO contract | Debug sample pack |
| --- | --- | --- |
| `labkit_ChronoOverlay_app` | Multiple chrono `.DTA` files loaded through `labkit.dta.loadFile(..., "chrono")`; CSV export is user-triggered. | Two representative chrono DTA files: current-pulse and voltage-pulse traces with tabular `Pt/T/Vf/Im` rows. Generate only; do not load. |
| `labkit_CIC_app` | Chrono `.DTA` input, automatic CIC analysis after load, CSV export on request. | Representative current-controlled chrono DTA with cathodic/anodic pulse windows suitable for charge/safety readouts. Generate only; do not load. |
| `labkit_VTResistance_app` | Chrono `.DTA` input, automatic resistance analysis after load, CSV export on request. | Representative current-pulse chrono DTA with steady segments and voltage response suitable for resistance readouts. Generate only; do not load. |
| `labkit_CSC_app` | CV/CT `.DTA` input through `labkit.dta.loadFile(..., "cvct")`; curve dropdown and Q/CSC comparison are app-owned. | Representative CV/CT DTA with scan-rate metadata and at least two curve tables. Generate only; do not load. |
| `labkit_EIS_app` | EIS ZCURVE `.DTA` through `labkit.dta.loadFile(..., "eis")`; CSV export on request. | Representative ZCURVE DTA with frequency, real/imaginary impedance, magnitude, phase, current, and voltage columns. Generate only; do not load. |
| `labkit_DICPreprocess_app` | Reference image plus moving/current image; saves current images and ROI mask through app-owned dialogs. | Textured grayscale/RGB reference and shifted moving image pair. Generate only; leave initial state empty. |
| `labkit_DICPostprocess_app` | Ncorr-like MAT file, reference image, and mask image; outputs overlay PNGs and summary CSV. | MAT file containing anonymous EXX/EYY strain maps plus ROI mask, paired with matching reference and mask images. Generate only; leave initial state empty. |
| `labkit_CurvatureMeasurement_app` | One image file; curve points, scale, fit, length, CSV, and overlay export are user-driven. | Image containing a visible arc/feature field. Generate only; leave initial state empty. |
| `labkit_FocusStack_app` | Folder or selected image files from one field of view; outputs fused PNG, focus map PNG, and summary CSV. | Three or more same-size focus slices with different sharp regions and mild realistic texture. Generate only; do not run fusion. |
| `labkit_ImageEnhance_app` | Source image set; app-owned history and export manifest. | Two figure/microscope-like images with uneven illumination, texture, and a neutral patch for white-balance tools. Generate only; leave initial state empty. |
| `labkit_ImageMatch_app` | Reference image plus source image set; app-owned match history and export manifest. | One reference image and two source images with tone/color shifts. Generate only; leave initial state empty. |
| `labkit_BatchImageCrop_app` | Image set, optional per-image scale calibration, crop centers, crop export manifest. | Two microscope-like images with obvious crop targets and a scale cue. Generate only; leave initial state empty. |
| `labkit_FLIRThermal_app` | FLIR radiometric JPEG/RJPEG files through `labkit.thermal`; outputs rendered images, colorbars, and manifest. | Anonymous radiometric JPEG-like files with FLIR/FFF/RawThermalImage structure and temperature gradients. Generate only; leave initial state empty. |
| `labkit_ECGPrint_app` | MAT timetable or CSV/TSV/TXT recording through `labkit.biosignal.readRecording`; exports segment SNR CSV and waveform PNG. | At least one CSV with `time_s`, ECG, and an auxiliary motion/noise channel; optional headerless TXT or MAT timetable can be included for manual parser checks. Generate only; leave initial state empty. |
| `labkit_RHSPreview_app` | RHS file, RHS folder/file set, optional protocol JSON; saves protocol and filter-record JSON. | Mini acquisition folder with multiple synthetic `.rhs` files plus optional protocol JSON. Generate only; leave initial state empty. |
| `labkit_NerveResponseAnalysis_app` | Filter-record JSON plus optional protocol JSON; reads RHS files lazily and exports analysis JSON. | Filter-record JSON referencing generated synthetic RHS files, plus protocol JSON. Generate only; leave initial state empty. |
| `labkit_ResponseReviewStats_app` | Analysis JSON or segment CSV; exports metrics CSV. | Segment CSV with aligned response columns and an analysis JSON with metrics rows. Generate only; leave initial state empty. |

Required workstreams:

1. Resume audit: inspect current diff, decide whether to continue, revise, or
   replace any partial uncommitted prototype. Do not silently discard user or
   prior-agent changes.
2. Shared debug session contract: finish the app-neutral debug context fields,
   session folder creation, manifest writer, docs, and unit tests.
3. App-owned generators: add one `+debug/writeSamplePack.m` per app or an
   equivalently app-owned role helper. Each helper returns generated paths,
   separates `representativeFiles` from boundary-only files, and writes a
   manifest payload through the debug context.
4. App wiring: in debug launch only, call the app's sample writer after UI
   construction and before first user interaction. Do not call app load/read
   callbacks and do not mutate app state with the generated files. Catch
   failures and report them through `debug.reportException`.
5. Generator validation: add focused unit tests that generate every sample
   pack and read the files through the real app/facade parser used by the app.
6. GUI validation: keep GUI assertions representative rather than exhaustive.
   At minimum, verify debug launch creates sample folders/manifests and that
   representative app families still show normal empty startup state.
7. Hygiene audit: scan diffs for local shared-drive paths, original filenames,
   device ids, timestamps, subject labels, serials, copied data arrays, and
   any `tests/shared` production dependency.
8. Final validation and handoff: use `labkit-test-planner` for changed-file
   routing; broad completion should include the relevant unit checks and GUI
   build task before commit/push.

Validation gates:

- Unit tests for `labkit.ui.diag` debug artifact fields and manifest writing.
- Unit tests for every app-owned sample generator.
- Parser/readback checks:
  - Representative valid DTA samples load with `labkit.dta.loadFile` under
    the correct kind; malformed DTA samples fail cleanly; format-valid edge
    samples stay readable but exercise app-level warning/failure paths.
  - Representative valid FLIR samples load through `labkit.thermal`;
    malformed/metadata-edge FLIR-like files fail or warn cleanly.
  - Representative valid RHS samples index and read a preview window through
    `labkit.rhs`; malformed or boundary RHS files are generated for controlled
    failure-path checks.
  - Representative valid ECG samples parse through
    `labkit.biosignal.readRecording`; malformed or difficult delimited/MAT
    files are generated for parser and app-boundary checks.
  - DIC MAT/reference/mask samples load through the app-owned postprocess IO.
  - Image samples load through `labkit.image` or app-owned readers.
- Representative GUI tests for debug sample generation and normal empty debug
  startup state.
- `buildtool changed` for changed-file validation; use broader `headless` or
  `gui` tasks when changed-file routing reaches shared debug or many apps.

Non-goals:

- Do not add public debug launch options.
- Do not create a `+labkit/+sample`, `+labkit/+data`, or generic sample-data
  facade.
- Do not commit generated sample files; they are created under `artifacts/`
  at debug runtime.
- Do not auto-run app analyses that require manual user judgment, except for
  existing app behavior that already analyzes immediately after a normal load.
- Do not replace existing hidden workflow tests with debug sample generation.
- Do not introduce real lab data, public dataset data, copied metadata, or
  source paths into tracked files.

Blockers:

- MATLAB unavailable for parser/readback validation.
- A generator cannot produce a file accepted by the real parser without
  changing parser behavior; in that case, fix the generator first and change
  parser behavior only with a separate explicit rationale.
- A proposed shared helper needs experiment-domain knowledge. Keep it app-owned
  or stop for a boundary decision instead of expanding `+labkit`.

Completion criteria:

- Every supported app creates deterministic debug samples in its debug session
  under `artifacts/debug/.../samples`.
- `manifest.json`, `trace.log`, crash report path, active-operation path, and
  `outputs/` are present or derivable from the debug context.
- Debug launches still return at most `[fig, debug]` and reject debug options.
- Representative debug launches generate useful synthetic inputs without user
  real data while leaving app state equivalent to normal startup.
- Debug sample packs include valid, malformed, and format-valid edge files
  where the app's real input domain supports those categories; manifests make
  clear which files are representative valid inputs and which are boundary-test
  inputs.
- All generated files are clean-room synthetic and free of sensitive labels or
  copied metadata.
- Relevant tests pass locally, or an exact validation blocker is reported.

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
foundation with UI, image, DTA, RHS, and biosignal facades. App-specific calculations,
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
