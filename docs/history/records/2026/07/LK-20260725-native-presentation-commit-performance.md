# Native presentation commits avoid repeated UI-tree searches

```labkit-change
id: LK-20260725-native-presentation-commit-performance
date: 2026-07-25
sequence: 167
type: perf
compatibility: compatible
component: `labkit.app` | `1.2.6 -> 1.2.7`
scope: App Framework
scope: Native presentation performance
scope: Batch Crop responsiveness
```

## Context

A profiled Batch Crop session showed that ten ROI interactions spent about
4.35 seconds committing complete view snapshots to native controls, while the
App-owned click and rectangle callbacks used less than 0.10 seconds together.
The dominant path applied enabled state 420 times and searched the complete
figure hierarchy for associated labels on every application.

## Decision and rationale

Preserve the complete Snapshot and transactional rollback contracts while
removing repeated native discovery. Labeled controls now retain their direct
label association when constructed, and native property writes return early
when the requested value is already present. This targets the measured cost
without adding a public API or introducing a more complex partial-state model.

## Changes

- Cache each labeled control's native label handle on its owning layout.
- Replace enabled-state figure searches with the cached association.
- Skip native property assignments when the property already has the requested
  value.
- Add hidden-GUI regression evidence that a field and its label still change
  enabled state together.

## User and data impact

Callbacks that update App state no longer repeatedly scan the full native UI
tree to rediscover labels. This reduces the pause after Batch Crop ROI clicks
and drag releases and benefits every App using labeled controls. Scientific
calculations, saved projects, and exports are unchanged.

## Compatibility and migration

The App SDK public surface, complete Snapshot contract, and all saved-project
schemas are unchanged. No migration is required.

## Validation

- Framework App SDK source contract, including hidden-GUI label availability.
- Batch Crop crop-geometry and hidden-GUI synthetic-project evidence.
- Focused before-and-after callback profiling and documentation consistency.

## Evidence

- [App SDK](../../../../framework/README.md)
- [Batch Image Crop](../../../../apps/image-measurement/batch-crop/README.md)
- [Performance profiling](../../../../development/tools/profiling.md)

## Known limitations and follow-up

Complete Snapshots still describe every visible property, and renderers still
redraw plots selected by each presentation. Further optimization should be
based on a separate measured bottleneck rather than weakening that contract.
