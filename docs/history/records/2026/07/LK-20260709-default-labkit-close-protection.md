# Default LabKit close protection

```labkit-change
schema: 1
id: LK-20260709-default-labkit-close-protection
date: 2026-07-09
type: fix
compatibility: compatible
component: `labkit.ui` | `5.0.2 -> 5.0.3`
component: `labkit_FocusStack_app` | `1.4.6 -> 1.4.7`
component: `labkit_ImageEnhance_app` | `1.5.5 -> 1.5.6`
component: `labkit_ImageMatch_app` | `1.5.5 -> 1.5.6`
```

## Context

- Public and private apps get a baseline close-safety prompt from the framework,
  without app-owned dirty-state close logic.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit.ui` `5.0.2 -> 5.0.3`
- `labkit_FocusStack_app` `1.4.6 -> 1.4.7`
- `labkit_ImageEnhance_app` `1.5.5 -> 1.5.6`
- `labkit_ImageMatch_app` `1.5.5 -> 1.5.6`

- LabKit runtime figures now show an in-window confirmation prompt before any
  framework-owned app window closes, even when the app has not marked itself
  dirty.
- Removed the app-facing `labkit.ui.runtime.setCloseGuard` API and migrated
  existing app close-guard dirty checks to the framework default behavior.
- Repeating or holding the app close shortcut while the in-window prompt is
  active confirms the close.

## User and data impact

- Public and private apps get a baseline close-safety prompt from the framework,
  without app-owned dirty-state close logic.

## Compatibility and migration

- Closing LabKit apps now requires one confirmation step by default. App code
  that calls `labkit.ui.runtime.setCloseGuard` must remove that call; close
  confirmation is framework-owned.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Mainline commit `0c9f472`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.
