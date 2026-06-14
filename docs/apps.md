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
actions to launch the selected app in debug mode, open Project Governance, and
clean LabKit-generated artifacts. If you already know the command, launch it
directly:

```matlab
labkit_CIC_app
labkit_DICPreprocess_app
labkit_ImageEnhance_app
labkit_ECGPrint_app
```

The cleanup action removes `artifacts/` plus legacy root diagnostic files named
`matlab_code_check.json` or `matlab_test*.log`. It does not remove source code,
docs, tests, photos, or derived data folders.

For path setup without opening the launcher:

```matlab
startup_labkit
```

`startup_labkit` adds the repository root, `apps/`, and app folders to the
MATLAB path. It does not add app-owned package folders such as
`apps/image_measurement/batch_crop/+batch_crop/` as direct path entries.

## App Catalog

| Command | Family | Purpose | Inputs | Typical outputs |
| --- | --- | --- | --- | --- |
| `labkit_ChronoOverlay_app` | Electrochemistry | Chrono voltage/current overlay. | Chrono DTA | Overlay plots and CSV. |
| `labkit_CIC_app` | Electrochemistry | CIC and voltage-transient metrics. | Chrono DTA | Results table and CSV. |
| `labkit_VTResistance_app` | Electrochemistry | Steady resistance estimates from voltage transients. | Chrono DTA | Resistance table and CSV. |
| `labkit_CSC_app` | Electrochemistry | CV/CT charge integration and CSC comparison. | CV/CT DTA | Plots and comparison values. |
| `labkit_EIS_app` | Electrochemistry | EIS curve overlay and export. | EIS ZCURVE DTA | Plot and CSV. |
| `labkit_DICPreprocess_app` | DIC | Image registration, paired crop preparation, and ROI mask drawing. | Reference/current images | Aligned images, crop PNGs, ROI mask. |
| `labkit_DICPostprocess_app` | DIC | Ncorr strain overlay, ROI summary, and colorbar export. | Ncorr MAT, reference image, mask | EXX/EYY overlays, summary CSV, colorbar files. |
| `labkit_CurvatureMeasurement_app` | Image measurement | Editable curve fit, calibrated scale bar, curvature, and length. | Image | Overlay PNG and curvature/length CSV. |
| `labkit_FocusStack_app` | Image measurement | Focus-stack fusion into one all-in-focus image. | Image folder or selected image files | Fused PNG, focus map PNG, summary CSV. |
| `labkit_ImageEnhance_app` | Image measurement | Brightness, contrast, clarity, color, and white-balance processing. | Image files | Enhanced images and manifest CSV. |
| `labkit_ImageMatch_app` | Image measurement | Reference-based tone, white-balance, Lab style, and histogram matching. | Image files | Matched images and manifest CSV. |
| `labkit_BatchImageCrop_app` | Image measurement | Fixed-size batch microscope crops with per-image center and rotation. | Microscope images | Cropped images and crop manifest CSV. |
| `labkit_ECGPrint_app` | Wearable biosignal | ECG waveform preview, ROI filtering, peak/segment SNR, and SNR-over-time display. | MAT timetable or CSV/TSV table | Segment SNR CSV and waveform PNG. |
| `labkit_ProjectGovernance_app` | Project tools | Create app scaffolds and scan MATLAB project code. | Scaffold options or repository code | New app files or `artifacts/code-check/matlab_code_check.json`. |

## Creating A New App

Run:

```matlab
labkit_ProjectGovernance_app
```

Use the app's `Create app` workflow. The fields mean:

| Field | Meaning | Example |
| --- | --- | --- |
| Family folder | First folder under `apps/`. Choose the domain or tool family. | `image_measurement` |
| App slug | Lowercase folder and package name. Use `lower_snake_case`. | `surface_roughness` |
| Public command | MATLAB function users call. Leave blank to generate it from the slug. | `labkit_SurfaceRoughness_app` |
| Window label | Human-readable title for the generated app window. | `Surface Roughness` |

The preview shows the files that will be created. The generated app is
ordinary MATLAB code; edit it directly after creation.

For command-line use, call the same app-owned operation after `startup_labkit`:

```matlab
startup_labkit
project_governance.ops.createLabKitApp("Family","image_measurement", ...
    "Slug","surface_roughness", ...
    "Label","Surface Roughness")
```

## App File Shape

Generated and migrated apps use this shape:

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
+io/       app-local readers, filters, file normalization
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

## Project Governance App

`labkit_ProjectGovernance_app` has two primary jobs:

- Create new app scaffolds directly from the governance app generator.
- Scan project MATLAB files with Code Analyzer and write
  `artifacts/code-check/matlab_code_check.json`.

It also exposes local MATLAB Project creation as a maintenance action. The
tracked repository does not include `LabKit.prj` or `resources/project/`;
those files are local IDE state. `scripts/` does not contain MATLAB governance
entry points; the implementation lives in
`apps/project/governance/+project_governance/+ops`.

## Validation

For app helper logic, use focused non-GUI selectors such as:

```matlab
runLabKitTests("Suites", "apps/image_measurement", "IncludeGui", false)
```

For app layout or launch changes, use GUI selectors or build tasks:

```bash
buildtool testAppsGui
```

Automated GUI tests check launch, layout, callback wiring, and debug trace
plumbing. They do not replace manual workflow review in MATLAB.
