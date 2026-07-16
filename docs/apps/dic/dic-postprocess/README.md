# DIC Postprocess

DIC Postprocess converts Ncorr strain fields into EXX and EYY overlays on an
optical reference image and calculates descriptive strain statistics over a
validated ROI. It is a rendering and summary tool; it does not rerun DIC.

## Requirements And Launch

The app requires the LabKit UI and Image facades. Input MAT files must contain
the Ncorr result structure recognized by the app loader.

```matlab
labkit_DICPostprocess_app
```

## Inputs

Three inputs define one analysis:

- an Ncorr MAT file containing readable EXX and EYY strain fields;
- the optical reference image used for the displayed specimen domain;
- a mask image whose nonzero pixels define the requested ROI.

All three are required before **Generate overlays + summary** can produce a
result. The loader validates the expected Ncorr structure and reports malformed
or incomplete MAT files instead of guessing at unrelated arrays.

## Basic Workflow

1. Choose the DIC MAT file, matching reference image, and mask image.
2. Set the overlay range and opacity.
3. Adjust oversampling, smoothing, and edge trimming when justified.
4. Optionally tune optical-image brightness, contrast, gamma, saturation, and
   RGB gains.
5. Generate the EXX/EYY overlays and review the summary table.
6. Save clean overlay PNGs and export the summary CSV.

Changing an option updates the reproducible project parameters. Generate again
before export when inputs or processing parameters change.

## Overlay Parameters

| Parameter | Default | Meaning |
| --- | ---: | --- |
| Alpha | 0.60 | opacity of strain color over the optical image |
| Color min | -0.15 | lower strain value mapped into the color scale |
| Color max | 0.15 | upper strain value mapped into the color scale |
| Oversample | 6 | output-domain refinement factor used during preparation |
| Smooth sigma | 0.8 | Gaussian smoothing scale applied to valid strain data |
| Edge trim | 1 | boundary pixels removed from the valid strain support |

Color limits affect rendering, not the stored numeric strain values used for
the summary. Alpha affects compositing only. Smoothing and edge trimming alter
the processed field and therefore can affect the summary; record them with any
reported measurements.

## Optical Image Parameters

Brightness defaults to `0`; contrast, gamma, saturation, and red/green/blue
gain default to `1`. These controls prepare the visual background. They do not
modify EXX/EYY values. Extreme settings can hide features or imply contrast
that is not present in the strain field, so exported figures should retain the
processing manifest.

## Processing And Scientific Semantics

The app constructs a valid-strain mask from finite Ncorr values, intersects it
with the requested ROI, trims invalid edges, and maps the result to the optical
image domain. Linear resizing is used for continuous image/strain data and
nearest-neighbor resizing for masks. Invalid strain samples remain excluded
rather than being converted to zero.

Summary statistics are computed independently for EXX and EYY over the final
valid ROI. The result table reports the metrics returned by
`dic_postprocess.analysisRun.summarizeStrain`; open its API page for the exact
table schema and non-finite-value behavior.

## Outputs

- a clean EXX overlay PNG;
- a clean EYY overlay PNG;
- a CSV table containing the ROI strain summary;
- a runtime result manifest describing inputs, parameters, and output roles.

The clean PNG exports contain only the composed image, not axes chrome or
interactive toolbar controls. Input MAT, reference, and mask files are never
modified.

## Use Without The GUI

```matlab
strain = dic_postprocess.sourceFiles.loadNcorrStrain("ncorr-result.mat");
reference = imread("reference.png");
mask = imread("mask.png") ~= 0;

options = struct("alpha", 0.60, "colorMin", -0.15, ...
    "colorMax", 0.15, "oversample", 6, ...
    "smoothSigma", 0.8, "edgeTrim", 1);
prepared = dic_postprocess.analysisRun.prepareOutputs( ...
    strain, reference, mask, options);
summary = dic_postprocess.analysisRun.summarizeStrain( ...
    prepared.exx, prepared.eyy, prepared.validMask);
```

The source loader is app-owned; the generated API table below lists only
operations intentionally supported as public GUI-free calculation APIs.

## Errors And Limitations

- A MAT file without the recognized Ncorr strain structure is rejected.
- Reference image, mask, and strain arrays must describe the same specimen
  domain; resizing resolves array dimensions, not semantic misalignment.
- A mask with no valid finite strain pixels produces no meaningful summary.
- Smoothing can suppress local extrema. Choose it as an analysis parameter,
  not merely a visual preference.

## Related Topics

- [DIC Preprocess](../dic-preprocess/README.md)
- [DIC family](../README.md)
- [Image Library](../../../libraries/image/README.md)
- [API Reference](../../../libraries/README.md)
