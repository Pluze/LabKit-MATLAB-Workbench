# RHS Preview

RHS Preview lets you inspect an Intan RHS recording without loading the entire
waveform into memory. Use it to check channels, move through short waveform
windows, choose the channels to plot, and prepare protocol or file-filter JSON
for later analysis.

The displayed file is decoded and presented by the source workflow that owns
the current window, preventing a separate display-file path from drifting from
the selected recording.

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

Use **Add RHS files**, **Add folder**, or **Add folder tree** to collect the
recordings for later analysis. The file table lets you assign a label and comment to each recording. Remove
individual entries or clear the list as needed, then choose **Save Filter
Record**.

The filter record identifies the selected files and their labels. It does not
copy the RHS recordings or contain decoded waveforms.

## Saved Project Sources

The preview recording, optional protocol, and filter recordings are saved as
distinct portable project sources. Older projects that stored these sources
separately are combined automatically on load.

## Saving And Reopening A Project

The project stores references to the preview recording, optional protocol, and
ordered filter recordings together with preview settings, channel assignments,
labels, and comments. Waveform samples are not copied into the project. When a
project is reopened, the App reads the required window from the source file;
if a source has moved, it asks you to locate it.

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
