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
aligned = response_review_stats.analysisRun.alignSegments(segments, options);
metrics = response_review_stats.analysisRun.measureAlignedSegments(aligned, options);
summary = response_review_stats.analysisRun.summarizeMetrics(metrics);
```

## See Also

- [Nerve Response Analysis](nerve-response-analysis.md)
- `response_review_stats.analysisRun.summarizeMetrics`

