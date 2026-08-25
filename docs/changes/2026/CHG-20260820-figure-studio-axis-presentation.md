# Figure Studio preserves axis notation and geometry

```labkit-change
id: CHG-20260820-figure-studio-axis-presentation
date: 2026-08-20
type: fix
compatibility: compatible
component: labkit_FigureStudio_app | 0.7.4 -> 0.7.5
```

## Why

Figure Studio inspected imported X-axis label strings to decide whether they needed balanced categorical wrapping. MATLAB's automatic logarithmic labels use TeX-like strings such as `10^{-1}`, so the categorical check treated them as long nonnumeric labels and redrew them with a plain-text interpreter. Separately, the interactive preview applied the configured plot-box aspect while a native axes export could retain the source axes' manual aspect metadata, making the exported data frame differ from the preview. Even after the frame was aligned, MATLAB could recalculate automatic logarithmic ticks for the full-size export font and reduce seven visible decade ticks to only one or two.

### Accepted choice

Keep logarithmic ruler labels under MATLAB's native exponent formatter, and make the configured Figure Studio plot frame and displayed ticks authoritative for both preview and export. Automatic wrapping is a categorical-axis presentation feature, while source aspect metadata and export-time tick-density recalculation must not override the presentation the user approved.

## What changed

The standard-layout classifier now excludes logarithmic X axes from categorical tick-label wrapping. Figure styling applies the configured plot-box aspect to ordinary export axes as well as preview axes. Native exports also copy the displayed X, Y, and Z tick positions and labels from the portable axes snapshot before full-size styling. Focused regressions cover automatic exponent labels and a native source whose stored aspect and export-time tick density conflict with the configured Figure Studio presentation.

## Impact

Logarithmic plots retain readable superscript exponent ticks instead of displaying TeX braces and crowded literal strings. Native FIG and axes-handoff exports use the same data-frame proportion and visible tick set shown in the interactive preview. Plot data, limits, scales, calculations, and export formats remain unchanged.

## Compatibility and limits

The App entrypoint, in-memory style settings, source FIG files, and export formats remain compatible. Figure Studio does not own a task-continuation archive, so no saved-data migration is required.

### Remaining limits

Automatic two-line wrapping remains limited to ordinary linear X axes with word-delimited categorical labels. Manual review remains appropriate for renderer-specific font metrics and native graphics that cannot be represented by the portable export path.
