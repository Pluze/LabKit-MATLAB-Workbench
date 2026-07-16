# Neurophysiology Apps

The neurophysiology apps cover three stages of an Intan RHS workflow: checking
recordings, measuring stimulus-evoked responses, and reviewing the resulting
measurements.

## Choose An App

| What you want to do | App |
| --- | --- |
| Check recording metadata and short waveform windows; assign channel roles | [RHS Preview](rhs-preview/README.md) |
| Find stimulation events and measure compound action potentials | [Nerve Response Analysis](nerve-response-analysis/README.md) |
| Recalculate or summarize measurements from an analysis or segment table | [Response Review and Stats](response-review-stats/README.md) |

## Recommended Workflow

1. Open a representative recording in RHS Preview. Confirm the channels and
   inspect a short portion of the waveform.
2. Save a protocol draft that records channel roles. If you are working with a
   set of recordings, label the files and save a filter record.
3. Open the filter record in Nerve Response Analysis, add the protocol, and run
   the analysis.
4. Export the analysis as JSON. This file contains the events, stimulus trains,
   response measurements, and any issues found while reading the recordings.
5. Open that JSON in Response Review and Stats to inspect and export the
   measurement table. A compatible segment CSV can be used instead when you
   need to recalculate measurements from waveforms.

Each stage saves its own parameters with the results. Keep those settings with
any reported latency, amplitude, or signal-to-noise values.

## Use RHS Data In MATLAB Code

The [RHS library](../../libraries/rhs/README.md) provides functions for reading
recording metadata and selected waveform windows without opening an app. The
individual app manuals show the calculation functions used for event
detection, response measurement, alignment, and summary statistics.

## Related Documentation

- [RHS library](../../libraries/rhs/README.md)
- [Biosignal library](../../libraries/biosignal/README.md)
- [App catalog](../README.md)
