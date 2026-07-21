# Durable Video Marker source metadata

```labkit-change
id: LK-20260716-video-marker-durable-metadata
date: 2026-07-16
sequence: 70
type: feat
compatibility: compatible
component: `labkit_VideoMarker_app` | `1.4.1 -> 1.5.0`
scope: project payload schema
scope: downstream gait inputs
```

## Context

Video Marker previously kept frame rate, frame count, duration, and image size
only in transient decoded-video state. Its MAT project preserved coordinates
but a GUI-independent downstream analysis could not recover time semantics
without reopening the original video or inventing a frame rate.

## Decision and rationale

Make immutable decoded-video facts part of the durable Video Marker project.
The portable source record continues to own the file path; the metadata record
contains only finite numeric facts required to interpret saved annotations.

## Changes

- Advanced the Video Marker project payload from version 1 to version 2.
- Added durable frame count, frame rate, duration, height, and width.
- Populate metadata when a video or marker CSV is opened and seed rebuilt
  sessions from saved metadata before optional source decoding.
- Refresh durable metadata from the reopened source before an explicit
  **Save autosave**, so a loaded version 1 autosave upgrades in place.
- Validate metadata values and annotation/frame-count consistency.
- Added an ordered v1-to-v2 migration that recovers frame count from saved
  annotation coordinates and leaves unknowable source facts at zero.

## User and data impact

New named projects and source-adjacent autosaves contain enough timing and
geometry information for Gait Analysis to treat the MAT document as its
authoritative input. Paths are not duplicated into the metadata record.

## Compatibility and migration

Version 1 LabKit project envelopes remain readable. Opening one marks it for an
upgrade; saving writes payload version 2. A frame rate absent from version 1
cannot be inferred from coordinates alone and remains zero until the source is
opened by the current Video Marker app.

## Validation

Video Marker unit tests verify metadata selection, absence of transient paths,
frame-count recovery, payload validation, and mismatched annotation rejection.
The existing GUI suite covers video opening, marker CSV import, project saves,
and recovery loading.

## Evidence

- [Video Marker](../../../../apps/image-measurement/video-marker/README.md)
  documents the persisted fields and downstream use.
- Gait Analysis input tests exercise the current payload contract separately.

## Known limitations and follow-up

Projects whose old payload never recorded a frame rate must reopen their source
video before producing a fully self-describing current project. Opening that
source through the saved reference and pressing **Save autosave** performs the
upgrade without another location prompt.
