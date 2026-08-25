# Electrochem Apps stop reading portable references

```labkit-change
id: CHG-20260716-electrochem-source-boundary
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_ChronoOverlay_app | 1.4.2 -> 1.4.3
component: labkit_CIC_app | 1.4.2 -> 1.4.3
component: labkit_CSC_app | 1.4.2 -> 1.4.3
component: labkit_EIS_app | 1.4.2 -> 1.4.3
component: labkit_VTResistance_app | 1.4.2 -> 1.4.3
```

## Why

The Electrochem Apps already delegated portable source creation, save-time rebasing, and load-time relinking to Runtime V2. Their session factories, source loaders, actions, and presenters nevertheless read the runtime's nested path field directly. CIC and VT Resistance also carried duplicate local path extraction functions.

### Accepted choice

Use the public Runtime source-path accessor at every App boundary. This keeps lazy-loading and batch-selection policies App-owned while removing knowledge of the portable-reference storage schema.

## What changed

- Replaced direct nested-reference reads in all five Electrochem Apps.
- Removed duplicate CIC and VT Resistance path extraction functions.
- Preserved source order and lazy first-item decoding.
- Kept DTA parsing, formulas, thresholds, plots, exports, and error wording unchanged.

## Impact

File selection, project reopen/relink, calculation, preview, and export behavior are unchanged. App code now expresses only its workflow use of paths; Runtime V2 owns how those paths are stored and resolved.

## Compatibility and limits

No project schema or saved source record changed. Existing projects require no migration and remain compatible with the same UI 7 contract range.

### Remaining limits

Other App families still contain direct reads and will migrate in their own behavior-tested commits before a repository-wide no-leak guard is enabled.
