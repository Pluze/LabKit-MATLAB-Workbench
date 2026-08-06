# App runtime input boundaries fail closed and repair preserves live sessions

```labkit-change
id: LK-20260806-app-runtime-input-boundaries
date: 2026-08-06
sequence: 175
type: fix
compatibility: compatible
component: `labkit.app` | `2.3.0 -> 2.3.1`
component: `labkit_launcher` | `1.8.3 -> 1.8.4`
scope: Native semantic input callback ownership
scope: Queued binding and callback transactions
scope: Live App installation repair protection
```

## Context

The native workspace adapter installed a selection callback even when the App
declared no workspace page behavior. Selecting a page therefore routed a valid
native interaction into the generic value path, which rejected the workspace
as having no value behavior. Related input paths for bound controls and file
lists also performed their state work outside the ordinary callback queue, so
they did not share one lifecycle for serialization, diagnostics, event
resources, and rollback. Installation repair could meanwhile remove framework
classes from the MATLAB path while a running App still owned delayed UI work.

## Decision and rationale

Make declared semantic behavior the source of truth for every native callback.
Compile-time validation rejects editable surfaces with no state or callback
owner, and native callback and presentation switches fail closed when a future
kind has no explicit policy. Route binding preparation and optional App
callbacks through one queue item that prepares against the latest committed
state. Mark native App figures and refuse installation replacement while any
marked or structurally recognized LabKit App remains open.

## Changes

- Workspace selection installs only for a declared page callback and dispatches
  through a page-specific runtime entry point.
- Bound controls and file-list selection now use the shared queued transaction,
  callback diagnostics, event-resource cleanup, state validation, presentation
  commit, and rollback lifecycle.
- Definition compilation rejects unowned editable controls, file lists, plot
  view modes, editable tables, and page callbacks without named pages; dynamic
  table edits receive the same presentation-time check.
- Native layout and presentation switches now report missing policies instead
  of silently accepting an unsupported future kind.
- Standalone repair and full Launcher version updates check for live LabKit
  figures before preparation and again immediately before replacing the
  installation.

## User and data impact

Changing workspace pages without an App callback remains a native visual
operation and no longer raises an error. Declared callbacks receive their typed
semantic values, and bound changes commit atomically with callback effects.
Failures retain the deepest actionable message in the native alert. Repair
does not move or replace an installation while an App is open, preventing
running callbacks from losing class definitions. Project and result formats
are unchanged.

## Compatibility and migration

Tracked Apps already give every editable surface a behavior owner, so no App or
saved-project migration is required. Previously accepted definitions containing
an inert editable surface now fail during Definition compilation with an
actionable ownership error; those surfaces must add the documented binding or
callback, or become read-only. The version-2 compatibility range is unchanged.

## Validation

Focused App SDK specifications exercise compile-time and dynamic ownership
failures, real native events for fields, ranges, sliders, plot modes, table
edits and table selections, workspace pages with and without callbacks,
transaction diagnostics, rollback alerts, and busy lifecycle behavior.
Focused Launcher and version-management specifications exercise live-App
refusal together with the existing replacement, rollback, path restoration,
and local-data preservation contracts.

## Evidence

- `AppSdkSpec` passed 28/28 focused identities.
- `LauncherBootstrapSpec` passed 28/28 focused identities.
- Public App definition inventory found no tracked editable surface without a
  declared behavior owner.

## Known limitations and follow-up

Hidden-GUI tests invoke real installed native callback functions but do not
prove pointer feel or rendering on every MATLAB release and operating system.
Repair cannot identify unrelated figures that imitate neither the stable App
tag nor the legacy workbench marker.
