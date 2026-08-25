# Launcher installation and App startup expose actionable progress

```labkit-change
id: CHG-20260726-launcher-install-and-startup-feedback
date: 2026-07-26
type: fix
compatibility: compatible
component: labkit_launcher | 1.7.0 -> 1.7.1
```

## Why

Opening an App from the Launcher was synchronous. Although the callback assigned an opening message before calling the App entry point, MATLAB could enter the expensive startup call before repainting the Launcher. Users therefore saw no visible acknowledgement, could interpret a legitimate startup as a hang, and could issue repeated double-clicks without knowing which stage was active. Existing GUI coverage asserted only the final opened state.

The standalone `labkit_launcher.m` also claimed it could bootstrap an otherwise empty folder, while its safety check and regression test rejected that exact case. Its repair window exposed neither a target folder nor a download-source choice, and did not distinguish a new installation from replacement of an existing one.

### Accepted choice

Treat startup acknowledgement as part of the Launcher interaction contract. Publish and paint a small number of honest stages before the expensive App entry point, disable launch surfaces while the action is active, and preserve the concrete entry-point failure when startup does not complete. Stages identify the current ownership boundary without inventing percentage progress that the Launcher cannot measure.

Keep the standalone entry self-contained but make its narrow responsibility complete: choose and validate a target before network access, distinguish installation from repair, offer stable/main/explicit-tag archives, confirm replacement, validate the extracted candidate, and retain transactional rollback. The installed Launcher continues to own rich version browsing and App catalog behavior.

## What changed

- Added visible path-preparation and App-window-initialization stages.
- Changed the launch button text and pointer while startup is active.
- Disabled the App table and all action buttons until startup finishes.
- Restored the normal controls after success or failure.
- Extended the native Launcher test to inspect status and control state at the instant the selected App entry point begins.
- Replaced the one-button repair window with target, source, a fetched published-version selector, confirmation, truthful operation stages, and status details. The UI neither requires users to type repository tags nor claims percentage progress for work it cannot measure.
- Allowed safe installation into a new, empty, or standalone-launcher-only folder while rejecting filesystem roots, Git checkouts, and unrelated nonempty folders before download.
- Added current-main and selected published-release downloads without importing the installed version manager into the standalone file.

## Impact

Users receive immediate acknowledgement after a button press or row double-click, can see whether startup is preparing the path or waiting in the named App entry point, and cannot accidentally queue another launch through the Launcher while the first is active. Scientific data and App projects are unchanged.

A user who downloads only `labkit_launcher.m` can now choose where to install, understand whether the operation is a new installation or repair, and select a published stable version or deliberate development source. Unsafe target folders fail before network or replacement activity.

## Compatibility and limits

The launcher command, catalog, table fields, visual layout, update tools, and App entry points are unchanged. The patch is compatible with existing installations and Apps. The standalone window adds choices but preserves latest stable as its recommended default.

### Remaining limits

The Launcher can identify that control has entered a named App entry point, but cannot report finer App-owned initialization phases until that App creates its Runtime diagnostics. Native dialog appearance, folder-picker behavior, and perceived responsiveness remain manual checks.
