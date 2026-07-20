# RHS Preview

Every action and input-selection button provides hover help describing its
RHS/protocol input, waveform window, response ROI, filter, or JSON output.

RHS Preview lets you inspect an Intan RHS recording without loading the entire
waveform into memory. Use it to check channels, move through short waveform
windows, choose the channels to plot, and prepare protocol or file-filter JSON
for later analysis.

## Open RHS Preview

From the LabKit launcher, select **RHS Preview** and choose **Open**. From a
source checkout, run:

```matlab
labkit_RHSPreview_app
```

## Preview A Recording

1. On **Setup**, choose one `.rhs` file.
2. The app reads the header, lists the amplifier channels, selects up to eight
   channels, and displays a short waveform window.
3. Drag **Pan** to move the window through the recording. Scroll over the plot
   to change the displayed duration around the pointer.
4. Edit the plotted interval on the graph when you need to mark a smaller
   region. Choose **Zoom to ROI** to make that interval the current window.
5. Choose **Refresh Preview** to reread the current window from disk.

Only the displayed window is decoded. This keeps navigation practical for long
recordings and does not change the source file.

## Choose Channels And Roles

On **Protocol**, the channel table contains four columns:

| Column | Purpose |
| --- | --- |
| Plot | Show or hide this channel in the stacked preview |
| Role | Assign its purpose in the experiment |
| Label | Enter a readable name for plots and later analysis |
| Channel | Intan channel name read from the recording |

You may open an existing protocol JSON before editing the table. Choose
**Save Protocol Draft** to save the current assignments. A protocol is
recommended for response analysis because it makes the stimulation,
reference, and response channels explicit.

## Prepare A File Filter

Use **Add RHS files or folder** to collect recordings for a later analysis.
The file table lets you assign a label and comment to each recording. Remove
individual entries or clear the list as needed, then choose **Save Filter
Record**.

The filter record identifies the selected files and their labels. It does not
copy the RHS recordings or contain decoded waveforms.

## Saved Project Sources

The preview recording, optional protocol, and filter recordings share the
standard project `inputs.sources` collection. Each record keeps its
`recording`, `protocol`, or `filterRecording` role, so reopening restores the
correct control without teaching the framework app-specific field names.
Version 1 RHS Preview projects stored three separate source fields; they are
combined on load and the next save writes payload version 2.

## Project And Session State

The durable project stores portable references for one preview recording, one
optional protocol, and an ordered collection of filter recordings. It also
stores preview settings, channel-role drafts, manual filter labels/comments,
and compact export records. The App owns the `recording`, `protocol`, and
`filterRecording` roles; App SDK runtime owns each reference's portable path data.

Header indices, decoded preview windows, table presentation state, current ROI
and window position, status text, and log messages are transient session data.
They are reconstructed from the project sources when a project is opened.

For developers, `rhs_preview.definition` is the complete product contract.
`rhs_preview.projectSpec` owns project creation, validation, and the version-1
upgrade; `rhs_preview.createSession` rebuilds transient state. Fixed recording
and protocol sources, plus the variable filter collection, are updated as
ordinary App-owned portable source values. Framework file-list bindings
preserve stable source IDs while files are added, removed, or rediscovered. The App-local
`rhs_preview.sourceFiles.pathsForRole` function selects its role ordering and
delegates portable-reference decoding to the sealed
`CallbackContext.resolveSourcePaths` operation.

## Review Recording Information

The **Review** tab shows the indexed duration, channel counts, current window,
selected channels, and recent action. The preview plot uses a separate vertical
band for each selected channel so traces do not obscure one another.

## Read An RHS Window Without The App

```matlab
[index, status] = labkit.rhs.indexFile("recording.rhs");
assert(status.ok, status.message)

options = struct( ...
    "family", "amplifier", ...
    "channels", ["A-000", "A-001"], ...
    "timeRangeSec", [1.0 1.5]);
[window, status] = labkit.rhs.readWindow("recording.rhs", options);
assert(status.ok, status.message)
```

`indexFile` reads recording metadata. `readWindow` returns the selected time
range together with the sample rate and channel information needed to
interpret the waveform matrix.

## Errors And Limitations

- RHS Preview currently displays amplifier channels.
- A channel listed in a protocol must exist in the selected recording.
- A window is limited to the indexed recording duration; requests outside that
  range are clamped.
- Short reads reduce memory and waiting time, but repeated navigation still
  requires disk access.
- The app is for inspection and preparation. Use Nerve Response Analysis for
  stimulus detection and CAP measurements.

## Related Functions And Apps

- `labkit.rhs.indexFile`
- `labkit.rhs.readWindow`
- `rhs_preview.analysisRun.readPreviewWindow`
- [Nerve Response Analysis](../nerve-response-analysis/README.md)
- [RHS library](../../../libraries/rhs/README.md)

## Framework Compatibility

This App uses the App SDK runtime lifecycle and requires `labkit.app >=1 <2` and
`labkit.rhs >=1.0 <2`. App code uses semantic actions, managed interval
interaction, direct layout callbacks, and `resolveSourcePaths`; migration
iteration, busy state, and portable-reference serialization remain
framework-private.

The project validator requires the source collection and retains recording,
protocol, and filter role/cardinality rules plus preview and annotation fields;
Runtime validates canonical buckets and each source record first.

Its session factory returns only App-specific status, time-window view, and
indexed preview cache fields. Runtime supplies absent canonical buckets and
owns workflow-log initialization.

The semantic layout follows the [Runtime callback contract](../../../framework/guides/runtime.md#layout-and-action-rules):
every control and plot names its concrete callback or renderer, and the
definition validates those bindings before creating a figure.
