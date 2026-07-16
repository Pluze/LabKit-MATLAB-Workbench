# Nerve Response Analysis

Nerve Response Analysis detects stimulation events in Intan RHS recordings and
measures compound action potential responses.

## Launch

```matlab
labkit_NerveResponseAnalysis_app
```

## Workflow

Load a recording or session, select channels, configure event and train
detection, review detected windows, then compute and export CAP metrics.
Interactive review separates detection decisions from numeric measurement.

## Scientific Semantics

Event thresholds and refractory rules identify candidate stimulation times.
Train grouping operates on event spacing. CAP metrics are measured in explicit
baseline and response windows with the recording sample rate and channel units
preserved.

## Use Without The GUI

```matlab
protocol = struct();  % Supply channel roles and analysis pairs when available.
options = struct("recordingId", "recording-1", "maxDurationSec", 30);
analysis = nerve_response_analysis.analysisRun.analyzeRecording( ...
    "recording.rhs", protocol, options);
```

The result contains the source identity, protocol snapshot, detected `events`
and `trains`, per-pair CAP `metrics`, and an `issues` table. Parse or detection
problems are represented in `issues` so a batch can retain successful files.
For multiple recordings, use
`nerve_response_analysis.analysisRun.analyzeSession`.

The detector and metric stages can also be called on already decoded arrays:

```matlab
[events, trains] = ...
    nerve_response_analysis.analysisRun.detectEventTrains( ...
    timeSec, eventSourceSignal, eventOptions);
metrics = nerve_response_analysis.analysisRun.measureCapMetrics( ...
    timeSec, responseSignal, events.timeSec, metricOptions);
```

`timeSec` and each signal must be equal-length column-compatible numeric
vectors. `eventOptions` controls derivative-score thresholding, minimum event
spacing, train grouping, isolation, and the physical stimulus-time shift.
`metricOptions` controls the pre-stimulus baseline, post-pulse blanking, and CAP
search end. Metric output includes baseline and noise, positive and negative
peaks, peak-to-peak amplitude, latency, SNR, and per-event status.

## Errors And Limitations

- Vector length mismatches throw named size errors; missing detections return
  empty tables rather than invented events.
- Default timing windows are policies, not universal physiology. Save the
  exact options and protocol used for each analysis.
- A derivative peak identifies an electrical transition; validate its relation
  to physical stimulus onset before interpreting latency.

## See Also

- [RHS Library](../../api/rhs.md)
- [Response Review and Stats](response-review-stats.md)
- `nerve_response_analysis.analysisRun.detectEventTrains`
- `nerve_response_analysis.analysisRun.measureCapMetrics`
