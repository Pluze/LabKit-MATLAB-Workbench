# ECG Print exports the analyzed region as a timetable

```labkit-change
id: LK-20260804-ecg-analysis-region-timetable-export
date: 2026-08-04
sequence: 173
type: feat
compatibility: compatible
component: `labkit_ECGPrint_app` | `1.6.1 -> 1.7.0`
scope: Current analysis-region timetable export
```

## Context

ECG Print exposed the current waveform visually and could export segment SNR
measurements or a rendered image, but it did not provide the sample-aligned raw
and filtered analysis region for continued MATLAB work.

## Decision and rationale

Build one App-owned timetable from the most recent successful analysis cache
and use it for both export paths. Keep preview-relative analysis time as row
times, retain absolute decoded source time as a column, and include the raw
signal, filtered signal, and detected-peak mask. This preserves the scientific
selector and units without rerunning analysis or silently applying edited
controls. The fixed base-workspace assignment is a narrowly reviewed dynamic
boundary; it does not expand the shared App SDK for one consumer.

## Changes

- The Exports section adds actions for the MATLAB base workspace and a MAT
  file.
- Both actions produce `ecgAnalysisRegion`, including channel, unit, sample
rate, and requested source-range metadata.
- The MAT export writes the normal LabKit result manifest beside the data.

## User and data impact

Users can continue analysis directly from the currently displayed ECG region
without reconstructing its crop, filter result, or peak indices. Existing
projects and existing CSV and PNG exports are unchanged.

## Compatibility and migration

The project schema adds an empty-or-compact MAT export record; existing
projects migrate by adding that field without changing analysis inputs or
results. The new timetable and buttons are otherwise additive. Repository
policy permits this kind of base-workspace export when both workspace and
variable names are literal and the exported value is validated data rather
than a runtime object.

## Validation

Focused ECG result and hidden-GUI workflow specifications cover timetable
shape, time semantics, units, peak markers, workspace assignment, MAT
round-trip, and manifest creation. The repository architecture specification
guards the single reviewed workspace-write boundary.

## Evidence

- Seven focused ECG result, workflow, and project identities passed.
- The exact dynamic-invocation architecture identity passed.
- The hidden-GUI workflow verified workspace assignment, MAT round-trip,
  manifest creation, project save, and project restore.

## Known limitations and follow-up

Automated tests do not assess whether downstream user scripts prefer different
column labels or additional derived measurements. The export intentionally
contains analyzed samples and detector markers, not segment SNR metrics.
