# DIC and Gait project validation ownership

```labkit-change
id: CHG-20260716-dic-gait-project-validation-ownership
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_DICPostprocess_app | 1.4.4 -> 1.4.5
component: labkit_DICPreprocess_app | 1.5.5 -> 1.5.6
component: labkit_GaitAnalysis_app | 2.0.5 -> 2.0.6
```

## Why

DIC Postprocess, DIC Preprocess, and Gait repeated Runtime's canonical project and source-record shape checks around their real domain constraints. The duplication made it harder to see which saved fields these Apps actually own.

### Accepted choice

Retain each App's required source collection and domain schema while relying on Runtime for canonical bucket structs and source-record internals. DIC continues to own alignment, crop, mask, summary, and parameter fields; Gait continues to own pose-analysis options, numeric limits, and result structure.

## What changed

- Removed 26 net lines of repeated framework structure checks from the three project specifications.
- Preserved every App-required source field and domain-specific validator.
- Added GUI-free DIC and Gait contracts that accept default projects and reject projects missing their required source collection.

## Impact

Valid DIC and Gait projects, migrations, calculations, and exports are unchanged. Malformed framework structures still fail in Runtime and malformed domain fields still fail in the owning App.

## Compatibility and limits

No payload format changed and no migration is required. Supported older projects continue through the same App-owned migration callbacks.

### Remaining limits

This boundary cleanup does not change the scientific gait analysis or image registration algorithms. Their domain complexity remains App-owned.
