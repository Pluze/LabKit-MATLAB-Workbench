# Changelog

Release-facing changes are summarized here. Keep detailed refactor history in git history and current behavior in `docs/`.

## Unreleased

### Added

- Current app families cover electrochemistry/DTA workflows, DIC image workflows, general image measurement, and an exploratory wearable ECG viewer.
- Reusable app-facing facades are `labkit.ui.*`, `labkit.dta.*`, and `labkit.biosignal.*`.
- GitHub Actions runs the default non-GUI MATLAB suite; local profiles cover focused GUI launch/layout checks.

### Changed

- Apps now use the unified resizable tabbed workbench shell, with scrollable left tabs and right-side plot/output regions.
- DTA parsing, sessions, pulse detection, and parsed curve/table access are behind the DTA facade.
- Biosignal loading, CSV repair, filtering, ECG peak detection, segmentation, templates, and SNR-style measurements are behind the biosignal facade.
- ECG filtering uses reflected edge padding/tapering, and the ECG app crops ROI after filtering.
- Public facade comments and docs now describe option fields, defaults, and legal values.
- Documentation has been shortened toward current user-facing behavior instead of historical refactor narration.

### Fixed

- CSV/time handling for biosignal imports supports preambles, headerless numeric data, epoch-like timestamps, duplicate/backward timestamps, and retained large gaps.
- Pan-Tompkins and streaming ECG peak detection perform final raw-signal peak snapping; streaming reviews recent anchors against the signal median to correct inverted anchors.

### Removed

- Removed public `+labkit/+io`, `+labkit/+data`, `+labkit/+analysis`, `+labkit/+util`, `+labkit/+plot`, and `+labkit/+app` surfaces.
- Removed root-level legacy wrappers, transitional app-helper namespaces, copy-only templates, and obsolete refactor-history documents.

## v1.0.0 - 2026-05-28

### Added

- Initial package-backed MATLAB modules under `+labkit`.
- App entry points under `apps/` for CIC, VT resistance, CV/CSC, and EIS workflows.
- Named DTA fixtures and MATLAB test runners.
- Initial documentation for architecture, data models, file formats, and validation.

### Preserved

- Scientific calculations and result definitions.
- Parser behavior for legacy-supported DTA file families.
- Pulse detection behavior.
- GUI layout and callback behavior.
- Plot labels, markers, axes, and visual behavior.
- CSV/export formats and column names.
