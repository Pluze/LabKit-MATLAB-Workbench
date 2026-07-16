# Managed image interactions and diagnostic tracing

```labkit-change
schema: 1
id: LK-20260604-managed-image-interactions
date: 2026-06-04
type: feat
compatibility: compatible
scope: historical project evolution
```

## Context

Image and ECG apps had made the workbench broader, but they also revealed a
class of GUI failures that did not appear in parser or calculation tests. An
anchor editor could re-enter a callback, a scale bar could lose ownership, an
axes popout could stop reflecting the source, and a long operation could leave
controls in an ambiguous state.

## Decision and rationale

Move repeatable interaction mechanics into the UI foundation while leaving
image-specific geometry and workflow state in each app. Give long-running
actions an explicit busy-state guard, make image axes and tools managed
resources, and record callback progress in diagnostic traces that could be
inspected after a failure.

## Changes

- Added axes popout support and corrected image aspect and menu refresh
  behavior.
- Added shared UI control helpers and a reusable ECG peak detector facade.
- Added the Focus Stack app with automatic and manual image selection.
- Improved anchor insertion, curvature controls, and scale-bar ownership.
- Added a busy-state guard to prevent overlapping actions.
- Introduced a managed image-axes runtime, layered UI facades, and app debug
  trace logging.
- Split large app entry points into app-owned private workflow helpers rather
  than widening the public framework API.

## User and data impact

Users gained Focus Stack and more predictable image editing. Popout views,
anchors, scale bars, and long operations provided clearer feedback and were
less likely to leave an app in a broken intermediate state. Debug traces made
it possible to distinguish a slow or failed callback from an unresponsive
window.

The changes affected UI state and presentation; they did not intentionally
alter existing scientific results.

## Compatibility and migration

Apps gradually moved from direct axes and interaction setup to the managed UI
facades. App-private geometry helpers remained private, so the framework did
not promise a public API for every interaction detail.

## Validation

The period added public API option documentation, app-private helper tests,
interaction regression coverage, and focused checks for UI layout ownership.
No single historical validation command covers the complete stage.

## Evidence

- Axes popout and control helpers `1e9022c4` through `2136009f`.
- ECG detector and filtering work `e8450652` through `adb7dfbf`.
- Focus Stack `08518e91`, `cc4cdf92`.
- Busy guard `ac36bd54`.
- Image interaction and scale-bar work `f58b8559` through `5304fa20`.
- Managed axes, traces, and layered UI facades `27bdbdd8`, `e86e4ea3`,
  `da0663f1`, `c4cae633`.

## Known limitations and follow-up

The interaction layer was still evolving and the test infrastructure mixed
custom runners with newer MATLAB tests. The v1.0 stabilization pass addressed
test entry points, package ownership, and remaining compatibility aliases.
