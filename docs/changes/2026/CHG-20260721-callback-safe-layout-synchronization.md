# Callback-safe native layout synchronization

```labkit-change
id: CHG-20260721-callback-safe-layout-synchronization
date: 2026-07-21
type: fix
compatibility: compatible
component: labkit.app | 1.2.3 -> 1.2.4
```

## Why

The App SDK synchronizes native layout before calculating pixel-dependent plot geometry and while publishing busy, startup, close-prompt, and popout views. A full MATLAB `drawnow` also executes pending callbacks, which can introduce unrelated UI or timer work during those internal rendering operations.

### Accepted choice

Keep the required native graphics synchronization, but defer callbacks while the framework is calculating or publishing its own view. Long-running interactive launcher and profiler waits continue to process callbacks so users can close their windows.

## What changed

- Use callback-deferred graphics updates for equal-scale fitting and fixed-aspect preview geometry.
- Use callback-deferred updates while the native App runtime publishes busy, startup, failure, close-prompt, and popout-style state.
- Verify equal-scale EIS fitting, preview-canvas layout, and native runtime lifecycle behavior with hidden GUI tests.

## Impact

Apps retain the same layouts and fitted limits while framework rendering no longer processes unrelated pending callbacks mid-operation. Projects, source records, results, and exports are unchanged.

## Compatibility and limits

This compatible patch does not alter the public API or require project/result migration.

### Remaining limits

Automated hidden GUI checks do not substitute for manual visual and interaction assessment on supported MATLAB desktop platforms.
