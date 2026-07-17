# Electrochem Apps stop reading portable references

```labkit-change
schema: 2
id: LK-20260716-electrochem-source-boundary
date: 2026-07-16
sequence: 92
type: refactor
compatibility: compatible
component: `labkit_ChronoOverlay_app` | `1.4.2 -> 1.4.3`
component: `labkit_CIC_app` | `1.4.2 -> 1.4.3`
component: `labkit_CSC_app` | `1.4.2 -> 1.4.3`
component: `labkit_EIS_app` | `1.4.2 -> 1.4.3`
component: `labkit_VTResistance_app` | `1.4.2 -> 1.4.3`
scope: Electrochemistry
scope: Runtime source boundary
```

## Context

The Electrochem Apps already delegated portable source creation, save-time
rebasing, and load-time relinking to Runtime V2. Their session factories,
source loaders, actions, and presenters nevertheless read the runtime's nested
path field directly. CIC and VT Resistance also carried duplicate local path
extraction functions.

## Decision and rationale

Use the public Runtime source-path accessor at every App boundary. This keeps
lazy-loading and batch-selection policies App-owned while removing knowledge
of the portable-reference storage schema.

## Changes

- Replaced direct nested-reference reads in all five Electrochem Apps.
- Removed duplicate CIC and VT Resistance path extraction functions.
- Preserved source order and lazy first-item decoding.
- Kept DTA parsing, formulas, thresholds, plots, exports, and error wording
  unchanged.

## User and developer impact

File selection, project reopen/relink, calculation, preview, and export behavior
are unchanged. App code now expresses only its workflow use of paths; Runtime
V2 owns how those paths are stored and resolved.

## Compatibility and migration

No project schema or saved source record changed. Existing projects require no
migration and remain compatible with the same UI 7 contract range.

## Validation

The Electrochem unit and hidden-GUI suites cover project reconstruction, DTA
loading, selection, plotting, computation, export, and saved-state workflows.
Package and version guardrails verify the shared API and component metadata.

## Evidence

- [Electrochemistry Apps](../../../../apps/electrochemistry/README.md)
- [Runtime and Lifecycle](../../../../framework/runtime.md)

## Known limitations and follow-up

Other App families still contain direct reads and will migrate in their own
behavior-tested commits before a repository-wide no-leak guard is enabled.
