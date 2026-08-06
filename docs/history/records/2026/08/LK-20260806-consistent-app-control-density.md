# App controls use consistent action rhythm and adaptive readonly height

```labkit-change
id: LK-20260806-consistent-app-control-density
date: 2026-08-06
sequence: 176
type: fix
compatibility: compatible
component: `labkit.app` | `2.3.1 -> 2.4.0`
scope: Consistent native action sizing
scope: Adaptive readonly fields
scope: Control-panel divider density
```

## Context

The native adapter estimated button height from label character count without
knowing the available width. Several single-line actions therefore occupied a
two-line row while neighboring actions retained the native single-line height.
Readonly values always used text areas, which put scroll affordances into
compact one-line status rows. Every control-tab section also received a heavy
divider after it, including the final section where the bar resembled an
unnecessary horizontal scrollbar.

## Decision and rationale

Keep workflow buttons single-line and use a consistent framework-owned action
row instead of guessing line count from text length. Keep complete action text
in the tooltip and permit bounded font fitting only for unusually long labels.
Render readonly values as framework-owned wrapped text surfaces that recompute
their height from current content and available value-column width. Apps keep
using `Kind="readonly"` without declaring line counts or a second field type.
Retain row resizing only between adjacent sections and present its separator
with lower visual contrast.

## Changes

- Native workflow buttons no longer wrap into label-dependent heights;
  adaptive action grids and compact single-file selectors use the same action
  row policy.
- Readonly fields use the existing App-facing kind while the native adapter
  recomputes their wrapped height when text or available width changes.
- Readonly text surfaces avoid textarea scrollbars and retain the complete
  current value in their tooltip.
- Control tabs omit the trailing resize bar after their final section and use
  a lighter separator only between adjacent resizable sections.
- Existing Apps retain their declarations, versions, and documentation; no
  App-specific type, line count, or geometry option is required.

## User and data impact

Buttons within a workflow now share a predictable visual rhythm instead of
changing height because one label crosses a character threshold. Compact
status values no longer show textarea scrollbars, while longer guidance remains
readable without transient clipping. Control panels retain scrolling and
between-section resizing with less visual weight. Scientific values, workflow
order, project state, calculations, plots, and exports are unchanged.

## Compatibility and migration

Readonly field syntax remains compatible within the LabKit App SDK 2 range.
Existing Apps receive the improved native presentation without source or
metadata changes. Saved projects and result files do not change and require no
migration.

## Validation

Framework specifications cover automatic readonly growth without geometry
options, equal single-line action heights, and bounded divider count.
All public App definitions and native construction are checked after the shared
layout change. A same-size hidden-GUI audit compares every public App before
and after the change.

## Evidence

- `AppSdkSpec` passed 29/29 focused identities with native button-height and
  no-wrap assertions, adaptive-readonly coverage, and divider bounds.
- `AppDefinitionConformanceSpec` passed 42/42 identities across all 21 public
  Apps without App-owned layout or requirement changes.
- The 21-App 1180-by-760 baseline found eight workflow actions at an unintended
  46-pixel height and 138 row dividers. The final audit launched and exported
  all 21 Apps with 217 buttons, no button above 32 pixels, 88 between-section
  dividers, and 113 text areas within a 60-to-110.234375-pixel range; its
  screenshots remain ignored temporary visual evidence for final review.
- Documentation link validation covered 261 authored files with no unresolved
  link, and `docsCheck` produced two byte-identical 389-file render trees.

## Known limitations and follow-up

Hidden-GUI exports prove native structure and geometry but not pointer feel,
text rendering at every display scale, or visual quality on every supported
MATLAB release. Final subjective inspection remains a manual GUI boundary.
