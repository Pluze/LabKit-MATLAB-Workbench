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

```matlab
result = ecg_print.analysisRun.analyzeSignal(signal, sampleRate, options);
assert(result.ok, result.message);
```

## Outputs

- detected peak and interval tables;
- segment SNR and summary measurements;
- printable ECG figures or reports.

## See Also

- [Biosignal Library](../../api/biosignal.md)
- `ecg_print.analysisRun.analyzeSignal`

