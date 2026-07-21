# Figure Studio edits one native subplot panel at a time

```labkit-change
id: LK-20260721-figure-studio-native-panel-editing
date: 2026-07-21
sequence: 153
type: feat
compatibility: compatible
component: `labkit_FigureStudio_app` | `0.4.0 -> 0.6.0`
scope: Figure Studio
```

## Context

Figure Studio reconstructed a limited portable snapshot from the first axes in
a FIG. This could omit composite graphics such as traditional `boxplot` groups,
gave no reliable way to choose a subplot from a mixed figure, and made export
canvas controls look like live plot-resize controls.

## Decision and rationale

Treat an opened FIG as a transient native document resource and select one
axes from it by an ordered subplot panel choice. The selected axes remains the
authoritative hierarchy for preview and editable/image export; the portable
snapshot remains an explicit secondary data-package representation. This gives
ordinary MATLAB charts a broader preservation path without promising that an
arbitrary custom graphics class is portable.

Use a fixed, visually calibrated single-panel default (1600 by 1333, 6:5).
The workbench now displays a raster rendering of that real export canvas, fit
as one image into the available workspace. Resizing the window never feeds
back into style sizing; supersampling remains export-only. Provide an explicit
automatic X/Y-limit recovery action instead of trying to infer limits during
unrelated style changes.

## Changes

- Added ordered mixed-FIG subplot-panel selection; preview, styling, limits,
  and exports all operate on the selected axes only.
- Added private native-source cloning for popout handoff and FIG import, with
  cleanup through the existing document-resource lifecycle.
- Preserved native child hierarchies in preview and editable FIG export,
  including traditional grouped `boxplot` graphics and hidden-handle visual
  children.
- Preserved source tick labels and tick configuration when copying native axes.
- Replaced free-form preview resizing with source/fixed export-size choices,
  aspect choices, export supersampling, and a stable true-export preview.
- Added **Recalculate X/Y limits** and project persistence for explicit limit
  overrides.
- Migrated project schema 3 to remember the selected panel index.

## User and data impact

Existing projects migrate automatically. A saved mixed FIG project restores
the same selected panel when its source is available. Popout projects retain a
portable snapshot after reload; their private native source is never saved.
No scientific calculation, source file, or source axes is modified.

## Compatibility and migration

Schema 1--3 projects migrate to schema 4. Schema 3 adds `panelIndex = 1`;
earlier migrations retain their existing style and limit conversions.

## Validation

- Project-schema tests cover migrations through schema 4.
- Hidden-GUI tests cover four-panel FIG selection, native boxplot preservation
  for FIG import and popout handoff, export, limit recovery, and a stable
  export-canvas preview through workspace resizing.
- Focused visual review checks a generated single-panel scientific probe at
  the default 1600-by-1333 reference size.

## Evidence

The focused test artifacts and generated local visual probe are supporting
evidence. No external laboratory data was used.

## Known limitations and follow-up

Developer-led visual review remains necessary for unusual custom charts,
native dialogs, and publication-specific annotation overlap. Portable data
packages intentionally support fewer object types than native FIG export.
