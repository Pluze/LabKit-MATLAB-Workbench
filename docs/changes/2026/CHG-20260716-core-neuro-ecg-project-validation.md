# Core, neurophysiology, and ECG project validation ownership

```labkit-change
id: CHG-20260716-core-neuro-ecg-project-validation
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_FigureStudio_app | 0.2.6 -> 0.2.7
component: labkit_NerveResponseAnalysis_app | 1.4.4 -> 1.4.5
component: labkit_ResponseReviewStats_app | 1.4.4 -> 1.4.5
component: labkit_RHSPreview_app | 1.4.4 -> 1.4.5
component: labkit_ECGPrint_app | 1.4.4 -> 1.4.5
```

## Why

The remaining public project validators still surrounded their own style, recording-role, metric-window, protocol, ECG, and result rules with repeated canonical bucket and source-record format checks.

### Accepted choice

Complete the public-App validation ownership split. Runtime owns canonical bucket structs and source-record internals. Each App continues to require its source collection and to enforce its own fields, role/cardinality rules, numeric limits, tables, annotations, and results.

## What changed

- Removed 66 net lines of repeated framework structure checks from Figure Studio, the three neurophysiology Apps, and ECG Print.
- Preserved Nerve Response Analysis's fixed source ID-role pairs and RHS Preview's recording/protocol/filter roles and cardinalities.
- Added focused project-spec contracts for default acceptance, missing-source rejection, and the retained neurophysiology role rules.

## Impact

Valid projects, migrations, signal calculations, previews, and exports are unchanged. Framework-shape failures now have one Runtime owner; domain-schema failures remain attributable to the App that defines them.

## Compatibility and limits

No payload format changed and no migration is required. All supported saved projects continue through their existing centralized `projectSpec.m` migration entry.

### Remaining limits

Project validator boilerplate is now removed across the public App fleet. Further App simplification must target independently evidenced action, presentation, or cache patterns rather than weakening domain validation.
