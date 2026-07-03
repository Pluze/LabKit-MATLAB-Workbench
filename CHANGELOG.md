# LabKit MATLAB Workbench Component Changelog

Generated from `main` branch history through 2026-07-02 America/Chicago, then
audited against the current development branch.

This changelog tracks component-level version metadata for LabKit MATLAB Workbench. It is intentionally different from ordinary release notes: it records the version history of each launcher, facade, and app component that owns a `version.m` file or equivalent version function.

## Reconstruction method

- The source of truth is the actual `main` branch commit history and the version metadata files as they existed at those commits.
- Pull requests are used only as context when a mainline commit is associated with a PR. Version rows should not be inferred only from PR boundaries.
- Direct commits on `main` are first-class version events. Many important version bumps happened outside a PR-bounded changelog step.
- App and launcher version metadata was introduced on 2026-06-23 in `d70c260` (`feat: add app version metadata guardrails (#24)`). Earlier work is recorded as **pre-versioned history**.
- Some very large commits have truncated API diffs in GitHub tool output. Where a later exact diff proves the previous version, this file records the proven before/after values. Where an exact before/after was not visible, the entry is called a checkpoint instead of an exact bump.

## Mainline version bump ledger

| Date | Main commit | Component(s) | Version change | History reason |
|---|---|---|---|---|
| 2026-06-23 | `d70c260` | all apps, launcher, `labkit.ui` | baseline app/launcher metadata; launcher `1.0.0`; UI `2.2.0` | Added app/launcher version metadata, versioned titles, lightweight `"version"` requests, launcher catalog version display, and version guardrails. |
| 2026-06-24 | `b145c90` | DTA/UI/app workflows | mainline checkpoint | Direct `main` breaking workflow migration: replaced task inputs with file panels and removed old DTA session helper surface. Later exact diffs show this was part of the transition into UI 3.x and the 1.2.x app lineages. |
| 2026-06-25 | `fe8654c` | launcher | `1.0.0 -> 1.1.0` | Added the launcher version manager and `Versions` rollback/upgrade flow for releases, tags, and main commits. |
| 2026-06-28 | `61e8edd` | `labkit.ui` | `3.0.1 -> 3.1.0` | Added selected-file title context and preview-title propagation for filePanel workflows. |
| 2026-06-28 | `f5bc6f9` | `labkit.ui` | `3.1.2 -> 3.1.3` | Added app diagnostic crash reports, active-operation files, caught-error reports, and callback stall diagnostics. |
| 2026-06-29 | `77084fb` | Image Enhance, Image Match | `1.3.0 -> 1.3.1` for both | Fixed result-table output-size reporting and White ROI responsiveness/default placement behavior. |
| 2026-06-29 | `f2189ae` | `labkit.ui` | `3.2.0 -> 3.2.2` | Hardened shared filePanel entry normalization and deterministic empty/duplicate ID regeneration. The PR body mentioned `3.2.1`; the actual file diff is `3.2.2`. |
| 2026-06-29 | `871739c` | `labkit.ui`, Batch Image Crop, Curvature | UI `3.2.2 -> 3.2.3`; Batch Crop `1.3.2 -> 1.3.3`; Curvature `1.2.0 -> 1.2.1` | Added semantic `toolPanel` hosts and moved scale-bar tool mounting out of empty UI sections. |
| 2026-06-30 | `c5055b9` | `labkit.ui`, DIC Pre/Post, Batch Crop, Focus Stack, Image Enhance | UI `3.2.5 -> 3.2.6`; DIC Pre/Post `1.2.0 -> 1.2.1`; Batch Crop `1.3.3 -> 1.3.4`; Focus Stack `1.2.1 -> 1.2.2`; Image Enhance `1.3.1 -> 1.3.2` | Added `labkit.ui.app.promptOutputFolder` and migrated output-folder prompts with chooser injection and safe default-folder behavior. |
| 2026-06-30 | `c0028a8` | DIC Post, Batch Crop, Curvature, Focus Stack | DIC Post `1.2.1 -> 1.2.2`; Batch Crop `1.3.4 -> 1.3.5`; Curvature `1.2.1 -> 1.2.2`; Focus Stack `1.2.2 -> 1.2.3` | Reported caught app-runner exceptions through framework debug diagnostics before alerts/recovery logs. |
| 2026-06-30 | `a81853e` | `labkit.ui`, Batch Crop, Focus Stack, Image Enhance | UI `3.2.6 -> 3.2.7`; Batch Crop `1.3.5 -> 1.3.6`; Focus Stack `1.2.3 -> 1.2.4`; Image Enhance `1.3.2 -> 1.3.3` | Promoted file-entry index helpers and connected dirty/incomplete workflow state to close guards. |
| 2026-06-30 | `8d7c83b` | `labkit.ui`, DIC Post | UI `3.2.7 -> 3.2.8`; DIC Post `1.2.2 -> 1.2.3` | Added hidden-test-safe `labkit.ui.app.showAlert` and routed app alert mechanics through the UI facade while keeping app-owned alert wording. |
| 2026-06-30 | `7023e87` | `labkit.image` | `1.0.0` baseline checkpoint | Added the shared GUI-free image facade for file filters, path normalization, display names, imread-backed records, and basic image helpers. |
| 2026-07-01 | `977c945` | `labkit.thermal`, FLIR Thermal app | thermal `1.0.0` baseline; FLIR app baseline checkpoint | Added the experimental thermal facade and FLIR Thermal Postprocess app. |
| 2026-07-01 | `15a798b` | `labkit.image` | `1.0.0 -> 1.1.0` | Added preview-budget helpers and expanded the image facade from file input into basic processing plus responsive preview support. |
| 2026-07-01 | `279befb` | `labkit.ui` and all supported apps | UI `3.3.1 -> 3.4.0`; broad app bump into `1.3.x` / image app minor versions | Added app-owned debug sample packs plus debug artifact sample/output folders. |
| 2026-07-02 | `eadcca8` | `labkit.ui` | `3.4.0 -> 3.4.1` | Compressed validation runtime with GUI idle/bounded waits and scale-bar debounce registration. |
| 2026-07-02 | `25912c5` | `labkit.ui`, Batch Crop | UI `3.4.1 -> 3.4.2`; Batch Crop `1.6.0 -> 1.6.1` | Reduced debug/profile startup overhead and deferred Batch Crop image reads until preview/export. |
| 2026-07-02 | `7d4ef11` | `labkit.ui`, launcher | UI `3.4.2 -> 3.4.4`; launcher `1.2.2 -> 1.2.3` | Painted launcher/app windows earlier, deferred launcher app discovery, lazily prepared preview scroll interactions, and saved profile reports without opening a browser. |

## Exhaustive version-change audit

This table is the completeness ledger for every commit found by auditing
`labkit_launcher.m`, `**/version.m`, and `+labkit/+contract/versionInfo.m` on
the `origin/main` first-parent history, plus current-branch version changes.

| Date | Commit | Version owner(s) | Recorded version change |
|---|---|---|---|
| 2026-06-23 | `a25b79f` | `labkit.biosignal`, `labkit.dta`, `labkit.rhs`, `labkit.ui`, `labkit.contract` | Introduced `versionInfo`; biosignal `1.0.0`, DTA `1.0.0`, RHS `1.0.0`, UI `2.0.0`. |
| 2026-06-23 | `3673e54` | `labkit.ui` | `2.0.0 -> 2.1.0`. |
| 2026-06-23 | `d70c260` | launcher, all apps, `labkit.ui` | Added app/launcher metadata; launcher `1.0.0`, apps `1.0.0`, UI `2.1.0 -> 2.2.0`. |
| 2026-06-23 | `49d9f41` | `labkit.ui`, DIC Pre/Post, Curvature | UI `2.2.0 -> 2.2.1`; DIC Pre/Post and Curvature `1.0.0 -> 1.0.1`. |
| 2026-06-24 | `b145c90` | `labkit.dta`, `labkit.ui`, all apps | DTA `1.0.0 -> 2.0.0`; UI `2.2.1 -> 3.0.0`; supported apps moved into the `1.2.0` line. |
| 2026-06-25 | `fe8654c` | launcher | `1.0.0 -> 1.1.0`. |
| 2026-06-25 | `ef89cf7` | launcher | `1.1.0 -> 1.1.1`. |
| 2026-06-26 | `3d23b7f` | `labkit.ui` | `3.0.0 -> 3.0.1`. |
| 2026-06-28 | `61e8edd` | `labkit.ui`, Batch Crop | UI `3.0.1 -> 3.1.0`; Batch Crop `1.2.0 -> 1.3.0`. |
| 2026-06-28 | `e966457` | launcher, `labkit.ui`, Batch Crop, Focus Stack, Image Enhance, Image Match, RHS Preview, Nerve Response Analysis, Response Review Stats | launcher `1.1.1 -> 1.1.2`; UI `3.1.0 -> 3.1.2`; Batch Crop `1.3.0 -> 1.3.1`; listed apps moved `1.2.0 -> 1.2.1`. |
| 2026-06-28 | `f5bc6f9` | `labkit.ui`, Batch Crop, Curvature | UI `3.1.2 -> 3.1.3`; Batch Crop `1.3.1 -> 1.3.2`; Curvature `1.2.1 -> 1.2.2`. |
| 2026-06-29 | `1768dd5` | Image Enhance, Image Match | Image Enhance `1.2.2 -> 1.3.0`; Image Match `1.2.1 -> 1.3.0`. |
| 2026-06-29 | `21eff4d` | launcher, `labkit.ui` | launcher `1.1.2 -> 1.1.3`; UI `3.1.3 -> 3.2.0`. |
| 2026-06-29 | `f2189ae` | `labkit.ui` | `3.2.0 -> 3.2.2`. |
| 2026-06-29 | `77084fb` | Image Enhance, Image Match | Both `1.3.0 -> 1.3.1`. |
| 2026-06-29 | `871739c` | `labkit.ui`, Batch Crop, Curvature | UI `3.2.2 -> 3.2.3`; Batch Crop `1.3.2 -> 1.3.3`; Curvature `1.2.0 -> 1.2.1`. |
| 2026-06-30 | `7f8df1c` | `labkit.ui` | `3.2.3 -> 3.2.4`. |
| 2026-06-30 | `02b2f1b` | `labkit.ui` | `3.2.4 -> 3.2.5`. |
| 2026-06-30 | `c5055b9` | `labkit.ui`, DIC Pre/Post, Batch Crop, Focus Stack, Image Enhance, Image Match, Curvature, neurophysiology apps | UI `3.2.5 -> 3.2.6`; affected apps advanced within their `1.2.x`/`1.3.x` lines for output-folder prompt migration. |
| 2026-06-30 | `c0028a8` | DIC Post, Batch Crop, Curvature, Focus Stack, Image Enhance, Image Match, RHS Preview, Nerve Response Analysis, Response Review Stats, ECG Print | Affected apps advanced within `1.2.x`/`1.3.x` for caught-exception reporting. |
| 2026-06-30 | `a81853e` | `labkit.ui`, Batch Crop, Focus Stack, Image Enhance, Image Match | UI `3.2.6 -> 3.2.7`; affected image apps advanced for file-entry index and close-guard changes. |
| 2026-06-30 | `8d7c83b` | `labkit.ui`, DIC Post, and supported apps using alert routing | UI `3.2.7 -> 3.2.8`; affected app versions advanced for framework alert routing. |
| 2026-06-30 | `7f73b71` | Image Enhance | `1.3.4 -> 1.3.5`. |
| 2026-06-30 | `e3349af` | Batch Crop | `1.3.7 -> 1.3.8`. |
| 2026-06-30 | `733fb95` | RHS Preview | `1.2.2 -> 1.2.3`. |
| 2026-06-30 | `98a2b02` | `labkit.ui` | `3.2.8 -> 3.2.9`. |
| 2026-06-30 | `391540a` | DIC Post, Batch Crop, RHS Preview | DIC Post `1.2.3 -> 1.2.4`; Batch Crop `1.3.8 -> 1.3.9`; RHS Preview `1.2.3 -> 1.2.4`. |
| 2026-06-30 | `7023e87` | `labkit.image`, Batch Crop, FLIR Thermal, Focus Stack, Image Enhance, Image Match | Introduced image facade `1.0.0`; image-measurement apps advanced for shared image facade adoption. |
| 2026-07-01 | `c33d027` | Image Enhance, Image Match | Both `1.4.0 -> 1.4.1`. |
| 2026-07-01 | `977c945` | `labkit.thermal`, `labkit.ui`, FLIR Thermal | Introduced thermal facade `1.0.0`; UI `3.2.9 -> 3.2.10`; FLIR Thermal `1.0.0`. |
| 2026-07-01 | `15a798b` | `labkit.image`, `labkit.ui`, Batch Crop, FLIR Thermal | image `1.0.0 -> 1.1.0`; UI `3.2.10 -> 3.3.0`; Batch Crop `1.4.0 -> 1.5.0`; FLIR Thermal `1.0.0 -> 1.1.0`. |
| 2026-07-01 | `ebf86cf` | launcher | `1.1.3 -> 1.1.4`. |
| 2026-07-01 | `becf939` | launcher | `1.1.4 -> 1.1.5`. |
| 2026-07-01 | `70bfcfd` | launcher, `labkit.ui`, Batch Crop, FLIR Thermal | launcher `1.1.5 -> 1.1.6`; UI `3.3.0 -> 3.3.1`; Batch Crop `1.5.0 -> 1.5.1`; FLIR Thermal `1.1.0 -> 1.1.2`. |
| 2026-07-01 | `8fd3ddf` | launcher | `1.1.6 -> 1.2.0`. |
| 2026-07-01 | `279befb` | `labkit.ui` and all supported apps | UI `3.3.1 -> 3.4.0`; supported apps moved into debug-sample-pack versions. |
| 2026-07-02 | `74025fe` | ECG Print | `1.3.0 -> 1.3.1`. |
| 2026-07-02 | `eadcca8` | `labkit.ui` | `3.4.0 -> 3.4.1`. |
| 2026-07-02 | `25912c5` | `labkit.ui`, Batch Crop | UI `3.4.1 -> 3.4.2`; Batch Crop `1.6.0 -> 1.6.1`. |
| 2026-07-02 | `c07dfc0` | launcher | `1.2.0 -> 1.2.1`. |
| 2026-07-02 | `fcfc36d` | launcher | `1.2.1 -> 1.2.2`. |
| 2026-07-02 | `7d4ef11` | launcher, `labkit.ui` | launcher `1.2.2 -> 1.2.3`; UI `3.4.2 -> 3.4.4`. |
| 2026-07-03 | `c04aaab` | `labkit.ui` on the current development branch | UI `3.4.4 -> 3.4.5` for declarative app definition/runtime support. |

## Current version inventory

### Core and launcher components

| Component | Current version | Status / family | Metadata location | Current notes |
|---|---:|---|---|---|
| `labkit_launcher` | `1.2.3` | Launcher | `labkit_launcher.m` | Self-contained GUI selector, updater, repair path, version manager, profiler/code-analyzer actions. |
| `labkit.ui` | `3.4.5` | stable facade | `+labkit/+ui/version.m` | UI 3.x app/spec/view/tool/diag contract, declarative app definitions, framework-owned runtime dispatch, visible-window early paint, startup readiness state, lazy preview scroll setup, debug artifacts, hidden-test-safe alerts, close guard, crash reports, output prompts, and text fitting. |
| `labkit.dta` | `2.0.0` | stable facade | `+labkit/+dta/version.m` | DTA parser, file item, pulse, and curve facade contract after old session helper removal. |
| `labkit.rhs` | `1.0.0` | stable facade | `+labkit/+rhs/version.m` | RHS discovery, metadata, indexing, and waveform-window facade contract. |
| `labkit.image` | `1.1.0` | stable facade | `+labkit/+image/version.m` | GUI-free image file input, basic processing, and preview-budget helpers. |
| `labkit.thermal` | `1.0.0` | experimental facade | `+labkit/+thermal/version.m` | GUI-free FLIR radiometric JPEG, raw matrix, temperature conversion, and display rendering facade. |
| `labkit.biosignal` | `1.0.0` | stable facade | `+labkit/+biosignal/version.m` | Biosignal recording, filtering, event, segmentation, and ECG facade contract. |

### App components

| App component | Family | Current version | Updated date | Metadata location |
|---|---|---:|---|---|
| `labkit_CIC_app` | Electrochem | `1.3.0` | 2026-07-01 | `apps/electrochem/cic/+cic/version.m` |
| `labkit_CSC_app` | Electrochem | `1.3.0` | 2026-07-01 | `apps/electrochem/csc/+csc/version.m` |
| `labkit_EIS_app` | Electrochem | `1.3.0` | 2026-07-01 | `apps/electrochem/eis/+eis/version.m` |
| `labkit_VTResistance_app` | Electrochem | `1.3.0` | 2026-07-01 | `apps/electrochem/vt_resistance/+vt_resistance/version.m` |
| `labkit_ChronoOverlay_app` | Electrochem | `1.3.0` | 2026-07-01 | `apps/electrochem/chrono_overlay/+chrono_overlay/version.m` |
| `labkit_DICPreprocess_app` | DIC | `1.3.0` | 2026-07-02 | `apps/dic/dic_preprocess/+dic_preprocess/version.m` |
| `labkit_DICPostprocess_app` | DIC | `1.3.0` | 2026-07-02 | `apps/dic/dic_postprocess/+dic_postprocess/version.m` |
| `labkit_BatchImageCrop_app` | Image Measurement | `1.6.1` | 2026-07-02 | `apps/image_measurement/batch_crop/+batch_crop/version.m` |
| `labkit_CurvatureMeasurement_app` | Image Measurement | `1.3.0` | 2026-07-01 | `apps/image_measurement/curvature/+curvature/version.m` |
| `labkit_FLIRThermal_app` | Image Measurement | `1.2.0` | 2026-07-02 | `apps/image_measurement/flir_thermal/+flir_thermal/version.m` |
| `labkit_FocusStack_app` | Image Measurement | `1.4.0` | 2026-07-01 | `apps/image_measurement/focus_stack/+focus_stack/version.m` |
| `labkit_ImageEnhance_app` | Image Measurement | `1.5.0` | 2026-07-01 | `apps/image_measurement/image_enhance/+image_enhance/version.m` |
| `labkit_ImageMatch_app` | Image Measurement | `1.5.0` | 2026-07-01 | `apps/image_measurement/image_match/+image_match/version.m` |
| `labkit_RHSPreview_app` | Neurophysiology | `1.3.0` | 2026-07-02 | `apps/neurophysiology/rhs_preview/+rhs_preview/version.m` |
| `labkit_NerveResponseAnalysis_app` | Neurophysiology | `1.3.0` | 2026-07-02 | `apps/neurophysiology/nerve_response_analysis/+nerve_response_analysis/version.m` |
| `labkit_ResponseReviewStats_app` | Neurophysiology | `1.3.0` | 2026-07-02 | `apps/neurophysiology/response_review_stats/+response_review_stats/version.m` |
| `labkit_ECGPrint_app` | Wearable | `1.3.1` | 2026-07-02 | `apps/wearable/ecg_print/+ecg_print/version.m` |

## Component histories

## Core and launcher

### `labkit_launcher`

| Version | Date | Main commit | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | pre-`d70c260` | Launcher existed as a self-contained selector/updater before structured launcher metadata. |
| `1.0.0` | 2026-06-23 | `d70c260` | Added `launcherVersion()`, `labkit_launcher("version")`, app catalog version/date display, and version-title integration. |
| `1.1.0` | 2026-06-25 | `fe8654c` | Added the version manager and `Versions` button for deliberate upgrade/rollback. |
| `1.2.2` | by 2026-07-02 | `d849d63` checkpoint | Launcher had accumulated native Code Analyzer export, profiling tool integration, and build-managed test routing before the startup-responsiveness pass. |
| `1.2.3` | 2026-07-02 | `7d4ef11` | Deferred app discovery until after the window appears, painted visible launcher earlier, and kept profile exports from opening a browser by default. |

### `labkit.ui`

| Version | Date | Main commit | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | pre-`d70c260` | Declarative app/spec/view/tool/diag UI architecture existed before component version metadata. |
| `2.2.0` | 2026-06-23 | `d70c260` | Added app version-title support and lightweight `"version"` request handling. |
| `3.0.x` | 2026-06-24 to 2026-06-28 | `b145c90` and follow-ups | Direct mainline filePanel/task-input migration moved the UI contract into the 3.x line. Exact later diff shows `3.0.1` immediately before `61e8edd`. |
| `3.1.0` | 2026-06-28 | `61e8edd` | Added selected-file title context and propagated it into figure/preview titles. |
| `3.1.3` | 2026-06-28 | `f5bc6f9` | Added debug crash reports, active-operation reports, caught-error reports, and stall diagnostics. |
| `3.2.2` | 2026-06-29 | `f2189ae` | Hardened filePanel entry scalar text normalization and deterministic ID regeneration. |
| `3.2.3` | 2026-06-29 | `871739c` | Added `toolPanel` semantic hosts for reusable UI tools. |
| `3.2.6` | 2026-06-30 | `c5055b9` | Added `promptOutputFolder` for safe output folder selection and chooser injection. |
| `3.2.7` | 2026-06-30 | `a81853e` | Promoted file-entry index helpers and close-guard integration paths. |
| `3.2.8` | 2026-06-30 | `8d7c83b` | Added hidden-test-safe alert mechanics through `labkit.ui.app.showAlert`. |
| `3.4.0` | 2026-07-01 | `279befb` | Added debug artifact sample/output folders for debug sample packs. |
| `3.4.1` | 2026-07-02 | `eadcca8` | Added GUI idle/bounded stability waits and scale-bar debounce registration. |
| `3.4.2` | 2026-07-02 | `25912c5` | Reduced debug trace text mirroring and GUI profiling overhead. |
| `3.4.4` | 2026-07-02 | `7d4ef11` | Added visible-window early paint and lazy preview scroll-interaction setup. |
| `3.4.5` | 2026-07-03 | `c04aaab` | Added declarative app definitions, framework-owned runtime dispatch, and startup readiness state on the current branch. |

### `labkit.dta`

| Version | Date | Main commit | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | EIS/electrochem parser extraction history | DTA parser and curve helpers were extracted while EIS and electrochem apps moved away from monolithic runners. |
| `1.x` lineage | 2026-06-23 | `d70c260` | DTA facade joined the version-guardrail model. |
| `2.0.0` | by 2026-06-24 | `b145c90` checkpoint | Old session helper surface was removed; current DTA contract is parser/file-item/pulse/curve focused. |

### `labkit.image`

| Version | Date | Main commit | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-30 | image app local helper history | Image apps owned local file reading, display-name, preview, and processing helpers. |
| `1.0.0` | 2026-06-30 | `7023e87` | Introduced shared GUI-free image facade for file input, filters, path normalization, display names, imread records, and basic image helpers. |
| `1.1.0` | 2026-07-01 | `15a798b` | Added preview-budget helpers and expanded the facade to cover responsive image-app processing support. |

### `labkit.thermal`

| Version | Date | Main commit | Change summary |
|---:|---|---|---|
| `1.0.0` | 2026-07-01 | `977c945` | Introduced experimental FLIR radiometric JPEG, raw matrix, temperature conversion, and thermal display-rendering facade. |

### `labkit.rhs`

| Version | Date | Main commit | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | RHS preview/import history | RHS file discovery, metadata, indexing, and waveform-window reads existed before formal facade versioning. |
| `1.0.0` | 2026-06-23 | `d70c260` checkpoint | First stable RHS facade contract. No later bump was observed through current `main`. |

### `labkit.biosignal`

| Version | Date | Main commit | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | ECG Print/biosignal helper history | Recording import, filtering, segmentation, and ECG analysis helpers existed before formal facade versioning. |
| `1.0.0` | 2026-06-23 | `d70c260` checkpoint | First stable biosignal facade contract. No later bump was observed through current `main`. |

## App families

### Electrochem apps: CIC, CSC, EIS, VT Resistance, Chrono Overlay

| Version | Date | Main commit | Apps | Change summary |
|---:|---|---|---|---|
| pre-versioned | before 2026-06-23 | electrochem parser/app migration commits | all electrochem apps | Parser extraction, runner-helper convergence, removal of dispatch routers, DTA facade adoption, and UI migration happened before app version metadata. |
| `1.0.0` | 2026-06-23 | `d70c260` | all electrochem apps | First app-owned version metadata. |
| `1.2.1` | 2026-06-24 checkpoint | direct mainline after `b145c90` | all electrochem apps | FilePanel/task-input migration and workflow hardening checkpoint before debug sample packs. |
| `1.3.0` | 2026-07-01 | `279befb` | all electrochem apps | Added app-owned debug sample packs and debug artifact integration. |

### DIC apps

| Version | Date | Main commit | Apps | Change summary |
|---:|---|---|---|---|
| pre-versioned | before 2026-06-23 | DIC migration commits | DIC Pre/Post | DIC apps moved toward package-root runners and declarative UI before app version metadata. |
| `1.0.0` | 2026-06-23 | `d70c260` | DIC Pre/Post | First DIC app version metadata. |
| `1.2.1` | 2026-06-30 | `c5055b9` | DIC Pre/Post | Migrated output-folder dialogs to `promptOutputFolder`. |
| `1.2.2` | 2026-06-30 | `c0028a8` | DIC Post | Reported caught DIC Post runner exceptions through debug diagnostics. |
| `1.2.3` | 2026-06-30 | `8d7c83b` | DIC Post | Routed DIC Post alerts through `labkit.ui.app.showAlert`. |
| `1.2.2` | 2026-06-30 checkpoint | direct mainline | DIC Pre | DIC Preprocess reached `1.2.2` before the debug sample pack bump; exact direct commit was not expanded in the truncated diff. |
| `1.3.0` | 2026-07-01 | `279befb` | DIC Pre/Post | Added app-owned debug sample packs and debug artifact integration. |

### Image Measurement apps

#### Batch Image Crop

| Version | Date | Main commit | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | PR #10 / image migration commits | Added multi-image fixed-geometry crop workflow, per-image rotation/crop center, and manifest exports before app version metadata. |
| `1.0.0` | 2026-06-23 | `d70c260` | First Batch Crop app version metadata. |
| `1.3.3` | 2026-06-29 | `871739c` | Mounted the scale-bar tool through a semantic `toolPanel` host. |
| `1.3.4` | 2026-06-30 | `c5055b9` | Migrated export folder selection to `promptOutputFolder`. |
| `1.3.5` | 2026-06-30 | `c0028a8` | Added debug reporting for caught image-load/export exceptions. |
| `1.3.6` | 2026-06-30 | `a81853e` | Used framework file-index helpers and close-guard wiring. |
| `1.6.0` | 2026-07-01 | `279befb` | Added debug sample pack support. |
| `1.6.1` | 2026-07-02 | `25912c5` | Deferred image reads until current preview/export for faster selection. |

#### Curvature Measurement

| Version | Date | Main commit | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | image migration commits | Curvature measurement workflow and scale-bar tooling existed before app version metadata. |
| `1.0.0` | 2026-06-23 | `d70c260` | First Curvature app version metadata. |
| `1.2.1` | 2026-06-29 | `871739c` | Mounted scale-bar tool through `toolPanel`. |
| `1.2.2` | 2026-06-30 | `c0028a8` | Added debug reporting for caught image-load/fit/export exceptions. |
| `1.3.0` | 2026-07-01 | `279befb` | Added app-owned debug sample pack support. |

#### Focus Stack

| Version | Date | Main commit | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | PR #2 / image migration commits | Focus Stack was introduced with optional registration and fusion before app version metadata. |
| `1.0.0` | 2026-06-23 | `d70c260` | First Focus Stack app version metadata. |
| `1.2.2` | 2026-06-30 | `c5055b9` | Normalized numeric focus options and moved folder prompt behavior. |
| `1.2.3` | 2026-06-30 | `c0028a8` | Added debug reporting for caught load/run/export exceptions. |
| `1.2.4` | 2026-06-30 | `a81853e` | Used framework file-index helper and connected close guard. |
| `1.4.0` | 2026-07-01 | `279befb` | Added app-owned debug sample pack support. |

#### Image Enhance

| Version | Date | Main commit | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | PR #20 / image migration commits | Image Enhance was introduced as a separate image app before app version metadata. |
| `1.0.0` | 2026-06-23 | `d70c260` | First Image Enhance app version metadata. |
| `1.3.1` | 2026-06-29 | `77084fb` | Fixed output-size reporting and White ROI responsiveness/default placement. |
| `1.3.2` | 2026-06-30 | `c5055b9` | Migrated output-folder selection to `promptOutputFolder`. |
| `1.3.3` | 2026-06-30 | `a81853e` | Promoted file-index helper usage and close-guard integration. |
| `1.5.0` | 2026-07-01 | `279befb` | Added app-owned debug sample pack support. |

#### Image Match

| Version | Date | Main commit | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | PR #20 / image migration commits | Image Match was introduced as a separate image app before app version metadata. |
| `1.0.0` | 2026-06-23 | `d70c260` | First Image Match app version metadata. |
| `1.3.1` | 2026-06-29 | `77084fb` | Fixed source/export output-size reporting. |
| `1.4.1` | 2026-07-01 checkpoint | direct mainline image workflow commits | Image Match reached `1.4.1` before debug sample packs. Exact direct commit was not expanded in the truncated diff. |
| `1.5.0` | 2026-07-01 | `279befb` | Added app-owned debug sample pack support. |

#### FLIR Thermal Postprocess

| Version | Date | Main commit | Change summary |
|---:|---|---|---|
| baseline | 2026-07-01 | `977c945` | Added FLIR Thermal Postprocess app alongside `labkit.thermal`. |
| `1.1.2` | 2026-07-01 checkpoint | direct mainline FLIR/image workflow commits | FLIR app reached `1.1.2` before debug sample packs and shared-range changes. |
| `1.2.0` | 2026-07-01 | `279befb` | Added debug sample pack support and updated shared range behavior. |

### Neurophysiology apps

| Version | Date | Main commit | Apps | Change summary |
|---:|---|---|---|---|
| pre-versioned | before 2026-06-23 | neurophysiology migration commits | RHS Preview, Nerve Response Analysis, Response Review Stats | Workflows existed before app version metadata and later used stable RHS/biosignal facades. |
| `1.0.0` | 2026-06-23 | `d70c260` | all neurophysiology apps | First app version metadata. |
| `1.2.4` / `1.2.3` checkpoints | 2026-06-30 to 2026-07-01 | direct mainline workflow commits | RHS Preview `1.2.4`, Nerve Response `1.2.4`, Response Review Stats `1.2.3` | Workflow acceptance and app-runner hardening before debug sample packs. |
| `1.3.0` | 2026-07-01 | `279befb` | all neurophysiology apps | Added app-owned debug sample packs and debug artifact integration. |

### Wearable app: ECG Print

| Version | Date | Main commit | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | ECG Print/biosignal migration commits | ECG Print existed before app version metadata. |
| `1.0.0` | 2026-06-23 | `d70c260` | First ECG Print app version metadata. |
| `1.2.2` | 2026-06-30 checkpoint | direct mainline workflow commits | ECG Print workflow acceptance and biosignal integration reached `1.2.2` before debug sample packs. |
| `1.3.0` | 2026-07-01 | `279befb` | Added app-owned debug sample pack support. |
| `1.3.1` | 2026-07-02 checkpoint | direct mainline post-debug adjustments | Current version after ECG Print debug/sample workflow adjustments. The exact direct commit was not expanded in truncated diff output; current metadata is authoritative. |

## Maintenance guidance for future updates

When changing a versioned component:

1. Update that component's own version metadata in the same change as the behavior change.
2. Use `X.Y.Z` semantic version format.
3. Treat app versions, launcher versions, and facade contract versions independently.
4. Record direct `main` commits as version events, even when no PR boundary exists.
5. Add a row with previous version, new version, main commit SHA, reason for the bump, and affected component(s).

## Quick append template

```markdown
| YYYY-MM-DD | `<main-sha>` | `<component>` | `<old> -> <new>` | `<why the version changed>` |
```
