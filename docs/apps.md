# Apps

LabKit apps are independent MATLAB GUI tools for concrete lab workflows. Each
app should be useful on its own, with a stable public launch command and
app-owned workflow logic.

## Launching Apps

For normal use, start from the single-file launcher linked in the root
[README](../README.md). Put `labkit_launcher.m` in a standalone LabKit folder,
open MATLAB in that folder, and run:

```matlab
labkit_launcher
```

The launcher is self-contained so it can open before the rest of LabKit is
installed and report its own version. Use `Latest` to download the current
`main` branch, `Release` to download the latest stable release, or `Versions`
to choose a recent release, tag, or main-branch commit. The version manager is
for deliberate upgrades or rollback when a newer build is unsuitable. After
LabKit is present, the launcher initializes the MATLAB path, discovers app
entry points with their app versions, and opens the selected app.

Treat the LabKit folder as an application runtime folder. Keep source data and
exported results in separate project folders; routine users do not need to
inspect or edit the files downloaded by the launcher.

Manual command launch is mainly for source checkouts, debugging, or scripted
local work. Add the repository root, `apps/`, and the target app folder to the
MATLAB path before calling an app command:

```matlab
root = pwd;
addpath(root);
addpath(fullfile(root, "apps"), "-end");
addpath(fullfile(root, "apps", "electrochem", "cic"), "-end");
labkit_CIC_app
```

The launcher also provides debug launch, generated-artifact cleanup, and MATLAB
Code Analyzer actions for maintenance work. Cleanup removes generated LabKit
artifacts under `artifacts/`.

The Code Analyzer action writes a native `codeIssues` JSON export to
`artifacts/code-check/matlab_code_issues.json` for manual maintenance review.

The launcher sets up the app path before opening an app. App-owned packages are
reached through their owning app entrypoint and package namespace.

The launcher update flow treats the LabKit folder as a replaceable runtime
directory. Before copying a selected GitHub zip into place, the launcher moves
the current top-level runtime contents into a dated `LabKit-previous-*`
subfolder under the same folder. It then copies the downloaded LabKit root as a
whole replacement instead of tracking individual managed files.

Keep lab data and exports outside the LabKit runtime folder. The update prompt
warns that current folder contents will be moved into the dated snapshot. If a
release removes or merges app entrypoints, the launcher gives an additional
warning before replacing the runtime; users who need old entrypoints should
choose an older release, tag, or commit through `Versions`.

## App Catalog

| Command | Family | Purpose | Inputs | Typical outputs |
| --- | --- | --- | --- | --- |
| `labkit_ChronoOverlay_app` | Electrochemistry | Chrono voltage/current overlay. | Chrono DTA | Overlay plots and CSV. |
| `labkit_CIC_app` | Electrochemistry | CIC and voltage-transient metrics. | Chrono DTA | Results table and CSV. |
| `labkit_VTResistance_app` | Electrochemistry | Steady resistance estimates from voltage transients. | Chrono DTA | Resistance table and CSV. |
| `labkit_CSC_app` | Electrochemistry | CV/CT charge integration and CSC comparison. | CV/CT DTA | Plots, comparison values, all-cycle CSC CSV, and column-oriented CV data CSV. |
| `labkit_EIS_app` | Electrochemistry | EIS curve overlay and export. | EIS ZCURVE DTA | Plot and CSV. |
| `labkit_DICPreprocess_app` | DIC | Image registration, paired crop preparation, and ROI mask drawing. | Reference/current images | Aligned images, crop PNGs, ROI mask. |
| `labkit_DICPostprocess_app` | DIC | Ncorr strain overlay and MAT-domain strain summary. | Ncorr MAT, reference image, mask | Clean same-size EXX/EYY overlay PNGs and summary CSV. |
| `labkit_CurvatureMeasurement_app` | Image measurement | Editable curve fit, calibrated scale bar, curvature, and length. | Image | Overlay PNG and curvature/length CSV. |
| `labkit_FocusStack_app` | Image measurement | Focus-stack fusion into one all-in-focus image. | Image folder or selected image files | Fused PNG, focus map PNG, summary CSV. |
| `labkit_ImageEnhance_app` | Image measurement | Brightness, contrast, clarity, color, and white-balance processing. | Image files | Enhanced images and manifest CSV. |
| `labkit_ImageMatch_app` | Image measurement | Reference-based tone, white-balance, Lab style, and histogram matching. | Source image files and separate reference image | Matched images and manifest CSV. |
| `labkit_BatchImageCrop_app` | Image measurement | Fixed-size batch microscope crops with edge-continuous padding, rotation, duplicate crop tasks, responsive downsampled preview rendering, and optional per-image physical scale normalization with independent crop and calibration units. | Microscope images, optional scale calibration per image | Cropped same-size images and crop manifest CSV. |
| `labkit_FLIRThermal_app` | Image measurement | FLIR radiometric JPEG/RJPEG thermal postprocessing with per-image display ranges, range-bound presets, linear/log/adjustable-gamma color mapping, clean heatmap rendering, and scale bars. | FLIR radiometric image files | Thermal image exports, colorbar PNGs, and manifest CSV. |
| `labkit_ECGPrint_app` | Wearable biosignal | ECG waveform preview, ROI filtering, peak/segment SNR, and SNR-over-time display. | MAT timetable or CSV/TSV table | Segment SNR CSV and waveform PNG. |
| `labkit_RHSPreview_app` | Neurophysiology | Intan RHS header inspection, stacked waveform preview, ROI zooming, channel protocol drafting, and manual folder filtering. | RHS file, RHS folder, and optional protocol JSON | Header summary, preview window, channel protocol JSON, and filter record JSON. |
| `labkit_NerveResponseAnalysis_app` | Neurophysiology | Filter-record-driven event train detection, differential response derivation, common-mode correction, and CAP metrics. | Filter record JSON and recommended protocol JSON | Analysis JSON with events, trains, metrics, and issues. |
| `labkit_ResponseReviewStats_app` | Neurophysiology | Immediate metric loading, aligned response segment review, and descriptive statistics from analysis metrics or legacy segment CSV. | Analysis JSON or segment CSV | Metrics CSV and summary table. |

## Current Workflow Notes

### CSC App

`labkit_CSC_app` loads one or more CV/CT Gamry DTA files and keeps the file
panel selection as the active file. Selecting a file resets the curve selector,
plot defaults, all-cycle table, and plot axes to that file's parsed curves.
The default curve choice is `All cycles`: both plot panes draw every parsed
cycle with per-cycle colors, and current traces split cathodic and anodic
segments into darker/lighter variants of the same cycle color. Time plots are
cycle-aligned by subtracting each cycle's initial time from that cycle's `T`
column.

Selecting an individual cycle switches the plots and comparison readout to
that curve. Plot X/Y dropdown changes redraw the curve data and refit X/Y
limits; overlay-only trim refreshes preserve the user's current plot view.
`Ignore first/last cycle` affects the all-cycle result table, all-cycle CSC
export, CV data export, and all-cycle plot display, so incomplete edge cycles
can be excluded consistently.

`Export all cycles CSV` writes one row per exported file cycle with cathodic,
anodic, and full CT/CV charge and CSC columns. `Export CV data CSV` writes a
column-oriented table for replotting CVs and recomputing CSC: one potential
column plus paired current and scan-rate columns per file cycle when all
exported cycles share the same voltage vector. When voltage vectors differ
across DTA files, the app writes one CSV per source DTA item using the chosen
output filename as the stem.

### FLIR Thermal App

`labkit_FLIRThermal_app` reads FLIR radiometric JPEG/RJPEG files through
`labkit.thermal`, keeps per-image display ranges, and exports clean thermal
images, colorbars, Celsius matrices, and a manifest. The display controls
include linear, log, and gamma color mapping. Log and gamma modes affect only
the color mapping from the selected display range into the palette; they do
not transform the stored raw or Celsius matrix and do not change exported
temperature CSV values. Gamma mode exposes a `Gamma` panner so users can tune
the display curve interactively.

## Creating A New App

Create new apps from a LabKit app template instead of copying an existing app
folder. The template should generate the public entrypoint, version metadata,
`definition.m`, `definitionActions.m`, `+appLifecycle`,
`+userInterface`, workflow package stubs, debug sample-pack stubs, and focused
starter tests.

Use the smallest nearby app only as a workflow reference. Do not copy its
directory shape wholesale. Replace state, commands, result tables, plots, and
exports with the new app's real behavior. New apps launch through the framework
app-definition runtime instead of package-root runners.

## App File Shape

LabKit uses one MATLAB package tree per app, but keeps the fixed framework
surface small. App authors should see lifecycle, UI, and concrete user
workflows, not broad buckets such as action, renderer, operation, IO, and
export.

The author-facing shape is the part app authors should read and edit first:

```text
apps/<family>/<app_slug>/labkit_<AppName>_app.m
apps/<family>/<app_slug>/+<app_slug>/definition.m
apps/<family>/<app_slug>/+<app_slug>/definitionActions.m
apps/<family>/<app_slug>/+<app_slug>/requirements.m
apps/<family>/<app_slug>/+<app_slug>/version.m
apps/<family>/<app_slug>/+<app_slug>/+appLifecycle/createInitialState.m
apps/<family>/<app_slug>/+<app_slug>/+userInterface/buildWorkbenchSpec.m
apps/<family>/<app_slug>/+<app_slug>/+userInterface/updateWorkbenchFromState.m
```

App-specific behavior is grouped by user-facing workflow or domain capability,
not by generic technical phase. Create only the packages the app actually
needs, and name each package after the concept a user or maintainer would
recognize:

```text
apps/<family>/<app_slug>/+<app_slug>/+sourceFiles/chooseSourceFiles.m
apps/<family>/<app_slug>/+<app_slug>/+sourceFiles/readSourceFiles.m
apps/<family>/<app_slug>/+<app_slug>/+sourceFiles/showSourceFilePreview.m
apps/<family>/<app_slug>/+<app_slug>/+analysisRun/collectAnalysisOptions.m
apps/<family>/<app_slug>/+<app_slug>/+analysisRun/computeAnalysisResults.m
apps/<family>/<app_slug>/+<app_slug>/+analysisRun/showAnalysisResults.m
apps/<family>/<app_slug>/+<app_slug>/+resultFiles/chooseResultFolder.m
apps/<family>/<app_slug>/+<app_slug>/+resultFiles/writeResultFiles.m
apps/<family>/<app_slug>/+<app_slug>/+resultFiles/showExportSummary.m
apps/<family>/<app_slug>/+<app_slug>/+debugArtifacts/createSyntheticSampleFiles.m
```

This is intentionally workflow-first. A source-file workflow may include a
chooser, reader, preview update, and validation in one package because those
functions change together. A result-file workflow may include the command
handler, writer, manifest builder, and completion summary for the same reason.
Do not split the same user story across `actions/`, `renderers/`, `io/`, and
`export/` role folders.

Avoid abstract bucket names such as `actions.m`, `render.m`, `ops.m`,
`io.m`, `manager.m`, or `processor.m`. Avoid generic packages such as
`+actions`, `+renderers`, `+ops`, `+io`, and `+export` for new app code. A
package named `+sourceFiles`, `+cropGeometry`, `+thermalFrames`,
`+analysisRun`, or `+resultFiles` is easier to navigate because the package
name states what user-visible capability it owns.

`requirements.m` declares only LabKit facade contract ranges by returning
`labkit.contract.requirements(...)`. Public app entrypoints return this struct
for the lightweight `"requirements"` request and check facade contracts before
normal or debug launch. Apps do not declare their own package metadata or solve
dependencies.

`version.m` declares the app's own visible version, display name, family, and
last version-change date. Public app entrypoints return it for the lightweight
`"version"` request, and app windows include the version and date in their
figure title. It returns `name`, `displayName`, `family`, `version`, and
`updated`, where `name` is the public app entrypoint function. When an app's
code or app-facing behavior changes, update that app version metadata in the
same change. When choosing the next app version, compare against the version
file in the latest `main` commit, not against intermediate local edits in the
current working tree.

`definition.m` declares the app's runtime contract. It returns a plain struct
created with `labkit.ui.app.define`, naming the app id, title, initial state
factory, data-only UI spec builder, command handler registry, visible-state
update function, startup phases, and optional idle hydration phases. The
framework runtime validates the definition, generates callbacks, schedules
startup, gates busy/ready state, and routes diagnostics. App code should not
own loading controls, startup timers, callback wrappers, or framework
readiness flags.

For nontrivial apps, `+userInterface/buildWorkbenchSpec.m` should make the
page hierarchy obvious at the top of the file. Keep the app constructor
shallow, then use local builder functions for tabs, sections, and the
workspace. Put section builders in the same order the user sees them, and keep
small field helpers after the workspace builder. The goal is readable MATLAB
source, not a separate UI-generation DSL. `+userInterface/updateWorkbenchFromState.m`
is the single top-level bridge from state to visible controls; it should call
specific workflow display helpers such as
`+sourceFiles/showSourceFilePreview.m` or `+analysisRun/showAnalysisResults.m`.

Keep one visible structure per concept. Do not keep both singular and
directory forms for the same concept (`sourceFiles.m` plus `+sourceFiles/`,
`analysisRun.m` plus `+analysisRun/`, or `resultFiles.m` plus
`+resultFiles/`). When a workflow grows, add specific files inside that
workflow package instead of creating parallel technical buckets.

Use the app slug as the package name. Do not use a shared `+app` namespace.
Do not add family-level `private/` helper folders.

## App Definition And Helper Shape

The app definition is the runtime boundary. It names initial state, UI spec,
registered command handlers, visible-state update, startup, and hydration. The
framework owns lifecycle orchestration: launch/debug wiring, callback adapters,
readiness, busy gating, close guards, startup phase timing, and
hidden-test-safe diagnostics.

Workflow package functions should use concrete verb-object names:

```text
apps/<family>/<app_slug>/+<app_slug>/+sourceFiles/chooseSourceFiles.m
apps/<family>/<app_slug>/+<app_slug>/+sourceFiles/readSourceFiles.m
apps/<family>/<app_slug>/+<app_slug>/+sourceFiles/showSourceFilePreview.m
apps/<family>/<app_slug>/+<app_slug>/+analysisRun/collectAnalysisOptions.m
apps/<family>/<app_slug>/+<app_slug>/+analysisRun/computeAnalysisResults.m
apps/<family>/<app_slug>/+<app_slug>/+analysisRun/showAnalysisResults.m
apps/<family>/<app_slug>/+<app_slug>/+resultFiles/writeResultFiles.m
```

The function name, not a generic parent folder, should explain the local
responsibility. A command handler may orchestrate file reads, computation,
state updates, and display refresh for one user workflow. Deterministic
calculation and file-writing helpers should still be separate functions inside
the same workflow package when they are worth testing directly.

Visible UI update functions translate prepared app state into existing UI
handles. They should not perform file IO, heavy computation, export writes, or
state mutation. `+userInterface/buildWorkbenchSpec.m` declares the
control/workspace tree, while `+userInterface/updateWorkbenchFromState.m`
updates that tree from state and delegates workflow-specific display updates.

Keep small code local when the call site is clearer than a separate name. Move
code into an app-owned workflow package when it owns a stable user workflow,
deterministic state transition, file normalization, computation, output write,
display update, or focused custom UI/tool glue that can be tested or reused by
the real app path. Do not create short pass-through helpers solely to lower the
line count. See [architecture.md](architecture.md#extraction-quality) for the
reusable extraction rule and helper-quality principles.

## Task Lifecycle

Apps with preview, edit, run, or export workflows should keep task lifecycle
state explicit. App state may track dirty flags, small preview caches, and the
last successful task fingerprint, but GUI-free helpers own deterministic task
snapshots inside the workflow package that owns the task.

Image apps should use `labkit.image` for generic image filters, path
normalization, display names, reads/writes, RGB double conversion, preview
resizing, mean filtering, and basic enhancement primitives. Thermal image apps
should use `labkit.thermal` for radiometric source parsing, raw thermal
matrices, temperature conversion, and linear thermal palette rendering.
Display policy such as per-image ranges, log/gamma color mapping controls, and
export manifests remains app-owned. Keep app-owned readers when they build app
item structs or enforce workflow-specific state.

Use this boundary:

- workflow state helpers build immutable task snapshots and fingerprints from
  inputs, options, and committed steps.
- computation helpers perform deterministic work without GUI or file side
  effects.
- result-file helpers write outputs from an explicit task/options boundary.
- preview actions operate on the current selection and display-resolution
  data when practical; full batch work happens at export or run actions.

File selection should register files and build app-owned task state with the
least data needed for the immediate preview. For large selections, avoid
eagerly reading or computing every file in the chooser action unless the
workflow truly cannot show a useful first state without the full batch. For
example, a crop workflow can keep path-only crop tasks until the current preview
or export needs pixels.

The UI framework prevents duplicate command submission. Apps decide what
changed, what result is dirty, and whether a repeated task can be skipped.

## App Ownership

Keep these decisions in the owning app:

- accepted input formats
- domain options and defaults
- formulas, thresholds, and units
- plots, labels, annotations, and summaries
- result table columns and export schemas
- user alerts, log wording, and workflow order

Move code into `+labkit` only when it is domain-neutral, app-facing, broadly
reusable, and clearer as a public facade. See [architecture.md](architecture.md)
for the extraction rule.

## Validation

Use the changed-file, headless, or GUI tasks from
[testing.md](testing.md) depending on the scope of the app change.

Automated GUI tests check launch, layout, callback wiring, and debug trace
plumbing, and current supported apps also have hidden synthetic workflow
coverage for their core task flow. These tests do not prove scientific
validity, visual quality, or manual workflow feel; keep manual workflow review
in MATLAB for those questions.
