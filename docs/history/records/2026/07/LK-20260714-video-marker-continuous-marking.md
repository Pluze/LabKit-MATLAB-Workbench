# Video Marker visual skeleton setup and continuous marking

```labkit-change
id: LK-20260714-video-marker-continuous-marking
date: 2026-07-14
sequence: 57
type: feat
compatibility: compatible
component: `labkit.ui` | `5.1.0 -> 5.1.1`
component: `labkit_VideoMarker_app` | `1.0.1 -> 1.1.0`
scope: Video Marker visual skeleton setup and continuous marking
```

## Context

Video Marker required comma-separated keypoint names, manually encoded edge
text, a start/finish edit toggle, and a separate confirm action. Those controls
made skeleton setup error-prone and added modes that did not match the direct
click-and-drag interaction already supported by the point editor.

## Decision and rationale

Make skeleton definition the first explicit step, represent keypoints and
connections as structured controls, and keep point editing active for the
whole video session. Frame navigation is the save boundary; complete frames
confirm automatically and inherited frames remain drafts until edited.

## Changes

- Replaced long skeleton strings with an editable ordered-keypoint table,
  mutually filtered connection endpoint selectors, and add/remove/reorder actions.
- Added editable skeleton presets led by the legacy iliac-to-foot five-point
  leg chain, while keeping blank custom construction available.
- Added a connect-in-order shortcut that fills all adjacent point connections
  without removing other user-defined edges.
- Added the domain-neutral `labkit.ui.control.setItems` API for dynamically
  updating selectable control choices without firing app callbacks.
- Added `labkit.ui.plot.replaceOverlay` so image apps can replace one named
  overlay layer without clearing peer graphics, view limits, or callbacks.
- Added hidden-test-safe `labkit.ui.runtime.confirm` for app-owned two-choice
  recovery and confirmation workflows.
- Removed start/finish and confirm controls; blank clicks add points in order,
  dragging refines them, and frame changes save and inherit coordinates.
- Made point edits refresh only the skeleton overlay so zoom, wheel handling,
  and the active continuous-marking session survive each placed point.
- Preserved the current X/Y viewport across frame navigation so users can mark
  the same zoomed ROI through consecutive frames.
- Added draft-only marking assists for temporal interpolation between nearest
  confirmed frames and lightweight local block matching from the immediately
  previous confirmed frame.
- Added atomic change-driven project-compatible autosave in a visible subfolder
  beside the source video, plus matching-video restore/start-new choices.
- Added a new-setup action that explicitly clears the current session before a
  different skeleton is declared.

## User and data impact

Skeleton setup is visible and validated before video loading. Existing marker
CSV, coordinate CSV, and project MAT schemas remain unchanged. Point order is
still the coordinate-column identity contract.

## Compatibility and migration

Existing marker CSV and project files remain readable. The workflow changes
are UI-only; users no longer press Apply skeleton, Start point edit, or Confirm
frame. Video Marker now requires `labkit.ui >=5.1.1 <6`.

## Validation

Unit tests cover skeleton presets, edits, and edge remapping. Hidden GUI workflow tests
cover preset application, table-based setup, mutually filtered connection choices, automatic editor
activation, consecutive point placement with preserved zoom/scroll callbacks,
complete-frame confirmation, frame inheritance, and draft-state
preservation. UI framework tests cover dynamic selectable items.

## Evidence

- Continuous-marking and skeleton workflow redesign `bcba1833`.

## Known limitations and follow-up

Automated hidden-GUI tests verify callbacks and state transitions but cannot
judge visual density or pointer ergonomics; those still need a short manual
review with a representative video.
