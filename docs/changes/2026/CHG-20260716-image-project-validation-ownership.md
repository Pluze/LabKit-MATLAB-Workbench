# Image App project validation ownership

```labkit-change
id: CHG-20260716-image-project-validation-ownership
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_BatchImageCrop_app | 1.7.4 -> 1.7.5
component: labkit_CurvatureMeasurement_app | 1.4.4 -> 1.4.5
component: labkit_FLIRThermal_app | 1.4.4 -> 1.4.5
component: labkit_FocusStack_app | 1.5.3 -> 1.5.4
component: labkit_ImageEnhance_app | 1.6.4 -> 1.6.5
component: labkit_ImageMatch_app | 1.6.4 -> 1.6.5
component: labkit_VideoMarker_app | 1.5.3 -> 1.5.4
```

## Why

The seven image workflow validators repeated Runtime's canonical project-bucket checks and, in six cases, the standard portable source-record field list. Those checks obscured the App-specific rules that actually matter: crop task relationships, parameter ranges, annotation shapes, video metadata, skeleton dimensions, and result schemas.

### Accepted choice

Keep the existence of each App's required source collection and every domain-specific relationship in `projectSpec.m`. Rely on Runtime for the five canonical bucket structs and the internal shape of every supplied source record. This preserves strict malformed-project rejection while making each validator read as its App schema.

## What changed

- Removed 71 net lines of repeated Runtime structure checks from the seven image App project specifications.
- Preserved required `inputs.sources` fields and all item/source, annotation/source, skeleton/frame, parameter, and result constraints.
- Added a GUI-free contract that accepts all seven default projects and rejects each project when its App-required source collection is removed.

## Impact

Valid projects, migrations, image calculations, annotations, and exports are unchanged. Malformed source records continue to fail in Runtime; malformed App fields continue to fail in the owning App validator.

## Compatibility and limits

No payload format changed and no migration is required. The refactor changes which layer reports framework-owned structure failures, not which valid data the Apps accept.

### Remaining limits

This change does not shorten action handlers or scientific workflow code. Those remain App-owned unless a separately measured repeated behavior proves to be stable and domain-neutral.
