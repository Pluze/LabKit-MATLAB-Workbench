# ECG Print links time review and exposes complete quality trends

```labkit-change
id: CHG-20260903-ecg-linked-signal-review
date: 2026-09-03
type: feat
compatibility: compatible
component: labkit_ECGPrint_app | 2.1.1 -> 2.2.0
```

## Why

ECG Print presented related time trends in separate viewports, reported only aggregate SNR, and required a manual choice between two complementary template views. Waveform and quality scales also omitted usable source identity and amplitude-unit context.

### Accepted choice

Keep the existing `SignalP2P`, `NoiseRMS`, and `SNRdB` formulas and improve their App-owned presentation. Replace the former ideal FFT mask with a finite, symmetric Hamming-windowed sinc FIR whose linear-phase delay is compensated during application. Link the absolute-time axes, make scroll zoom operate on time while each axis fits its visible Y data, add the existing peak-to-peak measurement as a trend and summary statistic, and show both existing template renderings at once. Use imported signal units when available and label otherwise uncalibrated samples as ADC counts. Allow peak locations to come from an optional second FIR applied after the main filter while retaining the main filtered signal as the only measurement and template source.

## What changed

- Waveform, noise RMS, peak-to-peak, and SNR trends share one time window and refit their own visible amplitudes after time zoom.
- Peak-to-peak amplitude gains its own raw and smoothed trend between noise and SNR.
- Residual-band and individual-segment template views appear side by side without a view selector.
- The waveform title uses the source filename, and amplitude labels include the imported unit or the ADC-count fallback.
- The summary adds mean and sample-standard-deviation values for peak-to-peak amplitude and noise RMS alongside SNR.
- Bandpass control limits follow the selected signal's Nyquist frequency, and the initial 0-to-Nyquist main band is an explicit no-filter state.
- Non-bypass bands use a stable odd-length linear-phase FIR with reflection padding and delay-compensated FFT convolution; tap count follows approximately four seconds of data and is capped at 8001.
- An optional second-stage bandpass can supply peak locations without changing the signal used for segments, templates, peak-to-peak, noise, or SNR.
- Filter Details derives magnitude, continuous phase, group delay, and impulse response from the production FIR coefficients for the first bandpass and, when enabled, the second and cascaded operations.
- Analysis-control edits remain pending without plot work. File, parse, and channel changes immediately replace and refit the waveform and clear stale derived plots; one successful Analyze action then builds and publishes all filtered waveform, metric, template, and filter-response models together.

## Impact

Users can inspect the same time interval across signal-quality measures without manually synchronizing axes and can compare both template diagnostics without switching state. Optional second-stage detection can change peak locations, while measurement formulas, measurement inputs after anchoring, and export schemas remain unchanged. Avoiding plot work during control edits keeps filter tuning responsive even for long recordings.

## Compatibility and limits

Existing in-memory project values that still contain the retired template-view preference remain readable because extra App-owned fields are ignored. The ADC-count label communicates an absent calibration unit; it does not convert or reinterpret sample values. Automatic visible-Y fitting is limited to the four absolute-time preview axes.
