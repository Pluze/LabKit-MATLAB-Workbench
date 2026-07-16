# Interactive recovery of missing project sources

```labkit-change
schema: 2
id: LK-20260716-runtime-source-relink
date: 2026-07-16
sequence: 66
type: fix
compatibility: compatible
component: `labkit.ui` | `6.0.1 -> 6.0.2`
scope: project loading
scope: portable source references
```

## Context

Saved projects could describe required external files with portable source
records, but an unresolved path produced a framework error unless the owning
app implemented the advanced `Project.RelinkSources` hook. Production apps
using standard source records therefore had no common recovery interaction
when a project moved between folders, drives, or operating systems.

## Decision and rationale

Make missing-file recovery the default Runtime V2 behavior for canonical
source records. The runtime already owns project loading, injected dialogs,
and transactional state replacement, so it can provide one consistent prompt
without duplicating native chooser code in every app. The advanced app hook
remains available for nonstandard source schemas.

## Changes

- Report the saved filename and source role when automatic resolution fails.
- Let the user locate each missing required file with one native file chooser.
- Rebuild the selected source reference relative to the loaded project before
  constructing the app session.
- Mark a successfully repaired document as unsaved so the replacement path can
  be retained on the next save.
- Mark migrated payloads, snapshots, and declared legacy variables as unsaved;
  **Save State** then upgrades the opened MAT path to the current project
  format through the existing atomic replacement.
- Treat cancellation as an atomic load cancellation without changing the live
  project or view.

## User and data impact

Projects whose external files remain in their recorded locations open exactly
as before. When a required file moved, the user can locate it instead of seeing
only an unresolved-source error. The runtime never searches arbitrary folders
or silently substitutes a different file. Merely opening an old document does
not rewrite it; saving the migrated document upgrades that same path.

## Compatibility and migration

The change is compatible with current project envelopes, declared legacy
imports, and existing custom `Project.RelinkSources` callbacks. Selecting a
replacement updates only the candidate project; saving writes the current
project format.

## Validation

The hidden Runtime V2 project test covers successful default relinking,
relative-reference rebuilding, dirty-document state, cancellation rollback,
and the existing custom relink hook.

## Evidence

- [Runtime and lifecycle](../../../../framework/runtime.md) documents the default
  missing-source interaction.
- Runtime source resolution reruns before fresh-session construction and state
  commit.

## Known limitations and follow-up

The default flow asks once for each unresolved source. Apps with a specialized
multi-file schema may continue to provide a custom relinking callback.
