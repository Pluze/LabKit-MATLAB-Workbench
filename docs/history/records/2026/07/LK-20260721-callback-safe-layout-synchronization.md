# Callback-safe native layout synchronization

```labkit-change
id: LK-20260721-callback-safe-layout-synchronization
date: 2026-07-21
sequence: 152
type: fix
compatibility: compatible
component: `labkit.app` | `1.2.3 -> 1.2.4`
scope: App Framework
scope: Hidden GUI validation
```

## Context

The App SDK synchronizes native layout before calculating pixel-dependent plot
geometry and while publishing busy, startup, close-prompt, and popout views.
A full MATLAB `drawnow` also executes pending callbacks, which can introduce
unrelated UI or timer work during those internal rendering operations.

## Decision and rationale

Keep the required native graphics synchronization, but defer callbacks while
the framework is calculating or publishing its own view. Long-running
interactive launcher and profiler waits continue to process callbacks so users
can close their windows.

## Changes

- Use callback-deferred graphics updates for equal-scale fitting and
  fixed-aspect preview geometry.
- Use callback-deferred updates while the native App runtime publishes busy,
  startup, failure, close-prompt, and popout-style state.
- Verify equal-scale EIS fitting, preview-canvas layout, and native runtime
  lifecycle behavior with hidden GUI tests.

## User and data impact

Apps retain the same layouts and fitted limits while framework rendering no
longer processes unrelated pending callbacks mid-operation. Projects, source
records, results, and exports are unchanged.

## Compatibility and migration

This compatible patch does not alter the public API or require project/result
migration.

## Validation

- Focused hidden-GUI EIS equal-axis, Figure Studio preview, and native adapter
  lifecycle checks pass locally.
- The complete platform matrix remains the final validation for native GUI
  scheduling behavior.

## Evidence

MATLAB documents that full `drawnow` both updates figures and processes pending
callbacks, while the `nocallbacks` forms defer those callbacks. The framework
uses callback-deferred synchronization only where it must read settled native
geometry or publish internal view state.

## Known limitations and follow-up

Automated hidden GUI checks do not substitute for manual visual and interaction
assessment on supported MATLAB desktop platforms.
