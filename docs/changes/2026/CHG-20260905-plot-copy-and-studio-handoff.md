# Direct plot copying and measurable Studio handoffs

```labkit-change
id: CHG-20260905-plot-copy-and-studio-handoff
date: 2026-09-05
type: feat
compatibility: compatible
component: labkit.app | 3.3.0 -> 3.4.0
component: labkit_FigureStudio_app | 0.8.1 -> 0.9.0
```

## Why

Copying a multi-panel App through MATLAB's graphics-only figure export fails when plots occupy nested UI containers. Treating an entire UI window as graphics also omits the distinction between the plot page and the complete interface. The accepted design provides two direct clipboard actions with explicit scope, while less frequent per-plot and cross-page operations stay on the plot context menu. Raster composition preserves the displayed plot meaning without relying on native cloning of UI axes or dual-Y axes.

Studio transfers also spent substantial work repeatedly resolving immutable layout relationships and extracting the same source snapshot. Indexing the compiled layout and reusing the already captured snapshot removes this redundant work. Timed boundaries make remaining discovery, construction, and presentation costs observable without introducing a background task framework.

## What changed

- Tools offers Copy Main Plots and Copy Current Interface alongside Diagnostics. The first preserves the active workspace's multi-panel arrangement; the second includes controls through an App-window capture.
- Plot context menus offer direct single-plot copy, direct Studio handoff, and explicit cross-page selection for a grid image.
- Studio can copy the complete styled document with all panels after publication preflight.
- Source and destination journals record transfer and startup stages. An explicit profiling action uses the existing profiling report workflow, and transfers prevent duplicate clicks while active.
- The native adapter indexes compiled parent and child relationships once. Studio uses one portable import snapshot and reserves native cloning for copyable ordinary axes.

## Impact

The shared runtime supplies these conveniences to every SDK App without requiring scientific or workflow code changes in each App. Users can copy ECG-style multi-panel pages, preserve plot-only views, or capture an entire interface without navigating export submenus. Studio retains its own publication layout and editing responsibilities.

## Compatibility and limits

Public App entry points, scientific calculations, saved formats, and result exports are unchanged. The former Tools plot/save submenus are replaced by direct copying and plot context actions; use App-owned file exports or Studio for saved figure output. Clipboard images are raster representations, not numeric data or editable graphics. Cross-page selection can include an uncomputed hidden plot. Operating-system paste behavior and native selection dialogs require interactive validation. UI construction remains synchronous; timing and profiling expose that cost rather than promising background execution.
