# LabKit name and the first multi-domain app families

```labkit-change
schema: 2
id: LK-20260530-app-family-expansion
date: 2026-05-30
sequence: 3
type: feat
compatibility: compatible
scope: historical project evolution
```

## Context

By the end of the electrochem extraction, the repository had reusable DTA
operations and several app entry points, but its naming and package layout still
reflected the original Gamry workbench. It was not yet clear whether the design
could serve workflows with different data, interaction, and visualization
needs.

## Decision and rationale

Rename the project LabKit and treat apps, rather than one scientific domain, as
the main deliverables. Keep a limited set of reusable packages underneath them,
then exercise that structure with image registration, region editing, curvature
measurement, wearable data import, and ECG viewing.

The purpose was not to turn LabKit into one analysis program. It was to make a
common MATLAB foundation useful to several independent laboratory tools without
erasing the workflow decisions that made each tool understandable.

## Changes

- Renamed the workbench namespace to `labkit` and reduced the public package
  surface to app-facing UI and domain operations.
- Standardized the basic workbench shell and DTA file panels across the
  electrochem apps.
- Added DIC preprocessing and postprocessing workflows with iterative crop,
  mask, registration, zoom, and preview interactions.
- Added the Curvature Measurement app and reused its anchor-curve editor across
  image workflows where the interaction was genuinely the same.
- Added a biosignal facade and the ECG Print app, including wearable CSV import
  and signal-column diagnostics.
- Added MATLAB CI and reorganized tests by source responsibility.

## User and data impact

LabKit now served electrochem, image, and biosignal work from distinct app
entry points. Image users gained direct manipulation of regions and anchors;
biosignal users gained a viewer for imported wearable recordings. Existing DTA
files remained external inputs and were not converted into a central project
format.

## Compatibility and migration

The namespace rename was an implementation migration for repository code. The
new image and biosignal apps were additive. Scripts that referenced the former
workbench namespace needed to adopt `labkit` or an app entry point.

## Validation

Focused DIC interaction tests, biosignal import tests, layout tests, and the
first MATLAB CI workflow were added during this stage. The exact historical
command used for each commit was not recorded.

## Evidence

- Public-surface cleanup and LabKit rename `9bd8ec8f` through `179885e1`.
- Unified workbench and file panels `2de7dd0f` through `1be52b9d`.
- DIC family `aa96ae88` through `fd808a56`.
- Curvature Measurement `9c1f3798`, `8bcde252`.
- Biosignal and ECG work `d7c31369` through `b7cabd52`.
- Initial MATLAB CI `5102640c`.

## Known limitations and follow-up

The new apps exposed interaction problems that ordinary callback tests did not
capture well, including popout axes, anchor editing, busy-state reentry, and
image zoom ownership. Those issues drove the managed interaction work that
followed before v1.0.
