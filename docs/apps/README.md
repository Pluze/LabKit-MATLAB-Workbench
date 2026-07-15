# Apps

LabKit apps are independent MATLAB GUI tools for concrete lab workflows. Each
app should be useful on its own, with a stable public launch command and
app-owned workflow logic.

## Launching Apps

For normal use, start from the single-file launcher linked in the root
[README](../../README.md). Put `labkit_launcher.m` in a standalone LabKit folder,
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
`LABKIT_PRIVATE_APP_ROOTS`. See [Private apps](../development/private-apps.md) for the
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
| `labkit_BatchImageCrop_app` | Image measurement | Fixed-size batch microscope crops with a highlighted draggable center handle, one-click center placement, edge-continuous padding, rotation, duplicate crop tasks, responsive downsampled preview rendering, and optional per-image physical scale normalization with independent crop and calibration units. | Microscope images, optional scale calibration per image | Cropped same-size images and crop manifest CSV. |
| `labkit_FLIRThermal_app` | Image measurement | FLIR radiometric JPEG/RJPEG thermal postprocessing with per-image display ranges, range-bound presets, linear/log/adjustable-gamma color mapping, clean heatmap rendering, and scale bars. | FLIR radiometric image files | Thermal image exports, colorbar PNGs, and manifest CSV. |
| `labkit_GaitAnalysis_app` | Gait | Pose-coordinate gait analysis with keypoint role mapping, smoothing, step-event detection, joint angles, translations, ROM, and QC previews. | Pose CSV/TSV/TXT or MAT coordinate files | Frame metrics CSV, coordinate CSV with raw pixel and scaled/origin-shifted columns, step metrics CSV, and summary CSV. |
| `labkit_ECGPrint_app` | Wearable biosignal | ECG waveform preview, ROI filtering, peak/segment SNR, and SNR-over-time display. | MAT timetable or CSV/TSV table | Segment SNR CSV and waveform PNG. |
| `labkit_RHSPreview_app` | Neurophysiology | Intan RHS header inspection, stacked waveform preview, ROI zooming, channel protocol drafting, and manual folder filtering. | RHS file, RHS folder, and optional protocol JSON | Header summary, preview window, channel protocol JSON, and filter record JSON. |
| `labkit_NerveResponseAnalysis_app` | Neurophysiology | Filter-record-driven event train detection, differential response derivation, common-mode correction, and CAP metrics. | Filter record JSON and recommended protocol JSON | Analysis JSON with events, trains, metrics, and issues. |
| `labkit_ResponseReviewStats_app` | Neurophysiology | Immediate metric loading, aligned response segment review, and descriptive statistics from analysis metrics or legacy segment CSV. | Analysis JSON or segment CSV | Metrics CSV and summary table. |

Electrochemistry analysis controls above a batch result table apply to the
whole loaded batch. CIC and VT Resistance decode the selected file for preview
and defer full-batch loading until export. Shared analysis settings are applied
consistently to every exported file. CIC delay values are microseconds after
each pulse end; delays outside the recorded time range fail instead of
extrapolating. CIC CSV exports include `Area_cm2` and `Delay_us` so the
normalization and sampling settings remain auditable.

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
It also reads explicit Video Marker project MAT files and their recovery or
autosave MAT files directly, extracting the saved skeleton names and frame
coordinates so users do not need to export an intermediate CSV first. Gait
analysis still owns its role mapping, frame-rate choice, and scale settings.

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
The `Session` section appears first in the Video tab and places `Open MAT`
beside `New setup`. `Open MAT` uses the same project loader as the window's
top-level `Load State` entry. `New setup` asks whether to cancel, save the
current project before starting, or discard it before starting a different
skeleton definition. Frame navigation preserves the current zoomed ROI; opening a new
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

## Related Documentation

- [Getting started](../getting-started/README.md)
- [App development](../development/app-development.md)
- [Public API reference](../api/README.md)
- [Testing](../development/testing.md)
