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

```matlab
window = rhs_preview.analysisRun.readPreviewWindow( ...
    "recording.rhs", channelSelection, startSample, sampleCount);
```

The result retains sampling and channel metadata needed to interpret the
returned waveform matrix.

## Troubleshooting

- Keep start and sample-count values inside the recording bounds.
- Resolve channels by metadata rather than assuming a fixed amplifier index.
- Use the full analysis app when event detection or CAP metrics are required.

## See Also

- [RHS Library](../../api/rhs.md)
- [Nerve Response Analysis](nerve-response-analysis.md)

