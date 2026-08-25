# Explicit application autosave

```labkit-change
id: CHG-20260716-explicit-autosave
date: 2026-07-16
type: feat
compatibility: compatible
component: labkit.ui | 6.0.2 -> 6.0.3
component: labkit_VideoMarker_app | 1.3.0 -> 1.4.0
```

## Why

Runtime V2 already wrote debounced recovery generations after durable edits, but an app could only expose the named-project save operation. Video Marker users who wanted to force the current recovery point had no direct control and using **Save State** introduced a destination prompt for an unnamed project.

### Accepted choice

Expose the existing framework-owned recovery writer as an injected action service. The service accepts the current action state, writes the same bounded recovery generations as the timer, and deliberately leaves the named project path and dirty status unchanged. Video Marker exposes that operation as **Save autosave** in its Session panel.

## What changed

- Factored the atomic recovery-generation writer out of the timer scheduler.
- Added `services.project.saveAutosave(state)` for an immediate, pathless recovery write.
- Added the Video Marker **Save autosave** button and visible workflow log acknowledgement.
- Kept ordinary **Save State** as the separate operation for choosing or updating a named project file.

## Impact

Clicking **Save autosave** does not open a native file dialog. It updates the current app/document recovery file and retains one previous generation. It does not make the recovery file the active named project and does not suppress later unsaved-close protection.

## Compatibility and limits

Existing projects, recovery files, and automatic autosave behavior remain compatible. Apps that do not expose the new service behave exactly as before.

### Remaining limits

An autosave is a recovery aid, not a user-named archival project. Users still use **Save State** when they need a deliberate project filename or location.
