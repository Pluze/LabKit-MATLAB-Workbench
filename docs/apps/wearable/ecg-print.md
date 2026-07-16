# ECG Print

ECG Print filters wearable ECG, detects peaks, measures segment quality, and
creates printable review outputs.

## Launch

```matlab
labkit_ECGPrint_app
```

## Workflow

Load a supported ECG recording, verify channel and sample-rate metadata,
configure filtering and peak detection, review detected beats and segment SNR,
then export the report and measurements.

## Scientific Semantics

Filtering, polarity, minimum peak spacing, and SNR windows affect detection and
must accompany reported heart-rate or quality results. The app retains source
timing and does not infer a sample rate when required metadata is absent.

## Use Without The GUI

`analyzeSignal` operates on the same decoded cache and durable parameters used
by Runtime V2:

```matlab
[recording, status] = labkit.biosignal.readRecording("ecg.csv");
assert(status.ok, status.message);
signalRecord = labkit.biosignal.getChannel(recording, 1);
cache = struct("signal", signalRecord);
parameters = struct( ...
    "lowCut", 0.5, "highCut", 40, ...
    "roiStart", 0, "roiEnd", 0, ...
    "peakMethod", "QRS streaming", "peakDistance", 0.25, ...
    "segmentWindow", 0.4, "templateTopN", 20);
cache = ecg_print.analysisRun.analyzeSignal(cache, parameters);
```

`signalRecord` is the normalized biosignal record returned by the app importer
or `labkit.biosignal.readRecording`, not a bare numeric vector. The returned
cache adds `workingSignal`, `filteredSignal`, `events`, `segments`, `template`,
and `measurements`. When `roiEnd <= roiStart`, the full signal is analyzed.
The upper cutoff is constrained below the Nyquist frequency.

For a smaller script that does not need the app cache, compose the public
facade functions directly: `filterSignal`, `detectEcgPeaks`,
`segmentByEvents`, `buildTemplate`, and `measureSegments`.

## Outputs

- detected peak and interval tables;
- segment SNR and summary measurements;
- printable ECG figures or reports.

## Errors And Limitations

- Required channel and sampling metadata must be present in the normalized
  recording.
- Automatic polarity and threshold selection still require visual review when
  morphology or noise changes across a recording.
- Filter settings, detection options, and excluded time ranges belong with any
  derived heart-rate or signal-quality result.

## See Also

- [Biosignal Library](../../api/biosignal.md)
- `ecg_print.analysisRun.analyzeSignal`
