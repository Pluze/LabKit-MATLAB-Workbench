# Figure Studio removes source-reference knowledge

```labkit-change
id: CHG-20260716-figure-studio-source-boundary
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_FigureStudio_app | 0.2.3 -> 0.2.4
```

## Why

Figure Studio read both the current path and stored filename from the nested portable source reference. It repeated those reads in session reconstruction, actions, file-list presentation, and selection lookup.

### Accepted choice

Resolve source paths once through Runtime V2 at each workflow boundary. Derive the displayed filename from the resolved path so the App needs no knowledge of any portable-reference field.

## What changed

- Migrated FIG session reconstruction, action loading, file presentation, and selection lookup to `labkit.ui.runtime.sourcePaths`.
- Derived the opened-file status name through `fileparts`.
- Removed every direct portable-reference field read from Figure Studio.
- Preserved imported axes data, default style adoption, source order, current selection, editing, and export behavior.

## Impact

FIG selection and display behave unchanged. Figure Studio now owns only how it uses a resolved FIG file; Runtime V2 owns how that file remains portable.

## Compatibility and limits

No project or source-record field changed. Existing Figure Studio projects require no migration.

### Remaining limits

The repository-wide portable-reference guard remains deferred until all remaining App families have migrated.
