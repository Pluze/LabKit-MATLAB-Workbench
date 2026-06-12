# Apps

LabKit apps are independent MATLAB GUI tools for concrete lab workflows. Each app should remain directly launchable and useful on its own. Shared UI, DTA, and biosignal helpers reduce boilerplate, but the scientific workflow belongs to the app that presents it.

## Startup

From MATLAB:

```matlab
labkit_launcher
```

This opens a single-file app selector that initializes the LabKit path, scans
`apps/**/labkit_*_app.m`, and launches the selected app. Apps remain directly
launchable by command name. For scripted setup without opening the selector,
run:

```matlab
startup_labkit
```

Startup adds the repository root, `apps/`, and nested app category folders to the MATLAB path.
MATLAB package folders below app folders, such as
`apps/image_measurement/batch_crop/+batch_crop/`, are not added as direct path
entries; they are resolved through their owning app folder.

Users who want MATLAB Project features can create a local project file:

```matlab
run("scripts/create_local_matlab_project.m")
```

`LabKit.prj` and `resources/project/` are local IDE metadata and are not part of
the repository contract.

## Current Apps

| App | Status | Purpose | Input | Typical output |
| --- | --- | --- | --- | --- |
| `labkit_CIC_app` | routine | CIC and voltage-transient metrics. | Chrono DTA | Results table and CSV. |
| `labkit_VTResistance_app` | routine | Steady resistance estimates from voltage transients. | Chrono DTA | Resistance table and CSV. |
| `labkit_CSC_app` | routine | CV/CT charge integration and CSC comparison. | CV/CT DTA | Plots and comparison values. |
| `labkit_EIS_app` | routine | EIS curve overlay and export. | EIS ZCURVE DTA | Plot and CSV. |
| `labkit_ChronoOverlay_app` | routine | Chrono voltage/current overlay. | Chrono DTA | Overlay plots and CSV. |
| `labkit_DICPreprocess_app` | active | Image registration, paired crop preparation, and ROI mask drawing. | Reference/current images | Aligned images, crop PNGs, ROI mask. |
| `labkit_DICPostprocess_app` | active | Ncorr strain overlay, ROI summary, and colorbar export. | Ncorr MAT, reference image, mask | EXX/EYY overlays, summary CSV, colorbar/level table. |
| `labkit_CurvatureMeasurement_app` | experimental | Editable image-curve circle fit, calibrated real-unit scale-bar placement, and curve length measurement. | Image | Overlay PNG and curvature/length CSV. |
| `labkit_FocusStack_app` | experimental | Microscope focus-stack fusion into one all-in-focus image. | Focus image folder or selected image files | Fused PNG, focus map PNG, summary CSV. |
| `labkit_ImageEnhance_app` | experimental | Stepwise brightness, contrast, clarity, color, and white-balance processing for figure images. | Image files | Enhanced images and processing manifest CSV. |
| `labkit_ImageMatch_app` | experimental | Reference-based white-balance, tone, Lab color-style, and histogram matching for figure images. | Image files | Matched images and processing manifest CSV. |
| `labkit_BatchImageCrop_app` | experimental | Batch fixed-size microscope image crops with per-image crop center and rotation. | Microscope image files | Cropped images and crop manifest CSV. |
| `labkit_ECGPrint_app` | experimental | ECG waveform preview, ROI filtering, peak/segment SNR, and SNR-over-time display. | MAT timetable or CSV/TSV table | Segment SNR CSV and waveform PNG. |
| `labkit_TemplateApp_app` | template | Starter canvas showing the current UI 2.0 app structure. | Synthetic placeholder state | Example controls, preview, summary, and log. |

Status labels:

| Status | Meaning |
| --- | --- |
| `routine` | Current daily-use workflow with established behavior. |
| `active` | Current workflow still being refined through real use. |
| `experimental` | Newer utility or workflow under evaluation. |
| `archived` | Kept for reference, not part of normal use. |
| `template` | Developer-facing starter app that demonstrates current app structure and UI APIs. |

## App Families

Electrochemistry apps live under `apps/electrochem/` and use the DTA facade for Gamry file discovery, loading, sessions, parsed curve access, and pulse detection.

DIC apps live under `apps/dic/`. They use the shared GUI shell and interaction runtime while keeping registration, crop geometry, Ncorr MAT extraction, strain overlays, summaries, and exports in the owning app files.

Image measurement apps live under `apps/image_measurement/`. They are separate from DIC because their workflows are general image measurements or image-processing utilities rather than DIC preprocessing or strain postprocessing.

Wearable biosignal apps live under `apps/wearable/`. They use the biosignal facade for recording loading, channel extraction, time ROI, filtering, events, segments, templates, and measurements, while the app owns workflow wording, plot layout, import controls, and export choices.

Template apps live under `apps/templates/`. They are launchable examples for
starting new LabKit apps and should demonstrate current app structure without
owning scientific workflow logic.

## App Ownership

The app owns:

- accepted input kind and parser requirements
- option defaults and controls
- domain logic and result fields
- plot labels, annotations, and interaction choices
- summary text
- result table columns and export formatting
- failed-row behavior
- callback ordering, alerts, and log wording

Every public app entry point should preserve its launch name and route debug
launch requests through `labkit.ui.app.dispatchRequest`. App GUIs build from
`labkit.ui.app.create` and `labkit.ui.spec.*`. Debug launches should keep
visible debug trace wired into the Log tab. Image apps with drawing, scale
bars, ROI, or preview scroll should pass a `labkit.ui.tool.createRuntime`
result into reusable tools instead of owning figure pointer callbacks directly.

When a documented UI tool owns app-neutral interaction mechanics, the app should consume that tool and keep workflow meaning, summaries, and exports app-local. `docs/architecture.md` owns the reusable-library extraction rule and temporary debt inventory.

## App File Shape

New lab apps should start as explicit public entry points under `apps/<category>/`
or `apps/<category>/<app_slug>/` when the app needs extracted helpers. A small
app may remain a single file. When helper extraction is needed, use an app-owned
package whose name matches the app folder slug:

```text
apps/<family>/<app_slug>/labkit_<AppName>_app.m
apps/<family>/<app_slug>/+<app_slug>/+ui/
apps/<family>/<app_slug>/+<app_slug>/+state/
apps/<family>/<app_slug>/+<app_slug>/+ops/
apps/<family>/<app_slug>/+<app_slug>/+view/
apps/<family>/<app_slug>/+<app_slug>/+export/
apps/<family>/<app_slug>/+<app_slug>/+io/
```

Create component packages only when the app has code for that responsibility.
Use the app slug package name, not a fixed `+app` namespace, so MATLAB package
resolution cannot mix helpers from sibling apps.

For UI 2.0 migrated apps, put the data-only workbench spec in
`+<app_slug>/+ui/buildSpec.m` and keep ordinary controls declarative. The public
entry point, or the app-owned orchestration runner it delegates to when the
public file is a thin dispatch wrapper, owns state, callbacks, alerts, log
wording, and refresh order. That orchestration source should call
`<app_slug>.ui.buildSpec(...)` followed by `labkit.ui.app.create(...)`.
`docs/architecture.md` owns the detailed component package role boundaries.

A typical single-file order before extraction is:

```text
1. Entry validation and optional debug launch hook
2. App state and GUI construction
3. Nested callbacks for file/session actions
4. Nested refresh/render/export callbacks that touch UI handles
5. End of the public app function
6. App-local domain functions
7. App-local table/export functions
8. App-local plotting annotation helpers
9. Small formatting, parsing, interpolation, and numeric utilities
```

Nested functions may read and update GUI handles or app state. Local functions
after the app `end` should be GUI-free when practical; extracted app-owned
package helpers give focused tests direct access without adding reusable
`+labkit` APIs.

The preferred public shape is one launchable app entry point per workflow. The
entry point owns GUI state, callbacks, user alerts, workflow ordering, debug
launch routing, and user-facing log wording. Extracted package helpers should
own focused responsibilities: control construction in `+ui`, state/result
defaults in `+state`, deterministic calculations and image/signal transforms in
`+ops`, display/table formatting in `+view`, CSV/image output builders in
`+export`, and dialog/file normalization in `+io`.

Do not add new string-dispatch workflow adapters such as `*Workflow.m` for
tests. Tests should call the app-owned package function that owns the behavior.
Use `apps/<family>/private/` only for helpers that are genuinely shared by
multiple apps in that family and are not ready for a reusable `+labkit` facade.
DIC apps now use app-owned packages rather than family-level `private/`
helpers. Do not add app-owned `+core/dispatch.m` string routers to new app work.

For active runner and app-private debt migrations, use
`../.agents/migration_guide.md` as the agent-facing roadmap. This document only
describes the preferred app shape and current app behavior.

## New App Checklist

Define these before adding controls or helpers:

```text
1. Accepted input kind and parser/data requirements
2. Session or loaded item shape
3. Domain options and defaults
4. Domain result fields
5. Plot axes, labels, and annotations
6. Summary fields shown in the GUI
7. Result table columns and units
8. Export format and failed-row behavior
9. Validation fixture or synthetic test case
10. GUI shell spec, debug trace behavior, and file-selection mode
```

Start from the closest existing app, reduce it to the needed workflow, and
preserve ownership boundaries. For new app UI, prefer
`labkit.ui.app.create` with `labkit.ui.spec.*` even for small apps so daily
interaction stays consistent across app families. Do not copy old manual
layout into new code.

For a blank starting point, copy `apps/templates/starter_app/`, rename the
public command, folder slug, and package namespace, then replace the synthetic
state and display helpers with the new workflow's state, calculations, plots,
exports, and tests.

## Validation

Pure app calculations, export table construction, and plotting helpers belong
in app-family build tasks. Use GUI tasks for noninteractive launch/layout
checks. See `docs/testing.md` for the canonical task names and pairings.

Interactive file selection, drawing, visual inspection, and full workflow feel are validated manually in MATLAB app windows.

## Current App Notes

| App | App-owned behavior | Export notes |
| --- | --- | --- |
| `labkit_ChronoOverlay_app` | Pulse-gap alignment, overlay plotting, and overlay export table construction. | Overlay CSV/plot exports stay app-local. |
| `labkit_EIS_app` | Axis-value generation, overlay plotting, and plot-export table construction. | Export table construction stays app-local. |
| `labkit_CSC_app` | CT/CV charge integration and comparison display. | No CSV export workflow currently. |
| `labkit_VTResistance_app` | Steady-window selection, baseline estimation, and resistance result tables. | VT CSV columns are guarded by app tests. |
| `labkit_CIC_app` | CIC, voltage-transient metrics, water-window status, and batch display tables. | CIC CSV columns are guarded by app tests. |
| `labkit_DICPreprocess_app` | Registration, repeated crop/align workflow, false-color preview, inline crop ROI, and binary ROI mask drawing. | Exports current image pair, crop PNGs, and white-inside/black-outside ROI masks. |
| `labkit_DICPostprocess_app` | Ncorr MAT extraction, EXX/EYY overlays, ROI summary, optical enhancement controls, and strain colorbar levels. | Exports overlays, summary CSV, and colorbar/level files. |
| `labkit_CurvatureMeasurement_app` | Curve-point workflow, circle fitting, curvature conversion, curve length measurement, dense-point display, residual annotations, result summaries, and CSV/overlay export schemas. It consumes reusable UI tools for generic anchor editing and scale-bar mechanics. | Exports overlay PNG and curvature/length CSV. |
| `labkit_FocusStack_app` | Folder or selected-file focus sequence loading, optional registration to the middle image, preset-guided Laplacian-pyramid focus fusion, user-facing detail/blend controls, and focus-depth preview. | Exports fused PNG, colorized focus map PNG, and per-source focus coverage CSV. |
| `labkit_ImageEnhance_app` | Multi-image figure enhancement, ordered non-destructive step history, undo/reset, brightness/contrast, local contrast, sharpening, hue/saturation, gray-world white balance, and batch export. | Exports enhanced image files plus a manifest CSV with source/output path, status, output size, and step count. |
| `labkit_ImageMatch_app` | Multi-image reference matching with ordered history, undo/reset, balanced matching, white-balance matching, tone-only matching, Lab style matching, histogram matching, and batch export. | Exports matched image files plus a manifest CSV with source/output path, status, output size, and step count. |
| `labkit_BatchImageCrop_app` | Selected-file microscope image loading, fixed global crop width/height, per-image rotation, per-image crop-center confirmation on a rotated preview canvas, and exact-pixel crop generation without resizing. | Exports unique cropped image files and a crop manifest CSV with source/output paths, rotation, center, output size, canvas size, and status. |
| `labkit_ECGPrint_app` | CSV/MAT import parsing, channel/ROI selection, padded filtering before ROI crop, ECG peak detection, segments, template, and SNR-over-time plots. | Exports per-segment SNR CSV and waveform PNG. Multi-file/class statistics belong in a separate wearable stats app. |
| `labkit_TemplateApp_app` | Developer-facing starter canvas for current UI 2.0 app structure, including app entrypoint, package-root runner, data-only `buildSpec`, semantic view updates, preview area, result table, log panel, and debug trace. | No scientific export workflow; copy it as a starting point and replace the placeholder state with real app-owned behavior. |
