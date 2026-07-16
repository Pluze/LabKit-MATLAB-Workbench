# Output folder prompts

```labkit-change
schema: 1
id: LK-20260630-output-folder-prompts
date: 2026-06-30
type: feat
compatibility: compatible
component: `labkit.ui` | `3.2.5 -> 3.2.6`
component: `labkit_DICPostprocess_app` | `1.2.0 -> 1.2.1`
component: `labkit_DICPreprocess_app` | `1.2.0 -> 1.2.1`
component: `labkit_BatchImageCrop_app` | `1.3.3 -> 1.3.4`
component: `labkit_FocusStack_app` | `1.2.1 -> 1.2.2`
component: `labkit_ImageEnhance_app` | `1.3.1 -> 1.3.2`
component: `labkit_ImageMatch_app` | `1.3.1 -> 1.3.2`
component: `labkit_NerveResponseAnalysis_app` | `1.2.1 -> 1.2.3`
component: `labkit_ResponseReviewStats_app` | `1.2.1 -> 1.2.2`
```

## Context

- Apps gained consistent output-folder behavior without hard-coding dialog
  mechanics into each workflow.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit.ui` `3.2.5 -> 3.2.6`
- DIC apps, Batch Crop, Focus Stack, Image Enhance/Match, Nerve Response, and
  Response Review patch bumped.

- Added `promptOutputFolder`.
- Migrated output-folder prompts with chooser injection and safe defaults.

## User and data impact

- Apps gained consistent output-folder behavior without hard-coding dialog
  mechanics into each workflow.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commit `c5055b98`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.
