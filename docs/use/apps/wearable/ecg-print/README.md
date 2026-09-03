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
4. To detect peaks from a narrower cascade, clear **Use analysis band for peaks** and set the secondary peak-detection band. This second filter changes only detected peak positions.
5. Set minimum peak distance, segment half-window, template count, and smoothing count.
6. Choose **Analyze current ROI**.
7. Review the waveform, noise RMS, peak-to-peak, and SNR trends, compare the side-by-side template residual-band and individual-segment views, and use **Power Spectra** to compare the raw, primary-filtered, and peak-detection inputs.

The filter is applied to the full selected channel before the time region is cropped. ECG Print uses an odd-length, symmetric, Hamming-windowed sinc FIR with approximately four seconds of taps and an 8001-tap ceiling. The finite coefficient sequence is BIBO stable. Reflection padding reduces record-edge transients, and centered convolution compensates the FIR's linear-phase delay so detected peaks remain aligned to source time.

The main bandpass controls and optional peak-detection band controls are limited dynamically to the selected channel's Nyquist frequency. The initial main band is **0 Hz to Nyquist**, a true no-filter state that preserves the loaded samples. Following the conventional Filter Analyzer organization, the **Filter Details** workspace tab calculates magnitude in decibels, continuous phase, group delay, and impulse response directly from the FIR coefficients. When the second stage is enabled, all four views also characterize the second FIR and the actual coefficient cascade. Only detected indices from the second stage are reused: segments, templates, noise RMS, peak-to-peak amplitude, and SNR are all calculated from the main analysis-filtered signal.

The **Power Spectra** workspace tab shows three equal-height, one-sided Welch power spectral densities for the current analyzed ROI: raw samples, primary analysis-filter output, and peak-detection input. Each finite segment is mean-centered and multiplied by a symmetric Hamming window; segments overlap by 50 percent and are limited to 8192 samples to bound analysis time and memory. The vertical axis is `10 log10(PSD / (1 unit^2/Hz))`, where `unit` is the imported amplitude unit or ADC counts. Display values are clipped 120 dB below each stage's maximum while the cached linear PSD remains unclipped. When peak detection reuses the primary band, the third plot says so explicitly and repeats that input instead of implying another filter stage.

The **Files + Analysis** tab keeps the workflow in five ordered sections: **Recording**, **Import Parsing**, **Channel + ROI**, **Signal Processing + SNR**, and **Exports**. Bounded numeric settings use paired spinner-and-slider controls. **Summary + Results** contains the analysis summary and file-header preview. **Tools > Diagnostics > Open Session Log...** records the current workflow and earlier runtime context. The **ECG Preview** workspace uses five equal-height rows: waveform, noise RMS, peak-to-peak, SNR, and a final template row split into side-by-side residual-band and segment-overlay axes.

The waveform title uses the source filename. Waveform, noise RMS, peak-to-peak, and template amplitude labels use the imported channel unit; recordings without a declared amplitude unit are labeled **ADC counts** rather than left ambiguous. The summary reports the mean and standard deviation of peak-to-peak amplitude, noise RMS, and SNR.

The four time-series axes share one X window. Scroll over any of them to zoom along time only; all four axes follow that window and independently refit Y to their visible samples. Opening a recording establishes its initial preview, and completing a new analysis refits the plots to the newly applied data. The two template axes use their independent peak-relative coordinate and remain available simultaneously.

Editing analysis controls does not redraw the plots. Successfully opening or reparsing a file or selecting another channel immediately replaces and refits the waveform while clearing results derived from the previous signal. The App publishes filtered waveform content, quality trends, templates, filter responses, and the three power spectra together only after **Analyze current ROI** succeeds; Filter Details and Power Spectra therefore always describe the most recently applied analysis settings.

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

The returned cache contains the working and filtered signals, detected events, segments, template, measurements, filter details, and three-stage power spectra. For a more customized pipeline, call the individual `labkit.biosignal` detection, segmentation, template, and measurement functions directly.

## Analysis Parameters

| Parameter | Default | Meaning |
| --- | --- | --- |
| Fallback sample rate | 2000 Hz | Used only when import cannot derive time spacing |
| Bandpass | 0 Hz to Nyquist | No filtering by default; narrower settings filter the analysis signal before peak detection |
| Peak method | QRS streaming | QRS streaming, Pan-Tompkins, or local peaks |
| Peak distance | 0.28 s | Minimum interval between accepted detections |
| Segment half-window | 0.7 s | Data retained before and after each event |
| Template top N | 30 | Number of best segments used to build the template |
| Smooth beats | 15 | Smoothing span used in exported per-segment trends |

The App accepts the three displayed peak methods. An unrecognized value is reported as an error rather than silently selecting another method.

Peak polarity is selected automatically. The default detector threshold is 2.8 standard deviations inside the app calculation.

## Output Files

**Export ROI timetable to workspace** assigns `ecgAnalysisRegion` in the MATLAB base workspace and confirms success with an information notice. **Export ROI timetable MAT** saves the same timetable as `ecgAnalysisRegion` in `ecg_analysis_region.mat`. Both commands use the most recent successful analysis, not unapplied control edits. Timetable row times match the analysis preview; its columns retain source time in seconds, raw and filtered channel samples, and a logical detected-peak marker. Channel name, signal unit, sample rate, and requested source range are stored in timetable metadata.

**Export segment SNR CSV** writes `ecg_segment_snr.csv`. The CSV contains per-segment measurements and smoothed trends.

**Export waveform PNG** writes `ecg_waveform.png`.

## Related Functions And Documentation

- `ecg_print.analysisRun.analyzeSignal`
- `ecg_print.analysisRun.powerSpectraModels`
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
