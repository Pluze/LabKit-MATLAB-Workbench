# LabKit MATLAB Workbench Changelog

This file is a version map for users and maintainers. It explains what changed
under each release tag, launcher version, facade version, and app version. It
does not try to replace git blame or raw commit history; it records the
maintainer intent and user impact that are easy to lose in commit subjects.

## How To Use This File

- Start with `Current Version Lookup` when you only need to identify the version
  and metadata file for a launcher, facade, or app.
- Use `Version History` as the main reading path. Each entry lists affected
  versions, what changed, why it matters, compatibility notes when relevant,
  and evidence.
- Use `Unreleased` for branch and pull-request work before the final mainline
  commit is known.
- Record meaningful behavior, compatibility, workflow, validation, diagnostics,
  and public facade changes. Do not dump raw git logs.

## Unreleased

### Pending - Code Analyzer reports and optional launcher tools

Affected versions:
- `labkit_launcher` `1.2.6 -> 1.2.7`
- `labkit.ui` `5.0.0 -> 5.0.1`

What changed:
- Moved the launcher Code Analyzer scan into `tools/codecheck`, which now
  writes a timestamped JSON/HTML report pair under `artifacts/code-check/`
  without overwriting earlier runs.
- The HTML report supports active/suppressed/all issue views, severity and
  CheckID filters, file and CheckID summaries, selected-issue details, and
  embedded source text for issue files.
- Code Analyzer reports and project style/code-quality guardrails can include
  local private app workspaces from `private_apps/apps/` and
  `LABKIT_PRIVATE_APP_ROOTS` when the private workspace opts in with
  `.labkit-accept-main-guardrails`.
- The visible launcher opens Code Analyzer and profiler HTML reports after
  manual tool actions; hidden automated GUI tests suppress browser launch.
- Optional maintenance buttons are disabled when their tool folders are missing,
  while app launch and version update actions remain available.
- Cleaned duplicate Code Analyzer branches in reusable UI helpers and adjusted
  launcher busy-state cleanup so MATLAB Code Analyzer no longer reports those
  error-level findings.

Why it matters:
- Code Analyzer cleanup can be reviewed from an interactive local HTML report
  without making the launcher own a growing maintenance workflow.
- Damaged or slimmed-down installs keep core launcher behavior available even
  when optional maintenance tools are absent.

Compatibility:
- Code Analyzer report consumers should read the timestamped
  `artifacts/code-check/matlab_code_issues_*.json` files.
- The HTML report is an additional timestamped artifact under `artifacts/` and
  is not tracked.

Evidence:
- Pending commit.

### Pending - Single app deployment packages

Affected versions:
- `labkit_launcher` `1.2.5 -> 1.2.6`

What changed:
- Added launcher actions and a deployment tool that package one selected LabKit
  app into a standalone zip, either as source `.m` files or encoded `.p` files.
- The generated package includes the selected app and its assets, `+labkit/`,
  `labkit_launcher.m`, the launcher-needed deployment/profiling tool folders,
  a manifest, and a direct `run_<app_command>.m` entry file.
- Private apps can be packaged from `private_apps/apps/` or
  `LABKIT_PRIVATE_APP_ROOTS`; inside the zip they remain under
  `private_apps/apps/...`.

Why it matters:
- A single lab workflow can be distributed into a fixed production or offline
  deployment step without shipping unrelated apps, tests, docs, or repository
  metadata.

Compatibility:
- Full LabKit checkout installs are unchanged.
- Single-app packages can start through either the packaged launcher or the
  direct run file; P-code packages require MATLAB to run the generated `.p`
  files.

Evidence:
- Pending commit.

### Pending - Private app workspace discovery

Affected versions:
- `labkit_launcher` `1.2.4 -> 1.2.5`

What changed:
- Added launcher discovery for local private app workspaces under
  `private_apps/apps/` and roots named by `LABKIT_PRIVATE_APP_ROOTS`.
- Added a `Visibility` catalog field so private app entries can be listed and
  launched locally without becoming public app entries.
- Documented the generic private-app workspace structure and Git ownership
  model without recording private app details in the public repository.

Why it matters:
- Developers can keep private LabKit apps next to a public checkout, use the
  ordinary launcher to open them, and push that workspace to a separate private
  repository.

Compatibility:
- Public apps, public releases, and public CI remain scoped to `apps/`.
- Existing launcher list consumers should tolerate the additional `Visibility`
  catalog column.

Evidence:
- Pending commit.

Template for branch work before the final mainline commit is known:

```markdown
### Pending - Short user-facing title

Affected versions:
- `component` `old -> new`

What changed:
- Plain-language change summary.

Why it matters:
- User or maintainer reason this version exists.

Compatibility:
- Migration or rollback note, or `No known manual migration.`

Evidence:
- PR, branch, or pending commit.
```

## Current Version Lookup

Audited against `main` UI 5 squash commit on 2026-07-06.

| Component | Current version | Family | Metadata location |
|---|---:|---|---|
| `labkit_launcher` | `1.2.7` | Launcher | `labkit_launcher.m` |
| `labkit.ui` | `5.0.1` | Facade | `+labkit/+ui/version.m` |
| `labkit.dta` | `2.0.0` | Facade | `+labkit/+dta/version.m` |
| `labkit.image` | `1.1.0` | Facade | `+labkit/+image/version.m` |
| `labkit.thermal` | `1.0.0` | Facade | `+labkit/+thermal/version.m` |
| `labkit.rhs` | `1.0.0` | Facade | `+labkit/+rhs/version.m` |
| `labkit.biosignal` | `1.0.0` | Facade | `+labkit/+biosignal/version.m` |
| `labkit_FigureStudio_app` | `0.1.4` | LabKit Core | `apps/labkit_core/figure_studio/+figure_studio/version.m` |
| `labkit_ChronoOverlay_app` | `1.3.5` | Electrochem | `apps/electrochem/chrono_overlay/+chrono_overlay/version.m` |
| `labkit_CIC_app` | `1.3.7` | Electrochem | `apps/electrochem/cic/+cic/version.m` |
| `labkit_CSC_app` | `1.3.9` | Electrochem | `apps/electrochem/csc/+csc/version.m` |
| `labkit_EIS_app` | `1.3.4` | Electrochem | `apps/electrochem/eis/+eis/version.m` |
| `labkit_VTResistance_app` | `1.3.7` | Electrochem | `apps/electrochem/vt_resistance/+vt_resistance/version.m` |
| `labkit_DICPreprocess_app` | `1.3.4` | DIC | `apps/dic/dic_preprocess/+dic_preprocess/version.m` |
| `labkit_DICPostprocess_app` | `1.3.4` | DIC | `apps/dic/dic_postprocess/+dic_postprocess/version.m` |
| `labkit_BatchImageCrop_app` | `1.6.6` | Image Measurement | `apps/image_measurement/batch_crop/+batch_crop/version.m` |
| `labkit_CurvatureMeasurement_app` | `1.3.4` | Image Measurement | `apps/image_measurement/curvature/+curvature/version.m` |
| `labkit_FLIRThermal_app` | `1.2.8` | Image Measurement | `apps/image_measurement/flir_thermal/+flir_thermal/version.m` |
| `labkit_FocusStack_app` | `1.4.5` | Image Measurement | `apps/image_measurement/focus_stack/+focus_stack/version.m` |
| `labkit_ImageEnhance_app` | `1.5.5` | Image Measurement | `apps/image_measurement/image_enhance/+image_enhance/version.m` |
| `labkit_ImageMatch_app` | `1.5.5` | Image Measurement | `apps/image_measurement/image_match/+image_match/version.m` |
| `labkit_RHSPreview_app` | `1.3.4` | Neurophysiology | `apps/neurophysiology/rhs_preview/+rhs_preview/version.m` |
| `labkit_NerveResponseAnalysis_app` | `1.3.4` | Neurophysiology | `apps/neurophysiology/nerve_response_analysis/+nerve_response_analysis/version.m` |
| `labkit_ResponseReviewStats_app` | `1.3.4` | Neurophysiology | `apps/neurophysiology/response_review_stats/+response_review_stats/version.m` |
| `labkit_ECGPrint_app` | `1.3.5` | Wearable | `apps/wearable/ecg_print/+ecg_print/version.m` |

## Version History

### 2026-07-06 - UI 5 facade redesign, app migration, and plot refresh

Affected versions:
- `labkit_launcher` `1.2.3 -> 1.2.4`
- `labkit.ui` `4.2.0 -> 5.0.0`
- `labkit_FigureStudio_app` `0.1.0 -> 0.1.4`
- `labkit_ChronoOverlay_app` `1.3.3 -> 1.3.5`
- `labkit_CIC_app` `1.3.5 -> 1.3.7`
- `labkit_CSC_app` `1.3.7 -> 1.3.9`
- `labkit_EIS_app` `1.3.3 -> 1.3.4`
- `labkit_VTResistance_app` `1.3.5 -> 1.3.7`
- `labkit_DICPreprocess_app` `1.3.3 -> 1.3.4`
- `labkit_DICPostprocess_app` `1.3.3 -> 1.3.4`
- `labkit_BatchImageCrop_app` `1.6.5 -> 1.6.6`
- `labkit_CurvatureMeasurement_app` `1.3.3 -> 1.3.4`
- `labkit_FLIRThermal_app` `1.2.7 -> 1.2.8`
- `labkit_FocusStack_app` `1.4.4 -> 1.4.5`
- `labkit_ImageEnhance_app` `1.5.4 -> 1.5.5`
- `labkit_ImageMatch_app` `1.5.4 -> 1.5.5`
- `labkit_RHSPreview_app` `1.3.3 -> 1.3.4`
- `labkit_NerveResponseAnalysis_app` `1.3.3 -> 1.3.4`
- `labkit_ResponseReviewStats_app` `1.3.3 -> 1.3.4`
- `labkit_ECGPrint_app` `1.3.4 -> 1.3.5`

What changed:
- Reorganized the UI facade into `labkit.ui.runtime`, `layout`, `control`,
  `plot`, `interaction`, and `debug` so app authors can find lifecycle,
  data-only layout, control update, plot-area, pointer/tooling, and diagnostic
  APIs by responsibility.
- Replaced the old app/spec/view/tool/diag UI paths with UI 5 names and moved
  every app to `definition(..., "Layout", @buildWorkbenchLayout)` plus
  `labkit.ui.layout.*`, `labkit.ui.control.*`, `labkit.ui.plot.*`,
  `labkit.ui.interaction.*`, and `labkit.ui.debug.*`.
- Added framework-owned plot helpers for registered axes lookup, clearing,
  empty-state messages, fitted limits, canvas framing, image preview redraw,
  and data/fraction coordinate conversion.
- Reset electrochem plot axes and legends when files are cleared, removed, or
  redrawn so old ranges, markers, shaded windows, and annotations do not remain
  after the file list changes.
- Refit CIC, Chrono Overlay, CSC all-cycle, and VT Resistance redraws to the
  current plotted data instead of preserving stale manual zoom limits.
- Staggered CIC Emc/Ema marker labels with readable white backgrounds so key
  extrema labels are less likely to be hidden by voltage-step or window
  annotations.
- Added visible busy/progress feedback for launcher actions that can wait on
  file scans, artifact cleanup, app startup, profiling, GitHub version lookup,
  or update/install work.
- Added launcher and version-manager busy gates so repeated clicks do not start
  overlapping synchronous operations.
- Replaced top workbench utility buttons with native window utility menus.
- Changed workbench plot popout/copy/save actions to operate on every
  registered preview axes in a multi-axes app.
- Replaced icon-only popout figure tools with visible text buttons for font,
  plotted-line, axes, grid, and Studio handoff controls.
- Added the LabKit Core Figure Studio app for opening MATLAB `.fig` files,
  switching between the measured LabKit single-panel style and the imported
  FIG defaults, tuning font/line/grid parameters, and exporting visible
  graphics data packages with reconstruction scripts.
- Normalized imported FIG axes before applying Studio canvas and style
  constraints so source layout/aspect metadata and file-selection titles cannot
  collapse the preview.
- Centered the managed preview canvas in the app preview grid so styled FIG
  labels and plot content render in the visible canvas instead of the corner
  cell.
- Added a `labkit.ui.plot.fitCanvas` canvas-frame helper so fixed-size preview
  axes use the framework-owned preview grid policy instead of app-owned
  row/column layout code.

Why it matters:
- App authors now use a smaller set of responsibility-named UI packages instead
  of learning old mixed app/spec/view/tool/diag buckets.
- Shared plot-area mechanics live in the framework, so app code can focus on
  domain plotting while the framework handles stale axes state, fitted ranges,
  empty previews, coordinate offsets, and registered preview utilities.
- Electrochem apps now match the active file selection after add/remove/clear
  workflows, and CIC keeps the critical Emc/Ema readout visible on dense plots.
- Users can distinguish long launcher work from a frozen MATLAB session.
- Multi-plot apps expose utility actions in a clearer, less repetitive flow.
- Figure cleanup and data/script export move into a dedicated reusable workflow
  instead of crowding every popout plot window.

Compatibility:
- Breaking UI facade migration: app code must use the UI 5 package paths and
  require `labkit.ui >=5 <6`.

Evidence:
- Main UI 5 squash commit.

### 2026-07-04 - UI utility snapshots and popout tools

Affected versions:
- `labkit.ui` `4.1.0 -> 4.2.0`

What changed:
- Added UI state snapshot save/load APIs.
- Added workbench utility controls.
- Improved axes popout export and copy tools.

Why it matters:
- Users can preserve UI state and move plot outputs out of the GUI with less
  manual work.

Evidence:
- Main commit `0155cd12`.

### 2026-07-03 - FLIR display tuning

Affected versions:
- `labkit_FLIRThermal_app` `1.2.4 -> 1.2.7`
- `labkit_CSC_app` `1.3.6 -> 1.3.7`

What changed:
- Refined CSC CV export.
- Added FLIR gamma color mapping and made gamma adjustable.

Why it matters:
- CSC exports became clearer for downstream analysis, and FLIR display tuning
  no longer requires code edits.

Evidence:
- Main commits `ee5b8f79`, `65dbf5ae`, and `f076561e`.

### 2026-07-03 - CSC export and viewport policy

Affected versions:
- `labkit.ui` `4.0.0 -> 4.1.0`
- All supported apps received aligned patch bumps.

What changed:
- Added CSC all-cycle export.
- Added viewport policy support and aligned app contracts with the UI 4.x line.

Why it matters:
- Users can export more complete CSC cycle data, and app layouts share the same
  viewport assumptions.

Evidence:
- Main commit `a69829c6`.

### 2026-07-03 - UI groups migration

Affected versions:
- `labkit.ui` `3.4.5 -> 4.0.0`
- All supported apps received patch bumps.

What changed:
- Replaced action groups with UI groups.
- Moved the reusable UI contract into the 4.x line.

Why it matters:
- This is the point where app action layout became a grouped UI contract instead
  of a looser action-list convention.

Compatibility:
- App workflow definitions had to align with the new grouped UI contract.

Evidence:
- Main commit `e81243a3`.

### 2026-07-03 - App file-selection and electrochem control fixes

Affected versions:
- CIC, CSC, VT Resistance, Batch Crop, FLIR Thermal, Focus Stack, Image Enhance,
  and Image Match patch bumped for appended file selections.
- CIC, CSC, and VT Resistance patch bumped again for manual plot-control
  removal.

What changed:
- Preserved appended file selections.
- Removed electrochem manual plot controls that no longer matched the workflow.

Why it matters:
- Multi-file workflows stopped losing appended selections, and electrochem app
  controls became less misleading.

Evidence:
- Main commits `6348185e` and `674d5d4b`.

### 2026-07-03 - Declarative app runtime

Affected versions:
- `labkit.ui` `3.4.4 -> 3.4.5`
- All supported apps received patch bumps.

What changed:
- Migrated apps to declarative workflow runtime.

Why it matters:
- Maintainers can reason about app wiring through workflow definitions instead
  of hand-following callback construction.

Evidence:
- Main commit `568b3e9b`.

### 2026-07-02 - Startup responsiveness

Affected versions:
- `labkit_launcher` `1.2.2 -> 1.2.3`
- `labkit.ui` `3.4.2 -> 3.4.4`

What changed:
- Painted launcher and app windows earlier.
- Deferred launcher app discovery and lazy preview scroll setup.

Why it matters:
- Users see responsive windows sooner instead of waiting on discovery and setup
  work before the GUI appears.

Evidence:
- Main commit `7d4ef11e`.

### 2026-07-02 - Profiling and validation speedups

Affected versions:
- `labkit_launcher` `1.2.0 -> 1.2.2`
- `labkit.ui` `3.4.0 -> 3.4.2`
- `labkit_BatchImageCrop_app` `1.6.0 -> 1.6.1`
- `labkit_ECGPrint_app` `1.3.0 -> 1.3.1`

What changed:
- Added LabKit profiling and build-managed test routing to the launcher.
- Reduced GUI profiling overhead and deferred Batch Crop image reads until
  preview/export.
- Compressed validation runtime with bounded GUI waits.

Why it matters:
- Maintainers get faster diagnosis and faster validation without changing app
  behavior.

Evidence:
- Main commits `c07dfc0a`, `74025fee`, `eadcca82`, `25912c54`, and `fcfc36d8`.

### 2026-07-01 - Launcher code-analysis export

Affected versions:
- `labkit_launcher` `1.1.6 -> 1.2.0`

What changed:
- Exported launcher Code Analyzer issues natively.

Why it matters:
- Maintainers can inspect launcher code issues through the workbench tooling
  without a separate manual MATLAB setup.

Evidence:
- Main commit `8fd3ddff`.

### 2026-07-01 - Debug sample packs

Affected versions:
- `labkit.ui` `3.3.1 -> 3.4.0`
- All supported apps moved into the `1.3.x`, `1.4.x`, `1.5.x`, or `1.6.x`
  debug-sample-pack lines.

What changed:
- Added app-owned debug sample packs.
- Added debug artifact sample and output folders.

Why it matters:
- Reproducing app failures became a maintained workflow instead of an ad hoc
  collection of local files.

Evidence:
- Main commit `279befbc`.

### 2026-07-01 - Image app workflow improvements

Affected versions:
- `labkit.image` `1.0.0 -> 1.1.0`
- `labkit.ui` `3.2.10 -> 3.3.1`
- Batch Crop `1.4.0 -> 1.5.1`
- FLIR Thermal `1.0.0 -> 1.1.2`
- `labkit_launcher` `1.1.5 -> 1.1.6`

What changed:
- Added preview-budget helpers.
- Improved image app range and preview controls.
- Improved image measurement workflows.

Why it matters:
- Large image workflows became more predictable and less likely to spend time on
  unnecessary preview work.

Evidence:
- Main commits `15a798ba` and `70bfcfd4`.

### 2026-07-01 - Thermal facade and FLIR app

Affected versions:
- `labkit.thermal` `1.0.0`
- `labkit.ui` `3.2.9 -> 3.2.10`
- `labkit_FLIRThermal_app` `1.0.0`

What changed:
- Added the thermal facade.
- Added the FLIR Thermal Postprocess app.

Why it matters:
- Thermal image parsing and rendering became a reusable LabKit contract instead
  of app-local logic.

Evidence:
- Main commit `977c9457`.

### 2026-07-01 - Launcher update reliability

Affected versions:
- `labkit_launcher` `1.1.3 -> 1.1.5`

What changed:
- Sped up launcher zip updates.
- Simplified launcher zip replacement.

Why it matters:
- Updating the self-contained launcher became less fragile.

Evidence:
- Main commits `ebf86cf2` and `becf9391`.

### 2026-06-30 - Shared image facade

Affected versions:
- `labkit.image` `1.0.0`
- Batch Crop, Curvature, Focus Stack, Image Enhance, and Image Match advanced
  within their image-facade adoption lines.

What changed:
- Added a GUI-free image facade for file input, display normalization, basic
  processing, and preview support.
- Adopted that facade across image-measurement apps.

Why it matters:
- Image app behavior became more consistent, and reusable image IO stopped
  living inside individual GUI workflows.

Evidence:
- Main commit `7023e87e`.

### 2026-06-30 - Migration helper cleanup

Affected versions:
- DIC Post, Batch Crop, and RHS Preview patch bumped.

What changed:
- Retired migration helper debt.
- Consolidated RHS preview window bounds, Batch Crop scale state, and Image
  Enhance export helpers.

Why it matters:
- Maintainers no longer need to route through temporary migration helpers to
  understand these workflows.

Evidence:
- Main commits `7f73b71b`, `e3349af6`, `733fb951`, `98a2b02c`, and `391540a7`.

### 2026-06-30 - App alerts through UI facade

Affected versions:
- `labkit.ui` `3.2.7 -> 3.2.8`
- DIC, electrochem, image-measurement, and ECG apps patch bumped where alert
  routing changed.

What changed:
- Routed app alerts through hidden-test-safe `labkit.ui.app.showAlert`.

Why it matters:
- App error reporting became testable without each app inventing its own alert
  mechanics.

Evidence:
- Main commit `8d7c83b1`.

### 2026-06-30 - Close guards and caught-exception diagnostics

Affected versions:
- `labkit.ui` `3.2.6 -> 3.2.7`
- DIC, Batch Crop, Curvature, Focus Stack, Image Match, neurophysiology apps,
  and ECG Print patch bumped for diagnostics or close-guard work.

What changed:
- Reported caught app-runner exceptions through framework debug diagnostics.
- Promoted file-entry index helpers.
- Connected dirty/incomplete workflow state to close guards.

Why it matters:
- Crashes and interrupted workflows leave better evidence for maintainers, and
  users get safer close behavior around incomplete image workflows.

Evidence:
- Main commits `c0028a81` and `a81853ef`.

### 2026-06-30 - Output folder prompts

Affected versions:
- `labkit.ui` `3.2.5 -> 3.2.6`
- DIC apps, Batch Crop, Focus Stack, Image Enhance/Match, Nerve Response, and
  Response Review patch bumped.

What changed:
- Added `promptOutputFolder`.
- Migrated output-folder prompts with chooser injection and safe defaults.

Why it matters:
- Apps gained consistent output-folder behavior without hard-coding dialog
  mechanics into each workflow.

Evidence:
- Main commit `c5055b98`.

### 2026-06-30 - File-panel layout stabilization

Affected versions:
- `labkit.ui` `3.2.3 -> 3.2.5`

What changed:
- Stabilized and compacted single file-panel layout.

Why it matters:
- File-heavy app workflows became easier to scan and less layout-fragile.

Evidence:
- Main commits `7f8df1cd` and `02b2f1b6`.

### 2026-06-29 - Tool-panel hosts and image app fixes

Affected versions:
- `labkit.ui` `3.2.0 -> 3.2.3`
- Batch Crop, Curvature, Image Enhance, and Image Match patch bumped where
  layouts or image-app behavior changed.

What changed:
- Hardened file-panel entry normalization and deterministic ID regeneration.
- Fixed output-size reporting and White ROI responsiveness.
- Added semantic `toolPanel` hosts.

Why it matters:
- Reusable tools gained a real layout host, and image app reports/ROI controls
  became less surprising.

Evidence:
- Main commits `f2189aef`, `77084fbe`, and `871739cd`.

### 2026-06-29 - UI diagnostics and release v3.0.0

Affected versions:
- Release tag `v3.0.0`
- `labkit.ui` `3.1.3 -> 3.2.0`
- `labkit_launcher` `1.1.2 -> 1.1.3`

What changed:
- Improved UI diagnostics and validation documentation.
- Published the v3.0.0 release line around UI diagnostics, validation docs, and
  duplicate CI avoidance.

Why it matters:
- Maintainers got better evidence when app callbacks failed, and users got a
  clearer release line to roll back to.

Evidence:
- Main commits `21eff4dc` and release tag commit `349a7549`.

### 2026-06-29 - Protected image enhancement workflows

Affected versions:
- Image Enhance `1.2.2 -> 1.3.0`
- Image Match `1.2.1 -> 1.3.0`

What changed:
- Added protected image enhancement workflows.

Why it matters:
- The image enhancement apps gained a more deliberate workflow boundary before
  later image-facade adoption.

Evidence:
- Main commit `1768dd57`.

### 2026-06-28 - App diagnostics and hardened UI workflows

Affected versions:
- `labkit.ui` `3.1.0 -> 3.1.3`
- Batch Crop, Focus Stack, Image Enhance/Match, neurophysiology apps, and the
  launcher patch bumped where runtime behavior changed.

What changed:
- Hardened LabKit UI workflows.
- Added crash reports, active-operation reports, caught-error reports, and stall
  diagnostics.

Why it matters:
- Maintainers get structured failure evidence instead of relying on screenshots
  or vague crash reports.

Evidence:
- Main commits `e966457b` and `f5bc6f98`.

### 2026-06-28 - Batch Crop file workflow feedback

Affected versions:
- `labkit.ui` `3.0.1 -> 3.1.0`
- Batch Crop `1.2.0 -> 1.3.0`

What changed:
- Added selected-file title context.
- Improved Batch Crop file workflow feedback.

Why it matters:
- Users can see which selected file a preview or result belongs to.

Evidence:
- Main commit `61e8edd3`.

### 2026-06-25 to 2026-06-26 - Launcher manager and stale callback fix

Affected versions:
- `labkit_launcher` `1.0.0 -> 1.1.1`
- `labkit.ui` `3.0.0 -> 3.0.1`

What changed:
- Added the launcher version manager and managed-manifest requirement.
- Released stale image drag callbacks.

Why it matters:
- Users gained a deliberate path to choose recent releases, tags, or main
  commits, and image interactions stopped carrying stale callback state.

Evidence:
- Main commits `fe8654c9`, `ef89cf77`, and `3d23b7f1`.

### 2026-06-24 - File-panel migration

Affected versions:
- `labkit.dta` `1.0.0 -> 2.0.0`
- `labkit.ui` `2.2.1 -> 3.0.0`
- All supported apps moved from `1.0.x` into the `1.2.0` workflow line.

What changed:
- Replaced task inputs with file panels.
- Removed the old DTA session helper surface.

Why it matters:
- File selection became a shared UI workflow instead of app-specific task-input
  plumbing.

Compatibility:
- This was a breaking workflow migration. Older app code expecting task inputs
  or the removed DTA session helpers needed migration.

Evidence:
- Main commit `b145c904`.

### 2026-06-23 - Version metadata baseline

Affected versions:
- Release tag `v2.4.0`
- `labkit_launcher` `1.0.0`
- All supported apps `1.0.0`
- `labkit.ui` `2.1.0 -> 2.2.0`

What changed:
- Added app and launcher version metadata.
- Added versioned titles, lightweight version requests, launcher catalog version
  display, and version guardrails.

Why it matters:
- This is the first point where app and launcher versions became first-class
  user-facing metadata.

Evidence:
- Main commit `d70c2607`.

### 2026-06-23 - Facade contract baseline and release validation hardening

Affected versions:
- `labkit.biosignal` `1.0.0`
- `labkit.dta` `1.0.0`
- `labkit.rhs` `1.0.0`
- `labkit.ui` `2.0.0 -> 2.2.1`
- DIC Pre/Post and Curvature `1.0.0 -> 1.0.1`
- Release tags `v2.4.1` and `v2.4.2`

What changed:
- Added facade contract metadata and requirement checks.
- Hardened app lifecycle and release validation contracts.
- Routed MATLAB CI shards through build tasks.

Why it matters:
- Reusable facades gained explicit compatibility contracts before the later
  app-version and launcher-version work.

Evidence:
- Main commits `a25b79f9`, `3673e548`, `49d9f41b`, and `7e39b558`.

### Before component versions - 2026-05-28 to 2026-06-23

Affected versions:
- Release tags `v1.0`, `v2.0`, legacy `2.1`, `v2.2.0`, `v2.3.0`, `v2.3.1`,
  `v2.3.2`, and `v2.3.3`.

What changed:
- Imported legacy MATLAB code and split it into app entry points.
- Extracted DTA parsers, electrochem calculations, DIC workflows, image
  measurement workflows, biosignal support, and ECG workflows.
- Replaced root legacy GUI entry points with package-backed runners.
- Added app shell behavior, axes popout, shared UI controls, debug trace
  logging, launcher/project metadata, release updater support, and reproducible
  release-asset rules.

Why it matters:
- This is the period where LabKit changed from loose scripts into an app
  workbench with a small reusable foundation.

Compatibility:
- Component/app version files did not exist yet, so this era is tracked by
  release tags, commit ranges, and workflow milestones rather than per-app
  version numbers.

Evidence:
- Main history from `5973bde0` through `a7e7dfb1`.
- Release tags: `v1.0`, `v2.0`, `2.1`, `v2.2.0`, `v2.3.0`, `v2.3.1`,
  `v2.3.2`, `v2.3.3`.

## Maintenance Template

Use this format for new versioned changes:

```markdown
### YYYY-MM-DD - Short user-facing title

Affected versions:
- `component` `old -> new`

What changed:
- Plain-language change summary.

Why it matters:
- User or maintainer reason this version exists.

Compatibility:
- Migration or rollback note, when relevant.

Evidence:
- Main commit `sha`.
```

For branch work before the final mainline SHA is known, place the entry in
`Unreleased` with PR or branch evidence. During release preparation or a
changelog audit, move the finalized entry into `Version History` with the
mainline commit SHA.
