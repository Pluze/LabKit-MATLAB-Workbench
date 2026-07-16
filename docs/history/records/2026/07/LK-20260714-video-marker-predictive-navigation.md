# Video Marker predictive frame navigation

```labkit-change
schema: 2
id: LK-20260714-video-marker-predictive-navigation
date: 2026-07-14
sequence: 58
type: feat
compatibility: compatible
component: `labkit_VideoMarker_app` | `1.1.0 -> 1.2.0`
component: `labkit.ui` | `5.1.1 -> 5.2.0`
scope: `docs/development/architecture.md`
scope: `docs/api/ui.md`
scope: runtime dependency policy
```

## Context

The first tracking implementation exposed separate interpolation and
previous-frame buttons. Its integer grayscale block search could only model a
small translation, and coordinate interpolation did not follow the actual
trajectory of articulated points. Users still had to request every estimate
manually.

## Decision and rationale

Make prediction an automatic part of forward navigation. Use a mature
pyramidal Kanade-Lucas-Tomasi tracker with forward/backward rejection for
short-range point propagation, and treat every complete human edit as a new
anchor. This matches the app's correction-oriented workflow without claiming
unattended long-term or occlusion tracking.

Keep the implementation MATLAB-local. Project policy now forbids incidental
third-party runtimes, Python environments, model downloads, and first-run
network installation; additional dependencies require an explicit architecture
decision.

## Changes

- Removed the user-facing Track and Interpolate actions.
- Added automatic forward prediction for adjacent frames and forward jumps.
- Replaced integer block matching with cropped four-level pyramidal KLT,
  forward/backward reliability checks, subpixel coordinates, and a
  constant-velocity fallback for rejected points.
- Added manual/predicted frame provenance and per-point confidence to the
  recoverable project payload while preserving marker CSV coordinates.
- Added reusable portable external-file references to `labkit.ui.runtime` and
  used them for both Video Marker projects and video-adjacent autosaves.
- Added a reusable field-labeled manual relinking fallback for malformed or
  unresolved references; app imports retain file-format validation ownership.
- Project and autosave payloads now prefer a path relative to the MAT file,
  fall back to the original path or same-folder filename, and offer video
  relinking when no automatic candidate exists.
- Made manual edits immutable anchors that reset subsequent prediction; only
  predicted drafts may be refreshed by the tracker.
- Added the repository runtime-dependency boundary to the root constitution,
  app rules, and human architecture documentation.

## User and data impact

After users mark a complete frame, moving forward presents editable predicted
points automatically. Correcting those points establishes a fresh anchor.
Older projects are upgraded in memory with provenance defaults; marker and
coordinate CSV formats are unchanged. Project/video directory trees can move
between users, cloud-drive roots, and operating systems without editing paths.

## Compatibility and migration

Existing Video Marker projects and autosaves remain readable. New project
payloads contain additive provenance and confidence fields. Systems without
the MATLAB KLT implementation retain coordinates through the motion fallback
and remain manually editable; no third-party installation is attempted.

## Validation

Synthetic tests cover subpixel translated-texture tracking, provenance upgrade,
and marker CSV round trips. Hidden GUI tests cover automatic prediction on
forward navigation and the absence of manual assist buttons. Local untracked
evaluation used adjacent frames from a representative video across marker,
eye, ear, nose, and toe textures; repository fixtures contain no real sample
paths or pixels.

## Evidence

- Predictive marking and portable file references `6bfd74c8`.

## Known limitations and follow-up

KLT is a short-range tracker. Low-texture, occluded, or strongly deforming
points can be rejected and require human correction; that correction is the
next anchor rather than an error state.
