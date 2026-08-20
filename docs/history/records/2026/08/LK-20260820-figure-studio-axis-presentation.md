# Figure Studio preserves axis notation and geometry

```labkit-change
id: LK-20260820-figure-studio-axis-presentation
date: 2026-08-20
sequence: 187
type: fix
compatibility: compatible
component: `labkit_FigureStudio_app` | `0.7.4 -> 0.7.5`
scope: Figure Studio logarithmic axis ticks
scope: Figure Studio preview and export plot-box parity
scope: Automatic categorical label wrapping
```

## Context

Figure Studio inspected imported X-axis label strings to decide whether they needed balanced categorical wrapping. MATLAB's automatic logarithmic labels use TeX-like strings such as `10^{-1}`, so the categorical check treated them as long nonnumeric labels and redrew them with a plain-text interpreter. Separately, the interactive preview applied the configured plot-box aspect while a native axes export could retain the source axes' manual aspect metadata, making the exported data frame differ from the preview.

## Decision and rationale

Keep logarithmic ruler labels under MATLAB's native exponent formatter, and make the configured Figure Studio plot frame authoritative for both preview and export. Automatic wrapping is a categorical-axis presentation feature, while source aspect metadata must not override the user's selected output geometry.

## Changes

The standard-layout classifier now excludes logarithmic X axes from categorical tick-label wrapping. Figure styling now applies the configured plot-box aspect to ordinary export axes as well as preview axes. Focused regressions cover automatic exponent labels and a native source whose stored aspect conflicts with the configured Figure Studio frame.

## User and data impact

Logarithmic plots retain readable superscript exponent ticks instead of displaying TeX braces and crowded literal strings. Native FIG and axes-handoff exports now use the same data-frame proportion shown in the interactive preview. Plot data, limits, scales, calculations, and export formats remain unchanged.

## Compatibility and migration

The App entrypoint, project schema, saved projects, source FIG files, and export formats remain compatible. Existing style settings keep their meaning, and no data migration is required.

## Validation

Focused Figure Studio source-capability evidence verifies that logarithmic exponent ticks bypass categorical wrapping while long linear category labels still wrap. Focused result evidence compares preview and native-export plot-box aspects and retains the existing outer-whitespace, composite-graphics, legend, and logarithmic-canvas contracts.

## Evidence

The tick regression uses the MATLAB logarithmic sequence from `10^{-1}` through `10^{5}`. The geometry regression begins with a square native plot box, applies the 900-by-725 Figure Studio frame, and verifies that preview and export both use the configured ratio.

## Known limitations and follow-up

Automatic two-line wrapping remains limited to ordinary linear X axes with word-delimited categorical labels. Manual review remains appropriate for renderer-specific font metrics and native graphics that cannot be represented by the portable export path.
