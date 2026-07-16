# Startup responsiveness

```labkit-change
schema: 1
id: LK-20260702-startup-responsiveness
date: 2026-07-02
type: perf
compatibility: compatible
component: `labkit_launcher` | `1.2.2 -> 1.2.3`
component: `labkit.ui` | `3.4.2 -> 3.4.4`
```

## Context

- Users see responsive windows sooner instead of waiting on discovery and setup
  work before the GUI appears.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit_launcher` `1.2.2 -> 1.2.3`
- `labkit.ui` `3.4.2 -> 3.4.4`

- Painted launcher and app windows earlier.
- Deferred launcher app discovery and lazy preview scroll setup.

## User and data impact

- Users see responsive windows sooner instead of waiting on discovery and setup
  work before the GUI appears.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commit `7d4ef11e`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.
