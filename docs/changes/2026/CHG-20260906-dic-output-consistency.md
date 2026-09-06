# Keep DIC strain and prepared outputs consistent

```labkit-change
id: CHG-20260906-dic-output-consistency
date: 2026-09-06
type: fix
compatibility: compatible
component: labkit_DICPostprocess_app | 1.7.2 -> 1.7.3
```

## Why

A failed reload could retain newly loaded strain beside the previous overlays and summary. An invalid display range could also leave old outputs presented under new settings.

## What changed

Generation commits the new strain and prepared outputs together. Display-option refresh clears prepared results before recomputation and retains loaded strain so corrected settings can recover.

## Impact

A failed Generate attempt retains the previous complete result; invalid settings make overlays and summary unavailable until successful recomputation. The manual explains recovery and the actual image/CSV exports.

## Compatibility and limits

Numerical formulas, interpolation, and valid display behavior are preserved. External files already written are not rolled back. Processing settings must be retained separately; there is no automatic processing manifest.
