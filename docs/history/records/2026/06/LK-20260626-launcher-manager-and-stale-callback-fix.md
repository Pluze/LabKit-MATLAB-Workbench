# Launcher manager and stale callback fix

```labkit-change
id: LK-20260626-launcher-manager-and-stale-callback-fix
date: 2026-06-26
sequence: 13
type: fix
compatibility: compatible
component: `labkit_launcher` | `1.0.0 -> 1.1.0`
component: `labkit_launcher` | `1.1.0 -> 1.1.1`
component: `labkit.ui` | `3.0.0 -> 3.0.1`
scope: Launcher manager and stale callback fix
```

## Context

The launcher could update LabKit but did not offer an explicit choice among a
recent release, a tag, and the main branch. Separately, image drag tools could
leave old callbacks attached after an interaction ended.

## Decision and rationale

Add a managed version selector backed by an install manifest, and make image
interaction cleanup restore or release every temporary callback. Both changes
reduce hidden state that otherwise survives beyond the user's selected action.

## Changes

- `labkit_launcher` `1.0.0 -> 1.1.1`
- `labkit.ui` `3.0.0 -> 3.0.1`

- Added the launcher version manager and managed-manifest requirement.
- Released stale image drag callbacks.

## User and data impact

Users could deliberately install a supported release or development revision.
Ending an image drag no longer left the figure responding to an obsolete tool.
Saved app data did not change.

## Compatibility and migration

Existing launcher installations remained usable. Managed installations needed
the launcher manifest for version replacement; image editors required no saved-
data conversion after their stale callbacks were released.

## Validation

The listed commits added launcher-manager/manifest coverage and regression
checks for image callback cleanup. Exact historical commands were not recorded.

## Evidence

- Main commits `fe8654c9`, `ef89cf77`, and `3d23b7f1`.

## Known limitations and follow-up

Version selection still depended on network access for remote revisions;
already installed local versions remained usable offline.
