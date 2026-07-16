# Destination-rebased source references

```labkit-change
schema: 2
id: LK-20260716-destination-rebased-source-references
date: 2026-07-16
sequence: 74
type: fix
compatibility: compatible
component: `labkit.ui` | `6.0.4 -> 6.0.5`
scope: project serialization
scope: named save, explicit autosave, and recovery
```

## Context

Runtime source records were created before an App knew its future project-file
location, so they began with an empty `relativePath`. Project-envelope creation
copied those records unchanged. As a result, the resolver supported relative
references, but ordinary Runtime V2 saves did not actually generate them.

## Decision and rationale

Rebase source references at the serialization boundary using the actual MAT
destination. A named project, app-owned autosave, and framework recovery file
can live in different folders, so each write must calculate its own relative
path rather than reusing a path cached in live state.

## Changes

- Passed the real destination path into every Runtime V2 envelope writer.
- Copied the durable project and refreshed reference schema, relative path,
  original path, and filename immediately before serialization.
- Preserved additive app/reference fields while replacing standard path fields.
- Kept resolved absolute paths in live state so current-session readers do not
  need to interpret portable references.

## User and data impact

A project and its source directory can now move together to another root or
machine and reopen through the saved relative relationship even when the old
absolute path no longer exists. Existing projects without a relative path
remain readable through their original-path and relink fallbacks.

## Compatibility and migration

The envelope and source-reference schema versions are unchanged. No payload
migration is needed: the next named save, explicit autosave, or recovery write
adds the destination-correct relative path.

## Validation

The Runtime V2 project GUI test saves a source/project directory tree, verifies
the generated relative path, moves the tree, and reloads from the new root.
Video Marker verifies that its source-adjacent explicit autosave is rebased from
the autosave destination. Existing atomic-save, relink, recovery, and additive
field tests remain in the same focused suites.

## Evidence

- [Runtime and Data Model](../../../../framework/runtime.md) explains when
  relative paths are created and how they are resolved.
- [UI Framework](../../../../framework/README.md) describes Runtime V2 project
  ownership and persistence.

## Known limitations and follow-up

The portable-reference creation and resolution algorithms remain public in UI
6 for compatibility. They are implementation mechanics rather than App-facing
workflow APIs and are reviewed with the remaining Runtime public surface for a
single future major-boundary cleanup.
