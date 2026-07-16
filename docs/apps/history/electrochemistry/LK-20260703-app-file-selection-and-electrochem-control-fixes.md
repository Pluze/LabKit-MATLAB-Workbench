# App file-selection and electrochem control fixes

```labkit-change
schema: 1
id: LK-20260703-app-file-selection-and-electrochem-control-fixes
date: 2026-07-03
type: fix
compatibility: compatible
component: `labkit_CIC_app` | `1.3.1 -> 1.3.2`
component: `labkit_CIC_app` | `1.3.2 -> 1.3.3`
component: `labkit_CSC_app` | `1.3.1 -> 1.3.2`
component: `labkit_CSC_app` | `1.3.2 -> 1.3.3`
component: `labkit_VTResistance_app` | `1.3.1 -> 1.3.2`
component: `labkit_VTResistance_app` | `1.3.2 -> 1.3.3`
component: `labkit_BatchImageCrop_app` | `1.6.2 -> 1.6.3`
component: `labkit_FLIRThermal_app` | `1.2.1 -> 1.2.2`
component: `labkit_FocusStack_app` | `1.4.1 -> 1.4.2`
component: `labkit_ImageEnhance_app` | `1.5.1 -> 1.5.2`
component: `labkit_ImageMatch_app` | `1.5.1 -> 1.5.2`
scope: historical project evolution
```

## Context

- Multi-file workflows stopped losing appended selections, and electrochem app
  controls became less misleading.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- CIC, CSC, VT Resistance, Batch Crop, FLIR Thermal, Focus Stack, Image Enhance,
  and Image Match patch bumped for appended file selections.
- CIC, CSC, and VT Resistance patch bumped again for manual plot-control
  removal.

- Preserved appended file selections.
- Removed electrochem manual plot controls that no longer matched the workflow.

## User and data impact

- Multi-file workflows stopped losing appended selections, and electrochem app
  controls became less misleading.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commits `6348185e` and `674d5d4b`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.
