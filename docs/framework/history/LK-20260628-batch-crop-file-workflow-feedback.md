# Batch Crop file workflow feedback

```labkit-change
schema: 1
id: LK-20260628-batch-crop-file-workflow-feedback
date: 2026-06-28
type: feat
compatibility: compatible
component: `labkit.ui` | `3.0.1 -> 3.1.0`
component: `labkit_BatchImageCrop_app` | `1.2.0 -> 1.3.0`
```

## Context

- Users can see which selected file a preview or result belongs to.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit.ui` `3.0.1 -> 3.1.0`
- Batch Crop `1.2.0 -> 1.3.0`

- Added selected-file title context.
- Improved Batch Crop file workflow feedback.

## User and data impact

- Users can see which selected file a preview or result belongs to.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commit `61e8edd3`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.
