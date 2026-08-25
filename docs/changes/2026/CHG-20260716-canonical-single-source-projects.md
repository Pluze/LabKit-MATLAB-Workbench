# Canonical single-source app projects

```labkit-change
id: CHG-20260716-canonical-single-source-projects
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_GaitAnalysis_app | 2.0.0 -> 2.0.1
component: labkit_CurvatureMeasurement_app | 1.4.0 -> 1.4.1
component: labkit_ECGPrint_app | 1.4.0 -> 1.4.1
component: labkit_ResponseReviewStats_app | 1.4.0 -> 1.4.1
```

## Why

The Runtime V2 project contract discovers external files through the `project.inputs.sources` collection. Four single-source apps instead stored their record under a singular `project.inputs.source` field. Their own actions could open that path, but framework save/load relinking could not discover it.

### Accepted choice

Use the same canonical source collection for every single-source app. The plural field is a collection even when it currently contains zero or one record, so persistence and relinking do not need app-specific field knowledge.

## What changed

- Moved Gait Analysis, Curvature Measurement, ECG Print, and Response Review Stats source ownership to `project.inputs.sources`.
- Advanced each payload schema by one version and added the corresponding ordered migration.
- Updated action, presenter, session, validation, export, and manual references to the canonical collection.
- Corrected the Gait family overview to describe its current strict Video Marker project input instead of retired generic MAT/table inputs.

## Impact

New saves expose their source records to the common portable-project resolver. Scientific calculations, UI choices, annotations, parameters, and result values are unchanged.

## Compatibility and limits

Existing payloads remain readable. Loading copies the former singular field to the canonical collection and removes the retired field. A later save writes the new payload version; source record contents are not transformed.

### Remaining limits

This record covers single-source apps. Multi-role neurophysiology projects are audited separately because preserving source roles requires a richer migration than renaming one field.
