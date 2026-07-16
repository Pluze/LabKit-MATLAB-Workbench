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
result = nerve_response_analysis.analysisRun.analyzeRecording(recording, options);
trains = nerve_response_analysis.analysisRun.detectEventTrains(events, options);
metrics = nerve_response_analysis.analysisRun.measureCapMetrics( ...
    waveform, eventSamples, options);
```

For multiple recordings, use
`nerve_response_analysis.analysisRun.analyzeSession`.

## See Also

- [RHS Library](../../api/rhs.md)
- [Response Review and Stats](response-review-stats.md)

