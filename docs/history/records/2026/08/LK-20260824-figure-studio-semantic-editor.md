# Figure Studio becomes a semantic scientific-figure editor

```labkit-change
id: LK-20260824-figure-studio-semantic-editor
date: 2026-08-24
sequence: 193
type: feat
compatibility: compatible
component: `labkit_FigureStudio_app` | `0.7.5 -> 0.8.0`
scope: Figure Studio semantic element editing
scope: Figure Studio complete axes and tick control
scope: Figure Studio multi-panel publication layout
scope: Figure Studio editable scientific annotations
scope: Figure Studio publication preflight and package export
```

## Context

Figure Studio previously combined a calibrated publication style with a native axes preview and a portable single-panel snapshot. That was useful for consistent exports but left important scientific presentation decisions implicit in MATLAB graphics: axis text and tick generation were incomplete, role-level and per-object edits shared no deterministic cascade, compound annotations fragmented into primitives, and a mixed figure could not become one controlled multi-panel output.

## Decision and rationale

Make one serializable semantic figure document authoritative for preview and every export. Represent panels, rulers, individual tick rows, graphic nodes, semantic groups, style inheritance, selection, and edit history explicitly. Keep source plot coordinates locked while allowing presentation properties and Studio-created annotations to be edited from whole categories down to one element. This combines predictable publication defaults with PowerPoint-like element control without moving scientific calculations out of their originating Apps.

## Changes

Figure Studio now imports multiple axes into exact panel geometry; supports independent X, left Y, right Y, and Z labels, ranges, scales, positions, tick locators, formatters, and per-tick text and typography; infers LabKit graphic and compound-annotation roles; and provides layers, grouping, ordering, duplication, transformation, alignment, and inherited document/type/role/group/object styles. It adds semantic text, arrow, reference-line, region, scale-bar, significance, and measurement annotations; editable colorbar state; reusable validated style files; publication preflight; and an editable package containing the document, FIG, visible panel data, and standalone reconstruction scripts.

## User and data impact

Users can correct axis wording and ranges, add labels for newly exposed ticks, edit or hide one tick, restyle a complete scientific category, override one element, assign a plotted object to the correct side of a dual-Y figure, and assemble publication panels without returning to low-level graphics commands. Source scientific coordinates remain unchanged and locked. An annotation added outside a displayed range expands that range and replans non-explicit ticks so the annotation and its labels remain visible.

## Compatibility and migration

The App entrypoint, FIG loading, LabKit plot handoff, established style controls, quick image and FIG exports, and existing portable extraction functions remain available. The in-memory editor is recreated from source snapshots, so no saved-project migration is required. Version `0.8.0` is a compatible capability expansion; unsupported native graphics remain preserved when copyable and are otherwise reported rather than silently discarded.

## Validation

Focused Figure Studio specifications cover semantic document creation and style inheritance, selection and command history, axes and per-tick editing, dual-Y assignment, colorbars, compound annotations, direct manipulation, multi-panel layout, preflight, native presentation parity, supported portable objects, package contents, and execution of a standalone exported panel script. Hidden-GUI startup and repository code policy checks also pass. Final branch validation includes the repository changed-file profile and documentation consistency checks.

## Evidence

Renderer fixtures exercise the plot archetypes used across current LabKit Apps: linear and logarithmic series, scatter and trajectories, bar and error-bar summaries, box charts, patches and uncertainty regions, images and surfaces with colorbars, rectangles and analysis windows, constant reference lines, text, dual-Y panels, legends, stacked overlays, skeleton-like line groups, and compound significance, scale, and measurement annotations. The maintained LabKit style retains the normalized typography, stroke, legend-token, frame, and canvas relationships calibrated from the nine-panel published-figure reference.

## Known limitations and follow-up

Role and dual-axis inference can only use visible metadata and geometry; ambiguous assignments require user review. Custom chart classes, callbacks, hidden source data, and App-specific analysis provenance remain outside the portable document contract. Renderer-specific font metrics and unrecognized native graphics still benefit from manual visual review before publication.
