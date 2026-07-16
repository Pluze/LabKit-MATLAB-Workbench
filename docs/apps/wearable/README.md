# Wearable Apps

The wearable family analyzes recorded physiological signals through reusable
`labkit.biosignal` data structures and app-owned workflows.

## App

[ECG Print](ecg-print/README.md) reads a MAT timetable or delimited table,
selects a time region, filters the waveform, detects peaks, builds aligned
segments and a template, and reports segment SNR.

## Programmatic Entry Points

The [Biosignal Library](../../libraries/biosignal/README.md) exposes recording import,
channel selection, filtering, peak detection, event segmentation, template
construction, and segment measurement. The cataloged
`ecg_print.analysisRun.analyzeSignal` function composes those operations using
the same durable parameters as the app.
