# v2.0: launcher, image apps, and UI 2.0

```labkit-change
id: CHG-20260615-v2-launcher-and-ui2
date: 2026-06-15
type: feat
compatibility: compatible
component: repository
```

## Why

The first release had stable app commands, but discovery was poor: users had to know which command to run. Apps also used a mixture of first-generation UI patterns, which made startup, resizing, debug launch, and preview behavior less consistent than the underlying package boundaries.

### Accepted choice

Add a launcher as the visible entrance to the workbench and migrate the app families to a second-generation UI contract. Preserve separate app entry points and app-owned workflows; the launcher would discover and start them rather than turn them into screens of one large application.

## What changed

- Added the LabKit launcher and localized MATLAB project metadata.
- Added Image Enhance and Image Match workflows and semantic tab resizing.
- Supplied a base-MATLAB path for image matching instead of requiring an Image Processing Toolbox implementation.
- Migrated LabKit apps to UI 2.0 and added a starter template for new apps.
- Stabilized responsive layout behavior and default text-panel sizing.
- Completed cold-start migration, simplified debug launch, and persisted debug artifacts for later inspection.
- Refined DIC Postprocess overlay export at the release boundary.

## Impact

Users could browse and start supported apps from one launcher while retaining the option to call an app directly. Image users gained enhancement and matching workflows. Debug sessions left evidence that could be inspected after a startup or callback problem.

Existing scientific file formats and app-specific saved data remained owned by their apps.

## Compatibility and limits

App implementations moved to UI 2.0, but the release preserved the model of separate named app entry points. Code that depended on first-generation UI implementation details needed to adopt the new runtime contracts.

### Remaining limits

The launcher did not yet update itself, and large file panels and image tools still exposed inconsistent busy, zoom, and path-selection behavior. Those cross-app concerns became the focus of the 2.1 through 2.3 releases.
