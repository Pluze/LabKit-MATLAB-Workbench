# FLIR display tuning

```labkit-change
schema: 1
id: LK-20260703-flir-display-tuning
date: 2026-07-03
type: feat
compatibility: compatible
component: `labkit_CSC_app` | `1.3.6 -> 1.3.7`
component: `labkit_FLIRThermal_app` | `1.2.4 -> 1.2.5`
component: `labkit_FLIRThermal_app` | `1.2.5 -> 1.2.6`
component: `labkit_FLIRThermal_app` | `1.2.6 -> 1.2.7`
```

## Context

- CSC exports became clearer for downstream analysis, and FLIR display tuning
  no longer requires code edits.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit_FLIRThermal_app` `1.2.4 -> 1.2.7`
- `labkit_CSC_app` `1.3.6 -> 1.3.7`

- Refined CSC CV export.
- Added FLIR gamma color mapping and made gamma adjustable.

## User and data impact

- CSC exports became clearer for downstream analysis, and FLIR display tuning
  no longer requires code edits.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commits `ee5b8f79`, `65dbf5ae`, and `f076561e`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.
