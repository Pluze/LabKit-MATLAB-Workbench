# UI utility snapshots and popout tools

```labkit-change
schema: 1
id: LK-20260704-ui-utility-snapshots-and-popout-tools
date: 2026-07-04
type: feat
compatibility: compatible
component: `labkit.ui` | `4.1.0 -> 4.2.0`
```

## Context

- Users can preserve UI state and move plot outputs out of the GUI with less
  manual work.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit.ui` `4.1.0 -> 4.2.0`

- Added UI state snapshot save/load APIs.
- Added workbench utility controls.
- Improved axes popout export and copy tools.

## User and data impact

- Users can preserve UI state and move plot outputs out of the GUI with less
  manual work.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commit `0155cd12`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.
