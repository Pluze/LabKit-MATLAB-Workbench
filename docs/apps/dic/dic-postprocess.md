# DIC Postprocess

Use DIC Postprocess to convert Ncorr MAT output into same-size strain overlays
and summary tables tied to a reference image and analysis mask.

## Launch

```matlab
labkit_DICPostprocess_app
```

## Inputs

- an Ncorr-compatible MAT result containing displacement/strain fields;
- the corresponding reference image;
- an optional ROI mask from DIC Preprocess or another binary-mask source.

The app validates array sizes and prepares image, field, and mask arrays before
rendering. It does not rewrite the Ncorr result.

## Workflow

1. Load the MAT result and reference image.
2. Load or inspect the analysis mask.
3. Choose EXX or EYY and display limits.
4. Review the clean overlay and summary values.
5. Export the overlay PNG and summary CSV.

## Scientific Semantics

Strain fields remain numeric arrays; color mapping is a presentation step.
Invalid or masked pixels do not contribute to summary statistics. Edge trimming
and optional smoothing operate through app-owned functions and are recorded in
the output preparation result so the displayed field and reported statistics
refer to the same valid domain.

## Outputs

- clean EXX/EYY overlay PNG files sized to the reference image;
- summary CSV containing valid-pixel statistics;
- project state with portable references to source files and display choices.

## Use Without The GUI

```matlab
prepared = dic_postprocess.analysisRun.prepareOutputs( ...
    referenceImage, strainField, roiMask, options);
overlay = dic_postprocess.analysisRun.makeStrainOverlay( ...
    prepared.referenceImage, prepared.strain, prepared.validMask, options);
stats = dic_postprocess.analysisRun.summarizeStrain( ...
    prepared.strain, prepared.validMask);
```

Consult each API page for the current struct fields and option names; do not
infer them from the rendered colorbar.

## Troubleshooting

- A size mismatch usually means the reference image is not the one used for
  the loaded DIC solution.
- Empty statistics indicate that masking and validity filters left no usable
  pixels.
- Change display limits to inspect contrast; this does not change the stored
  strain values.

## See Also

- [DIC Preprocess](dic-preprocess.md)
- [DIC family](../families/dic.md)
