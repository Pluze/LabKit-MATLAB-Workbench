# Changelog

All notable user-facing and maintainer-facing changes are recorded here.

## Unreleased

### Changed

- Documentation now frames LabKit as an internal lab app workbench with independent workflow apps, conservative public library growth, and app-owned domain logic.
- Project licensing is now explicit: LabKit MATLAB Workbench is released under the MIT License.
- Added a `labkit.biosignal` facade for GUI-free MAT/table recording loading, channel extraction, time ROI cropping, filtering, generic peak detection, event-centered segmentation, template-residual SNR-style measurements, and group comparisons.
- Added an experimental wearable ECG print/SNR explorer app with waveform preview, explicit CSV import parsing controls, file-header preview, time ROI, peak/segment SNR analysis, SNR-over-time plotting, and CSV/PNG exports.
- Reusable package, startup, and app entrypoint names now use the generic `labkit` namespace.
- Added DIC preprocess and postprocess apps built on the shared UI foundation, with image registration, paired crop, Ncorr strain overlay, and ROI summary logic kept app-local.
- Added an image measurement app category with a curvature measurement app that edits curve anchors directly on a single large image preview, measures scale bars with a two-anchor edit mode, fits a circle, optionally shows densified fit points, keeps anchors plus radial residual distances visible after fitting, reports curvature, and exports overlays and result CSV files without adding the workflow to DIC.
- Reusable UI now includes an anchor-curve editor for image axes, covering DIC-style double-click add/insert/delete anchors, drag-to-move anchors, curve/straight-line preview, and scroll-wheel zoom.
- DIC image/overlay apps now use a pure dual-output right pane without empty plot-control rows, left-side DIC section heights can be resized manually, DIC preprocess crop ROI selection happens inline on the right preview with synchronized crop-pair display, and DIC strain summaries include min/max values.
- DIC postprocess overlays now extend strain maps from valid ROI data before smoothing/resizing and clip the display back to the ROI/mask to avoid zero-filled edge leakage; optical reference-image enhancement controls were added for brightness, contrast, gamma, saturation, and RGB channel gains.
- DIC postprocess can export a standalone strain colorbar PNG plus a CSV mapping strain levels to RGB values, and DIC preprocess can draw editable curve or straight-line ROI boundaries with double-click add/insert/delete, drag-to-move, and preview controls before saving white-inside/black-outside ROI masks.
- DIC preprocess now keeps original and current image pairs, supports repeated crop/manual-align/auto-align operations in either order with undo, shows false-color differences before alignment, and uses one save action for the current image pair.
- DIC preprocess ROI editing now handles preview scroll-wheel zoom directly during direct point editing and no longer needs a separate pan/zoom mode button.
- DIC preprocess ROI masks now have a canvas workflow for unioning a boundary into the mask, subtracting a boundary from the mask, undoing canvas edits, previewing, and saving the resulting binary mask.
- Left-side workbench tabs now make their content grids scrollable, so app-specific control sections can extend below the visible window without clipping inaccessible panels.
- Left-side workbench tab sections can now declare draggable row boundaries at the UI framework level without exposing spacer rows or changed `Layout.Row` numbering to apps.
- MATLAB test runner now supports `--profile`, `--suite`, and `--test` filters for focused validation without running unrelated app families; GUI layout checks are split into UI, DIC, and electrochemistry scopes.
- Chrono DTA loading now exposes `item.controlMode` / `meta.controlMode` for current-controlled, voltage-controlled, or unknown chrono files, and CIC/VT summary panels display that mode for the selected file.
- Public app-facing package surface is now `labkit.ui.*` plus `labkit.dta.*`.
- DTA parser helpers, session save/load, item/session construction, pulse internals, and parsed table/curve access now live behind the DTA facade or under `+labkit/+dta/private`.
- Current app implementations are single public files under `apps/`; experiment-specific analysis, plotting, result tables, and CSV/export schemas stay app-local.
- Documentation and architecture tests now guard against reintroducing public `+io`, `+data`, `+analysis`, `+util`, app-helper packages, or legacy wrapper entry points as app-facing APIs.
- `startup_labkit` now adds nested app category folders so app entry points resolve without changing into app directories.
- Current app GUIs now share the same resizable tabbed workbench shell: scrollable control tabs on the left and plot/output content on the right.
- App shells now use the standard three-tab workbench framework, and DTA-facing apps share the same file-selection panel structure.
- GUI app entry points now build from the unified `labkit.ui.createWorkbench` shell, with compatibility shell wrappers layered over that entry point.
- Reusable UI components now include generic panel-grid creation and single/multi listbox selection refresh so app files can define domain-specific sections with less layout boilerplate.
- README and docs now describe the current app/UI/DTA architecture directly instead of framing the project as an active refactor.
- Docs are now organized around the reusable UI library, current DTA library, app-owned workflow details, testing, and architecture.
- Copy-only MATLAB template files were removed; their app-starting guidance now lives in the app documentation.
- DTA fixture files moved from `demo/` to `tests/fixtures/dta/` to make their role as test/example fixtures explicit.
- GitHub Actions now runs the default non-GUI MATLAB test suite on pushes and pull requests to `main`.
- README now displays the MATLAB Tests workflow badge, and docs describe CI coverage versus local GUI/manual validation.
- Agent/testing docs now require concise Conventional Commit-style messages for future commits.

### Fixed

- CSC app file loading now preserves the loaded session item struct shape while updating app state, and GUI tests cover loading a CV/CT fixture through the CSC app refresh path.
- Biosignal delimited-table loading no longer treats any monotonic numeric column as seconds; time columns now require explicit time-like names or caller-provided `timeColumn`/`timeUnit` options, otherwise synthetic sample-index time is used.
- Biosignal CSV loading now handles preambles, headerless numeric data, text-preserved epoch timestamps, backward timestamp jumps, duplicate timestamps, and retained large positive time gaps more robustly.

### Removed

- Public `+labkit/+io`, `+labkit/+data`, `+labkit/+analysis`, `+labkit/+util`, `+labkit/+plot`, and `+labkit/+app` app-facing surfaces.
- Transitional `apps/private` and `apps/+labkit_apps` helper namespaces.
- Root-level wrappers for the original legacy GUI command names and the old `legacy/` reference directory.
- One-line or app-specific reusable wrappers that only hid MATLAB built-ins or experiment decisions.
- The archived refactor-history document.

## v1.0.0 - 2026-05-28

### Added

- Package-backed parser, data, analysis, plotting, export, session, and UI helper modules under `+labkit`.
- App entry points under `apps/` for CIC, VT resistance, CV/CSC, and EIS workflows.
- Root-level compatibility wrappers for the original legacy GUI command names.
- Named DTA fixtures and MATLAB test runners.
- Current documentation under `docs/` for architecture, data models, file formats, and validation.

### Preserved

- Scientific calculations and result definitions.
- Parser behavior for legacy-supported DTA file families.
- Pulse detection behavior.
- GUI layout and callback behavior.
- Plot labels, markers, axes, and visual behavior.
- CSV/export formats and column names.
