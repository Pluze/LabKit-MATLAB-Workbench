# Single-click DIC rigid point matching

```labkit-change
schema: 1
id: LK-20260713-dic-rigid-point-editor
date: 2026-07-13
type: feat
compatibility: additive
component: `labkit.ui` | `5.0.4 -> 5.1.0`
component: `labkit_DICPreprocess_app` | `1.3.6 -> 1.4.0`
```

## Context

DIC manual rigid matching had draggable points but maintained a separate
pointer implementation and required a less consistent placement workflow than
the ROI-center anchors used by Imager Reconstruction.

## Decision and rationale

Extend the existing app-neutral anchor editor with a discrete point mode, then
keep moving/fixed pair order, numbering, minimum pair count, and rigid-fit
policy inside DIC.

## Changes

- Added `mode="points"`: one blank click appends a point, dragging refines it,
  no connecting curve is drawn, and deletion remains under explicit controls.
- Migrated the DIC modal to two shared point-mode editors while preserving
  ordered moving/fixed pairs, labels, undo, cancel, and acceptance rules.
- Retained toolbox-free image display and rigid alignment behavior.

## User and data impact

Feature placement now follows the same direct click-and-drag model as Imager
ROI anchors. Point coordinates and the resulting rigid transform keep their
existing N-by-2 pixel-coordinate contract.

## Compatibility and migration

The default anchor-editor curve mode is unchanged. DIC exports and transform
math are unchanged; this is an additive interaction improvement.

## Validation

UI anchor-editor tests cover discrete point append and no-path behavior. The
DIC GUI workflow covers toolbox-free modal cancellation and app launch wiring.

## Evidence

Primary sources are `labkit.ui.interaction.anchorEditor` and
`dic_preprocess.userInterface.selectRigidPointPairs`; branch checkpoint
`392a073e` carries the implementation before the final squash merge.

## Known limitations and follow-up

Automated hidden-GUI tests cannot judge pointing ergonomics; final interaction
feel still requires a short manual placement-and-drag check.
