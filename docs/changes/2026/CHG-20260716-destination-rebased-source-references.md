# Destination-rebased source references

```labkit-change
id: CHG-20260716-destination-rebased-source-references
date: 2026-07-16
type: fix
compatibility: compatible
component: labkit.ui | 6.0.4 -> 6.0.5
```

## Why

Runtime source records were created before an App knew its future project-file location, so they began with an empty `relativePath`. Project-envelope creation copied those records unchanged. As a result, the resolver supported relative references, but ordinary Runtime V2 saves did not actually generate them.

### Accepted choice

Rebase source references at the serialization boundary using the actual MAT destination. A named project, app-owned autosave, and framework recovery file can live in different folders, so each write must calculate its own relative path rather than reusing a path cached in live state.

## What changed

- Passed the real destination path into every Runtime V2 envelope writer.
- Copied the durable project and refreshed reference schema, relative path, original path, and filename immediately before serialization.
- Preserved additive app/reference fields while replacing standard path fields.
- Kept resolved absolute paths in live state so current-session readers do not need to interpret portable references.

## Impact

A project and its source directory can now move together to another root or machine and reopen through the saved relative relationship even when the old absolute path no longer exists. Existing projects without a relative path remain readable through their original-path and relink fallbacks.

## Compatibility and limits

The envelope and source-reference schema versions are unchanged. No payload migration is needed: the next named save, explicit autosave, or recovery write adds the destination-correct relative path.

### Remaining limits

The portable-reference creation and resolution algorithms remain public in UI 6 for compatibility. They are implementation mechanics rather than App-facing workflow APIs and are reviewed with the remaining Runtime public surface for a single future major-boundary cleanup.
