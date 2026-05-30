# Apps

Apps are the owning layer for domain-specific workflows. They compose `labkit.ui.*` and, when needed, `labkit.dta.*`, while keeping calculations, plotting decisions, displayed result fields, and export schemas local to the app file.

## Startup

From MATLAB:

```matlab
startup_labkit
```

This adds the repository root, `apps/`, and normal nested app category folders to the MATLAB path.

## Current Electrochemistry Apps

```text
labkit_CIC_app
labkit_VTResistance_app
labkit_CSC_app
labkit_EIS_app
labkit_ChronoOverlay_app
```

The current electrochemistry app bodies live under `apps/electrochem/`.

## Current DIC Apps

```text
labkit_DICPreprocess_app
labkit_DICPostprocess_app
```

The current DIC app bodies live under `apps/dic/`. They use `labkit.ui.*` for the shared GUI shell and keep image registration, crop geometry, Ncorr MAT extraction, strain overlays, summaries, and exports local to the owning app files.

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

Move code into `+labkit` only when it is reusable without app vocabulary.

## App File Layout

Keep new lab apps as explicit single files, organized roughly in this order:

```text
1. Entry validation and optional test hook
2. App state and GUI construction
3. Nested callbacks for file/session actions
4. Nested refresh/render/export callbacks that touch UI handles
5. End of the public app function
6. App-local domain functions
7. App-local table/export functions
8. App-local plotting annotation helpers
9. Small formatting, parsing, interpolation, and numeric utilities
```

Nested functions may read and update GUI handles or app state. Local functions after the app `end` should be GUI-free when practical so tests can call them through narrow app test hooks.

## Templates

Template source files live under `templates/` and are copy-only starting points, not runtime app entry points:

```text
templates/gui_only_app_template.m       GUI helpers only
templates/dta_only_script_template.m    DTA facade only
templates/gui_dta_app_template.m        GUI helpers plus DTA facade
```

Copy one into an `apps/<category>/` folder only when starting a real app. Keep the copied app explicit and local; do not create a helper package just because two callbacks look similar.

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
10. GUI shell type and file-selection mode
```

Prefer `labkit.ui.createWorkbench` even when the app has only one small control page. This keeps daily app interaction consistent as `apps/<category>/` grows while leaving domain-specific tab content under app ownership.

## Current App-Specific Notes

Chrono overlay pulse-gap alignment, overlay plotting, and overlay export table construction live as local functions in `apps/electrochem/labkit_ChronoOverlay_app.m`.

EIS overlay axis-value generation, plotting, and plot-export table construction are local functions in `apps/electrochem/labkit_EIS_app.m`.

CSC CT/CV charge integration is a local detail of `apps/electrochem/labkit_CSC_app.m`; it is not a separate reusable library API.

VT steady-window selection and baseline estimation are local details of `apps/electrochem/labkit_VTResistance_app.m`.

Current VT CSV column order:

```text
File,Ic_A,Ia_A,Vc_ss_V,Va_ss_V,Vc_baseline_V,Va_baseline_V,dVc_V,dVa_V,Rc_bc_ohm,Ra_bc_ohm,Ravg_bc_ohm,WindowMode,Detection,Status
```

Current CIC CSV column order uses one of:

```text
File,Amp_A,Emc_V,Ema_V,Qc_C,Qa_C,Qt_C,CICc_mCcm2,CICa_mCcm2,CICt_mCcm2,Safe,Detection
File,Amp_A,Emc_V,Ema_V,Qc_C,Qa_C,Qt_C,CICc_uCcm2,CICa_uCcm2,CICt_uCcm2,Safe,Detection
```

The current CV/CSC app has no CSV export workflow.

DIC preprocess image registration, inline right-preview ROI selection, paired-crop geometry, and editable spline ROI mask drawing are local details of `apps/dic/labkit_DICPreprocess_app.m`. The app keeps original loaded images plus a current working pair, so manual/automatic alignment and crop operations can be applied repeatedly in either order and undone. False-color preview compares the current pair even before alignment, and one save action exports the current reference/current moving images. The mask workflow uses explicit add, move, delete, preview, undo, clear, and save controls for anchor-based curve fitting, with scroll-wheel zoom available on the image preview. ROI masks are saved as white-inside / black-outside binary PNG images.

DIC postprocess Ncorr MAT extraction, EXX/EYY overlay generation, ROI summary statistics, optical reference-image enhancement, strain colorbar/level export, and PNG/CSV export are local details of `apps/dic/labkit_DICPostprocess_app.m`. The current overlay path extends valid strain values from the ROI before smoothing/resizing, then clips display back to the ROI/mask to avoid zero-filled edge leakage. The current ROI summary reports mean, standard deviation, median, minimum, and maximum for EXX and EYY.
