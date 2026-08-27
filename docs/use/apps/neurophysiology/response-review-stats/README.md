# Response Review And Stats

```labkit-page
id: app-response-review-stats
type: landing
audience: app-user
summary: Review nerve-response results or segment tables, adjust measurement windows when needed, and export a clean CSV for downstream statistics.
```

Response Review and Stats opens a Nerve Response Analysis result or a segment table, displays the measurements, and exports a clean CSV for review or downstream statistics. Segment tables can also be aligned and measured again with new baseline and noise windows.

Loading or recalculating a source produces the presentation data consumed by the review pages directly, without a second source-file presenter state.

## Open Response Review And Stats

From the launcher, select **Response Review Stats** and choose **Open**. From a source checkout, run:

```matlab
labkit_ResponseReviewStats_app
```

## Review An Analysis

1. On **Setup**, choose an analysis JSON or segment CSV.
2. The app loads the measurement rows immediately.
3. If the input contains waveform segments, set the **Baseline** and **Noise** windows. Both ranges are expressed in seconds relative to alignment time.
4. Choose **Refresh Metrics** when you want to reload the source explicitly.
5. On **Review**, inspect the summary and details. Switch the plot between **Summary** and **Aligned**.
6. On **Export**, choose a folder and select **Export Metrics**.

Changing either time window recalculates a loaded segment input automatically. For an analysis JSON that already contains measurements, the app reads those measurements rather than recreating unavailable waveform data.

Loading or refreshing metrics fits the selected **Summary** or **Aligned** result view. Switching between those coordinate views also fits once; table, status, and export redraws preserve the current zoom.

## Accepted Inputs

- JSON exported by Nerve Response Analysis. The app reads its `metrics` records.
- CSV that can be interpreted as waveform segments with time and values.

When segments have different time grids, the app interpolates them onto a shared grid. If no interval is specified in code, it uses the median positive source interval. If the timestamps cannot provide one, it uses 0.0001 seconds. When no window is specified, the grid spans the intersection of the time ranges after each segment's alignment-time shift. Samples outside an aligned segment's original range remain `NaN`.

The selected input remains a live source while the App is open. Response Review does not write a task archive; the metrics CSV is its durable output.

## Align Segments In MATLAB Code

<!-- labkit-runnable-example -->
```matlab
localTime = (-0.003:0.001:0.012).';
firstValues = zeros(size(localTime));
firstValues(localTime == 0.004) = 2;
firstValues(localTime == 0.008) = -1;
secondValues = 0.8 * firstValues;
segments = struct( ...
    "timeSec", {10 + localTime, 20 + localTime}, ...
    "values", {firstValues, secondValues}, ...
    "name", {"first", "second"}, ...
    "alignTimeSec", {10, 20});
options = struct( ...
    "sampleIntervalSec", 0.001, ...
    "windowSec", [-0.003 0.012], ...
    "baselineWindowSec", [-0.003 -0.001], ...
    "noiseWindowSec", [-0.003 -0.001], ...
    "measurementWindowSec", [0 0.010]);

aligned = response_review_stats.analysisRun.alignSegments(segments, options);
metrics = response_review_stats.analysisRun.measureAlignedSegments( ...
    aligned, options);
summary = response_review_stats.analysisRun.summarizeMetrics(metrics);
```

Each segment supplies `timeSec`, `values`, and `name`. An optional `alignTimeSec` shifts that segment to the common zero. `aligned.values` is a samples-by-segments matrix.

## Measurements And Summary

For each aligned segment, the calculation subtracts the baseline mean and reports positive and negative peaks, peak-to-peak amplitude, noise RMS, and SNR. The summary groups rows by `pairId` when available; otherwise it uses the segment name. Counts are included so exclusions and missing rows remain visible.

## Output Files

**Export Metrics** writes:

- `response_review_metrics.csv`, one row per measurement.

## Function Reference

The generated pages for [`alignSegments`](../../../../reference/api/response_review_stats/analysisRun/alignSegments.html) and [`measureAlignedSegments`](../../../../reference/api/response_review_stats/analysisRun/measureAlignedSegments.html) define time-window option shapes and defaults, interpolation and empty-sample behavior, output table columns, failures, examples, and related APIs.

## Related Functions And Apps

- `response_review_stats.analysisRun.loadMetrics`
- `response_review_stats.analysisRun.alignSegments`
- `response_review_stats.analysisRun.measureAlignedSegments`
- `response_review_stats.analysisRun.summarizeMetrics`
- [Nerve Response Analysis](../nerve-response-analysis/README.md)

## Errors And Limitations

- Baseline and noise windows must overlap the available data to produce finite measurements.
- Interpolation makes grids comparable but cannot restore timing precision or bandwidth that is absent from the source.
- An empty input returns an empty result rather than a synthetic summary.
- Keep the chosen windows with any exported amplitude or SNR values.
