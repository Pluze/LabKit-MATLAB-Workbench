# LabKit name and the first multi-domain app families

```labkit-change
id: CHG-20260530-app-family-expansion
date: 2026-05-30
type: feat
compatibility: compatible
component: repository
```

## Why

By the end of the electrochem extraction, the repository had reusable DTA operations and several app entry points, but its naming and package layout still reflected the original Gamry workbench. It was not yet clear whether the design could serve workflows with different data, interaction, and visualization needs.

### Accepted choice

Rename the project LabKit and treat apps, rather than one scientific domain, as the main deliverables. Keep a limited set of reusable packages underneath them, then exercise that structure with image registration, region editing, curvature measurement, wearable data import, and ECG viewing.

The purpose was not to turn LabKit into one analysis program. It was to make a common MATLAB foundation useful to several independent laboratory tools without erasing the workflow decisions that made each tool understandable.

## What changed

- Renamed the workbench namespace to `labkit` and reduced the public package surface to app-facing UI and domain operations.
- Standardized the basic workbench shell and DTA file panels across the electrochem apps.
- Added DIC preprocessing and postprocessing workflows with iterative crop, mask, registration, zoom, and preview interactions.
- Added the Curvature Measurement app and reused its anchor-curve editor across image workflows where the interaction was genuinely the same.
- Added a biosignal facade and the ECG Print app, including wearable CSV import and signal-column diagnostics.
- Added MATLAB CI and reorganized tests by source responsibility.

## Impact

LabKit now served electrochem, image, and biosignal work from distinct app entry points. Image users gained direct manipulation of regions and anchors; biosignal users gained a viewer for imported wearable recordings. Existing DTA files remained external inputs and were not converted into a central project format.

## Compatibility and limits

The namespace rename was an implementation migration for repository code. The new image and biosignal apps were additive. Scripts that referenced the former workbench namespace needed to adopt `labkit` or an app entry point.

### Remaining limits

The new apps exposed interaction problems that ordinary callback tests did not capture well, including popout axes, anchor editing, busy-state reentry, and image zoom ownership. Those issues drove the managed interaction work that followed before v1.0.
