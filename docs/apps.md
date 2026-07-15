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

The Code Analyzer action delegates to `tools/codecheck`, writes both a native
`codeIssues` JSON export and a self-contained HTML viewer under
`artifacts/code-check/`, and opens the HTML report when run from the visible
launcher. Each run writes a new timestamped JSON/HTML pair such as
`matlab_code_issues_YYYYMMDD_HHMMSS.json` and
`matlab_code_issues_YYYYMMDD_HHMMSS.html` so earlier reports are not
overwritten.
The scan includes the public checkout plus local private app workspaces that
opt in by placing `.labkit-accept-main-guardrails` at the private workspace
root. Accepted private workspaces can live under `private_apps/apps/` or
`LABKIT_PRIVATE_APP_ROOTS`; private source remains ignored by the public
repository, but its local analyzer findings appear in the same generated
report.

Maintenance buttons that depend on optional tool folders are disabled when
those tool folders are missing. Core launcher actions, including app launch and
GitHub version update, remain available.

The launcher app table has a `Package` checkbox column independent of the
single highlighted row used by Open and Debug. `Package Checked` creates one
source zip under `artifacts/deployment/` containing every checked app folder
and its assets, `+labkit/`, the launcher, launcher-needed
deployment/profiling tool folders, a `packaged_app_manifest.json`, and one
direct `run_<app_command>` entry file per app. Users can run any direct entry
file or `labkit_launcher` from the unzipped source package.

`Checked P-code` creates a runtime-only package with MATLAB code encoded as
`.p` files instead of source `.m` files. It includes the checked app folders
and assets, `+labkit/`, a `packaged_app_manifest.json`, and one direct
`run_<app_command>` entry file per app. It intentionally does not include
`labkit_launcher` or launcher maintenance tools, so users start the app through
the direct entry file from the unzipped folder.

Both package formats intentionally omit unchecked public apps, tests, docs, CI
files, and source-checkout metadata.

The launcher sets up the app path before opening an app. App-owned packages are
reached through their owning app entrypoint and package namespace.

Local private apps can live in an ignored workspace at `private_apps/apps/`
inside any source checkout, or in one or more roots named by
`LABKIT_PRIVATE_APP_ROOTS`. See [private-apps.md](private-apps.md) for the
generic structure and Git ownership model. Private app details belong in the
private app repository, not in the public LabKit docs.

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
| `labkit_FigureStudio_app` | LabKit Core | FIG cleanup, LabKit/FIG-default style modes, per-part figure styling, and visible graphics data export. | MATLAB FIG files or popout axes | Styled preview, `plot_data.mat`, optional CSV, and `recreate_plot.m`. |
| `labkit_DICPreprocess_app` | DIC | Image registration, paired crop preparation, and ROI mask drawing. | Reference/current images | Aligned images, crop PNGs, ROI mask. |
| `labkit_DICPostprocess_app` | DIC | Ncorr strain overlay and MAT-domain strain summary. | Ncorr MAT, reference image, mask | Clean same-size EXX/EYY overlay PNGs and summary CSV. |
| `labkit_CurvatureMeasurement_app` | Image measurement | Editable curve fit, calibrated scale bar, curvature, and length. | Image | Overlay PNG and curvature/length CSV. |
| `labkit_VideoMarker_app` | Image measurement | Visual skeleton setup followed by continuous ordered video keypoint annotation with frame inheritance. | Video | Round-trip marker CSV, derived coordinate CSV, and project MAT. |
| `labkit_FocusStack_app` | Image measurement | Focus-stack fusion into one all-in-focus image. | Image folder or selected image files | Fused PNG, focus map PNG, summary CSV. |
| `labkit_ImageEnhance_app` | Image measurement | Brightness, contrast, clarity, color, and white-balance processing. | Image files | Enhanced images and manifest CSV. |
| `labkit_ImageMatch_app` | Image measurement | Reference-based tone, white-balance, Lab style, and histogram matching. | Source image files and separate reference image | Matched images and manifest CSV. |
| `labkit_BatchImageCrop_app` | Image measurement | Fixed-size batch microscope crops with edge-continuous padding, rotation, duplicate crop tasks, responsive downsampled preview rendering, and optional per-image physical scale normalization with independent crop and calibration units. | Microscope images, optional scale calibration per image | Cropped same-size images and crop manifest CSV. |
| `labkit_FLIRThermal_app` | Image measurement | FLIR radiometric JPEG/RJPEG thermal postprocessing with per-image display ranges, range-bound presets, linear/log/adjustable-gamma color mapping, clean heatmap rendering, and scale bars. | FLIR radiometric image files | Thermal image exports, colorbar PNGs, and manifest CSV. |
| `labkit_GaitAnalysis_app` | Gait | Pose-coordinate gait analysis with keypoint role mapping, smoothing, step-event detection, joint angles, translations, ROM, and QC previews. | Pose CSV/TSV/TXT or MAT coordinate files | Frame metrics CSV, coordinate CSV with raw pixel and scaled/origin-shifted columns, step metrics CSV, and summary CSV. |
| `labkit_ECGPrint_app` | Wearable biosignal | ECG waveform preview, ROI filtering, peak/segment SNR, and SNR-over-time display. | MAT timetable or CSV/TSV table | Segment SNR CSV and waveform PNG. |

Electrochemistry analysis controls above a batch result table apply to the
whole loaded batch. CIC and VT Resistance recompute every loaded file when a
shared analysis setting changes and again immediately before export. CIC delay
values are microseconds after each pulse end; delays outside the recorded time
range fail instead of extrapolating. CIC CSV exports include `Area_cm2` and
`Delay_us` so the normalization and sampling settings remain auditable.
| `labkit_RHSPreview_app` | Neurophysiology | Intan RHS header inspection, stacked waveform preview, ROI zooming, channel protocol drafting, and manual folder filtering. | RHS file, RHS folder, and optional protocol JSON | Header summary, preview window, channel protocol JSON, and filter record JSON. |
| `labkit_NerveResponseAnalysis_app` | Neurophysiology | Filter-record-driven event train detection, differential response derivation, common-mode correction, and CAP metrics. | Filter record JSON and recommended protocol JSON | Analysis JSON with events, trains, metrics, and issues. |
| `labkit_ResponseReviewStats_app` | Neurophysiology | Immediate metric loading, aligned response segment review, and descriptive statistics from analysis metrics or legacy segment CSV. | Analysis JSON or segment CSV | Metrics CSV and summary table. |

## Current Workflow Notes

### DIC Preprocess App

`labkit_DICPreprocess_app` performs manual point matching directly in its main
stacked preview. Start point matching, select a reference feature followed by
the corresponding moving-image feature, and repeat for at least two pairs.
Points can be dragged to refine them, the most recent pair can be undone, and
applying the alignment immediately switches the main preview to the false-color
registration overlay. Point matching can be cancelled without changing the
current working image pair.

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

### Gait Analysis App

`labkit_GaitAnalysis_app` analyzes pose-coordinate tables after keypoints have
already been tracked or manually marked. It accepts generic wide coordinate
CSV/TSV/TXT files, LabKit coordinate CSV shapes with `point__x` and `point__y`
columns, and MAT pose files with `coords` plus `pointNames`.

Users map the iliac, hip, knee, ankle, and foot roles, optionally set frame
rate, scale calibration, and whether exported coordinates should use the first
frame's first point as the origin, tune smoothing and step-detection
thresholds, and then run the analysis. The app detects contact/lift-off events
from foot motion relative to the hip, computes hip/knee/ankle angles, bone
segment lengths, per-step point translations, stride length, step time, and
angle ROM. Exports are plain CSV files for frame metrics, coordinates, step
metrics, and a compact summary table. The coordinate CSV keeps raw
`point__x_px`/`point__y_px` columns for overlay or editing and writes
scaled/origin-shifted `point__x`/`point__y` columns for plotting in external
programs.

### Video Marker App

`labkit_VideoMarker_app` starts with a visual skeleton setup. Users can apply
an editable preset, including the legacy five-point leg chain, or add and
rename ordered keypoints in a table. They can then reorder or remove selected
points and create connections from endpoint selectors that exclude self-links.
An additional action connects every adjacent pair in the current point order.
A new annotation session cannot begin until at least one keypoint exists, and
the skeleton is locked after the video opens. The video picker remains
available from an empty setup so matching autosave data can restore its own
skeleton definition.

Point marking is continuously active while a video is open: a blank click adds
the next ordered keypoint, dragging a displayed point refines it, and moving to
another frame saves the current coordinates automatically. A complete edited
frame is a manual anchor. Moving forward predicts every ordered point with
cropped pyramidal KLT tracking and forward/backward reliability checks; a
constant-velocity estimate is used only for rejected points. Predicted frames
remain editable drafts, and dragging any point turns that complete frame into
a new manual anchor for subsequent prediction. Jumping forward propagates
through intermediate frames and preserves existing manual anchors.
`New setup (clear current)` starts
a different skeleton definition without retaining the current annotation
session. Frame navigation preserves the current zoomed ROI; opening a new
video or project starts from its home view. Marker CSV remains the round-trip editing format, while coordinate CSV
is the plotting-oriented export with optional calibration and origin choices.

Prediction is part of forward frame navigation rather than a separate Track or
Interpolate command. The implementation uses MATLAB's KLT point tracker when
available and does not install third-party packages or download model assets.
The intended workflow is short automatic propagation followed by occasional
human correction, not unattended long-term tracking through arbitrary
occlusion.

After a video session starts, durable annotation changes are atomically saved
to `Video Marker Autosaves` under the source video's folder. These visible MAT
files use the same project payload as explicit project saves, so they can be
backed up or opened manually. Both payloads store a portable video reference:
the path relative to the MAT file is preferred, with the original path and
same-folder filename as fallbacks. This lets a synchronized project/video
directory tree move between Google Drive roots, users, and operating systems.
If no candidate exists or the saved reference is malformed, project open asks
the user to locate the source video without discarding the skeleton or
annotations. Reopening the video detects its adjacent recovery data and asks
whether to restore it or start a new session. Starting a new setup or declining
recovery discards that video's autosave; explicit project saves and CSV exports
remain separate outputs.

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
apps/<family>/<app_slug>/+<app_slug>/+appLifecycle/createProject.m
apps/<family>/<app_slug>/+<app_slug>/+appLifecycle/createSession.m
apps/<family>/<app_slug>/+<app_slug>/+appLifecycle/validateProject.m
apps/<family>/<app_slug>/+<app_slug>/+userInterface/buildWorkbenchLayout.m
apps/<family>/<app_slug>/+<app_slug>/+userInterface/presentWorkbench.m
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
created with `labkit.ui.runtime.define`, naming the app id, title, project
schema, optional session factory, data-only workbench layout builder, handler
registry, presenter, prepared-data renderers, and optional `Start` event. The
framework validates the definition, generates callbacks, queues events,
commits presentation, gates busy/ready state, and routes diagnostics. App code should not
own loading controls, startup timers, callback wrappers, or framework
readiness flags.

For nontrivial apps, `+userInterface/buildWorkbenchLayout.m` should make the
page hierarchy obvious at the top of the file. Keep the app constructor
shallow, then use local builder functions for tabs, sections, and the
workspace. Put section builders in the same order the user sees them, and keep
small field helpers after the workspace builder. The goal is readable MATLAB
source, not a separate UI-generation DSL. `+userInterface/presentWorkbench.m`
is the single pure bridge from canonical state to semantic control properties,
prepared preview models, and controlled interaction specs.

Keep one visible structure per concept. Do not keep both singular and
directory forms for the same concept (`sourceFiles.m` plus `+sourceFiles/`,
`analysisRun.m` plus `+analysisRun/`, or `resultFiles.m` plus
`+resultFiles/`). When a workflow grows, add specific files inside that
workflow package instead of creating parallel technical buckets.

Use the app slug as the package name. Do not use a shared `+app` namespace.
Do not add family-level `private/` helper folders.

## App Definition And Helper Shape

The app definition is the runtime boundary. It names the project schema,
optional session factory, UI layout, registered handlers, presenter,
renderers, and optional `Start`. The framework owns lifecycle orchestration:
launch/debug wiring, callback adapters, queueing, readiness, busy gating, close guards, and
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

Presenters translate canonical state into semantic properties and prepared
preview models. They should not perform file IO, heavy computation, export
writes, mutate state, or receive raw UI handles.
`+userInterface/buildWorkbenchLayout.m` declares the control/workspace tree;
registered renderers draw only the prepared models they receive.

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
