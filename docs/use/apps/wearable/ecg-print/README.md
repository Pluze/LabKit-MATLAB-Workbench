# ECG Print

```labkit-page
id: app-ecg-print
type: landing
audience: app-user
summary: Analyze a recording with ECGNExT, review NST-centered noise, QRS amplitude and SNR for every beat, and export the applied results.
```

ECG Print follows one file-analysis workflow: import an ECG channel, prepare its time base, detect R peaks, extract noise with ECGNExT, and report measurements for each beat. The plots, beat table, summary, and exports use the same applied analysis result. It requires Base MATLAB and the LabKit biosignal facade.

## Open And Analyze A Recording

Launch **ECG Print** from LabKit or run `labkit_ECGPrint_app` from a configured source checkout.

1. Choose **Open recording**, then select the ECG channel. Supported inputs are MAT, CSV, TXT, and TSV recordings handled by the biosignal reader, including supported BIOPAC exports, timetables, ordinary tables, and unambiguous numeric arrays.
2. In **Results**, inspect the raw waveform and adjust **Start** and **End**. Both sliders use the actual file duration and their numeric arrows step by 0.1 seconds; the blue interval is the pending selection. Opening a file or switching channels selects from zero to the nearest tenth of a second within the file extent; the control maximum retains the exact endpoint. Excluded samples do not enter filtering or noise analysis. Use at least 30 seconds of stable-morphology ECG. Long records are analyzed with overlapping ECGNExT windows automatically.
3. Choose the R-peak detector and minimum RR interval, then select **Analyze ECG**. The default detector is QRS streaming with a 0.28-second minimum interval. Pan-Tompkins and local peaks are also available.
4. **Results** shows four time-linked plots: input ECG with detected R peaks, NST-centered noise RMS per beat, signal QRS peak-to-peak amplitude per beat, and SNR per beat. The summary and per-beat table are in the Results controls.
5. Open **Signal chain** to compare full-interval traces vertically or select **Overlay signals** to superimpose them.
6. Export the per-beat CSV or complete analysis MAT. Exports use the last applied analysis; changing a setting marks it pending until **Analyze ECG** runs again.

A successful analysis reports the number of measured beats, detected beats, and extraction windows. Boundary beats remain in the table with their status and an undefined noise score where the reference algorithm lacks a complete noise interval. Their R time and QRS amplitude are still available when measurable.

## Import Settings

The separate **Import Settings** tab contains header line, header presence, time-column name, time unit, signal-column names, and fallback sample rate. Use **Preview file header** to inspect a text preamble. Choose **Parse / refresh file** after editing import options; analysis is disabled until the new options have been applied. A failed parse retains header access so the settings can be corrected.

For recordings with a reliable sample-counter column, select that column, set **Time unit** to **samples**, and enter the acquisition rate under **Sample rate / fallback (Hz)**. The App scales sample-index time to seconds while preserving the channel values. This provides an explicit acquisition clock for mixed or unsuitable timestamp columns.

The fallback rate is 2000 Hz and is used only when the reader cannot derive timing. Verify time interpretation and amplitude units before comparing recordings. Source or channel changes clear the previous analysis. The App does not save a task archive; exports are the durable result boundary.

## Preparation And R Peaks

The analysis uses finite, uniformly sampled input at 100 Hz or above. It crops the selected source interval and prepares a 1000 Hz grid, as required by the reference ECGNExT implementation. Native 1000 Hz samples are preserved. Lower rates use linear interpolation, which does not add acquired bandwidth. Higher rates use an App-owned reflection-padded FIR with 450 Hz cutoff before interpolation. The result therefore describes the prepared acquisition bandwidth, not frequency components removed by antialiasing.

The ECGNExT morphology input uses a fixed 0.5–40 Hz, fifth-order Butterworth bandpass prototype applied forward and backward through stable second-order sections. The forward/backward response is squared. Before filtering, the selected ROI is extended by even reflection of up to 15 seconds of its own samples at each end. This gives the slow 0.5 Hz high-pass poles time to settle without importing artifacts from the excluded part of the recording. The extension is removed after filtering; internal SOS calculations retain 30-sample odd reflection and steady-state initialization. Endpoint estimates still depend on the reflected continuation, so inspect the raw and filtered traces when cutting through a sharp feature. The FDA manual describes the prototype and band, while this zero-phase implementation is an explicit App preparation choice. No optional Signal Processing Toolbox is required.

R detection uses a fixed 5–20 Hz FIR on the prepared raw ECG, independently of the Butterworth morphology filter, automatic polarity, and a robust detector threshold setting of 2.8. The detector filter affects peak localization; the morphology reconstruction uses the fixed Butterworth signal and noise restoration uses the prepared raw signal. Review peak locations when noise or morphology changes. Minimum RR must exceed 0.2 seconds so default blank/blend regions remain inside their own beat intervals.

## ECGNExT Extraction And Beat Ownership

The noise extraction follows the [FDA ECG Noise Extraction Tool](https://cdrh-rst.fda.gov/ecg-noise-extraction-tool-ecgnext), the [official code and manual](https://github.com/dbp-osel/ECGNExT/tree/972c66cb274319acf705776d723b8e52372e22f0), and Galeotti and Scully, *A method to extract realistic artifacts from electrocardiogram recordings for robust algorithm testing*, Journal of Electrocardiology 51 (2018), S56–S60. The pinned reference commit is `972c66cb274319acf705776d723b8e52372e22f0`.

The reference aligns beats in time and amplitude, constructs a median morphology including recurring P and T waves, reconstructs the ECG, and subtracts it. It removes ±40 ms around each R peak and crossfades 60 ms of neighboring data. It applies the same removal to the raw-minus-bandpassed residual and adds that residual back, retaining prepared-bandwidth noise outside the morphology filter.

Records up to 60000 prepared samples use one extraction window. Longer records use 60000-sample windows with 30000-sample stride plus a final window ending at the last sample. Each core extraction preserves the reference arithmetic. Overlap supplies template context around joins instead of dropping beats at every nonoverlapping boundary.

A beat owns the interval between adjacent R midpoints; an exact midpoint belongs to the later beat. These source labels pass through the same QRS removal and crossfade as the noise. With R spacing above 200 ms, both contributors to each crossfade belong to the same beat. The App selects each complete beat candidate from the window whose center is closest to its R peak. A beat appears once in the result table and extracted samples are not duplicated across beats. Where only a partial boundary candidate exists, its noise remains available for inspection but its RMS is undefined.

`noise` preserves the selected exact reference samples. `time` preserves the corresponding crossfaded plotting coordinates with the window offset; it is not a uniform source clock or a sample-aligned cancellation signal. `beatIndex` identifies ownership directly. `windows` retains the selected-window provenance, median templates, reconstruction, each post-QRS-removal residual component, exact extracted noise/time/ownership. The assembled `synthetic` waveform uses the selected window for each beat.

## Signal Chain

Open **Signal chain** to inspect five simultaneous plots across the full applied interval: original ECG, template reconstruction, original-minus-reconstruction residual, noise after QRS removal and crossfade, and NST-centered noise used for per-beat RMS and SNR. Three additional plots below the five processing stages show the same per-beat noise RMS, QRS peak-to-peak and SNR as Results, with identical colors and values. All eight plots share ROI time limits and zoom horizontally together. **Overlay signals** superimposes the five processing stages above the three retained per-beat result plots without changing their values or time coordinates. Noise retains crossfaded reference times rather than being interpolated onto the raw sample grid. Changes to the ROI apply after **Analyze ECG** runs again.

Plot 2 also shows the 0.5-40 Hz filtered ECG used for QRS peak-to-peak measurement within R ±50 ms. Plot 4 displays the selected unmodified ECGNExT noise samples, with no mean subtraction or detrending. Residual and final-noise plots use the same vertical limits. Shaded regions in plot 3 mark R ±40 ms removed before 60 ms crossfading. The MATLAB default palette is used consistently: blue denotes measured ECG, orange-red dashed lines denote the template, cyan denotes the subtraction residual, and green denotes unchanged ECGNExT noise; curve identities appear in the plot titles; only overlay mode uses an external legend. Plot 5 shows the actual centered samples used for RMS, with a zero reference and undefined trailing chunks left as gaps. Purple denotes this statistics branch. Only the bottom plot repeats time labels, leaving equal-height waveform areas. Plot 1 identifies the selected input channel, which may already have device filtering. The measurement guide separates ECGNExT extraction from NST one-second noise centering and App-added per-beat RMS, QRS amplitude and SNR statistics.


The Results waveform and its R markers both use prepared raw ECG; filtering may shift the visible peak, so filtered ECG is shown separately in the signal chain. Full arrays are retained in these plots and in the complete MAT export. Gaps in reconstruction indicate unavailable boundary estimates. Results continues to show all per-beat trends and summary statistics. Detailed templates, alignment and window provenance remain in the complete result export.

## Per-Beat Measurements

| Column | Definition |
| --- | --- |
| Beat | One-based index of the detected R peak |
| RTime | R time in seconds from the prepared ROI start |
| Window | Selected extraction-window index; zero when no candidate exists |
| QRSPeakToPeak | Maximum minus minimum in the prepared 0.5–40 Hz filtered ECG within ±50 ms of R |
| NoiseRMS | `sqrt(mean(z.^2))` of samples assigned to the beat after NST one-second chunk centering; App-added per-beat statistic |
| QRSNoiseDb | `20*log10(QRSPeakToPeak/(sqrt(8)*NoiseRMS))` for the same beat |
| NoiseSamples | Number of extracted samples assigned to the beat |
| Status | `complete` or `boundary` |

The summary reports arithmetic means, sample variances (denominator `n−1`), and finite complete-beat counts for noise RMS, QRS peak-to-peak and SNR in dB. These are untrimmed per-beat statistics. The mean of per-beat dB values is not a whole-record NST calibration ratio. Each metric excludes its nonfinite values; a single value has undefined sample variance. Amplitude variance has squared amplitude units and SNR variance has dB-squared units. Positive QRS with zero noise produces infinite SNR, while zero QRS and zero noise produces NaN; nonfinite ratios remain in the beat table but do not enter finite summary statistics. All signal plots default to horizontal (X-axis) scroll zoom.

## NST Noise Processing And Interpretation

The [WFDB NST definition](https://physionet.org/physiotools/wag/nst-1.htm) removes the mean separately within each one-second noise chunk before computing its RMS. ECG Print applies that operation to consecutive 1000-sample chunks of the assembled ECGNExT output in a separate statistics branch: `z_j = n_j - mean(n_chunk(j))`. The signal-chain plot retains unmodified `n`. An incomplete final chunk is left unavailable, with NaN in the centered branch. A beat touching unavailable samples is a boundary result and has no RMS or SNR.

After centering, the App uses the existing beat ownership labels to compute `N_i = sqrt(mean(z_i.^2))`. A beat crossing a chunk boundary uses the centered samples from both chunks, weighted by their actual sample counts. It does not receive a copied one-second RMS or undergo a second per-beat mean subtraction. Its own filtered QRS range `A_i` gives `SNR_i = 20*log10(A_i/(sqrt(8)*N_i))`. Consequently a constant offset is excluded, while variation within a chunk remains in the noise statistic.

One second here means 1000 consecutive noise-output samples after QRS deletion and crossfade, rather than one second on the nonuniform original-ROI plotting coordinates. Chunk boundaries start at the first assembled noise sample. Long-record extraction-window selection and concatenation remain App extensions; their joins can affect a chunk that crosses a selected-window boundary.

NST also specifies a calibration aggregate using up to 300 normal reference QRS complexes and 300 one-second noise chunks, trimming 5% from each distribution tail before averaging. This App retains per-beat trends throughout the ROI; it does not apply that cap or trimming to individual beats, and does not label its per-beat SNR as the official NST aggregate. It uses floating arithmetic rather than WFDB integer ADC truncation. The QRS input is the device's filtered ECG with automatic peak detection, rather than a clean ECG with annotated normal beats. Template consistency and SNR do not establish physiological waveform fidelity.

ECGNExT owns the noise extraction, NST supplies the one-second centering and QRS-equivalent-power convention, and the App owns beat attribution, per-beat RMS/SNR and mean/variance summaries. The complete MAT retains `nstNoise.centered`, chunk sample bounds, removed chunk means and chunk RMS for reproducibility. `noiseRMS` pooled over complete-beat centered samples and `qrsP2P` trimmed amplitude remain auxiliary MAT statistics; they are not combined into a reported whole-record SNR.

## Results And Exports

- **Export statistics CSV** writes `ecg_statistics.csv` with metric, mean, sample variance, valid count, and units. The same `statistics` table is included in the complete analysis MAT.
- **Export per-beat CSV** writes `ecg_beats.csv` with exactly the displayed beat-table columns, including boundary rows and undefined measurements.
- **Export complete analysis MAT** saves `ecgNext` in `ecg_next_results.mat`: per-beat table, raw and prepared ECG, R indices, reconstruction, exact ECGNExT noise and the separate NST-centered statistics branch, plotting time, sample ownership, window provenance, preparation, units, applied settings, and reference commit.
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

R detection first finds candidates on the 5–20 Hz branch, then searches the prepared raw ECG within ±20 ms for an extremum with the candidate’s local detector polarity. Ties use the nearest sample; conflicting moves revert to preserve beat order and minimum spacing. Detection scores refer to the original candidates. The complete result records original indices and corrections in `peakLocalization`. This is an App localization step before the unchanged ECGNExT extraction core; it can change templates and per-beat estimates. Raw noise can affect the selected extremum. Review the raw ECG markers; original detector positions and corrections are available in the complete MAT export.
