# ECG Print

ECG Print reads a wearable recording, filters one channel, detects beats,
builds event-centered segments and a representative template, and reports
signal quality over time. It can export the segment measurements and a
printable waveform image.

## Open ECG Print

From the LabKit launcher, select **ECG Print** and choose **Open**. From a
source checkout, run:

```matlab
labkit_ECGPrint_app
```

## Supported Inputs

Choose **Open recording** to load a MAT, CSV, TXT, or TSV biosignal file. MAT
files can contain a supported timetable or recording structure. Delimited text
files can be detected automatically or parsed with the controls under
**Import Parsing**.

For a difficult text file, choose **Preview file header**, then set:

- the line containing column names;
- whether a header is present;
- the time column and its unit;
- the signal columns;
- a fallback sample rate when time values are unavailable.

Choose **Parse / refresh file** after changing import settings. The app reports
the detected channels and lets you select one for analysis.

## Analyze ECG

1. Open and parse a recording.
2. Select a channel and, if needed, set the start and end of the time region.
   When the end is not greater than the start, the full signal is used.
3. Set the bandpass range and peak method.
4. Set minimum peak distance, segment half-window, template count, and smoothing
   count.
5. Choose **Analyze current ROI**.
6. Review the four plots: waveform and peaks, template-noise RMS, template SNR,
   and the template with either a residual band or individual segments.

The filter is applied to the full selected channel before the time region is
cropped. This reduces boundary artifacts at the region edges.

## Analysis Parameters

| Parameter | Default | Meaning |
| --- | --- | --- |
| Fallback sample rate | 2000 Hz | Used only when import cannot derive time spacing |
| Bandpass | 0.5 to 40 Hz | Applied before peak detection; the upper cutoff is kept below 45% of sample rate |
| Peak method | QRS streaming | QRS streaming, Pan-Tompkins, or local peaks |
| Peak distance | 0.28 s | Minimum interval between accepted detections |
| Segment half-window | 0.7 s | Data retained before and after each event |
| Template top N | 30 | Number of best segments used to build the template |
| Smooth beats | 15 | Smoothing span used in exported per-segment trends |
| Template plot | Template + residual band | Alternative view is template plus individual segments |

Peak polarity is selected automatically. The default detector threshold is
2.8 standard deviations inside the app calculation.

## Output Files

**Export segment SNR CSV** writes `ecg_segment_snr.csv` and a matching
`ecg_segment_snr.labkit.json` manifest. The CSV contains per-segment
measurements and smoothed trends.

**Export waveform PNG** writes `ecg_waveform.png` and
`ecg_waveform.labkit.json`. The manifest records the source, import and
analysis settings, output identity, event count, segment count, and summary.

## Analyze A Signal In MATLAB Code

```matlab
[recording, status] = labkit.biosignal.readRecording("ecg.csv");
assert(status.ok, status.message)

signal = labkit.biosignal.getChannel(recording, 1);
cache = struct("signal", signal);
parameters = struct( ...
    "lowCut", 0.5, ...
    "highCut", 40, ...
    "roiStart", 0, ...
    "roiEnd", 0, ...
    "peakMethod", "QRS streaming", ...
    "peakDistance", 0.28, ...
    "segmentWindow", 0.7, ...
    "templateTopN", 30);

cache = ecg_print.analysisRun.analyzeSignal(cache, parameters);
```

The returned cache contains the working and filtered signals, detected events,
segments, template, and measurements. For a more customized pipeline, call
`labkit.biosignal.filterSignal`, `detectEcgPeaks`, `segmentByEvents`,
`buildTemplate`, and `measureSegments` directly.

## Errors And Limitations

- Time or a valid sample rate is required to interpret filter frequencies and
  event spacing.
- Automatic parsing should be checked when a text file has long preambles,
  unusual headers, or mixed metadata rows.
- Automatic peak polarity and thresholds still require visual review when
  morphology or noise changes within a recording.
- Filtering and detection settings must accompany any reported heart rate or
  signal-quality result.

## Related Functions And Documentation

- `ecg_print.analysisRun.analyzeSignal`
- `labkit.biosignal.readRecording`
- `labkit.biosignal.detectEcgPeaks`
- `labkit.biosignal.measureSegments`
- [Biosignal library](../../../libraries/biosignal/README.md)
