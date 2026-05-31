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
events = labkit.biosignal.detectEcgPeaks(signal, ecgPeakOptions);
segments = labkit.biosignal.segmentByEvents(signal, events, windowSec);
template = labkit.biosignal.buildTemplate(segments, templateOptions);
measurements = labkit.biosignal.measureSegments(segments, template, measureOptions);
comparison = labkit.biosignal.compareGroups(values, groups);
```

`readRecording` currently accepts MAT files containing timetable variables and delimited text tables such as CSV/TSV. Low-level format normalization lives under `+labkit/+biosignal/private`.

For delimited text tables, time handling is deliberately conservative. The reader does not treat an arbitrary monotonic numeric column as seconds. It uses a table column as time only when the column is `datetime`/`duration`, when the column name is time-like such as `time_s` or `time_ms`, or when the caller explicitly passes `timeColumn` and optionally `timeUnit`. Otherwise the recording uses a synthetic sample-index time axis and keeps numeric columns as signal channels.

CSV files from wearable workflows can contain preamble rows, headerless numeric data, `I0/I1`-style Arduino columns, epoch timestamps, gaps, duplicated rows, or time axes that jump backward. The table reader tries to handle the common cases automatically and records import choices in `recording.metadata`. Backward or duplicate time steps are stitched forward with a nominal sample interval; large positive gaps are preserved and counted in `metadata.timeRepair`. If auto-detection is ambiguous, the app or caller should pass explicit import options rather than relying on inference.

Example explicit text-table time options:

```matlab
opts = struct('timeColumn', 'timestamp', 'timeUnit', 'milliseconds');
[recording, status] = labkit.biosignal.readRecording(filepath, opts);
```

Useful delimited-table options include `headerLine`, `hasHeader`, `timeColumn`, `timeUnit`, `signalColumns`, `fallbackFs`, and `timeRepair`.

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

Apps own:

- ECG-specific labels and workflow wording
- which channel is treated as ECG
- GUI controls, previews, plot arrangement, and printing/export layout
- which measurements are displayed or exported
- class labels and interpretation of group comparisons

Do not put GUI construction, `uigetfile`, app-specific plot labels, export filenames, or ECG-only workflow text inside `labkit.biosignal`.
