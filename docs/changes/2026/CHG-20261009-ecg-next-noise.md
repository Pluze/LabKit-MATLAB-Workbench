# Analyze every ECG beat with ECGNExT

```labkit-change
id: CHG-20261009-ecg-next-noise
date: 2026-10-09
type: feat
compatibility: breaking
component: labkit_ECGPrint_app | 2.2.2 -> 3.0.0
```

## Why

Fixed beat-relative residual windows can overlap physiological waves, and retaining two noise definitions makes results difficult to interpret. The accepted workflow replaces those measurements with ECGNExT extraction throughout the file analysis, plots, summary, and exports. Short-window noise estimates are attributed to individual beats with explicit provenance, rather than assigning one whole-record RMS to every beat.

## What changed

ECG Print prepares the selected channel at 1000 Hz, localizes R peaks on prepared raw ECG, and runs the pinned ECGNExT extraction core in overlapping windows. Each beat selects its nearest-center complete extraction candidate. A separate statistics branch centers successive one-second noise-output chunks following NST and computes per-beat noise RMS, filtered QRS peak-to-peak and SNR. Summaries report arithmetic means, sample variances and finite counts.

Results shows the ECG and per-beat trends; Signal chain shows the extraction stages and actual SNR inputs on synchronized time axes. The unchanged ECGNExT output remains separate from the centered statistics branch. Exports retain the applied values and provenance. Time controls follow the imported duration with 0.1-second steps. Filtering uses only the selected interval with reflected endpoint context, excluding discarded samples.

## Impact

Long recordings no longer require manual cropping into the extraction window length. Users can inspect every beat's measured noise, QRS amplitude and status, then export exactly those rows and their source provenance. P/T waves outside the QRS interval do not directly inflate its measured amplitude. Signal-chain noise retains the exact ECGNExT samples. NST chunk centering is separate from this output, and the per-beat SNR is identified as an App extension rather than NST aggregate calibration.

## Compatibility and limits

This major version replaces fixed-window residual metrics, their CSV schema, and configurable auxiliary filter/template controls. ROI exports now describe the prepared 1000 Hz grid with source time coordinates. The extraction core retains reference arithmetic; rate conversion, window overlap, beat attribution, and amplitude/RMS summaries are explicit App extensions. Boundary beats have no invented scores. Physiological suitability, peak accuracy, and morphology fidelity require appropriate review or matched-reference evidence.
