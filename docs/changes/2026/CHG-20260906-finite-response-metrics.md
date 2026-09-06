# Measure response windows from finite samples

```labkit-change
id: CHG-20260906-finite-response-metrics
date: 2026-09-06
type: fix
compatibility: compatible
component: labkit_NerveResponseAnalysis_app | 1.7.1 -> 1.7.2
component: labkit_ResponseReviewStats_app | 1.7.1 -> 1.7.2
component: labkit.biosignal | 3.0.0 -> 3.0.1
```

## Why

Nonfinite baseline or noise samples could contaminate otherwise usable response measurements. CAP windows containing only nonfinite samples could be reported as successful. QC-only filter records also acquired a default label that prevented their exclusion flags from being consulted.

## What changed

Baseline, noise, response selection, and grouped means omit nonfinite samples while summary row counts retain missing observations. Event detection requires a positive transition score, so constant and wholly missing signals do not invent events; a lone finite sample extends as a constant rather than failing interpolation. The biosignal facade applies the same sole-sample policy in its private missing-value helper used by filtering and ingestion. Empty finite CAP search windows retain their event row with noSamples status. Nerve session inclusion preserves keep, label, then qcFlag precedence without inventing a higher-priority label.

## Impact

Finite recordings preserve their formulas, units, and values. Partially invalid recordings can retain supported finite measurements, and rejected QC-only rows are excluded from analysis.

## Compatibility and limits

Finite samples do not establish signal quality or scientific validity. Missing support remains NaN; CAP baseline fallback uses the recording-wide finite median with unavailable noise. These calculations do not replace review of channel roles, artifacts, or protocol windows.
