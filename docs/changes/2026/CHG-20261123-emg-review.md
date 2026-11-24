# Review EMG noise and spectral content

```labkit-change
id: CHG-20261123-emg-review
date: 2026-11-23
type: feat
compatibility: compatible
component: labkit_EMGReview_app | new -> 1.0.0
```

## Why

A defensible EMG noise comparison needs traceable baseline and activity windows, a stated SNR model, and a way to see whether energy is distributed across the band or concentrated near line frequency.

## What changed

EMG Review supports manually placed or automatically suggested pairs, mean-removed RMS, noise-corrected SNR, paired spectra, a 60 Hz detail view, a recording spectrogram and per-pair CSV export.

## Impact

Users can inspect numbered pairs against the waveform and compare recordings using an explicit measurement band and a common ROI duration.

## Compatibility and limits

The analysis covers one channel at a time. Automatic selection is based on amplitude and requires review against the experiment. SNR requires positive baseline power, higher activity power and a suitable additive-noise assumption.
