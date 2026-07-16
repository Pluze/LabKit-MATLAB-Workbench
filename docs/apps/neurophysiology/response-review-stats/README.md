# Response Review And Stats

Response Review and Stats aligns response segments, supports visual review, and
summarizes retained measurements.

## Launch

```matlab
labkit_ResponseReviewStats_app
```

## Workflow

Load response results, select alignment and baseline policies, inspect the
segments, exclude invalid observations when justified, then export aligned
signals, per-segment measurements, and summary statistics.

## Scientific Semantics

Alignment changes the common time origin but not source sampling. Measurement
windows and baseline policy must be consistent across compared groups.
Summaries report the retained sample count so exclusions remain auditable.

## Use Without The GUI

```matlab
options = struct( ...
    "sampleIntervalSec", 1e-4, ...
    "windowSec", [-0.01 0.02], ...
    "baselineWindowSec", [-0.01 -0.002], ...
    "noiseWindowSec", [-0.01 -0.002], ...
    "measurementWindowSec", [0.002 0.012]);
aligned = response_review_stats.analysisRun.alignSegments(segments, options);
metrics = response_review_stats.analysisRun.measureAlignedSegments( ...
    aligned, options);
summary = response_review_stats.analysisRun.summarizeMetrics(metrics);
```

Each input segment must provide `timeSec`, `values`, and `name`; an optional
`alignTimeSec` shifts that segment onto the common time origin. When
`sampleIntervalSec` is omitted, the median positive source interval is used.
When `windowSec` is omitted, alignment uses only the time range shared by all
segments. Linear interpolation leaves out-of-range samples as `NaN`.

`measureAlignedSegments` returns one row per segment with baseline limits,
positive and negative peaks, peak-to-peak amplitude, noise RMS, and SNR in dB.
The baseline mean is subtracted before measuring. `summarizeMetrics` groups by
`pairId` when present, otherwise by `SegmentName`, and reports count plus mean
peak-to-peak and SNR values.

## Errors And Limitations

- Empty input returns an aligned model with status `empty`; an invalid or
  unavailable sample interval falls back to a 10 kHz grid.
- Baseline, noise, and measurement windows use seconds and must overlap the
  aligned grid to produce finite measurements.
- Interpolation enables comparison on a shared grid but cannot recreate
  bandwidth or timing precision absent from the source samples.

## See Also

- [Nerve Response Analysis](../nerve-response-analysis/README.md)
- `response_review_stats.analysisRun.alignSegments`
- `response_review_stats.analysisRun.measureAlignedSegments`
- `response_review_stats.analysisRun.summarizeMetrics`
