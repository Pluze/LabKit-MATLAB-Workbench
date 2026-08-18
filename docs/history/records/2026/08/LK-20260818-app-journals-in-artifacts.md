# App session journals use the visible LabKit artifacts folder

```labkit-change
id: LK-20260818-app-journals-in-artifacts
date: 2026-08-18
sequence: 183
type: fix
compatibility: compatible
component: `labkit.app` | `2.4.0 -> 2.4.1`
scope: App session journal location
scope: User-managed diagnostic artifacts
```

## Context

App sessions wrote persistent structured journals beneath MATLAB's release-specific preferences directory. That location was not visible from the LabKit installation and could accumulate usage history without an obvious relationship to the generated artifacts users already manage.

## Decision and rationale

Place new session journals beneath the existing installation-owned `artifacts` boundary. This keeps diagnostics, screenshots, saved states, and session journals discoverable through one generated-data location without adding another public configuration surface or a cross-session deletion policy. Remove the unconsumed cross-session inspection, lease, recovery, and retention machinery so users manage retained session folders explicitly.

## Changes

- New App sessions write their manifest and JSONL event segments beneath `artifacts/logs/sessions/` in the active LabKit installation.
- The existing private artifact store owns the shared category-folder calculation used by journals and other runtime artifacts.
- Cross-session automatic inspection, stale-session recovery, lease markers, and retention pruning were removed because no shipped runtime consumed them.
- Existing journals beneath MATLAB's preferences directory are neither migrated nor deleted.

## User and data impact

Users can see and manage new session logs beside other LabKit-generated artifacts. Existing logs retain their original location and contents. App calculations, project files, exported results, and diagnostic bundle contents are unchanged.

## Compatibility and migration

The change is compatible with existing App definitions and saved projects. No migration is required. Maintainers or users who no longer need legacy preference-directory journals may remove them explicitly.

## Validation

Focused App SDK source evidence verifies that the default journal root resolves beneath the active LabKit installation's `artifacts/logs` folder while explicit test journal roots remain supported. Session snapshot/export and active-session segment-bound coverage remain intact after removing the unconsumed cross-session cleanup path. Deterministic documentation validation covers the updated framework manual and structured history.

## Evidence

The focused Session Journal specification and documentation check cover the changed path contract without creating or deleting user journals.

## Known limitations and follow-up

LabKit does not automatically delete complete session folders, either in the new artifacts location or the legacy preferences location. The existing live-session segment bound remains a writer safety limit; users explicitly manage retained session folders.
