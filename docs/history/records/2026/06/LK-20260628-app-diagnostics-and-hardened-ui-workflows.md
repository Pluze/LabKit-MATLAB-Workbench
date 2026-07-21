# App diagnostics and hardened UI workflows

```labkit-change
id: LK-20260628-app-diagnostics-and-hardened-ui-workflows
date: 2026-06-28
sequence: 15
type: feat
compatibility: compatible
component: `labkit_launcher` | `1.1.1 -> 1.1.2`
component: `labkit.ui` | `3.1.0 -> 3.1.2`
component: `labkit.ui` | `3.1.2 -> 3.1.3`
component: `labkit_BatchImageCrop_app` | `1.3.0 -> 1.3.1`
component: `labkit_BatchImageCrop_app` | `1.3.1 -> 1.3.2`
component: `labkit_FocusStack_app` | `1.2.0 -> 1.2.1`
component: `labkit_ImageEnhance_app` | `1.2.0 -> 1.2.1`
component: `labkit_ImageEnhance_app` | `1.2.1 -> 1.2.2`
component: `labkit_ImageMatch_app` | `1.2.0 -> 1.2.1`
component: `labkit_NerveResponseAnalysis_app` | `1.2.0 -> 1.2.1`
component: `labkit_ResponseReviewStats_app` | `1.2.0 -> 1.2.1`
component: `labkit_RHSPreview_app` | `1.2.0 -> 1.2.1`
scope: App diagnostics and hardened UI workflows
```

## Context

When an app stalled or caught an exception, screenshots and the visible Log tab
often omitted the active callback and stack information needed to reproduce the
problem.

## Decision and rationale

Capture active operations, uncaught crashes, caught errors, and suspected stalls
in structured local reports while hardening the UI paths that generate those
events. Keep reports outside project data so diagnostics cannot alter results.

## Changes

- `labkit.ui` `3.1.0 -> 3.1.3`
- Batch Crop, Focus Stack, Image Enhance/Match, neurophysiology apps, and the
  launcher patch bumped where runtime behavior changed.

- Hardened LabKit UI workflows.
- Added crash reports, active-operation reports, caught-error reports, and stall
  diagnostics.

## User and data impact

Debug runs produced evidence that could identify the failing operation and app
state without copying laboratory inputs into the repository. Normal projects
and exports kept their previous formats.

## Compatibility and migration

The diagnostic files were additive and existing app inputs and saved results
remained readable. Debug runs began producing more detailed local artifacts.

## Validation

Commits `e966457b` and `f5bc6f98` updated launcher, framework, and affected app
workflow tests for diagnostic creation and hardened callbacks.

## Evidence

- Main commits `e966457b` and `f5bc6f98`.

## Known limitations and follow-up

Diagnostics report the state and stack available at capture time; they do not
replace a reproducible input or a focused regression test.
