# ECG Print

```labkit-page
id: app-ecg-print
type: landing
audience: app-user
summary: Analyze a recording with ECGNExT, review per-beat detrended noise, QRS amplitude and SNR for every beat, and export the applied results.
```

ECG Print follows one file-analysis workflow: import an ECG channel, prepare its time base, detect R peaks, extract noise with ECGNExT, and report measurements for each beat. The plots, beat table, summary, and exports use the same applied analysis result. It requires Base MATLAB and the LabKit biosignal facade.

## Open And Analyze A Recording

Launch **ECG Print** from LabKit or run `labkit_ECGPrint_app` from a configured source checkout.

1. Choose **Open recording**, then select the ECG channel. Supported inputs are MAT, CSV, TXT, and TSV recordings handled by the biosignal reader, including supported BIOPAC exports, timetables, ordinary tables, and unambiguous numeric arrays.
2. In **Results**, inspect the raw waveform and adjust **Start** and **End**. Both sliders use the actual file duration and their numeric arrows step by 0.1 seconds; the blue interval is the pending selection. Opening a file or switching channels selects from zero to the nearest tenth of a second within the file extent; the control maximum retains the exact endpoint. Excluded samples do not enter filtering or noise analysis. Use at least 30 seconds of stable-morphology ECG. Long records are analyzed with overlapping ECGNExT windows automatically.
3. Choose the R-peak detector and minimum RR interval, then select **Analyze ECG**. The default detector is QRS streaming with a 0.28-second minimum interval. Pan-Tompkins and local peaks are also available.
4. **Results** shows four time-linked plots: input ECG with detected R peaks, per-beat detrended noise RMS per beat, signal QRS peak-to-peak amplitude per beat, and SNR per beat. The summary and per-beat table are in the Results controls.
5. Open **Templates** and choose a window from the **Template window** dropdown; each option lists its index, file-time range and extraction status. From top to bottom, review the selected final template with all aligned heartbeats, the corresponding aligned per-beat detrended noise used for SNR, and the final templates from all available windows overlaid.
6. Open **Signal chain** to compare full-interval traces vertically or select **Overlay signals** to superimpose them.
7. Export the per-beat CSV or complete analysis MAT. Exports use the last applied analysis; changing a setting marks it pending until **Analyze ECG** runs again.

A successful analysis reports the number of measured beats, detected beats, and extraction windows. Boundary beats remain in the table with their status and an undefined noise score where the reference algorithm lacks a complete noise interval. Their R time and QRS amplitude are still available when measurable.

## Import Settings

The separate **Import Settings** tab contains header line, header presence, time-column name, time unit, signal-column names, and fallback sample rate. Use **Preview file header** to inspect a text preamble. Choose **Parse / refresh file** after editing import options; analysis is disabled until the new options have been applied. A failed parse retains header access so the settings can be corrected.

For recordings with a reliable sample-counter column, select that column, set **Time unit** to **samples**, and enter the acquisition rate under **Sample rate / fallback (Hz)**. The App scales sample-index time to seconds while preserving the channel values. This provides an explicit acquisition clock for mixed or unsuitable timestamp columns.

The fallback rate is 2000 Hz and is used only when the reader cannot derive timing. Verify time interpretation and amplitude units before comparing recordings. Source or channel changes clear the previous analysis. Replacing or reloading a recording refits the preview to the newly decoded file extent. The App does not save a task archive; exports are the durable result boundary.

## Preparation And R Peaks

The analysis uses finite, uniformly sampled input at 100 Hz or above. It crops the selected source interval and prepares a 1000 Hz grid, as required by the reference ECGNExT implementation. Native 1000 Hz samples are preserved. Lower rates use linear interpolation, which does not add acquired bandwidth. Higher rates use an App-owned reflection-padded FIR with 450 Hz cutoff before interpolation. The result therefore describes the prepared acquisition bandwidth, not frequency components removed by antialiasing.

The ECGNExT morphology input uses a fixed 0.5–40 Hz, fifth-order Butterworth bandpass prototype applied forward and backward through stable second-order sections. The forward/backward response is squared. Before filtering, the selected ROI is extended by even reflection of up to 15 seconds of its own samples at each end. This gives the slow 0.5 Hz high-pass poles time to settle without importing artifacts from the excluded part of the recording. The extension is removed after filtering; internal SOS calculations retain 30-sample odd reflection and steady-state initialization. Endpoint estimates still depend on the reflected continuation, so inspect the raw and filtered traces when cutting through a sharp feature. The FDA manual describes the prototype and band, while this zero-phase implementation is an explicit App preparation choice. No optional Signal Processing Toolbox is required.

R detection uses a fixed 5–20 Hz FIR on the prepared raw ECG, independently of the Butterworth morphology filter, positive R polarity, and a robust detector threshold setting of 2.8. The detector filter affects peak localization; the morphology reconstruction uses the fixed Butterworth signal and noise restoration uses the prepared raw signal. The App assumes that the R wave is the positive peak for every input channel. It requests positive polarity from every detector and searches only for a maximum during final raw-signal refinement; it never flips input samples. Inverted recordings must be corrected before import. Review peak locations when noise or morphology changes. Minimum RR must exceed 0.2 seconds so default blank/blend regions remain inside their own beat intervals.

## ECGNExT Extraction And Beat Ownership

The noise extraction follows the [FDA ECG Noise Extraction Tool](https://cdrh-rst.fda.gov/ecg-noise-extraction-tool-ecgnext), the [official code and manual](https://github.com/dbp-osel/ECGNExT/tree/972c66cb274319acf705776d723b8e52372e22f0), and Galeotti and Scully, *A method to extract realistic artifacts from electrocardiogram recordings for robust algorithm testing*, Journal of Electrocardiology 51 (2018), S56–S60. The pinned reference commit is `972c66cb274319acf705776d723b8e52372e22f0`.

The reference aligns beats in time and amplitude, constructs a median morphology including recurring P and T waves, reconstructs the ECG, and subtracts it. It removes ±40 ms around each R peak and crossfades 60 ms of neighboring data. It applies the same removal to the raw-minus-bandpassed residual and adds that residual back, retaining prepared-bandwidth noise outside the morphology filter.

Records up to 60000 prepared samples use one extraction window. Longer records use 60000-sample windows with 30000-sample stride plus a final window ending at the last sample. Each core extraction preserves the reference arithmetic. Overlap supplies template context around joins instead of dropping beats at every nonoverlapping boundary.

A beat owns the interval between adjacent R midpoints; an exact midpoint belongs to the later beat. These source labels pass through the same QRS removal and crossfade as the noise. With R spacing above 200 ms, both contributors to each crossfade belong to the same beat. The App selects each complete beat candidate from the window whose center is closest to its R peak. A beat appears once in the result table and extracted samples are not duplicated across beats. Where only a partial boundary candidate exists, its noise remains available for inspection but its RMS is undefined.

`noise` preserves the selected exact reference samples. `time` preserves the corresponding crossfaded plotting coordinates with the window offset; it is not a uniform source clock or a sample-aligned cancellation signal. `beatIndex` identifies ownership directly. `windows` retains the selected-window provenance, median templates, reconstruction, each post-QRS-removal residual component, exact extracted noise/time/ownership. The assembled `synthetic` waveform uses the selected window for each beat.

## Signal Chain

Open **Signal chain** to inspect five simultaneous plots across the full applied interval: original ECG, template reconstruction, original-minus-reconstruction residual, noise after QRS removal and crossfade, and per-beat detrended noise used for per-beat RMS and SNR. Three additional plots below the five processing stages show the same per-beat noise RMS, QRS peak-to-peak and SNR as Results, with identical colors and values. All eight plots share ROI time limits and zoom horizontally together. **Overlay signals** superimposes the five processing stages above the three retained per-beat result plots without changing their values or time coordinates. Noise retains crossfaded reference times rather than being interpolated onto the raw sample grid. Changes to the ROI apply after **Analyze ECG** runs again.

Horizontal linkage remains active when switching between stacked and overlaid signals. Returning to an unanalyzed recording leaves its waveform view independent of the per-beat result plots.

Plot 2 also shows the 0.5-40 Hz filtered ECG used for QRS peak-to-peak measurement within R ±50 ms. Plot 4 displays the selected unmodified ECGNExT noise samples, with no mean subtraction or detrending. Residual and final-noise plots use the same vertical limits. Shaded regions in plot 3 mark R ±40 ms removed before 60 ms crossfading. The MATLAB default palette is used consistently: blue denotes measured ECG, orange-red dashed lines denote the template, cyan denotes the subtraction residual, and green denotes unchanged ECGNExT noise; curve identities appear in the plot titles; only overlay mode in Signal chain uses an external legend. Plot 5 shows the actual detrended samples used for RMS, with a zero reference, gaps between independently fitted beats, and unavailable boundary samples left as gaps. Purple denotes this statistics branch. Only the bottom plot repeats time labels, leaving equal-height waveform areas. Plot 1 identifies the selected input channel, which may already have device filtering. The measurement guide separates ECGNExT extraction from App-owned per-beat linear detrending, RMS, QRS amplitude and SNR statistics.


The Results waveform and its R markers both use prepared raw ECG; filtering may shift the visible peak, so filtered ECG is shown separately in the signal chain. Full arrays are retained in these plots and in the complete MAT export. Gaps in reconstruction indicate unavailable boundary estimates. Results continues to show all per-beat trends and summary statistics. Detailed templates, alignment and window provenance remain in the complete result export.

## Template Inspection

The **Templates** page starts with a window selector and three plots in workflow order. The first shows the selected window's final median template in orange and all available aligned filtered heartbeats in pale blue. Edge beats without a complete alignment segment are omitted; data tips identify the global beat number. The initial short median remains available in the complete analysis export.

The second plot overlays the exact per-beat detrended noise samples used for SNR, read directly from `statisticsNoise.detrended`. It does not refit the selected template window's extraction. For overlapping windows, each beat retains the winning-window samples chosen for its RMS/SNR, even when another template window is selected. Each beat's reference time is shifted relative to R and receives the same horizontal correction as its displayed ECG segment; amplitudes and sample counts are unchanged, so the RMS of each plotted curve equals the reported beat NoiseRMS. Beats without valid SNR statistics are omitted. Data tips identify the global beat and the SNR source window. The first two plots share aligned R-relative time limits and horizontal zoom.

The third plot overlays every available window's final template on its own R-relative time grid. The selected window has a thicker line; data tips identify window numbers. Different template lengths remain intact. Windows without a usable extraction have no template curve, and selecting one shows empty detail plots. Overlapping windows are inspected independently here; full-result noise and per-beat metrics retain their existing candidate-selection rules.

## Per-Beat Measurements

| Column | Definition |
| --- | --- |
| Beat | One-based index of the detected R peak |
| RTime | R time in seconds from the prepared ROI start |
| Window | Selected extraction-window index; zero when no candidate exists |
| QRSPeakToPeak | Maximum minus minimum in the prepared 0.5–40 Hz filtered ECG within ±50 ms of R |
| NoiseRMS | `sqrt(mean(z.^2))` of samples assigned to the beat after fitting and removing a line within that same beat; App-added per-beat statistic |
| QRSNoiseDb | `20*log10(QRSPeakToPeak/(sqrt(8)*NoiseRMS))` for the same beat |
| NoiseSamples | Number of extracted samples assigned to the beat |
| Status | `complete` or `boundary` |

The summary reports arithmetic means, sample variances (denominator `n−1`), and finite complete-beat counts for noise RMS, QRS peak-to-peak and SNR in dB. These are untrimmed per-beat statistics. The mean of per-beat dB values is not a whole-record NST calibration ratio. Each metric excludes its nonfinite values; a single value has undefined sample variance. Amplitude variance has squared amplitude units and SNR variance has dB-squared units. Positive QRS with zero noise produces infinite SNR, while zero QRS and zero noise produces NaN; nonfinite ratios remain in the beat table but do not enter finite summary statistics. All signal plots default to horizontal (X-axis) scroll zoom.

## Drift-Reduced Noise And SNR Interpretation

Noise statistics use exactly the selected samples owned by each complete beat, between adjacent R midpoints after ECGNExT removal and crossfading. For beat `i`, the App fits `n(t) = a_i + b_i * (t - mean(t_i))` by least squares, subtracts that line, and calculates `N_i = sqrt(mean(residual_i.^2))`. Fitting uses the retained ECGNExT crossfaded time coordinates in seconds; replacing these with compressed output indices would give a different treatment of source-time drift. Each fit and RMS use the same beat's samples. There are no fixed-second blocks, cross-beat fits or incomplete final-second exclusions. Incomplete beats, fewer than three samples, or zero time spread have undefined RMS and SNR.

This statistic characterizes variation remaining after removal of a beat's constant offset and locally linear drift. It is not total artifact power, and removing a trend also removes genuine noise energy along those fitted components. Curved drift can remain. The operation has no fixed frequency cutoff, and its effective behavior depends on RR duration and retained samples; it must not be interpreted as a calibrated high-pass filter. Compare recordings with compatible preparation, heart rates and detector quality. Plotting gaps between beat fits avoid implying that their independent fitted baselines form a continuous noise signal.

The beat's filtered QRS range `A_i` gives `SNR_i = 20*log10(A_i/(sqrt(8)*N_i))`. The `sqrt(8)` factor follows the QRS sinusoidal-equivalent-power convention of [WFDB NST](https://physionet.org/physiotools/wag/nst-1.htm), but this App's per-beat linear detrending and SNR are custom estimates. They are not NST calibration or a validated physiological SNR. The QRS input is the device's filtered ECG rather than a clean reference with normal-beat annotations. A high value does not establish morphology fidelity or low total motion artifact.

ECGNExT noise remains unchanged in `noise` and Signal chain plot 4. Only the separate statistics branch is detrended. The complete MAT retains `statisticsNoise.detrended`, the removed samplewise `trend`, per-beat `fits` with counts, time centers, removed means and slopes in amplitude units per second, plus the method and time basis. Pooled `noiseRMS` and trimmed `qrsP2P` remain auxiliary MAT statistics; they are not combined into a reported whole-record SNR.

ECG Print 4.0 changes `NoiseRMS` and `QRSNoiseDb` to this drift-reduced definition and replaces the MAT `nstNoise` branch with `statisticsNoise`. CSV column names remain stable, but their noise/SNR values must not be pooled with earlier versions without identifying the method or recomputing from retained raw extraction data. Existing exports are not rewritten.

## Results And Exports

- **Export statistics CSV** writes `ecg_statistics.csv` with metric, mean, sample variance, valid count, and units. The same `statistics` table is included in the complete analysis MAT.
- **Export per-beat CSV** writes `ecg_beats.csv` with exactly the displayed beat-table columns, including boundary rows and undefined measurements.
- **Export complete analysis MAT** saves `ecgNext` in `ecg_next_results.mat`: per-beat table, raw and prepared ECG, R indices, reconstruction, exact ECGNExT noise and the separate per-beat detrended statistics branch, plotting time, sample ownership, window provenance, preparation, units, applied settings, and reference commit.
- **Export ECG PNG** writes the analyzed ECG and R markers.
- **Export prepared ROI MAT** saves `ecgAnalysisRegion`, a timetable on the prepared 1000 Hz grid. Columns include source-coordinate time, prepared raw signal, Butterworth signal, and peak markers.
- **Export ROI to workspace** assigns that same timetable to `ecgAnalysisRegion` in the MATLAB base workspace.

Amplitudes use the imported unit, or ADC counts when no unit is declared. Noise ratios do not establish voltage calibration. Report the source and prepared rates, bandwidth/antialiasing, ROI, gain/unit, detector settings and peak review, QRS amplitude, and noise RMS with comparisons.

## Programmatic Analysis

Typical call after decoding a recording:

```matlab
signal = labkit.biosignal.getChannel(recording, 1);
parameters = struct('roiStart', 0, 'roiEnd', 0, ...
    'peakMethod', "QRS streaming", 'peakDistance', 0.28);
cache = ecg_print.analysisRun.analyzeSignal(struct('signal', signal), parameters);
beats = cache.ecgNext.perBeat;
```

`ecgNextExtract` accepts prepared raw/bandpassed vectors at 1000 Hz and accurately located R indices directly. This permits using a simultaneous reference ECG for peak locations. `ecgNextAnalysis` adds overlapping windows and per-beat results; `analyzeSignal` owns preparation and detection. These are App-owned functions with no file writes or GUI construction.

## Recovery And Limits

Use at least 30000 prepared samples. Short records return an actionable status and no invented noise measurements. Windows with insufficient or geometrically incompatible peaks are recorded in the extraction result; unexpected failures are reported explicitly. Logs distinguish ECGNExT completion from unavailable results and retain counts and reasons rather than scientific samples.

The FDA tool is intended for short, stable-morphology recordings from healthy volunteers and was evaluated under additive-noise conditions. It has not established validity for arrhythmias, changing morphology, or arbitrary nonlinear distortion. Automatic overlapping windows do not establish physiological validity for a long recording. This derived implementation is not FDA endorsement or regulatory qualification. QRS blanking deliberately excludes QRS-region noise, and exact numerical conformance does not prove that a recording's detected peaks are correct.

ECG Print 3.0 replaces the older fixed-window residual metrics and their CSV schema with ECGNExT per-beat measurements. Saved CSVs retain their original meaning; they must not be interpreted as the new noise definition.

## Related Documentation

- [Biosignal library](../../../../develop/libraries/biosignal/README.md)
- `ecg_print.analysisRun.analyzeSignal`
- `ecg_print.analysisRun.ecgNextAnalysis`
- `ecg_print.analysisRun.ecgNextExtract`

The default end time is the nearest tenth of a second within the file extent (for example, 65.234 s selects 65.2 s). The time-control maximum retains the exact file duration, so the file endpoint remains selectable. Import refresh and channel changes apply the same default.

R detection first finds candidates on the 5–20 Hz branch, then searches the prepared raw ECG within ±20 ms for a positive maximum. Ties use the nearest sample; conflicting moves revert to preserve beat order and minimum spacing. Detection scores refer to the original candidates. The complete result records original indices and corrections in `peakLocalization`. This is an App localization step before the unchanged ECGNExT extraction core; it can change templates and per-beat estimates. Raw noise can affect the selected extremum. Review the raw ECG markers; original detector positions and corrections are available in the complete MAT export.
