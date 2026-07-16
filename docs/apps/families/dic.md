# DIC Apps

The DIC family prepares image pairs for digital image correlation and turns
Ncorr result fields into reviewable strain overlays and tabular summaries.

## Choose An App

| Task | App |
| --- | --- |
| Register reference and moving images, crop a shared region, or draw a mask | [DIC Preprocess](../dic/dic-preprocess.md) |
| Render EXX/EYY fields and calculate statistics from Ncorr MAT output | [DIC Postprocess](../dic/dic-postprocess.md) |

## Shared Workflow

1. Keep original image files unchanged outside the LabKit installation.
2. Use DIC Preprocess to establish geometric correspondence and a consistent
   analysis region.
3. Run the external DIC solver with the prepared images.
4. Use DIC Postprocess to combine solver output, the reference image, and mask.

Registration, crop, and mask edits are project state. Scientific solver output
is not silently modified in place; exports are new files with explicit sizes
and summary fields.

## Programmatic Entry Points

The cataloged `dic_preprocess.analysisRun.*` functions provide GUI-free rigid
registration, crop, and overlay operations. The cataloged
`dic_postprocess.analysisRun.*` functions prepare strain maps, overlays, and
summary statistics. Open their API reference pages for coordinate conventions
and array shapes.

## Related Libraries

- [Image Library](../../api/image.md)
- [App Framework](../../api/ui.md)
