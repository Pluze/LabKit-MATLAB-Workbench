# Canonical single-source app projects

```labkit-change
id: LK-20260716-canonical-single-source-projects
date: 2026-07-16
sequence: 72
type: refactor
compatibility: compatible
component: `labkit_GaitAnalysis_app` | `2.0.0 -> 2.0.1`
component: `labkit_CurvatureMeasurement_app` | `1.4.0 -> 1.4.1`
component: `labkit_ECGPrint_app` | `1.4.0 -> 1.4.1`
component: `labkit_ResponseReviewStats_app` | `1.4.0 -> 1.4.1`
scope: project payload schema
scope: source relinking
```

## Context

The Runtime V2 project contract discovers external files through the
`project.inputs.sources` collection. Four single-source apps instead stored
their record under a singular `project.inputs.source` field. Their own actions
could open that path, but framework save/load relinking could not discover it.

## Decision and rationale

Use the same canonical source collection for every single-source app. The
plural field is a collection even when it currently contains zero or one
record, so persistence and relinking do not need app-specific field knowledge.

## Changes

- Moved Gait Analysis, Curvature Measurement, ECG Print, and Response Review
  Stats source ownership to `project.inputs.sources`.
- Advanced each payload schema by one version and added the corresponding
  ordered migration.
- Updated action, presenter, session, validation, export, and manual references
  to the canonical collection.
- Corrected the Gait family overview to describe its current strict Video
  Marker project input instead of retired generic MAT/table inputs.

## User and data impact

New saves expose their source records to the common portable-project resolver.
Scientific calculations, UI choices, annotations, parameters, and result
values are unchanged.

## Compatibility and migration

Existing payloads remain readable. Loading copies the former singular field
to the canonical collection and removes the retired field. A later save writes
the new payload version; source record contents are not transformed.

## Validation

Focused unit tests verify each field migration, current project version, and
existing calculations. Focused hidden-GUI tests verify that each app still
launches and follows its source workflow with the renamed durable field.

## Evidence

- [App Framework](../../../../framework/README.md) defines the canonical source
  collection used by project persistence.
- [Gait Analysis](../../../../apps/gait/gait-analysis/README.md), [Curvature
  Measurement](../../../../apps/image-measurement/curvature/README.md), [ECG
  Print](../../../../apps/wearable/ecg-print/README.md), and [Response Review
  Stats](../../../../apps/neurophysiology/response-review-stats/README.md)
  describe their upgraded project behavior.

## Known limitations and follow-up

This record covers single-source apps. Multi-role neurophysiology projects are
audited separately because preserving source roles requires a richer migration
than renaming one field.
