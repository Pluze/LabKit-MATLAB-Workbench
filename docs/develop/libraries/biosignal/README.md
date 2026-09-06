# Biosignal API

```labkit-page
id: library-biosignal
type: reference
audience: app-developer
summary: Use GUI-free import and processing functions for physiological and wearable time-series data.
```

[Public API index](../../../reference/README.md) | [App guide](../../../use/apps/README.md)

`labkit.biosignal.*` provides GUI-free import and processing functions for physiological and wearable time-series data. Use it to build a MATLAB script from the same recording, channel, event, segment, template, and measurement structures used by LabKit apps.

`labkit.biosignal.version()` returns biosignal-library version and compatibility information used by `labkit.contract` requirement checks.

ECG peak detection is the only modality-specific detector in the current module. Import, filtering, segmentation, template construction, and measurement use generic biosignal structures.

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
```

`readRecording` accepts MAT files containing timetable or table variables, BIOPAC AcqKnowledge MAT exports containing `data`, `isi`, `isi_units`, `labels`, and `units`, MAT files containing one unambiguous nonscalar numeric array, and delimited text tables such as CSV, TSV, and TXT. BIOPAC MAT sample intervals are converted to seconds while channel labels, engineering units, and the exported start-sample value remain available in signal metadata.

The public call remains the same across formats. Lightweight file inspection ranks compatible readers, the importer falls back when the highest-ranked reader rejects the content, and `status.format`, `status.attempts`, `status.fallbackUsed`, and `status.fileInfo` explain the result. Matching fields in `recording.metadata` keep this information with successful data. This is a closed internal reader plan rather than a public device registry.

Every decoded channel is normalized to uniform sampling by default. The target interval is the median positive input interval. Already uniform data keeps its sample values and receives an exact grid. Before interpolation, non-finite time rows are removed, samples are sorted by time, and duplicate timestamps retain their first sample. Irregular continuous sections then use linear interpolation. Gaps larger than `gapFactor` delimit sections and are compressed rather than filled with invented samples across the gap. Per-channel and recording-level `samplingNormalization` metadata records whether values were resampled, input and output counts, removed times, the nominal interval, timing deviation, and compressed gaps. Pass `resampleUniform=false` only when a workflow requires the parser-produced irregular time axis.

For delimited text tables, time handling is deliberately conservative. The reader does not treat an arbitrary monotonic numeric column as seconds. It uses a table column as time only when the column is `datetime`/`duration`, when the column name is time-like such as `time_s` or `time_ms`, or when the caller explicitly passes `timeColumn` and optionally `timeUnit`. Otherwise the recording uses a synthetic sample-index time axis and keeps numeric columns as signal channels.

CSV and TXT files from wearable workflows can contain preamble rows, headerless numeric data, `I0/I1`-style Arduino columns, BIOPAC `sec`/channel tables with channel-label and unit preambles plus per-column count rows, epoch timestamps, footer metadata rows, gaps, duplicated rows, or time axes that jump backward. The table reader tries to handle the common cases automatically and records import choices in `recording.metadata`. For a recognized BIOPAC text preamble, displayed channel names and signal units come from that preamble rather than generic `CH` column identifiers. Backward or duplicate time steps are stitched forward with a nominal sample interval; large positive gaps are preserved and counted in `metadata.timeRepair`. If auto-detection is ambiguous, the app or caller should pass explicit import options rather than relying on inference.

Example explicit text-table time options:

```matlab
opts = struct('timeColumn', 'timestamp', 'timeUnit', 'milliseconds');
[recording, status] = labkit.biosignal.readRecording(filepath, opts);
```

Useful delimited-table options include `headerLine`, `hasHeader`, `timeColumn`, `timeUnit`, `signalColumns`, `fallbackFs`, and `timeRepair`. Option structures are closed contracts. Unknown fields or non-struct values raise `labkit:biosignal:InvalidOptions` instead of being silently ignored.

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
| `resampleUniform` | logical | `true` | Normalize decoded channels onto a uniform seconds grid; false preserves parser time. |

## Data Structures

Functions exchange ordinary MATLAB structures with these principal fields:

```text
recording.sourcePath, recording.name, recording.signals, recording.metadata
signal.time, signal.values, signal.fs, signal.name, signal.displayName, signal.metadata
events.index, events.time, events.amplitude, events.score, events.label
segments.values, segments.timeOffset, segments.eventIndex, segments.eventTime, segments.fs
template.values, template.timeOffset, template.keptSegmentIndex, template.score
measurements.perSegment, measurements.summary
```

Open an individual function page for required fields, row/column orientation, units, empty-result behavior, and errors.

## Processing Provided By This Module

The public functions cover:

- file loading and timetable/table normalization
- channel listing and extraction
- time ROI cropping
- generic filtering
- ECG/QRS peak detection
- event-centered segmentation
- template building and template-residual SNR-style segment measurements
- generic group summaries and pairwise Welch-style comparisons

`detectEcgPeaks` supports `qrs-streaming`, `pan-tompkins`, and `local` methods. Select the method through its options; no detector-specific helper call is required.

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

Filtering fills missing or nonfinite values by linear interpolation and extrapolation. If only one finite sample remains, it extends that value as a constant; an entirely missing signal becomes zeros. This is numerical missing-sample handling, not evidence of a valid acquisition.

### Other Processing Options

| Function | Options / parameters |
| --- | --- |
| `filterSignal(signal, spec)` | `spec.type`: `bandpass`, `lowpass`, `highpass`, `none`, `off`; `spec.cutoffHz`: scalar or `[low high]`; `spec.edgeMode`: `reflect` default or `none`; `spec.edgePadSec`: padding seconds, auto by default; `spec.edgeTaperSec`: padded-edge taper seconds, default `1`. |
| `segmentByEvents(signal, events, windowSec)` | `windowSec`: `[start end]` seconds relative to event, default `[-0.35 0.35]`. |
| `buildTemplate(segments, opts)` | `opts.topN`: positive integer, default `min(30, segmentCount)`. |
| `measureSegments(segments, template, opts)` | `opts.signalWindowSec`: `[start end]`, default `[-0.06 0.06]`; `opts.noiseWindowsSec`: N-by-2 matrix, default `[-0.30 -0.20; 0.40 0.50]`. |

Applications decide:

- ECG-specific labels and workflow wording
- which channel is treated as ECG
- GUI controls, previews, plot arrangement, and printing or export layout
- which measurements are displayed or exported
- class labels and interpretation of group comparisons

These application choices are intentionally not parameters of the generic biosignal functions.

## Reference Contract

The generated page for every `labkit.biosignal` function documents its exact input structure, implemented options, defaults, legal values, empty-result and error behavior, and related functions. The repository documentation contract discovers the whole public package rather than relying on a hand-maintained function list, and executes every block labeled `Example:`.
