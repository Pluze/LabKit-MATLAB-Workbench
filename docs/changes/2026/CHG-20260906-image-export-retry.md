# Preserve image processing and export integrity

```labkit-change
id: CHG-20260906-image-export-retry
date: 2026-09-06
type: fix
compatibility: compatible
component: labkit_BatchImageCrop_app | 1.10.3 -> 1.10.4
component: labkit_ImageEnhance_app | 1.9.2 -> 1.9.3
component: labkit_ImageMatch_app | 1.9.1 -> 1.9.2
```

## Why

Export fingerprints described paths, dimensions, and parameters but could not establish that output files still existed or contained the current image result. A previous attempt could suppress a necessary retry.

## What changed

Explicit export always writes the current task using the existing unique-filename policy. Private duplicate-export plans and fingerprint state are removed. App guidance makes reuse conditional on complete result identity and successful existing outputs rather than requiring export fingerprints by default. Enhancement and matching continue to reread source and reference files for export. Crop resampling also supports a one-pixel source axis by extending its constant value. Image Match handles a single-pixel source or reference with constant percentiles and zero observed covariance. Image Enhance preserves the sign of descending saturation ramps so low-saturation backgrounds, rather than saturated subjects, supply the white-background statistic.

## Impact

Users can recreate deleted outputs and export changed image contents without changing unrelated settings. Current manuals state the actual completion-manifest fields and the need to record processing settings separately for reproducibility.

## Compatibility and limits

Repeated export can create additional output sets. Batch Crop continues to use its loaded image cache; it does not monitor source-file changes. Existing exports are preserved. Subject-preserving enhancement can intentionally produce different pixels because its background selection now follows the stated policy. No task archive, new manifest schema, or shared hashing API is introduced.
