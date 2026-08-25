# V4 stability contracts become explicit and machine-verifiable

```labkit-change
id: CHG-20260730-v4-stability-contract-closure
date: 2026-07-30
type: fix
compatibility: compatible
component: labkit.app | 2.0.3 -> 2.1.0
component: labkit.biosignal | 1.0.3 -> 1.0.4
component: labkit.dta | 3.0.0 -> 3.1.0
component: labkit.image | 2.0.3 -> 2.0.4
component: labkit.rhs | 1.0.3 -> 1.0.4
component: labkit.thermal | 1.1.2 -> 1.1.3
component: labkit_launcher | 1.8.1 -> 1.8.2
component: labkit_DICPostprocess_app | 1.6.0 -> 1.6.1
component: labkit_DICPreprocess_app | 1.7.0 -> 1.7.1
component: labkit_ChronoOverlay_app | 1.6.0 -> 1.6.1
component: labkit_CIC_app | 1.6.0 -> 1.6.1
component: labkit_CSC_app | 1.6.0 -> 1.6.1
component: labkit_EIS_app | 1.6.0 -> 1.6.1
component: labkit_VTResistance_app | 1.6.0 -> 1.6.1
component: labkit_GaitAnalysis_app | 2.2.0 -> 2.2.1
component: labkit_BatchImageCrop_app | 1.9.1 -> 1.9.2
component: labkit_CurvatureMeasurement_app | 1.6.0 -> 1.6.1
component: labkit_FLIRThermal_app | 1.6.0 -> 1.6.1
component: labkit_FocusStack_app | 1.7.0 -> 1.7.1
component: labkit_ImageEnhance_app | 1.8.0 -> 1.8.1
component: labkit_ImageMatch_app | 1.8.0 -> 1.8.1
component: labkit_VideoMarker_app | 1.7.0 -> 1.7.1
component: labkit_FigureStudio_app | 0.7.1 -> 0.7.2
component: labkit_NerveResponseAnalysis_app | 1.6.0 -> 1.6.1
component: labkit_ResponseReviewStats_app | 1.6.0 -> 1.6.1
component: labkit_RHSPreview_app | 1.6.0 -> 1.6.1
component: labkit_TTestWizard_app | 1.3.0 -> 1.3.1
component: labkit_ECGPrint_app | 1.6.0 -> 1.6.1
```

## Why

The V4 architecture had stable ownership boundaries, but several behaviors still relied on inference or permissive fallback: project source fields were derived from UI layout, option structures ignored unknown fields, DTA failures required message parsing, and invalid scientific settings could cross a saved project boundary. Runtime V2 had also lost the prior cross-window input and output folder memory.

### Accepted choice

Close those gaps with additive metadata, stable private mechanics, focused validation, and compatibility fallbacks. Built-in Apps explicitly declare portable-source fields, while external definitions that omit the declaration retain layout inference. Existing project payloads and App entrypoints remain unchanged.

## What changed

- Added project `SourceBindings`, accepted-document fingerprints, and external overwrite rejection with an unaffected Save As path.
- Restored separate last-successful input/output folder preferences across App windows and preserved explicit valid start-path precedence.
- Closed documented option structures in biosignal, image, RHS, and thermal facades; added DTA status codes and strict ECG, gait, focus, and thermal invalid-input handling.
- Replaced append-only runtime status history with one current status value and avoided redundant Launcher path refresh on a correctly resolved install.
- Made the fixed repair-root dispatcher and fixed Launcher tool calls statically visible. The three remaining production `feval` boundaries now validate a discovered App file, a legacy named MATLAB callback, or an exact profiler target file, and a repository test rejects any additional hidden production call.
- Added repository Skill manifests, activation examples, deterministic validation, CI routing, and a scientific-change workflow; compressed promoted experience out of the reservoir.
- Replaced the `framework/*`, `system/*`, and private `tests/cases` test taxonomies with production-path mirrors. Public and accepted private specifications now use the same path-derived owner, contract/environment metadata, compiled plan, progress, and heartbeat contracts.
- Cleared Code Analyzer information, warning, and error findings across the public MATLAB source and test tree without suppression pragmas. Collection preallocation preserves each empty cell, struct, string, and numeric shape rather than relying on append growth or untyped concatenation.

## Impact

Ordinary valid workflows and numerical outputs are preserved. App file choosers again begin in the last successful folder when no valid start path is provided. Stale windows no longer silently overwrite a project file changed outside LabKit. Invalid or hand-edited settings fail earlier with stable identifiers or codes.

## Compatibility and limits

The change is backward compatible. Existing project payload versions, saved source records, result schemas, and exports require no migration. Omitted `SourceBindings` keep the former inference behavior, and the restored dialog preferences reuse the published `LabKit/LastInputFolder` and `LabKit/LastOutputFolder` keys. The maintainer profiler no longer accepts an arbitrary command string; pass a function handle for calls that need arguments or setup state.

### Remaining limits

Automated tests cannot assess native dialog appearance or real laboratory data quality. Those remain manual platform and domain-review boundaries; no known code migration debt remains from this stability batch.
