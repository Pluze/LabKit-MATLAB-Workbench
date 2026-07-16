# Startup responsiveness

```labkit-change
schema: 2
id: LK-20260702-startup-responsiveness
date: 2026-07-02
sequence: 31
type: perf
compatibility: compatible
component: `labkit_launcher` | `1.2.2 -> 1.2.3`
component: `labkit.ui` | `3.4.2 -> 3.4.4`
```

## Context

Profiling showed that a substantial part of perceived startup delay occurred
after MATLAB had created the window but before it allowed the operating system
to paint it. Launcher discovery and preview scroll setup also ran before their
results were needed, leaving users with a blank or apparently frozen window.

## Decision and rationale

Paint the launcher and app shell as soon as their basic structure exists, then
defer discovery and preview navigation setup until the UI can remain
responsive. Preserve the same controls and app catalog once initialization
finishes.

## Changes

- `labkit_launcher` `1.2.2 -> 1.2.3`
- `labkit.ui` `3.4.2 -> 3.4.4`

- Painted launcher and app windows earlier.
- Deferred launcher app discovery and lazy preview scroll setup.

## User and data impact

The window appeared and responded earlier, making initialization visible
instead of presenting a long white-screen interval. App discovery and scroll
navigation still completed automatically; the change moved their timing rather
than removing those capabilities.

## Compatibility and migration

App definitions and saved data were unchanged. The launcher and runtime altered
only when discovery and interaction setup occurred during startup.

## Validation

Launcher profiler assertions checked the earlier paint point, while UI axes
layout tests covered deferred scroll navigation in `7d4ef11e`.

## Evidence

- Main commit `7d4ef11e`.

## Known limitations and follow-up

Earlier painting improved perceived responsiveness, but it also made progress
communication important. Later runtime work introduced explicit startup stages
and lifecycle-managed readiness reporting.
