# EMG Review

```labkit-page
id: app-emg-review
type: landing
audience: app-user
summary: Mark paired EMG baseline and activity windows, measure noise and SNR, and compare spectra and time–frequency content.
```

EMG Review measures one channel of a recording at a time. Use it to compare electrical activity with a baseline from the same acquisition, review 60 Hz components and broadband power, and retain one CSV row per measured pair. It requires Base MATLAB and the LabKit biosignal facade.

## Open And Mark A Recording

1. Launch **EMG Review** from LabKit or run `labkit_EMGReview_app` from a configured checkout.
2. Choose **Open recording** and select an EMG channel. The reader accepts supported BIOPAC ACQ, BIOPAC MAT exports, MAT timetables or tables, and CSV, TSV or TXT tables. Use files with a known acquisition clock, such as an ACQ or a table with a time column named `time_s` or `time_ms`. Verify the displayed sample rate and units. When preparing an input that has only sample indices, add the time column in seconds from its acquisition rate.
3. Choose a measurement band and window duration. Each pair uses the same duration for both windows and starts at the nearest sample. The default is one second. **Baseline start (s)** and **Activity start (s)** use file-relative seconds. The two windows in each pair must fit without overlapping.
4. Enter start times manually or choose **Auto-mark selected pair** and review the suggested marks on the waveform. Use **Add pair** to mark another pair. The **Pair** dropdown highlights the pair being edited. The waveform identifies baseline and activity by color and by their shared pair number.
5. Choose **Analyze EMG**. The waveform displays the analyzed signal and annotates each activity window with its SNR. **Pair metrics** lists the applied coordinates and measurements. **Spectrum** compares baseline and activity power at full bandwidth and around 60 Hz. **Time–frequency** shows how spectral power changes across the recording.
6. Choose **Export pair metrics CSV** to save the applied coordinates, RMS, SNR, contrast, 58–62 Hz power percentages, channel, unit, sample rate and measurement band. A window, duration, or band edit requires applying the analysis again. A channel or source change starts a fresh set of marks.

## Measurement Band And Automatic Marks

**As recorded** uses the imported waveform. **20–450 Hz** applies a centered Blackman-windowed FIR without phase delay. It uses 501 taps at 2000 Hz and scales the support to approximately ±0.125 seconds at other rates. It is the default above 900 Hz. Filtered windows exclude the first and last 0.25 seconds. At 900 Hz or below, use **As recorded** because 450 Hz reaches or exceeds Nyquist. The waveform shows the original signal until an analysis is applied.

Automatic marking searches for the lowest mean-removed RMS window that has room for a partner. It then selects the highest mean-removed RMS window that fits without overlap. The search excludes windows already marked in other pairs and resolves equal scores to the earliest start. Review the suggestions against experiment timing, electrode motion, or clipping. High RMS can come from an artifact, and low RMS does not establish a true noise baseline. Short records may require a shorter window or **As recorded** to provide room for two windows. Manually overlapping marks across different pairs are allowed, so those rows can share samples.

## RMS And SNR

For each window, subtract its own mean and compute RMS in the imported amplitude unit. Let `B` be baseline RMS and `A` be activity RMS. Activity-to-baseline contrast is `20 × log10(A/B)` dB. Noise-corrected SNR is `10 × log10((A² − B²)/B²)` dB. It assumes that the active window contains the same additive, uncorrelated baseline noise power as the baseline window. If baseline power is zero or activity power does not exceed baseline power, SNR is undefined and the CSV records a missing value. Report the measurement band, window selection and baseline assumption when comparing SNR across recordings.

## Spectral Views

The spectrum uses a mean-removed, periodic-Hann, one-sided power spectral density estimate for each ROI. The plot averages linear PSD independently across the baseline and activity windows before converting to dB relative to one squared source unit per Hz. The per-pair 60 Hz metric reports the 58–62 Hz bin power as a percentage of 20–450 Hz bin power within the measured bandwidth. It is undefined when the line band has no bin or the denominator is zero. For noisy recordings, use the full spectrum and the detail view together to distinguish a narrow feature from power spread over many frequencies. A relative band percentage alone does not identify a noise source.

The spectrogram uses the same density convention with an approximately 250 ms Hann window and a nominal 75% overlap. The hop increases for long recordings to keep the displayed grid at up to 600 time columns. The color scale shows the top 60 dB of the plotted PSD. Analysis uses the full samples in each selected window even when the waveform preview shows only time-ordered display extrema.

## Compatibility And Recovery

Direct ACQ import supports uncompressed big-endian revision 133 files with equal-length channels and sample divider 1. For other layouts, export the recording from AcqKnowledge as a supported MAT or delimited-text file. If a result is missing, read the App's status, check that both marks fit the chosen band and duration, and analyze again. The App retains the current marks in memory and uses CSV for durable results.

See the [Biosignal import guide](../../../../develop/libraries/biosignal/README.md) for supported source layouts.
