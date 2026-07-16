# Launcher manager and stale callback fix

```labkit-change
schema: 1
id: LK-20260626-launcher-manager-and-stale-callback-fix
date: 2026-06-26
type: fix
compatibility: compatible
component: `labkit_launcher` | `1.0.0 -> 1.1.0`
component: `labkit_launcher` | `1.1.0 -> 1.1.1`
component: `labkit.ui` | `3.0.0 -> 3.0.1`
```

## Context

- Users gained a deliberate path to choose recent releases, tags, or main
  commits, and image interactions stopped carrying stale callback state.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit_launcher` `1.0.0 -> 1.1.1`
- `labkit.ui` `3.0.0 -> 3.0.1`

- Added the launcher version manager and managed-manifest requirement.
- Released stale image drag callbacks.

## User and data impact

- Users gained a deliberate path to choose recent releases, tags, or main
  commits, and image interactions stopped carrying stale callback state.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commits `fe8654c9`, `ef89cf77`, and `3d23b7f1`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.
