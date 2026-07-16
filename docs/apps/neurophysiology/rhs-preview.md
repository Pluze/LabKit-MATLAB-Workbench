# RHS Preview

RHS Preview opens bounded waveform windows from Intan RHS recordings and helps
inspect channels before a longer analysis.

## Launch

```matlab
labkit_RHSPreview_app
```

## Workflow

Choose an RHS file, select channels and a time window, inspect waveform and
stimulation context, then save the preview or draft protocol information.
Windowed reads avoid decoding an entire long recording for each navigation
action.

## Use Without The GUI

For ordinary non-GUI waveform access, call the reusable RHS facade directly:

```matlab
[index, status] = labkit.rhs.indexFile("recording.rhs");
assert(status.ok, status.message);
options = struct( ...
    "family", "amplifier", ...
    "channels", ["A-000", "A-001"], ...
    "timeRangeSec", [1.0 1.5]);
[window, status] = labkit.rhs.readWindow("recording.rhs", options);
assert(status.ok, status.message);
```

`indexFile` reads recording metadata without decoding the full waveform.
`readWindow` returns the bounded data and retains sampling and channel metadata
needed to interpret the waveform matrix.

`rhs_preview.analysisRun.readPreviewWindow` is also documented because it is
an app-owned callable contract, but it is intended for Runtime V2 state
transitions. It accepts the complete RHS Preview state, selected channel ids,
an action label, and a preserve-ROI flag, then returns updated state, an `ok`
flag, and a log message. Scripts that only need data should prefer
`labkit.rhs.readWindow`.

## Errors And Limitations

- File indexing can succeed even when a requested family or channel selection
  is unavailable; check the status from each read.
- Time ranges use seconds and are clamped by app state in the GUI workflow.
- Windowed reads reduce IO and memory cost but do not cache an unlimited number
  of decoded windows.

## Troubleshooting

- Keep start and sample-count values inside the recording bounds.
- Resolve channels by metadata rather than assuming a fixed amplifier index.
- Use the full analysis app when event detection or CAP metrics are required.

## See Also

- [RHS Library](../../api/rhs.md)
- [Nerve Response Analysis](nerve-response-analysis.md)
