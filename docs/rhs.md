# RHS Library

`labkit.rhs.*` is the GUI-free Intan RHS file facade. It provides file
discovery, header inspection, block indexing, and lazy time-window reads for
RHS-backed apps.

This facade owns the RHS file mechanics only. Experiment protocols, channel
roles, stimulus-train interpretation, CAP thresholds, segment definitions,
plots, and export schemas stay in the owning app or protocol file.

## Public RHS API

Common calls:

```matlab
filepaths = labkit.rhs.findFiles(folder);
[info, status] = labkit.rhs.inspectFile(filepath);
[index, status] = labkit.rhs.indexFile(filepath);
[window, status] = labkit.rhs.readWindow(filepath, opts);
```

`inspectFile` reads only the file header. `indexFile` adds data-offset,
bytes-per-block, sample-count, duration, and exact-block status. `readWindow`
loads only the requested full sample window rather than converting the whole
file into a MAT file.

`readWindow` options:

```matlab
opts = struct( ...
    "family", "amplifier", ...
    "channels", "C001", ...
    "timeRangeSec", [0.0 0.050]);
[window, status] = labkit.rhs.readWindow(filepath, opts);
```

Supported families:

```text
amplifier
stim
dcAmplifier
boardAdc
boardDac
boardDigIn
boardDigOut
```

Channel selection may use numeric indices or native/custom channel names.
Names are matched exactly first, then by a normalized comparison that ignores
punctuation, so `C001` can match a native channel such as `C-001`.

## Returned Structs

`info` fields include:

```text
type, version, filepath, name, fileVersion, sampleRateHz,
samplesPerBlock, frequencyParameters, stimParameters, notes,
dcAmplifierSaved, boardMode, referenceChannel, channelFamilies,
channelTable, spikeTriggers, signalGroups, fileBytes, dataOffsetBytes,
bytesPerBlock, dataBytes, blockCount, sampleCount, durationSec,
exactBlocks
```

`window` fields include:

```text
type, version, sourcePath, name, family, unit, sampleRateHz,
sampleRange, channels, timeSec, values
```

`values` is always samples-by-channels. Amplifier data are returned in
microvolts, stim current in microamps, ADC/DAC data in volts, and digital
channels as logical-style 0/1 values.

## Parser Basis

The parser follows Intan's RHS MATLAB reader layout:

```text
header
per-block timestamps
per-block amplifier data
optional per-block DC amplifier data
per-block stim data
per-block board ADC data
per-block board DAC data
optional digital input raw words
optional digital output raw words
```

The facade preserves the same physical-unit scaling used by the Intan reader.
It does not apply protocol-specific filtering, event detection, or CAP
analysis.

## Protocol Files

Neurophysiology apps can use a lightweight protocol JSON to describe signal
semantics for one experiment family. The protocol is a channel map, not an
analysis settings dump.

The protocol is intentionally app-owned. `labkit.rhs` can read the waveforms
and metadata it describes, but it should not interpret nerve experiment
semantics itself.

The supported protocol shape is intentionally small:

```text
channels.roles   named channel roles matched to RHS native channel names
channels.pairs   differential or associated role pairs built from roles
preview          default preview family and time window
```

Minimal saved shape:

```json
{
  "schemaVersion": "labkit.rhs.protocol.v1",
  "protocolId": "rhs_protocol_draft",
  "label": "RHS Protocol Draft",
  "channels": {
    "roles": [
      {
        "id": "reference",
        "label": "Reference",
        "match": {"anyNativeName": ["C-001"]},
        "required": false
      }
    ],
    "pairs": [
      {
        "id": "cp_diff",
        "label": "CP",
        "positive": "cp_positive",
        "negative": "cp_negative",
        "mode": "positive-minus-negative"
      }
    ]
  },
  "preview": {
    "defaultFamily": "amplifier",
    "defaultWindowSec": [0, 0.05]
  }
}
```

Roles should express lab meaning such as `reference`, `cp_positive`,
`cp_negative`, `stim_monitor`, or any other experiment-local name. Pairs should
express relationships such as a positive-minus-negative differential. Optional
recording-pattern hints can be added later when a real workflow needs them, but
QC thresholds, CAP search windows, metric lists, common-mode algorithm details,
and export schemas belong to the analysis apps, not the protocol file.

`labkit_RHSPreview_app` is the visual protocol drafting surface. The Protocol
tab loads an optional JSON, shows editable channel-role and pair rows beside
the stacked waveform preview, and saves a normalized lightweight draft. There
is no tracked sample protocol file; users create one from an RHS recording in
the Preview app.

## Neurophysiology App Flow

The RHS app family keeps raw RHS access lazy and channel-map aware:

```text
labkit_RHSPreview_app
  RHS file + optional protocol JSON -> stacked waveform preview and protocol draft

labkit_RHSScreen_app
  RHS folder + optional protocol JSON -> curated rhs_screen_session.json

labkit_NerveResponseAnalysis_app
  rhs_screen_session.json + recommended protocol JSON -> nerve_response_analysis.json

labkit_ResponseReviewStats_app
  nerve_response_analysis.json or segment CSV -> response_review_metrics.csv
```

## Required Files and Folder Shape

`labkit_RHSPreview_app` only needs one Intan `.rhs` file. A protocol JSON is
optional. If no protocol exists yet, load an RHS file, inspect the waveforms,
fill the Protocol Roles and Protocol Pairs tables, then save a protocol draft.

Choosing an RHS file indexes the header/data blocks and immediately reads an
adaptive preview window. The right pane shows selected channels as stacked,
time-aligned waveforms. The default preview length is estimated from file
duration, sample rate, and selected channel count so short files can show more
data while long files stay interactive. Use the Pan panner to move through the
file, the panner arrow buttons for small left/right steps, and the mouse wheel
over the preview axes to zoom the time window. Dragging on the preview axes
with the left mouse button marks a temporary ROI for visual review. Use Zoom to
ROI to set the preview window to that marked time range and reread only that
window.

The Protocol tab is the protocol-drafting surface. Select which channels to
plot, assign roles/labels, mark required channels, define any role pairs, and
use Save Protocol Draft to write a JSON draft. Apps should not require
hand-written JSON for basic preview or screening.

`labkit_RHSScreen_app` expects a folder, not a single file. The app searches
that folder recursively for `.rhs` recordings, so either flat or nested batches
are valid:

```text
experiment_batch/
  recording_001.rhs
  recording_002.rhs
  subfolder/
    recording_003.rhs
```

Screening export requires an output folder and writes:

```text
rhs_screen_session.json
```

Choosing a folder starts a structural scan immediately. The Refresh Scan action
reruns the same pass after changing QC options or protocol metadata. This scan
indexes RHS headers and block structure only; it is the replacement for the old
workflow that converted every RHS file into timetables before manual curation.

The session JSON stores metadata and local paths to the original RHS files; it
does not copy raw waveforms. If the RHS files move, rescan the folder or update
the session paths before analysis.

`labkit_NerveResponseAnalysis_app` needs the `rhs_screen_session.json` created
by screening. A protocol JSON is recommended for reliable role and differential
pair resolution, but the app should still run with best-effort fallbacks and
issue rows when protocol information is missing. The RHS files referenced by
the session must still be reachable. Export writes:

```text
nerve_response_analysis.json
```

`labkit_ResponseReviewStats_app` accepts either `nerve_response_analysis.json`
or a legacy segment CSV. Selecting an input immediately loads metrics when
possible. Segment CSVs can use a shared `Time_s` column with one or more signal
columns, or paired columns such as `Segment1_Time_s` and `Segment1_Signal`.
Export writes:

```text
response_review_metrics.csv
```

`rhs_screen_session.json` stores recording paths, header/index QC, channel
signatures, grouping, a user-editable `keep` flag, review notes, and kept
recording ids. It does not store raw waveforms. Auto QC is intentionally
structural: index failures are failed, header-only/no-data files need review,
trailing partial blocks need review when exact blocks are required, short
recordings can need review, and otherwise recordings default to kept. It does
not decide whether a nerve response is scientifically good.

The analysis app reads only recordings kept by the screening session. For each
kept RHS file it reads only the channels it needs, using the protocol to
resolve roles such as reference and positive/negative differential pairs.

Event detection tries usable stimulus-current information first, then
reference-channel derivative detection, then recording-channel fallbacks
derived from protocol pairs or known role names. Missing or poor channels
should produce issue rows or review flags, not a crashing batch.

The response review app accepts the analysis metrics directly, and also accepts
legacy segment CSV layouts by normalizing them to:

```text
segments -> aligned time grid -> metrics/statistics
```

This keeps old manual segment workflows usable while giving new workflows a
stable aligned data model. CAP plots should stay visually plain: white
background, thin lines, clear grid/axes, shared time axis for stacked traces,
and explicit overlays for peaks, segment windows, or baseline windows when
those data are available.
