# Biosignal and ECG Print detect and normalize recording formats

```labkit-change
id: LK-20260817-biopac-biosignal-import
date: 2026-08-17
sequence: 180
type: feat
compatibility: breaking
component: `labkit.biosignal` | `1.0.4 -> 2.0.0`
component: `labkit_ECGPrint_app` | `1.7.0 -> 2.0.0`
scope: Automatic biosignal format detection and uniform sampling
scope: BIOPAC AcqKnowledge MAT and text recording import
```

## Context

BIOPAC AcqKnowledge MAT exports store a sample-by-channel matrix beside sample-interval, label, and unit variables rather than a MATLAB timetable. BIOPAC text exports could already be parsed numerically, but their preamble channel labels and units were not retained.

## Decision and rationale

Extend the existing GUI-free `labkit.biosignal.readRecording` import boundary because device decoding and sampling normalization are reusable recording concerns and ECG Print already consumes that contract. Rank private readers from lightweight file facts, fall back only among compatible formats, expose the decision through existing return structures, and keep the public call unchanged. Normalize channels to a median-interval uniform grid without interpolating across large timestamp gaps.

## Changes

- BIOPAC MAT exports with `data`, `isi`, `isi_units`, `labels`, and `units` now produce one normalized signal per data column.
- Recognized BIOPAC text preambles now replace generic channel identifiers with exported labels and attach the exported engineering units.
- MAT timetable, table, BIOPAC, and unambiguous numeric-array readers participate in an ordered fallback plan; delimited files report generic or BIOPAC text detection.
- Successful and failed imports expose file facts, resolved format, fallback state, and attempt details through the existing outputs.
- Decoded channels are uniformly sampled by default after removing non-finite times, ordering samples, dropping duplicate timestamps, and applying segmented linear interpolation with explicit normalization metadata.
- ECG Print declares the newer biosignal contract and reports format, fallback, and uniform-sampling cleanup.
- ECG Print never sends binary MAT contents to the Summary header-preview control; MAT recordings show a bounded format notice instead.

## User and data impact

Users can open supported BIOPAC MAT and text exports, MAT tables, timetables, and simple numeric MAT recordings directly in ECG Print. BIOPAC channels use exported names and units. Uniform input samples are not rescaled; irregular continuous sections are linearly resampled, and large timestamp gaps are compressed between independently resampled sections rather than bridged.
Opening Summary after analyzing a MAT recording no longer risks rendering an unbounded binary line as UI text.

## Compatibility and migration

Existing calls and saved ECG Print projects require no migration. The format and file-information fields are additive. Uniform resampling is the new default data contract; callers that require the earlier parser-produced irregular time axis can pass `resampleUniform=false`.

## Validation

Focused biosignal source specifications cover BIOPAC MAT interval conversion, labels, units, start-sample provenance, BIOPAC text preamble mapping, ranked MAT fallback, table and numeric MAT inputs, quoted time headers, segmented uniform resampling, its opt-out, and existing timetable and delimited imports. ECG source specifications restrict header preview to supported text extensions and bound both bytes read and rendered line length. The supplied recording samples and format inventory are checked through the public importer without copying them into the repository.

## Evidence

Ten focused biosignal source identities, four ECG source-file identities, two ECG workbench presentation identities, and six ECG definition/product conformance identities passed. The workbench workflow includes analysis followed by a Summary-tab switch. The nine supplied MAT/text/CSV samples, both supplied MAX86178 CSVs, and representative real MAT table and timetable files imported successfully with uniform output time. Private recording data was not copied into the repository.

## Known limitations and follow-up

BIOPAC matrix exports must use one shared sample interval. Native Origin OPJU projects are not recording inputs because production code cannot depend on Origin or another third-party runtime. Spreadsheet files found in the reviewed workspace contain analysis summaries rather than raw time-series recordings and remain outside this importer.
