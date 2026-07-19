# Core, neurophysiology, and ECG project validation ownership

```labkit-change
schema: 2
id: LK-20260716-core-neuro-ecg-project-validation
date: 2026-07-16
sequence: 121
type: refactor
compatibility: compatible
component: `labkit_FigureStudio_app` | `0.2.6 -> 0.2.7`
component: `labkit_NerveResponseAnalysis_app` | `1.4.4 -> 1.4.5`
component: `labkit_ResponseReviewStats_app` | `1.4.4 -> 1.4.5`
component: `labkit_RHSPreview_app` | `1.4.4 -> 1.4.5`
component: `labkit_ECGPrint_app` | `1.4.4 -> 1.4.5`
scope: remaining public App project schemas
scope: App maintenance cost
```

## Context

The remaining public project validators still surrounded their own style,
recording-role, metric-window, protocol, ECG, and result rules with repeated
canonical bucket and source-record format checks.

## Decision and rationale

Complete the public-App validation ownership split. Runtime owns canonical
bucket structs and source-record internals. Each App continues to require its
source collection and to enforce its own fields, role/cardinality rules,
numeric limits, tables, annotations, and results.

## Changes

- Removed 66 net lines of repeated framework structure checks from Figure
  Studio, the three neurophysiology Apps, and ECG Print.
- Preserved Nerve Response Analysis's fixed source ID-role pairs and RHS
  Preview's recording/protocol/filter roles and cardinalities.
- Added focused project-spec contracts for default acceptance, missing-source
  rejection, and the retained neurophysiology role rules.

## User and data impact

Valid projects, migrations, signal calculations, previews, and exports are
unchanged. Framework-shape failures now have one Runtime owner; domain-schema
failures remain attributable to the App that defines them.

## Compatibility and migration

No payload format changed and no migration is required. All supported saved
projects continue through their existing centralized `projectSpec.m`
migration entry.

## Validation

Focused project-spec tests cover all five defaults and missing-source cases,
plus invalid Nerve and RHS source roles. Representative unit and hidden-GUI
workflows cover project reconstruction, preview, analysis, and export behavior.

## Evidence

- [Figure Studio](../../../../apps/labkit-core/figure-studio/README.md)
- [Neurophysiology Apps](../../../../apps/neurophysiology/README.md)
- [ECG Print](../../../../apps/wearable/ecg-print/README.md)
- [Runtime and Lifecycle](../../../../framework/guides/runtime.md)

## Known limitations and follow-up

Project validator boilerplate is now removed across the public App fleet.
Further App simplification must target independently evidenced action,
presentation, or cache patterns rather than weakening domain validation.
