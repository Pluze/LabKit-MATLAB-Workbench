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
scope: Figure Studio displayed tick preservation
scope: Automatic categorical label wrapping
```

## Context

Figure Studio inspected imported X-axis label strings to decide whether they needed balanced categorical wrapping. MATLAB's automatic logarithmic labels use TeX-like strings such as `10^{-1}`, so the categorical check treated them as long nonnumeric labels and redrew them with a plain-text interpreter. Separately, the interactive preview applied the configured plot-box aspect while a native axes export could retain the source axes' manual aspect metadata, making the exported data frame differ from the preview. Even after the frame was aligned, MATLAB could recalculate automatic logarithmic ticks for the full-size export font and reduce seven visible decade ticks to only one or two.

## Decision and rationale

Keep logarithmic ruler labels under MATLAB's native exponent formatter, and make the configured Figure Studio plot frame and displayed ticks authoritative for both preview and export. Automatic wrapping is a categorical-axis presentation feature, while source aspect metadata and export-time tick-density recalculation must not override the presentation the user approved.

## Changes

The standard-layout classifier now excludes logarithmic X axes from categorical tick-label wrapping. Figure styling applies the configured plot-box aspect to ordinary export axes as well as preview axes. Native exports also copy the displayed X, Y, and Z tick positions and labels from the portable axes snapshot before full-size styling. Focused regressions cover automatic exponent labels and a native source whose stored aspect and export-time tick density conflict with the configured Figure Studio presentation.

## User and data impact

Logarithmic plots retain readable superscript exponent ticks instead of displaying TeX braces and crowded literal strings. Native FIG and axes-handoff exports use the same data-frame proportion and visible tick set shown in the interactive preview. Plot data, limits, scales, calculations, and export formats remain unchanged.

## Compatibility and migration

The App entrypoint, in-memory style settings, source FIG files, and export formats remain compatible. Figure Studio does not own a task-continuation archive, so no saved-data migration is required.

## Validation

Focused Figure Studio source-capability evidence verifies that logarithmic exponent ticks bypass categorical wrapping while long linear category labels still wrap. Focused result evidence compares preview and native-export plot-box aspects, tick positions, and tick labels while retaining the existing outer-whitespace, composite-graphics, legend, and logarithmic-canvas contracts.

## Evidence

The tick regression uses the MATLAB logarithmic sequence from `10^{-1}` through `10^{5}`. The geometry regression begins with a native plot box that conflicts with the configured Figure Studio frame, then verifies that preview and export use the same ratio and all seven displayed decade ticks. A synthetic 1:1 PNG smoke export retains that complete tick sequence at full export typography.

## Known limitations and follow-up

Automatic two-line wrapping remains limited to ordinary linear X axes with word-delimited categorical labels. Manual review remains appropriate for renderer-specific font metrics and native graphics that cannot be represented by the portable export path.
