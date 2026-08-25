# Figure Studio restores its calibrated visual proportions on import

```labkit-change
id: CHG-20260818-figure-studio-automatic-standard-layout
date: 2026-08-18
type: fix
compatibility: compatible
component: labkit_FigureStudio_app | 0.7.3 -> 0.7.4
component: labkit_TTestWizard_app | 1.3.1 -> 1.3.2
```

## Why

Figure Studio applied individual publication-style properties to a plot handoff, but importing source-window geometry or widening the canvas for labels could change the normalized relationship between the plotting frame, text, and strokes. Comparison brackets could also retain a stroke meaning inconsistent with the calibrated semantic hierarchy.

### Accepted choice

Keep Figure Studio responsible for the complete standard publication layout. Every LabKit-style import returns to the calibrated reference plot frame and its measured typography and stroke ratios, regardless of source-window geometry. Resolve long categorical labels through automatic balanced two-line layout rather than widening the panel or reducing the calibrated text scale.

## What changed

- Plot handoffs now open with the complete **LabKit figure** reference frame instead of inheriting source-window geometry.
- Categorical label length is compared with its available category slot using the calibrated 96-PPI upper density; labels that cannot fit wrap at a balanced word boundary without changing the reference panel proportions.
- Legend-excluded comparison brackets and annotation lines now use the standard reference-line width instead of retaining an unrelated source stroke, while visible line series use the standard data-line width regardless of point count.
- Standard bar charts use an unfilled white-ground treatment with the calibrated color sequence on their boundaries instead of retaining large source-color fills.
- FIG and subplot selection restore the reference layout for a standard preset while preserving the complete source layout only for **FIG default**.
- **FIG default** continues to restore the complete source presentation instead of the standard style.
- Added product and source-capability regressions for reference visual geometry without source typography leakage.

## Impact

Imported plots open with the same normalized panel size, plotting-to-text proportion, colors, and semantic stroke hierarchy as the maintained reference. Long labels wrap rather than changing the visual scale. Scientific data, statistics, annotations, limits, and exports are not recalculated.

## Compatibility and limits

Existing saved Figure Studio projects keep their stored style and canvas settings. No project-schema migration is required; reference restoration applies only when a new axes handoff, FIG source, or subplot selection enters the standard-style editing workflow.

### Remaining limits

Users can still choose another aspect, fixed width, or label orientation after the calibrated default is applied when a publication destination requires it.
