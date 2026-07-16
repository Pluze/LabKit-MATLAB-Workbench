# Protected image enhancement workflows

```labkit-change
schema: 1
id: LK-20260629-protected-image-enhancement-workflows
date: 2026-06-29
type: feat
compatibility: compatible
component: `labkit_ImageEnhance_app` | `1.2.2 -> 1.3.0`
component: `labkit_ImageMatch_app` | `1.2.1 -> 1.3.0`
scope: historical project evolution
```

## Context

- The image enhancement apps gained a more deliberate workflow boundary before
  later image-facade adoption.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- Image Enhance `1.2.2 -> 1.3.0`
- Image Match `1.2.1 -> 1.3.0`

- Added protected image enhancement workflows.

## User and data impact

- The image enhancement apps gained a more deliberate workflow boundary before
  later image-facade adoption.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commit `1768dd57`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.
