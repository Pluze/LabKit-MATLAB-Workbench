# File collections support consistent selection and validation

```labkit-change
id: LK-20260803-file-selection-validation
date: 2026-08-03
sequence: 170
type: fix
compatibility: compatible
component: `labkit.app`
component: `labkit_ChronoOverlay_app` | `1.6.1 -> 1.6.2`
component: `labkit_CIC_app` | `1.6.1 -> 1.6.2`
component: `labkit_CSC_app` | `1.6.1 -> 1.6.2`
component: `labkit_EIS_app` | `1.6.1 -> 1.6.2`
component: `labkit_VTResistance_app` | `1.6.1 -> 1.6.2`
component: `labkit_BatchCrop_app` | `1.9.2 -> 1.9.3`
component: `labkit_FLIRThermal_app` | `1.6.1 -> 1.6.2`
component: `labkit_FocusStack_app` | `1.7.1 -> 1.7.2`
component: `labkit_ImageEnhance_app` | `1.8.1 -> 1.8.2`
component: `labkit_ImageMatch_app` | `1.8.1 -> 1.8.2`
component: `labkit_FigureStudio_app` | `0.7.2 -> 0.7.3`
component: `labkit_RHSPreview_app` | `1.6.1 -> 1.6.2`
scope: Electrochemistry multi-file import
scope: Folder and recursive DTA filtering
scope: App SDK file-list path predicates
scope: Cross-App file chooser consistency
scope: FLIR radiometric candidate validation
```

## Context

CIC, CSC, and VT Resistance configured their file dialogs for single
selection even though their workflows and exports support batches. Folder and
recursive-folder actions selected every `.DTA` path by extension, so a folder
containing another Gamry experiment type caused session reconstruction to
fail transactionally and discarded compatible files in the same batch.
FLIR Thermal, Batch Crop, and Figure Studio also represented file collections
with single-selection controls, while several file buttons still duplicated
legacy folder wording despite separate folder actions. File-panel parsing
exceptions had no framework-owned alert fallback.

## Decision and rationale

Extend the existing App SDK file-list contract with a domain-neutral batch
path predicate and a standard aggregate filtering notice. Keep experiment
type detection in each electrochemistry App through the DTA facade: the SDK
owns selection lifecycle and interaction consistency, while Apps retain the
scientific meaning of chrono, CV/CT, and EIS inputs.
Apply the same acquisition contract across every public App: collections are
multi-select, semantic one-file slots remain explicitly bounded, and file
buttons do not claim folder behavior. Keep radiometric acceptance in FLIR
Thermal through the thermal facade, and let the private native adapter surface
otherwise-unhandled file-action failures without changing App-owned wording.

## Changes

- Added `PathFilter` and `PathFilterDescription` to
  `labkit.app.layout.fileList`.
- Applied predicates only to newly proposed paths, retained previously
  accepted sources, validated the returned logical mask, and omitted rejected
  paths before portable source records were created.
- Added one aggregate, filename-free notice when unsupported files are
  filtered.
- Enabled native multi-file selection for CIC, CSC, and VT Resistance.
- Declared chrono, CV/CT, or EIS predicates for all five electrochemistry Apps.
- Enabled multi-file selection for FLIR Thermal, Batch Crop, and Figure Studio.
- Removed legacy folder wording from file buttons across affected image and
  neurophysiology Apps while preserving the separate folder/tree controls.
- Added FLIR content-level candidate inspection so ordinary JPEGs, unreadable
  payloads, and wrong file types are omitted with the standard aggregate alert.
- Added a native file-panel error fallback so an unhandled parsing or
  validation failure is presented in an alert after transactional rollback.

## User and data impact

Users can select several files at once and import a folder or folder tree even
when it contains other DTA experiment types. Matching files keep their order
and portable identities; unsupported paths are not stored. The notice reports
counts only and does not expose source filenames or paths. Source files and
saved project schemas are unchanged.
Single-file roles such as a DIC image, protocol JSON, video, or source table
remain intentionally limited to one file. No scientific calculation, source
payload, or result schema changes.

## Compatibility and migration

The change is compatible. Existing projects reopen without migration, existing
accepted sources remain registered, and Apps requiring `labkit.app >=2 <3`
remain within that range. Scientific formulas, units, analysis parameters,
result schemas, and export values are unchanged.

## Validation

Focused App SDK source specifications cover callback signature validation,
batch mask application, preservation of existing sources, portable-source
alignment, and aggregate notice wording. App-owned source specifications cover
chrono, CV/CT, and EIS discrimination. One existing hidden-GUI workflow per
electrochemistry App covers the mixed batch through plotting, analysis,
export, and project restore; CIC, CSC, and VT Resistance also verify native
multiple selection.
The public-App conformance specification checks every compiled file collection
for multi-selection and unambiguous file-button wording. FLIR source evidence
covers readable radiometric data, ordinary JPEGs, and wrong extensions. A
hidden native SDK specification verifies that an unhandled source parsing
failure produces an error alert.

## Evidence

- App SDK plus five App source specification files: 29 identities passed.
- Five electrochemistry hidden-GUI workflow specification files: 5 identities
  passed.
- Cross-App file-entry and SDK/FLIR focused specifications: 64 identities
  passed across 21 public Apps.

## Known limitations and follow-up

Automated tests do not operate native file and folder dialogs or prove
behavior on approved laboratory data. The predicates use the supported DTA
content detector; a malformed file that cannot be classified is intentionally
reported as filtered rather than registered as an analysis source. Hidden GUI
tests do not operate native file or folder dialogs, so manual dialog feel and
platform-specific chooser rendering remain outside automation.
