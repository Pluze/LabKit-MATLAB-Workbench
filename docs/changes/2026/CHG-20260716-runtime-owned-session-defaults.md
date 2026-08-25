# Runtime-owned session defaults across App families

```labkit-change
id: CHG-20260716-runtime-owned-session-defaults
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit.ui | 7.4.3 -> 7.4.4
component: labkit_DICPostprocess_app | 1.4.3 -> 1.4.4
component: labkit_DICPreprocess_app | 1.5.4 -> 1.5.5
component: labkit_GaitAnalysis_app | 2.0.4 -> 2.0.5
component: labkit_BatchImageCrop_app | 1.7.3 -> 1.7.4
component: labkit_CurvatureMeasurement_app | 1.4.3 -> 1.4.4
component: labkit_FLIRThermal_app | 1.4.3 -> 1.4.4
component: labkit_FocusStack_app | 1.5.2 -> 1.5.3
component: labkit_ImageEnhance_app | 1.6.3 -> 1.6.4
component: labkit_ImageMatch_app | 1.6.3 -> 1.6.4
component: labkit_VideoMarker_app | 1.5.2 -> 1.5.3
component: labkit_FigureStudio_app | 0.2.5 -> 0.2.6
component: labkit_NerveResponseAnalysis_app | 1.4.3 -> 1.4.4
component: labkit_ResponseReviewStats_app | 1.4.3 -> 1.4.4
component: labkit_RHSPreview_app | 1.4.3 -> 1.4.4
component: labkit_ECGPrint_app | 1.4.3 -> 1.4.4
```

## Why

Runtime V2 already adds the canonical `selection`, `workflow`, `view`, and `cache` session buckets after an App factory returns. Its workflow service also creates `logLines` on the first log operation. Fifteen App factories still repeated empty buckets or initialized that framework-owned log, making their state declarations longer and obscuring which transient fields were genuinely App-specific.

### Accepted choice

Treat canonical session shape and workflow-log initialization as Runtime control-plane responsibilities. An App session factory now returns only the selection, workflow, view, and cache fields that express its own workflow. This preserves explicit App state while removing framework boilerplate.

## What changed

- Removed empty canonical session buckets from affected App factories.
- Removed every App-owned `logLines` initializer; the injected workflow service remains the only writer and lazy initializer.
- Removed Image Enhance's direct log-panel presenter binding; Runtime commits the workflow log to every declared log panel.
- Added `services.project.newState()` and moved full-project reset actions onto that Runtime-owned creation and normalization path.
- Added a fleet-wide structure guard that rejects empty canonical buckets and direct workflow-log initialization in `createSession.m`.
- Updated every affected App manual and patch version.

## Impact

There is no workflow, scientific, persistence, or saved-data change. Runtime normalization produces the same complete in-memory session before validation, presentation, or the first callback. Existing project files remain compatible.

## Compatibility and limits

The change is source-compatible within Runtime V2 and requires no project payload migration. Direct tests of an App's raw session factory should inspect only App-owned fields; tests that need canonical empty buckets should create state through Runtime.

### Remaining limits

Most factories still perform necessary source decoding or reconstruction. They should not be removed merely to reduce file count. Further simplification requires evidence that a repeated reconstruction pattern is domain-neutral and belongs behind a stable Runtime service.
