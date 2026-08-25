# App SDK fields keep reader-facing text visible

```labkit-change
id: CHG-20260825-readable-sdk-fields
date: 2026-08-25
type: fix
compatibility: compatible
component: labkit.app | 3.1.0 -> 3.1.1
```

## Why

Readonly fields used disabled multiline edit controls that could resemble incompletely drawn text boxes, reserve excess height for short values, and clip useful content inside their native chrome. Compact single-file selectors also displayed a complete absolute path on one line, so a long parent path could push the useful filename out of view.

The accepted choice was to make these two presentation rules part of the domain-neutral App SDK. Apps continue to declare the same semantic fields and file lists; the native adapter owns readable layout and path presentation consistently across Apps.

## What changed

- Readonly values use compact, selectable, wrapping text surfaces with their native border inset from the layout edge.
- Multiline readonly values continue to grow with their content and available width.
- Compact single-file selectors show the complete filename on a wrapping surface and retain the absolute path as hover text.
- `labkit.app` advances from 3.1.0 to 3.1.1.

## Impact

Users can read and copy short status values without oversized blank boxes, long summaries remain wrapped and selectable, and filenames remain visible when their parent paths are long. Source paths, App state, callbacks, calculations, result data, and saved formats are unchanged.

## Compatibility and limits

Existing App definitions need no source or state migration. Code that inspects private native control classes is outside the supported App SDK contract. A narrow selector still uses hover text for the complete absolute path, and native visual quality requires platform review.
