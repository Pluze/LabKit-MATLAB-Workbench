# ECG Print

```labkit-page
id: app-ecg-print
type: landing
audience: app-user
summary: Filter and analyze a wearable ECG channel, build beat-centered segments and a representative template, assess signal quality, and export results.
```

ECG Print reads a wearable recording, filters one channel, detects beats, builds event-centered segments and a representative template, and reports signal quality over time. It can export the analyzed sample region as a MATLAB timetable, the segment measurements, and a printable waveform image.

## Open ECG Print

From the LabKit launcher, select **ECG Print** and choose **Open**. From a source checkout, run:

```matlab
labkit_ECGPrint_app
```

## Supported Inputs

Choose **Open recording** to load a MAT, CSV, TXT, or TSV biosignal file. MAT files can contain a supported timetable or a BIOPAC AcqKnowledge export. They may also contain ordinary table variables or one unambiguous numeric array. Delimited text files can be detected automatically or parsed with the controls under **Import Parsing**. For BIOPAC MAT and text exports, the App uses the exported channel labels, channel units, and sample interval automatically. The import status reports the selected format, parser fallback, and uniform-sampling cleanup. Every channel reaches analysis on a uniform time grid; large timestamp gaps separate resampling sections instead of being interpolated across.

For a difficult text file, choose **Preview file header**, then set:

- the line containing column names;
- whether a header is present;
- the time column and its unit;
- the signal columns;
- a fallback sample rate when time values are unavailable.

Choose **Parse / refresh file** after changing import settings. The app reports the detected channels and lets you select one for analysis. MAT recordings show a short format notice in the header-preview area instead of decoding binary file contents as text.

The recording remains a live source while the App is open. ECG Print does not write a task archive; export commands are the durable output boundary.

## Analyze ECG

1. Open and parse a recording.
2. Select a channel and, if needed, set the start and end of the time region. When the end is not greater than the start, the full signal is used.
3. Set the bandpass range and peak method.
4. Set minimum peak distance, segment half-window, template count, and smoothing count.
5. Choose **Analyze current ROI**.
6. Review the four plots: waveform and peaks, template-noise RMS, template SNR, and the template with either a residual band or individual segments.

The filter is applied to the full selected channel before the time region is cropped. This reduces boundary artifacts at the region edges.

The **Files + Analysis** tab keeps the workflow in five ordered sections: **Recording**, **Import Parsing**, **Channel + ROI**, **Signal Processing + SNR**, and **Exports**. Bounded numeric settings use paired spinner-and-slider controls. **Summary + Results** contains the analysis summary and file-header preview. **Tools > Diagnostics > Open Session Log...** records the current workflow and earlier runtime context. The **ECG Preview** workspace keeps four vertically stacked time-series axes available on every tab.

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

The returned cache contains the working and filtered signals, detected events, segments, template, and measurements. For a more customized pipeline, call `labkit.biosignal.filterSignal`, `detectEcgPeaks`, `segmentByEvents`, `buildTemplate`, and `measureSegments` directly.

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

The App accepts the three displayed peak methods. An unrecognized value is reported as an error rather than silently selecting another method.

Peak polarity is selected automatically. The default detector threshold is 2.8 standard deviations inside the app calculation.

## Output Files

**Export ROI timetable to workspace** assigns `ecgAnalysisRegion` in the MATLAB base workspace and confirms success with an information notice. **Export ROI timetable MAT** saves the same timetable as `ecgAnalysisRegion` in `ecg_analysis_region.mat`. Both commands use the most recent successful analysis, not unapplied control edits. Timetable row times match the analysis preview; its columns retain source time in seconds, raw and filtered channel samples, and a logical detected-peak marker. Channel name, signal unit, sample rate, and requested source range are stored in timetable metadata.

**Export segment SNR CSV** writes `ecg_segment_snr.csv`. The CSV contains per-segment measurements and smoothed trends.

**Export waveform PNG** writes `ecg_waveform.png`.

## Related Functions And Documentation

- `ecg_print.analysisRun.analyzeSignal`
- `labkit.biosignal.readRecording`
- `labkit.biosignal.detectEcgPeaks`
- `labkit.biosignal.measureSegments`
- [Biosignal library](../../../../develop/libraries/biosignal/README.md)

## Errors And Limitations

- Time or a valid sample rate is required to interpret filter frequencies and event spacing.
- Automatic parsing should be checked when a text file has long preambles, unusual headers, or mixed metadata rows.
- A failed **Parse / refresh file** keeps the selected source and header preview available so import settings can be corrected in place.
- Automatic peak polarity and thresholds still require visual review when morphology or noise changes within a recording.
- Filtering and detection settings must accompany any reported heart rate or signal-quality result.
