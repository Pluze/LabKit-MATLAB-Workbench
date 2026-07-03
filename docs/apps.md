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
| `labkit_CSC_app` | Electrochemistry | CV/CT charge integration and CSC comparison. | CV/CT DTA | Plots and comparison values. |
| `labkit_EIS_app` | Electrochemistry | EIS curve overlay and export. | EIS ZCURVE DTA | Plot and CSV. |
| `labkit_DICPreprocess_app` | DIC | Image registration, paired crop preparation, and ROI mask drawing. | Reference/current images | Aligned images, crop PNGs, ROI mask. |
| `labkit_DICPostprocess_app` | DIC | Ncorr strain overlay and MAT-domain strain summary. | Ncorr MAT, reference image, mask | Clean same-size EXX/EYY overlay PNGs and summary CSV. |
| `labkit_CurvatureMeasurement_app` | Image measurement | Editable curve fit, calibrated scale bar, curvature, and length. | Image | Overlay PNG and curvature/length CSV. |
| `labkit_FocusStack_app` | Image measurement | Focus-stack fusion into one all-in-focus image. | Image folder or selected image files | Fused PNG, focus map PNG, summary CSV. |
| `labkit_ImageEnhance_app` | Image measurement | Brightness, contrast, clarity, color, and white-balance processing. | Image files | Enhanced images and manifest CSV. |
| `labkit_ImageMatch_app` | Image measurement | Reference-based tone, white-balance, Lab style, and histogram matching. | Source image files and separate reference image | Matched images and manifest CSV. |
| `labkit_BatchImageCrop_app` | Image measurement | Fixed-size batch microscope crops with edge-continuous padding, rotation, duplicate crop tasks, responsive downsampled preview rendering, and optional per-image physical scale normalization with independent crop and calibration units. | Microscope images, optional scale calibration per image | Cropped same-size images and crop manifest CSV. |
| `labkit_FLIRThermal_app` | Image measurement | FLIR radiometric JPEG/RJPEG thermal postprocessing with per-image display ranges, range-bound presets, clean heatmap rendering, and scale bars. | FLIR radiometric image files | Thermal image exports, colorbar PNGs, and manifest CSV. |
| `labkit_ECGPrint_app` | Wearable biosignal | ECG waveform preview, ROI filtering, peak/segment SNR, and SNR-over-time display. | MAT timetable or CSV/TSV table | Segment SNR CSV and waveform PNG. |
| `labkit_RHSPreview_app` | Neurophysiology | Intan RHS header inspection, stacked waveform preview, ROI zooming, channel protocol drafting, and manual folder filtering. | RHS file, RHS folder, and optional protocol JSON | Header summary, preview window, channel protocol JSON, and filter record JSON. |
| `labkit_NerveResponseAnalysis_app` | Neurophysiology | Filter-record-driven event train detection, differential response derivation, common-mode correction, and CAP metrics. | Filter record JSON and recommended protocol JSON | Analysis JSON with events, trains, metrics, and issues. |
| `labkit_ResponseReviewStats_app` | Neurophysiology | Immediate metric loading, aligned response segment review, and descriptive statistics from analysis metrics or legacy segment CSV. | Analysis JSON or segment CSV | Metrics CSV and summary table. |

## Creating A New App

Create new apps from a LabKit app template instead of copying an existing app
folder. The template should generate the public entrypoint, version metadata,
runtime adapter files, a small author-facing source layout, debug sample-pack
stub, and focused starter tests.

Use the smallest nearby app only as a workflow reference. Do not copy its
directory shape wholesale. Replace state, actions, result tables, plots, and
exports with the new app's real behavior. New apps launch through the framework
app-definition runtime instead of package-root runners.

## App File Shape

LabKit separates the author-facing source shape from the MATLAB package shape
required by the runtime.

The author-facing shape is the part app authors should read and edit first:

```text
apps/<family>/<app_slug>/labkit_<AppName>_app.m
apps/<family>/<app_slug>/app.m
apps/<family>/<app_slug>/ui.m
apps/<family>/<app_slug>/model.m
apps/<family>/<app_slug>/actions.m
apps/<family>/<app_slug>/render.m
apps/<family>/<app_slug>/ops/
apps/<family>/<app_slug>/io/
apps/<family>/<app_slug>/export/
apps/<family>/<app_slug>/debug/
```

Small apps can keep `actions.m` and `render.m` as single files. Larger apps can
expand only the roles they need:

```text
actions/files.m
actions/edit.m
actions/analyze.m
actions/tools.m
actions/export.m
views/summary.m
views/plots.m
views/preview.m
views/controls.m
```

The runtime adapter shape is generated by the template or kept as thin bridge
code while the current MATLAB package runtime is in use:

```text
apps/<family>/<app_slug>/+<app_slug>/definition.m
apps/<family>/<app_slug>/+<app_slug>/requirements.m
apps/<family>/<app_slug>/+<app_slug>/version.m
apps/<family>/<app_slug>/+<app_slug>/+state/initial.m
apps/<family>/<app_slug>/+<app_slug>/+actions/table.m
apps/<family>/<app_slug>/+<app_slug>/+ui/buildSpec.m
apps/<family>/<app_slug>/+<app_slug>/+view/render.m
```

Authors should think in terms of `app`, `ui`, `model`, `actions`, `render`,
and optional `ops/io/export/debug` roles. The `+<app_slug>` adapter exists to
connect that source to MATLAB package resolution and `labkit.ui.app.run`.

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

`app.m` and the generated `definition.m` together declare the app's runtime
contract. The generated adapter returns a plain struct created with
`labkit.ui.app.define`, naming the app id, title, initial state factory,
data-only UI spec builder, action table, render function, startup phases, and
optional idle hydration phases. The framework runtime validates the definition,
generates callbacks, schedules startup, gates busy/ready state, and routes
diagnostics. App code should not own loading controls, startup timers, callback
wrappers, or framework readiness flags.

For nontrivial apps, `ui.m` should make the page hierarchy obvious at the top
of the file. Keep the app constructor shallow, then use local builder
functions for tabs, sections, and the workspace. Put section builders in the
same order the user sees them, and keep small field helpers after the workspace
builder. The generated `+ui/buildSpec.m` adapter can call this author-facing
UI declaration. The goal is readable MATLAB source, not a separate
UI-generation DSL.

Create optional role packages only when the app has code for that role:

```text
+state/    defaults, factories, presets
+io/       app-local file discovery, workflow-specific readers, and import parsing
+ops/      GUI-free calculations and transforms
+view/     table rows, detail text, display-ready data
+export/   CSV/image output writers and manifests
```

Use the app slug as the package name. Do not use a shared `+app` namespace.
Do not add family-level `private/` helper folders.

## App Definition And Helper Shape

The app definition is the runtime boundary. It names state, actions, render,
spec, startup, and hydration. The framework owns lifecycle orchestration:
launch/debug wiring, callback adapters, readiness, busy gating, close guards,
startup phase timing, and hidden-test-safe diagnostics.

Actions own app-specific workflow transitions. They should be named by user
intent or startup phase, update app-owned state, call app-owned IO/ops/export
helpers as needed, and request framework effects such as alerts, logs,
prompts, render refresh, busy text, or idle work. App actions should not reach
behind the runtime to manipulate MATLAB timers, appdata readiness flags,
loading controls, or generated callback wrappers.

Render helpers own the translation from prepared app state into existing UI
handles. They should not perform file IO, heavy computation, export writes, or
state mutation. `buildSpec.m` declares the control/workspace tree, while
`+view/render.m` updates that tree from state.

Keep small code local when the call site is clearer than a separate name. Move
code into app-owned role packages when it owns deterministic state, IO
normalization, file discovery, GUI-free operations, export output, display
data, or focused custom UI/tool glue that can be tested or reused by the real
app path.

When an action table, render helper, or role package grows dense, choose one
substantial responsibility to move or one reusable workflow hook to extract.
Do not create short pass-through helpers solely to lower the line count. See
[architecture.md](architecture.md#extraction-quality) for the reusable
extraction rule and helper-quality principles.

## Task Lifecycle

Apps with preview, edit, run, or export workflows should keep task lifecycle
state explicit. Runner code may track dirty flags, small preview caches, and
the last successful task fingerprint, but GUI-free helpers own deterministic
task snapshots under the app package, usually in `+state`.

Image apps should use `labkit.image` for generic image filters, path
normalization, display names, reads/writes, RGB double conversion, preview
resizing, mean filtering, and basic enhancement primitives. Thermal image apps
should use `labkit.thermal` for radiometric source parsing, raw thermal
matrices, temperature conversion, and thermal palette rendering. Keep app-owned
readers when they build app item structs or enforce workflow-specific state.

Use this boundary:

- `+state` builds immutable task snapshots and fingerprints from inputs,
  options, and committed steps.
- `+ops` performs deterministic computation without GUI or file side effects.
- `+export` writes outputs from an explicit task/options boundary.
- preview actions operate on the current selection and display-resolution
  data when practical; full batch work happens at export or run actions.

File selection should register files and build app-owned task state with the
least data needed for the immediate preview. For large selections, avoid
eagerly reading or computing every file in the chooser action unless the
workflow truly cannot show a useful first state without the full batch. For
example, a crop workflow can keep path-only crop tasks until the current preview
or export needs pixels.

The UI framework prevents duplicate action submission. Apps decide what
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
