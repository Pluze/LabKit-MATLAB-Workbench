# LabKit MATLAB Workbench Changelog

This changelog records user-facing and maintainer-relevant changes for LabKit
MATLAB Workbench. It is written for humans, but it also keeps enough commit and
version evidence to answer which behavior shipped with each launcher, facade,
or app version.

## Changelog Policy

- `CHANGELOG.md` owns component version history. GitHub release notes remain
  shorter, release-specific summaries.
- `Unreleased` is the staging area for branch and pull-request work whose final
  mainline commit is not known yet.
- `Version Bump Ledger` is the audited mainline history. Move finalized
  `Unreleased` rows there when preparing a release or doing a changelog audit.
- Record notable behavior, compatibility, workflow, validation, diagnostics,
  and public facade changes. Do not dump raw git logs.
- For versioned components, every behavior change that bumps a `version.m` file
  or `labkit_launcher.m` must mention the component and new version here.
- App versions, facade versions, and launcher versions are independent.

## Unreleased

No pending version rows. Add branch work here before the final mainline commit
is known.

| Date | Component(s) | Version change | Notable change | Evidence |
|---|---|---|---|---|
| _template_ | `labkit.ui` | `4.2.0 -> 4.3.0` | Short user-facing or maintainer-facing summary. | PR or branch commit, then main commit after merge. |

## Current Version Inventory

Audited against `main` at `0155cd12` on 2026-07-04.

### Core And Facades

| Component | Current version | Status / family | Metadata location | Current notes |
|---|---:|---|---|---|
| `labkit_launcher` | `1.2.3` | Launcher | `labkit_launcher.m` | Self-contained GUI selector, updater, repair path, version manager, profiler, and code-analyzer actions. |
| `labkit.ui` | `4.2.0` | stable facade | `+labkit/+ui/version.m` | UI 4.x app/spec/view/tool/diag contract, declarative runtime, grouped actions, utility bar, state snapshots, enhanced popout tools, debug artifacts, alerts, close guard, output prompts, and text fitting. |
| `labkit.dta` | `2.0.0` | stable facade | `+labkit/+dta/version.m` | DTA parser, file item, pulse, and curve facade after old session helper removal. |
| `labkit.image` | `1.1.0` | stable facade | `+labkit/+image/version.m` | GUI-free image file input, display normalization, basic processing, and preview-budget helpers. |
| `labkit.thermal` | `1.0.0` | experimental facade | `+labkit/+thermal/version.m` | GUI-free FLIR radiometric JPEG, raw matrix, temperature conversion, and thermal rendering facade. |
| `labkit.rhs` | `1.0.0` | stable facade | `+labkit/+rhs/version.m` | RHS discovery, metadata, indexing, and waveform-window reads. |
| `labkit.biosignal` | `1.0.0` | stable facade | `+labkit/+biosignal/version.m` | Biosignal recording, filtering, event, segmentation, and ECG measurement contracts. |

### Apps

| App component | Family | Current version | Metadata location |
|---|---|---:|---|
| `labkit_ChronoOverlay_app` | Electrochem | `1.3.3` | `apps/electrochem/chrono_overlay/+chrono_overlay/version.m` |
| `labkit_CIC_app` | Electrochem | `1.3.5` | `apps/electrochem/cic/+cic/version.m` |
| `labkit_CSC_app` | Electrochem | `1.3.7` | `apps/electrochem/csc/+csc/version.m` |
| `labkit_EIS_app` | Electrochem | `1.3.3` | `apps/electrochem/eis/+eis/version.m` |
| `labkit_VTResistance_app` | Electrochem | `1.3.5` | `apps/electrochem/vt_resistance/+vt_resistance/version.m` |
| `labkit_DICPreprocess_app` | DIC | `1.3.3` | `apps/dic/dic_preprocess/+dic_preprocess/version.m` |
| `labkit_DICPostprocess_app` | DIC | `1.3.3` | `apps/dic/dic_postprocess/+dic_postprocess/version.m` |
| `labkit_BatchImageCrop_app` | Image Measurement | `1.6.5` | `apps/image_measurement/batch_crop/+batch_crop/version.m` |
| `labkit_CurvatureMeasurement_app` | Image Measurement | `1.3.3` | `apps/image_measurement/curvature/+curvature/version.m` |
| `labkit_FLIRThermal_app` | Image Measurement | `1.2.7` | `apps/image_measurement/flir_thermal/+flir_thermal/version.m` |
| `labkit_FocusStack_app` | Image Measurement | `1.4.4` | `apps/image_measurement/focus_stack/+focus_stack/version.m` |
| `labkit_ImageEnhance_app` | Image Measurement | `1.5.4` | `apps/image_measurement/image_enhance/+image_enhance/version.m` |
| `labkit_ImageMatch_app` | Image Measurement | `1.5.4` | `apps/image_measurement/image_match/+image_match/version.m` |
| `labkit_RHSPreview_app` | Neurophysiology | `1.3.3` | `apps/neurophysiology/rhs_preview/+rhs_preview/version.m` |
| `labkit_NerveResponseAnalysis_app` | Neurophysiology | `1.3.3` | `apps/neurophysiology/nerve_response_analysis/+nerve_response_analysis/version.m` |
| `labkit_ResponseReviewStats_app` | Neurophysiology | `1.3.3` | `apps/neurophysiology/response_review_stats/+response_review_stats/version.m` |
| `labkit_ECGPrint_app` | Wearable | `1.3.4` | `apps/wearable/ecg_print/+ecg_print/version.m` |

## Release Tag Index

| Tag | Date | Main commit | Notes |
|---|---|---|---|
| `v1.0` | 2026-06-06 | `0bb83a6e` | Early LabKit workbench release after app and runner migration cleanup. |
| `v2.0` | 2026-06-14 | `4bc7343f` | UI 2.0 app migration line. |
| `2.1` | 2026-06-21 | `76ddf7d0` | Legacy tag style; preserved for compatibility. |
| `v2.2.0` | 2026-06-21 | `c904baca` | Release updater button and launcher flow. |
| `v2.3.0` | 2026-06-21 | `f2ed23c2` | Batch crop padding and physical-scale workflow line. |
| `v2.3.1` | 2026-06-21 | `83d03e7a` | Launcher as primary user entry. |
| `v2.3.2` | 2026-06-22 | `29669ca6` | Image preview/export workflow hardening. |
| `v2.3.3` | 2026-06-23 | `a7e7dfb1` | Contributor identity normalization before facade contracts. |
| `v2.4.0` | 2026-06-23 | `d70c2607` | App and launcher version metadata baseline. |
| `v2.4.1` | 2026-06-23 | `49d9f41b` | Release validation contract hardening. |
| `v2.4.2` | 2026-06-23 | `7e39b558` | MATLAB CI shard routing through build tasks. |
| `v3.0.0` | 2026-06-29 | `349a7549` | UI diagnostics, validation docs, and duplicate CI avoidance line. |

## Notable Pre-Versioned History

Before `d70c2607` introduced app and launcher version metadata on 2026-06-23,
the repository still had important user-visible and architecture milestones:

| Date | Main commit(s) | Notable change |
|---|---|---|
| 2026-05-28 | `5973bde0` through `40f46561` | Imported the old MATLAB code, extracted DTA parsers and electrochem calculations, added named fixtures, and created dedicated app entry points. |
| 2026-05-28 to 2026-05-29 | `eb69fb1f` through `41403a8b` | Removed root legacy GUI entry points, moved electrochem apps into package-backed runners, and folded one-off helper packages back into app-owned workflows. |
| 2026-05-29 | `88b19851` through `e04292c0` | Added the GUI-free DTA loading facade, adopted it in electrochem apps, and documented/locked parser report schemas. |
| 2026-05-30 | `9bd8ec8f` through `1be52b9d` | Exposed app-facing DTA templates, renamed the workbench namespace to `labkit`, standardized file panels, and unified the app workbench shell. |
| 2026-05-30 | `aa96ae88` through `d7c31369` | Added DIC workflow apps, image curvature measurement, biosignal facade, and ECG explorer workflow. |
| 2026-05-31 | `1e9022c4` through `e94ce691` | Added axes popout, shared UI controls, ECG peak detection, public library option docs, and app regression coverage. |
| 2026-06-04 | PRs `#2` to `#5` and direct follow-ups | Added Focus Stack, UI busy guard behavior, image measurement improvements, scale-bar tool promotion, managed image axes runtime, and app debug trace logging. |
| 2026-06-05 to 2026-06-06 | PRs `#6` to `#19` plus migration commits | Rewrote app/test platform layout, hardened build entry points, completed app namespace migrations, cleared electrochem and DIC runner debt, and converged migration governance. |
| 2026-06-09 to 2026-06-14 | `5443dc7b` through `4bc7343f` | Removed Code Analyzer suppression pragmas, added launcher/project metadata, migrated apps to UI 2.0, persisted app debug artifacts, and reorganized tests. |
| 2026-06-18 to 2026-06-22 | `7ddc036f` through `1832f46a` | Added RHS neurophysiology app family, centralized UI busy/path contracts, made the launcher self-contained, added release updater support, and required reproducible release assets. |
| 2026-06-23 | `a25b79f9` through `10ee7df7` | Introduced facade contract checks, hid automated GUI windows, added version metadata guardrails, and routed CI shards through build tasks. |

## Version Bump Ledger

This ledger was rebuilt from first-parent `main` history by auditing
`labkit_launcher.m`, `+labkit/**/version.m`, `apps/**/version.m`, and
`+labkit/+contract/versionInfo.m`. Rows are grouped when one commit advanced
many apps for the same user-visible or maintainer-visible reason.

| Date | Main commit | Component(s) | Version change | Notable change |
|---|---|---|---|---|
| 2026-06-23 | `a25b79f9` | `labkit.biosignal`, `labkit.dta`, `labkit.rhs`, `labkit.ui` | baselines: biosignal/DTA/RHS `1.0.0`, UI `2.0.0` | Added facade contract metadata and requirement checks. |
| 2026-06-23 | `3673e548` | `labkit.ui` | `2.0.0 -> 2.1.0` | Hardened app lifecycle contracts. |
| 2026-06-23 | `d70c2607` | launcher, all supported apps, `labkit.ui` | launcher/apps `1.0.0`, UI `2.1.0 -> 2.2.0` | Added app and launcher version metadata, versioned titles, version requests, catalog version display, and version guardrails. |
| 2026-06-23 | `49d9f41b` | `labkit.ui`, DIC Pre/Post, Curvature | UI `2.2.0 -> 2.2.1`; listed apps `1.0.0 -> 1.0.1` | Hardened release validation contracts. |
| 2026-06-24 | `b145c904` | `labkit.dta`, `labkit.ui`, all supported apps | DTA `1.0.0 -> 2.0.0`; UI `2.2.1 -> 3.0.0`; apps into `1.2.0` | Breaking migration from task inputs to file panels and removal of old DTA session helpers. |
| 2026-06-25 | `fe8654c9` | launcher | `1.0.0 -> 1.1.0` | Added version manager and deliberate release/tag/main rollback flow. |
| 2026-06-25 | `ef89cf77` | launcher | `1.1.0 -> 1.1.1` | Required managed launcher manifests. |
| 2026-06-26 | `3d23b7f1` | `labkit.ui` | `3.0.0 -> 3.0.1` | Released stale image drag callbacks. |
| 2026-06-28 | `61e8edd3` | `labkit.ui`, Batch Crop | UI `3.0.1 -> 3.1.0`; Batch Crop `1.2.0 -> 1.3.0` | Added selected-file title context and improved file workflow feedback. |
| 2026-06-28 | `e966457b` | launcher, `labkit.ui`, Batch Crop, Focus Stack, Image Enhance/Match, neurophysiology apps | launcher `1.1.1 -> 1.1.2`; UI `3.1.0 -> 3.1.2`; listed apps advanced within `1.2.x`/`1.3.x` | Hardened UI workflows and app runtime behavior. |
| 2026-06-28 | `f5bc6f98` | `labkit.ui`, Batch Crop, Image Enhance | UI `3.1.2 -> 3.1.3`; listed apps patch bumped | Added crash reports, active-operation reports, caught-error reports, and stall diagnostics. |
| 2026-06-29 | `1768dd57` | Image Enhance, Image Match | Enhance `1.2.2 -> 1.3.0`; Match `1.2.1 -> 1.3.0` | Added protected image enhancement workflows. |
| 2026-06-29 | `21eff4dc` | launcher, `labkit.ui` | launcher `1.1.2 -> 1.1.3`; UI `3.1.3 -> 3.2.0` | Improved UI diagnostics and validation documentation. |
| 2026-06-29 | `f2189aef` | `labkit.ui` | `3.2.0 -> 3.2.2` | Hardened file-panel entry normalization and deterministic ID regeneration. |
| 2026-06-29 | `77084fbe` | Image Enhance, Image Match | both `1.3.0 -> 1.3.1` | Fixed output-size reporting and White ROI responsiveness/default placement. |
| 2026-06-29 | `871739cd` | `labkit.ui`, Batch Crop, Curvature | UI `3.2.2 -> 3.2.3`; Batch Crop `1.3.2 -> 1.3.3`; Curvature `1.2.0 -> 1.2.1` | Added semantic `toolPanel` hosts and repaired app layout section hosts. |
| 2026-06-30 | `7f8df1cd` | `labkit.ui` | `3.2.3 -> 3.2.4` | Stabilized single file-panel layout. |
| 2026-06-30 | `02b2f1b6` | `labkit.ui` | `3.2.4 -> 3.2.5` | Compacted single file-panel rows. |
| 2026-06-30 | `c5055b98` | `labkit.ui`, DIC apps, Batch Crop, Focus Stack, Image Enhance/Match, Nerve Response, Response Review | UI `3.2.5 -> 3.2.6`; affected apps patch bumped | Added `promptOutputFolder` and migrated output-folder prompts with chooser injection and safe defaults. |
| 2026-06-30 | `c0028a81` | DIC Post, Batch Crop, Curvature, Focus Stack, Image Match, neurophysiology apps, ECG Print | affected apps patch bumped | Reported caught app-runner exceptions through framework debug diagnostics. |
| 2026-06-30 | `a81853ef` | `labkit.ui`, Batch Crop, Focus Stack, Image Enhance/Match | UI `3.2.6 -> 3.2.7`; affected image apps patch bumped | Promoted file-entry index helpers and close-guard integration. |
| 2026-06-30 | `8d7c83b1` | `labkit.ui`, DIC apps, electrochem apps, image apps, ECG Print | UI `3.2.7 -> 3.2.8`; affected apps patch bumped | Routed app alerts through hidden-test-safe `labkit.ui.app.showAlert`. |
| 2026-06-30 | `7f73b71b` | Image Enhance | `1.3.4 -> 1.3.5` | Merged image enhance export helpers. |
| 2026-06-30 | `e3349af6` | Batch Crop | `1.3.7 -> 1.3.8` | Consolidated scale state. |
| 2026-06-30 | `733fb951` | RHS Preview | `1.2.2 -> 1.2.3` | Consolidated preview window bounds. |
| 2026-06-30 | `98a2b02c` | `labkit.ui` | `3.2.8 -> 3.2.9` | Added curvature workflow acceptance coverage and UI contract adjustment. |
| 2026-06-30 | `391540a7` | DIC Post, Batch Crop, RHS Preview | affected apps patch bumped | Retired migration helper debt. |
| 2026-06-30 | `7023e87e` | `labkit.image`, image measurement apps | image `1.0.0`; image apps advanced within `1.2.x` to `1.4.x` | Added shared GUI-free image facade and adopted it across image apps. |
| 2026-07-01 | `c33d027e` | Image Enhance, Image Match | both `1.4.0 -> 1.4.1` | Removed unused image display helpers. |
| 2026-07-01 | `ebf86cf2` | launcher | `1.1.3 -> 1.1.4` | Sped up launcher zip updates. |
| 2026-07-01 | `becf9391` | launcher | `1.1.4 -> 1.1.5` | Simplified launcher zip replacement. |
| 2026-07-01 | `977c9457` | `labkit.thermal`, `labkit.ui`, FLIR Thermal | thermal `1.0.0`; UI `3.2.9 -> 3.2.10`; FLIR `1.0.0` | Added thermal facade and FLIR Thermal Postprocess app. |
| 2026-07-01 | `15a798ba` | `labkit.image`, `labkit.ui`, Batch Crop, FLIR Thermal | image `1.0.0 -> 1.1.0`; UI `3.2.10 -> 3.3.0`; affected apps minor bumped | Added preview budgets and improved range/preview controls. |
| 2026-07-01 | `70bfcfd4` | launcher, `labkit.ui`, Batch Crop, FLIR Thermal | launcher `1.1.5 -> 1.1.6`; UI `3.3.0 -> 3.3.1`; affected apps patch bumped | Improved image measurement workflows. |
| 2026-07-01 | `279befbc` | `labkit.ui`, all supported apps | UI `3.3.1 -> 3.4.0`; apps moved into debug-sample-pack lines | Added app-owned debug sample packs and debug artifact sample/output folders. |
| 2026-07-01 | `8fd3ddff` | launcher | `1.1.6 -> 1.2.0` | Exported launcher Code Analyzer issues natively. |
| 2026-07-02 | `c07dfc0a` | launcher | `1.2.0 -> 1.2.1` | Added LabKit profiling tool. |
| 2026-07-02 | `74025fee` | ECG Print | `1.3.0 -> 1.3.1` | Sped up changed validation for ECG Print workflow coverage. |
| 2026-07-02 | `eadcca82` | `labkit.ui` | `3.4.0 -> 3.4.1` | Compressed validation runtime with GUI idle and bounded waits. |
| 2026-07-02 | `25912c54` | `labkit.ui`, Batch Crop | UI `3.4.1 -> 3.4.2`; Batch Crop `1.6.0 -> 1.6.1` | Reduced GUI profiling overhead and deferred Batch Crop image reads until preview/export. |
| 2026-07-02 | `fcfc36d8` | launcher | `1.2.1 -> 1.2.2` | Added launcher profiling and build-managed test routing. |
| 2026-07-02 | `7d4ef11e` | launcher, `labkit.ui` | launcher `1.2.2 -> 1.2.3`; UI `3.4.2 -> 3.4.4` | Painted launcher/app windows earlier and deferred launcher app discovery. |
| 2026-07-03 | `568b3e9b` | `labkit.ui`, all supported apps | UI `3.4.4 -> 3.4.5`; all apps patch bumped | Migrated apps to declarative workflow runtime. |
| 2026-07-03 | `6348185e` | CIC, CSC, VT Resistance, Batch Crop, FLIR, Focus Stack, Image Enhance/Match | affected apps patch bumped | Preserved appended file selections. |
| 2026-07-03 | `674d5d4b` | CIC, CSC, VT Resistance | affected apps patch bumped | Removed electrochem manual plot controls. |
| 2026-07-03 | `e81243a3` | `labkit.ui`, all supported apps | UI `3.4.5 -> 4.0.0`; all apps patch bumped | Replaced action groups with UI groups and moved UI contract into the 4.x line. |
| 2026-07-03 | `a69829c6` | `labkit.ui`, all supported apps | UI `4.0.0 -> 4.1.0`; all apps patch bumped | Added CSC all-cycle export and viewport policy while aligning affected app contracts. |
| 2026-07-03 | `ee5b8f79` | CSC, FLIR Thermal | CSC `1.3.6 -> 1.3.7`; FLIR `1.2.4 -> 1.2.5` | Refined CSC CV export and FLIR color mapping. |
| 2026-07-03 | `65dbf5ae` | FLIR Thermal | `1.2.5 -> 1.2.6` | Added FLIR gamma color mapping. |
| 2026-07-03 | `f076561e` | FLIR Thermal | `1.2.6 -> 1.2.7` | Made FLIR gamma mapping adjustable. |
| 2026-07-04 | `0155cd12` | `labkit.ui` | `4.1.0 -> 4.2.0` | Added state snapshot save/load APIs, workbench utility controls, and enhanced axes popout export/copy tooling. |

## Maintenance Template

Use this row format for new versioned changes:

```markdown
| YYYY-MM-DD | `main-or-pending-sha` | `component` | `old -> new` | User-facing or maintainer-facing reason. |
```

For branch work before the final mainline SHA is known, place the row in
`Unreleased` with PR or branch evidence. During release preparation or a
changelog audit, replace the evidence with the mainline commit and move the row
into `Version Bump Ledger`.
