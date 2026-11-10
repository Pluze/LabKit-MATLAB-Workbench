# ECG preview, beat templates and drift-reduced noise statistics

```labkit-change
id: CHG-20261109-ecg-preview-and-polarity
date: 2026-11-09
type: fix
compatibility: breaking
component: labkit_ECGPrint_app | 3.0.1 -> 4.0.0
component: labkit.biosignal | 3.0.1 -> 3.0.2
```

## Why

Recording refresh reset the plot revision, allowing a reused source identity to retain an obsolete viewport. Automatic ECG peak direction also differed across detectors: absolute candidate localization could alternate lobes, while streaming median correction preferred positive anchors. Template formation and window-specific extracted noise needed a dedicated inspection view. Fixed-second noise centering did not follow beat ownership and left within-block drift in per-beat RMS; drift-reduced statistics require fitting on the actual samples of each beat.

## What changed

Recording refresh advances the existing plot revision so the decoded preview refits once. A dedicated Templates page shows a window dropdown with file-time ranges and status, followed by the selected final template with all aligned heartbeats, the exact detrended per-beat SNR samples using the same horizontal alignment, and all-window final-template overlays. Results retains its full-width beat measurements. Each complete beat’s noise is fitted against its retained reference time to remove a constant and linear trend before RMS/SNR calculation. Exports retain the detrended samples, removed trends and fit coefficients; raw ECGNExT noise remains unchanged. Automatic detection now determines one direction from the median signed amplitude of preliminary absolute-polarity candidates and records the resolved direction before repeating detection.

## Impact

Users can review template agreement across windows and compare each window’s per-beat noise on the same R-relative coordinates as its aligned ECG segments. ECG Print assumes positive R peaks and explicitly requests positive anchors through detector and raw refinement. Library auto mode preserves negative recordings and uses a common direction. See the [ECG Print manual](../../use/apps/wearable/ecg-print/README.md) and [biosignal guide](../../develop/libraries/biosignal/README.md).

## Compatibility and limits

ECG Print noise/SNR semantics change: `NoiseRMS` and `QRSNoiseDb` use per-beat linear detrending, and the MAT `nstNoise` branch is replaced by `statisticsNoise`. CSV names remain stable but values from different definitions require method-aware comparison. The ECGNExT extraction core, amplitude units and SNR ratio formula are unchanged. Library explicit polarity modes remain supported. Automatic peak indices, templates and downstream measurements can change. Dominant polarity does not establish the physiological R lobe. Linear detrending also excludes genuine low-frequency noise components, has no fixed frequency cutoff and does not validate physiological signal quality. Templates reuses the exact detrended samples used for each reported beat SNR, retaining its winning-window provenance when template windows overlap.
