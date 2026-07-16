# Neurophysiology Apps

The neurophysiology family moves from raw Intan RHS inspection through protocol
definition, event-locked response analysis, and final metric review.

## Choose An App

| Stage | App |
| --- | --- |
| Inspect headers and waveform windows; draft channel/filter protocol | [RHS Preview](../neurophysiology/rhs-preview.md) |
| Detect stimulation trains and measure CAP responses | [Nerve Response Analysis](../neurophysiology/nerve-response-analysis.md) |
| Review aligned segments and descriptive statistics | [Response Review and Stats](../neurophysiology/response-review-stats.md) |

## Shared Workflow

RHS Preview reads bounded windows rather than loading complete recordings.
Nerve Response Analysis combines a filter record, protocol, and source files
into an analysis JSON containing events, trains, metrics, and issues. Response
Review and Stats reads that analysis or a supported legacy segment table and
exports review metrics.

## Programmatic Entry Points

`labkit.rhs.*` provides indexed header and waveform access. Cataloged
`nerve_response_analysis.analysisRun.*` and
`response_review_stats.analysisRun.*` functions expose event detection,
segment alignment, CAP measurement, and summary calculations without a GUI.

## Related Libraries

- [RHS Library](../../api/rhs.md)
- [Biosignal Library](../../api/biosignal.md)
