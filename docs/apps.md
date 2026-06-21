# Apps

LabKit apps are independent MATLAB GUI tools for concrete lab workflows. Each
app should be useful on its own, with a stable public launch command and
app-owned workflow logic.

## Launching Apps

From the repository root in MATLAB:

```matlab
labkit_launcher
```

The launcher initializes the LabKit path, discovers
`apps/**/labkit_*_app.m`, and opens the selected app. It also provides direct
actions to launch the selected app in debug mode, run MATLAB Code Analyzer,
and clean LabKit-generated artifacts. If you already know the command, launch
it directly:

```matlab
labkit_CIC_app
labkit_DICPreprocess_app
labkit_ImageEnhance_app
labkit_ECGPrint_app
labkit_RHSPreview_app
labkit_NerveResponseAnalysis_app
labkit_ResponseReviewStats_app
```

The cleanup action targets generated LabKit artifacts: `artifacts/` plus older
root-level diagnostic files named `matlab_code_check.json` or
`matlab_test*.log`.

The Code Analyzer action writes
`artifacts/code-check/matlab_code_check.json` for manual maintenance review.

The launcher sets up the app path before opening an app. App-owned packages are
reached through their owning app entrypoint and package namespace.

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
| `labkit_ImageMatch_app` | Image measurement | Reference-based tone, white-balance, Lab style, and histogram matching. | Image files | Matched images and manifest CSV. |
| `labkit_BatchImageCrop_app` | Image measurement | Fixed-size batch microscope crops with duplicate crop tasks for multiple regions in one source image. | Microscope images | Cropped images and crop manifest CSV. |
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
apps/<family>/<app_slug>/+<app_slug>/run.m
apps/<family>/<app_slug>/+<app_slug>/+ui/buildSpec.m
```

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
