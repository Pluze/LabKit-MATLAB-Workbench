# Preview-area per-axis wheel zoom

```labkit-change
schema: 1
id: LK-20260709-preview-area-per-axis-wheel-zoom
date: 2026-07-09
type: feat
compatibility: compatible
component: `labkit.ui` | `5.0.3 -> 5.0.4`
```

## Context

- App-owned side panels such as color scales and histograms can remain compact
  and stable without disabling useful wheel interaction.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit.ui` `5.0.3 -> 5.0.4`

- Added a `scrollZoomAxes` preview-area layout option so apps can declare
  whether each preview axis should mouse-wheel zoom in `xy`, `x`, or `y`.
- Preview-area side axes can now remain horizontally stable while still
  allowing app-selected vertical wheel zoom.

## User and data impact

- App-owned side panels such as color scales and histograms can remain compact
  and stable without disabling useful wheel interaction.

## Compatibility and migration

- Existing preview areas keep default `xy` wheel zoom unless they opt into
  another per-axis setting.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Mainline commit `3c143eb`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.
