# Default LabKit close protection

```labkit-change
id: CHG-20260709-default-labkit-close-protection
date: 2026-07-09
type: fix
compatibility: compatible
component: labkit.ui | 5.0.2 -> 5.0.3
component: labkit_FocusStack_app | 1.4.6 -> 1.4.7
component: labkit_ImageEnhance_app | 1.5.5 -> 1.5.6
component: labkit_ImageMatch_app | 1.5.5 -> 1.5.6
```

## Why

Only apps that installed a dirty-state guard warned before closing. A newly created public or private app could therefore discard work silently until its author implemented and tested a separate guard. Repeated close shortcuts could also race with a modal confirmation.

### Accepted choice

Make close confirmation a default property of every framework-owned app window and remove the optional app-facing guard API. Keep one in-window prompt active at a time; a repeated close shortcut confirms that prompt instead of opening another one.

## What changed

- LabKit runtime figures now show an in-window confirmation prompt before any framework-owned app window closes, even when the app has not marked itself dirty.
- Removed the app-facing `labkit.ui.runtime.setCloseGuard` API and migrated existing app close-guard dirty checks to the framework default behavior.
- Repeating or holding the app close shortcut while the in-window prompt is active confirms the close.

## Impact

Every public or private LabKit app asked before its window closed, even if the app had no custom dirty-state logic. Users gained a consistent protection against accidental closure at the cost of one confirmation step.

## Compatibility and limits

- Closing LabKit apps now requires one confirmation step by default. App code that calls `labkit.ui.runtime.setCloseGuard` must remove that call; close confirmation is framework-owned.

### Remaining limits

This policy protected the window, not the semantic completeness of each saved project. Runtime V2 later combined default close handling with app-owned dirty state and lifecycle services.
