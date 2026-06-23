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
installed. Use `Latest` to download the current `main` branch or `Release` to
download the latest stable release. After LabKit is present, the launcher
initializes the MATLAB path, discovers app entry points, and opens the selected
app.

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
Code Analyzer actions for maintenance work. Cleanup targets generated LabKit
artifacts: `artifacts/` plus older root-level diagnostic files named
`matlab_code_check.json` or `matlab_test*.log`.

The Code Analyzer action writes
`artifacts/code-check/matlab_code_check.json` for manual maintenance review.

The launcher sets up the app path before opening an app. App-owned packages are
reached through their owning app entrypoint and package namespace.

The launcher refuses updates when the LabKit folder contains unmanaged
non-LabKit files. Keep lab data and exports outside the LabKit runtime folder.
If a release removes or merges app entrypoints, the launcher warns before
overwriting managed files; users who need old entrypoints should choose an older
release tag manually.

## App Catalog

| Command | Family | Purpose | Inputs | Typical outputs |
| --- | --- | --- | --- | --- |
| `labkit_ChronoOverlay_app` | Electrochemistry | Chrono voltage/current overlay. | Chrono DTA | Overlay plots and CSV. |
| `labkit_CIC_app` | Electrochemistry | CIC and voltage-transient metrics. | Chrono DTA | Results table and CSV. |
| `labkit_VTResistance_app` | Electrochemistry | Steady resistance estimates from voltage transients. | Chrono DTA | Resistance table and CSV. |
| `labkit_CSC_app` | Electrochemistry | CV/CT charge integration and CSC comparison. | CV/CT DTA | Plots and comparison values. |
| `labkit_EIS_app` | Electrochemistry | EIS curve overlay and export. | EIS ZCURVE DTA | Plot and CSV. |
| `labkit_DICPreprocess_app` | DIC | Image registration, paired crop preparation, and ROI mask drawing. | Reference/current images | Aligned images, crop PNGs, ROI mask. |
| `labkit_DICPostprocess_app` | DIC | Ncorr strain overlay and MAT-domain strain summary. | Ncorr MAT, reference image, mask | Clean same-size EXX/EYY overlay PNGs and summary CSV. |
| `labkit_CurvatureMeasurement_app` | Image measurement | Editable curve fit, calibrated scale bar, curvature, and length. | Image | Overlay PNG and curvature/length CSV. |
| `labkit_FocusStack_app` | Image measurement | Focus-stack fusion into one all-in-focus image. | Image folder or selected image files | Fused PNG, focus map PNG, summary CSV. |
| `labkit_ImageEnhance_app` | Image measurement | Brightness, contrast, clarity, color, and white-balance processing. | Image files | Enhanced images and manifest CSV. |
| `labkit_ImageMatch_app` | Image measurement | Reference-based tone, white-balance, Lab style, and histogram matching. | Source image files and separate reference image | Matched images and manifest CSV. |
| `labkit_BatchImageCrop_app` | Image measurement | Fixed-size batch microscope crops with edge-continuous padding, rotation, duplicate crop tasks, and optional per-image physical scale normalization. | Microscope images, optional scale calibration per image | Cropped same-size images and crop manifest CSV. |
| `labkit_ECGPrint_app` | Wearable biosignal | ECG waveform preview, ROI filtering, peak/segment SNR, and SNR-over-time display. | MAT timetable or CSV/TSV table | Segment SNR CSV and waveform PNG. |
| `labkit_RHSPreview_app` | Neurophysiology | Intan RHS header inspection, stacked waveform preview, ROI zooming, channel protocol drafting, and manual folder filtering. | RHS file, RHS folder, and optional protocol JSON | Header summary, preview window, channel protocol JSON, and filter record JSON. |
| `labkit_NerveResponseAnalysis_app` | Neurophysiology | Filter-record-driven event train detection, differential response derivation, common-mode correction, and CAP metrics. | Filter record JSON and recommended protocol JSON | Analysis JSON with events, trains, metrics, and issues. |
| `labkit_ResponseReviewStats_app` | Neurophysiology | Immediate metric loading, aligned response segment review, and descriptive statistics from analysis metrics or legacy segment CSV. | Analysis JSON or segment CSV | Metrics CSV and summary table. |

## Creating A New App

Create new apps directly in the standard app shape below. Use the smallest
nearby app as a reference when it shares the same workflow style, then replace
the state, callbacks, result tables, and exports with the new app's real
behavior.

## App File Shape

Apps use this shape:

```text
apps/<family>/<app_slug>/labkit_<AppName>_app.m
apps/<family>/<app_slug>/+<app_slug>/requirements.m
apps/<family>/<app_slug>/+<app_slug>/run.m
apps/<family>/<app_slug>/+<app_slug>/+ui/buildSpec.m
```

`requirements.m` declares only LabKit facade contract ranges. Public app
entrypoints return this struct for the lightweight `"requirements"` request and
check facade contracts before normal or debug launch. Apps do not declare their
own package metadata or solve dependencies.

For nontrivial apps, `buildSpec.m` should make the page hierarchy obvious at
the top of the file. Keep the app constructor shallow, then use local builder
functions for tabs, sections, and the workspace. Put section builders in the
same order the user sees them, and keep small field helpers after the workspace
builder. The goal is readable MATLAB source, not a separate UI-generation DSL.

Create optional role packages only when the app has code for that role:

```text
+state/    defaults, factories, presets
+io/       app-local file discovery, filters, readers, and import parsing
+ops/      GUI-free calculations and transforms
+view/     table rows, detail text, display-ready data
+export/   CSV/image output writers and manifests
```

Use the app slug as the package name. Do not use a shared `+app` namespace.
Do not add family-level `private/` helper folders.

## Task Lifecycle

Apps with preview, edit, run, or export workflows should keep task lifecycle
state explicit. Runner code may track dirty flags, small preview caches, and
the last successful task fingerprint, but GUI-free helpers own deterministic
task snapshots under the app package, usually in `+state`.

Use this boundary:

- `+state` builds immutable task snapshots and fingerprints from inputs,
  options, and committed steps.
- `+ops` performs deterministic computation without GUI or file side effects.
- `+export` writes outputs from an explicit task/options boundary.
- preview callbacks operate on the current selection and display-resolution
  data when practical; full batch work happens at export or run actions.

The UI framework prevents duplicate callback submission. Apps decide what
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
plumbing. They do not replace manual workflow review in MATLAB.
