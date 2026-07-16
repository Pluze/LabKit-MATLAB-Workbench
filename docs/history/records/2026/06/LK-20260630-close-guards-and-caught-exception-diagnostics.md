# Close guards and caught-exception diagnostics

```labkit-change
schema: 1
id: LK-20260630-close-guards-and-caught-exception-diagnostics
date: 2026-06-30
type: feat
compatibility: compatible
component: `labkit.ui` | `3.2.6 -> 3.2.7`
component: `labkit_DICPostprocess_app` | `1.2.1 -> 1.2.2`
component: `labkit_BatchImageCrop_app` | `1.3.4 -> 1.3.5`
component: `labkit_BatchImageCrop_app` | `1.3.5 -> 1.3.6`
component: `labkit_CurvatureMeasurement_app` | `1.2.1 -> 1.2.2`
component: `labkit_FocusStack_app` | `1.2.2 -> 1.2.3`
component: `labkit_FocusStack_app` | `1.2.3 -> 1.2.4`
component: `labkit_ImageEnhance_app` | `1.3.2 -> 1.3.3`
component: `labkit_ImageMatch_app` | `1.3.2 -> 1.3.3`
component: `labkit_ImageMatch_app` | `1.3.3 -> 1.3.4`
component: `labkit_NerveResponseAnalysis_app` | `1.2.3 -> 1.2.4`
component: `labkit_ResponseReviewStats_app` | `1.2.2 -> 1.2.3`
component: `labkit_RHSPreview_app` | `1.2.1 -> 1.2.2`
component: `labkit_ECGPrint_app` | `1.2.0 -> 1.2.1`
```

## Context

- Crashes and interrupted workflows leave better evidence for maintainers, and
  users get safer close behavior around incomplete image workflows.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit.ui` `3.2.6 -> 3.2.7`
- DIC, Batch Crop, Curvature, Focus Stack, Image Match, neurophysiology apps,
  and ECG Print patch bumped for diagnostics or close-guard work.

- Reported caught app-runner exceptions through framework debug diagnostics.
- Promoted file-entry index helpers.
- Connected dirty/incomplete workflow state to close guards.

## User and data impact

- Crashes and interrupted workflows leave better evidence for maintainers, and
  users get safer close behavior around incomplete image workflows.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commits `c0028a81` and `a81853ef`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.
