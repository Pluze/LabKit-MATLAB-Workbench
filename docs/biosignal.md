# Biosignal

`labkit.biosignal.*` is the GUI-free facade for physiological or wearable time-series data. It is a peer of `labkit.dta`, not a replacement for app-owned workflow logic.

The module currently supports the first ECG-oriented wearable app, but the public API intentionally uses generic signal vocabulary: recordings, channels, events, segments, templates, measurements, and groups.

## Public Surface

Current app-facing functions:

```matlab
[recording, status] = labkit.biosignal.readRecording(filepath);
names = labkit.biosignal.listChannels(recording);
signal = labkit.biosignal.getChannel(recording, channel);
cropped = labkit.biosignal.cropSignal(signal, [startSec endSec]);
filtered = labkit.biosignal.filterSignal(signal, filterSpec);
ecgPeakOptions = labkit.biosignal.defaultEcgPeakOptions("qrs-streaming");
events = labkit.biosignal.detectEcgPeaks(signal, ecgPeakOptions);
segments = labkit.biosignal.segmentByEvents(signal, events, windowSec);
template = labkit.biosignal.buildTemplate(segments, templateOptions);
measurements = labkit.biosignal.measureSegments(segments, template, measureOptions);
comparison = labkit.biosignal.compareGroups(values, groups);
```

`readRecording` currently accepts MAT files containing timetable variables and delimited text tables such as CSV/TSV. Low-level format normalization lives under `+labkit/+biosignal/private`.

For delimited text tables, time handling is deliberately conservative. The reader does not treat an arbitrary monotonic numeric column as seconds. It uses a table column as time only when the column is `datetime`/`duration`, when the column name is time-like such as `time_s` or `time_ms`, or when the caller explicitly passes `timeColumn` and optionally `timeUnit`. Otherwise the recording uses a synthetic sample-index time axis and keeps numeric columns as signal channels.

CSV and TXT files from wearable workflows can contain preamble rows, headerless numeric data, `I0/I1`-style Arduino columns, `sec`/channel tables with per-column count rows, epoch timestamps, footer metadata rows, gaps, duplicated rows, or time axes that jump backward. The table reader tries to handle the common cases automatically and records import choices in `recording.metadata`. Backward or duplicate time steps are stitched forward with a nominal sample interval; large positive gaps are preserved and counted in `metadata.timeRepair`. If auto-detection is ambiguous, the app or caller should pass explicit import options rather than relying on inference.

Example explicit text-table time options:

```matlab
opts = struct('timeColumn', 'timestamp', 'timeUnit', 'milliseconds');
[recording, status] = labkit.biosignal.readRecording(filepath, opts);
```

Useful delimited-table options include `headerLine`, `hasHeader`, `timeColumn`, `timeUnit`, `signalColumns`, `fallbackFs`, and `timeRepair`.

### `readRecording` Options

| Option | Type | Default | Valid values / meaning |
| --- | --- | --- | --- |
| `headerLine` | positive integer | auto | Header line for text tables, or first data line when `hasHeader=false`. |
| `hasHeader` | logical | auto | Whether the detected/explicit line contains column names. |
| `timeColumn` | name or 1-based index | auto | Explicit time column. Use this when auto-detection is ambiguous. |
| `timeUnit` | string | infer | `seconds`, `milliseconds`, `microseconds`, `nanoseconds`, or sample/index aliases. |
| `signalColumns` | names or 1-based indices | all numeric non-time columns | Restricts imported signal channels. |
| `fallbackFs` | positive scalar Hz | none | Used for synthetic sample-index time or timestamp repair fallback. |
| `timeRepair` | string | `auto` | `auto` stitches duplicate/backward time steps; `none`/`off` disables repair. |
| `gapFactor` | positive scalar | `20` | Positive gaps larger than this multiple of nominal `dt` are counted as large gaps. |
| `useFirstNumericColumnAsTime` | logical | `false` | Opt-in fallback for ambiguous text tables. |

## Data Shape

The first version uses structs rather than MATLAB classes:

```text
recording.sourcePath, recording.name, recording.signals, recording.metadata
signal.time, signal.values, signal.fs, signal.name, signal.displayName, signal.metadata
events.index, events.time, events.amplitude, events.score, events.label
segments.values, segments.timeOffset, segments.eventIndex, segments.eventTime, segments.fs
template.values, template.timeOffset, template.keptSegmentIndex, template.score
measurements.perSegment, measurements.summary
```

This keeps the API easy to test and avoids committing to a class hierarchy before the wearable workflows stabilize.

## Ownership Boundary

The biosignal facade may own:

- file loading and timetable/table normalization
- channel listing and extraction
- time ROI cropping
- generic filtering
- ECG/QRS peak detection through a public facade with private algorithm implementations
- event-centered segmentation
- template building and template-residual SNR-style segment measurements
- generic group summaries and pairwise Welch-style comparisons

`detectEcgPeaks` is intentionally ECG-specific. It exposes a stable app-facing facade while keeping the concrete peak detectors private. Supported methods are `qrs-streaming`, `pan-tompkins`, and `local`; apps can switch methods for visual/performance comparison without calling the private implementations directly.

### `detectEcgPeaks` Options

Start from `labkit.biosignal.defaultEcgPeakOptions(method)` and override only the fields the app exposes:

```matlab
opts = labkit.biosignal.defaultEcgPeakOptions("pan-tompkins");
opts.polarity = "positive";
opts.minDistanceSec = 0.35;
events = labkit.biosignal.detectEcgPeaks(signal, opts);
```

| Option | Type | Default | Valid values / meaning |
| --- | --- | --- | --- |
| `method` | string | `qrs-streaming` | `qrs-streaming`, `pan-tompkins`, or `local`. |
| `polarity` | string | `auto` | `auto`, `positive`, `negative`, or `absolute`. |
| `minDistanceSec` | positive scalar | `0.25` for ECG methods, `0.05` for local | Minimum accepted peak spacing. |
| `thresholdStd` | scalar | `3` | Local method robust-threshold multiplier. |
| `smoothSec` | positive scalar | `0.01` | Local method score smoothing window. |
| `integrationWindowSec` | positive scalar | `0.150` | Pan-Tompkins moving-integration window. |
| `refineSearchSec` | positive scalar | `0.120` Pan-Tompkins, `0.090` streaming | Detector-trace peak snap search half-window. |
| `rawRefineSearchSec` | positive scalar | `0.020` | Final raw-signal peak snap half-window for Pan-Tompkins and streaming. |
| `baselineWindowSec` | positive scalar | `0.600` | Streaming causal baseline window. |
| `envelopeWindowSec` | positive scalar | `0.080` | Streaming slope-envelope window. |
| `lookaheadSec` | positive scalar | `0.080` | Streaming local-maximum lookahead. |
| `minTemplateScore` | scalar | `0.45` | Streaming rolling-template QC threshold. |
| `medianPolarityCorrection` | logical | `true` | Streaming post-pass for `auto`/`positive` polarity: reviews recent anchors against the signal median and re-snaps inverted anchors. |
| `medianReviewPeakCount` | positive integer | `3` | Number of latest streaming peaks considered by the median polarity review. |

### Other Processing Options

| Function | Options / parameters |
| --- | --- |
| `filterSignal(signal, spec)` | `spec.type`: `bandpass`, `lowpass`, `highpass`, `none`, `off`; `spec.cutoffHz`: scalar or `[low high]`; `spec.edgeMode`: `reflect` default or `none`; `spec.edgePadSec`: padding seconds, auto by default; `spec.edgeTaperSec`: padded-edge taper seconds, default `1`. |
| `segmentByEvents(signal, events, windowSec)` | `windowSec`: `[start end]` seconds relative to event, default `[-0.35 0.35]`. |
| `buildTemplate(segments, opts)` | `opts.topN`: positive integer, default `min(30, segmentCount)`. |
| `measureSegments(segments, template, opts)` | `opts.signalWindowSec`: `[start end]`, default `[-0.06 0.06]`; `opts.noiseWindowsSec`: N-by-2 matrix, default `[-0.30 -0.20; 0.40 0.50]`. |

Apps own:

- ECG-specific labels and workflow wording
- which channel is treated as ECG
- GUI controls, previews, plot arrangement, and printing/export layout
- which measurements are displayed or exported
- class labels and interpretation of group comparisons

Do not put GUI construction, `uigetfile`, app-specific plot labels, export filenames, or ECG-only workflow text inside `labkit.biosignal`.
