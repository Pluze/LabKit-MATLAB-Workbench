# App diagnostics and hardened UI workflows

```labkit-change
schema: 1
id: LK-20260628-app-diagnostics-and-hardened-ui-workflows
date: 2026-06-28
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
```

## Context

- Maintainers get structured failure evidence instead of relying on screenshots
  or vague crash reports.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit.ui` `3.1.0 -> 3.1.3`
- Batch Crop, Focus Stack, Image Enhance/Match, neurophysiology apps, and the
  launcher patch bumped where runtime behavior changed.

- Hardened LabKit UI workflows.
- Added crash reports, active-operation reports, caught-error reports, and stall
  diagnostics.

## User and data impact

- Maintainers get structured failure evidence instead of relying on screenshots
  or vague crash reports.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commits `e966457b` and `f5bc6f98`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.
