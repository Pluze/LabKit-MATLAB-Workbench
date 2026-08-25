# Figure Studio becomes a semantic scientific-figure editor

```labkit-change
id: CHG-20260824-figure-studio-semantic-editor
date: 2026-08-24
type: feat
compatibility: compatible
component: labkit_FigureStudio_app | 0.7.5 -> 0.8.0
```

## Why

Figure Studio previously combined a calibrated publication style with a native axes preview and a portable single-panel snapshot. That was useful for consistent exports but left important scientific presentation decisions implicit in MATLAB graphics: axis text and tick generation were incomplete, role-level and per-object edits shared no deterministic cascade, compound annotations fragmented into primitives, and a mixed figure could not become one controlled multi-panel output.

### Accepted choice

Make one serializable semantic figure document authoritative for preview and every export. Represent panels, rulers, individual tick rows, graphic nodes, semantic groups, style inheritance, selection, and edit history explicitly. Keep source plot coordinates locked while allowing presentation properties and Studio-created annotations to be edited from whole categories down to one element. This combines predictable publication defaults with PowerPoint-like element control without moving scientific calculations out of their originating Apps.

## What changed

Figure Studio now imports multiple axes into exact panel geometry; supports independent X, left Y, right Y, and Z labels, ranges, scales, positions, tick locators, formatters, and per-tick text and typography; infers LabKit graphic and compound-annotation roles; and provides layers, grouping, ordering, duplication, transformation, alignment, and inherited document/type/role/group/object styles. It adds semantic text, arrow, reference-line, region, scale-bar, significance, and measurement annotations; editable colorbar state; reusable validated style files; publication preflight; and an editable package containing the document, FIG, visible panel data, and standalone reconstruction scripts.

## Impact

Users can correct axis wording and ranges, add labels for newly exposed ticks, edit or hide one tick, restyle a complete scientific category, override one element, assign a plotted object to the correct side of a dual-Y figure, and assemble publication panels without returning to low-level graphics commands. Source scientific coordinates remain unchanged and locked. An annotation added outside a displayed range expands that range and replans non-explicit ticks so the annotation and its labels remain visible.

## Compatibility and limits

The App entrypoint, FIG loading, LabKit plot handoff, established style controls, quick image and FIG exports, and existing portable extraction functions remain available. The in-memory editor is recreated from source snapshots, so no saved-project migration is required. Version `0.8.0` is a compatible capability expansion; unsupported native graphics remain preserved when copyable and are otherwise reported rather than silently discarded.

### Remaining limits

Role and dual-axis inference can only use visible metadata and geometry; ambiguous assignments require user review. Custom chart classes, callbacks, hidden source data, and App-specific analysis provenance remain outside the portable document contract. Renderer-specific font metrics and unrecognized native graphics still benefit from manual visual review before publication.
