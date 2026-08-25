# Launcher manager and stale callback fix

```labkit-change
id: CHG-20260626-launcher-manager-and-stale-callback-fix
date: 2026-06-26
type: fix
compatibility: compatible
component: labkit_launcher | 1.0.0 -> 1.1.1
component: labkit.ui | 3.0.0 -> 3.0.1
```

## Why

The launcher could update LabKit but did not offer an explicit choice among a recent release, a tag, and the main branch. Separately, image drag tools could leave old callbacks attached after an interaction ended.

### Accepted choice

Add a managed version selector backed by an install manifest, and make image interaction cleanup restore or release every temporary callback. Both changes reduce hidden state that otherwise survives beyond the user's selected action.

## What changed

- Added the launcher version manager and managed-manifest requirement.
- Released stale image drag callbacks.

## Impact

Users could deliberately install a supported release or development revision. Ending an image drag no longer left the figure responding to an obsolete tool. Saved app data did not change.

## Compatibility and limits

Existing launcher installations remained usable. Managed installations needed the launcher manifest for version replacement; image editors required no saved- data conversion after their stale callbacks were released.

### Remaining limits

Version selection still depended on network access for remote revisions; already installed local versions remained usable offline.
