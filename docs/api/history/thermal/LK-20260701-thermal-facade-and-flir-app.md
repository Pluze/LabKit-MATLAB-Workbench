# Thermal facade and FLIR app

```labkit-change
schema: 1
id: LK-20260701-thermal-facade-and-flir-app
date: 2026-07-01
type: feat
compatibility: compatible
introduced: `labkit.thermal` | `1.0.0`
component: `labkit.ui` | `3.2.9 -> 3.2.10`
introduced: `labkit_FLIRThermal_app` | `1.0.0`
```

## Context

- Thermal image parsing and rendering became a reusable LabKit contract instead
  of app-local logic.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit.thermal` `1.0.0`
- `labkit.ui` `3.2.9 -> 3.2.10`
- `labkit_FLIRThermal_app` `1.0.0`

- Added the thermal facade.
- Added the FLIR Thermal Postprocess app.

## User and data impact

- Thermal image parsing and rendering became a reusable LabKit contract instead
  of app-local logic.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commit `977c9457`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.
