# Workflow Guide Assets

[Guide index](README.md) | [App guide](../apps/README.md)

This maintainer note explains how to generate reusable screenshots and example
outputs for LabKit workflow guides.

The current asset generator focuses on the Image measurement family:

- `labkit_ImageEnhance_app`
- `labkit_ImageMatch_app`
- `labkit_BatchImageCrop_app`

It uses synthetic, non-sensitive images and then calls the real app-owned
read, operation, and export functions. The resulting images are suitable for
SOPs, onboarding guides, release notes, and app screenshots.

## Generate Image App Assets

Run from the repository root:

```bash
matlab -batch "run('docs/tools/generate_image_app_workflow_assets.m')"
```

By default, assets are written under:

```text
artifacts/doc-assets/image-app-workflows/
```

That folder is intentionally ignored by git. Copy only the final documentation
artifact or selected reviewed images into the place where the guide will be
published.

To write elsewhere:

```matlab
setenv("LABKIT_DOC_ASSET_OUTPUT", "/tmp/labkit-image-workflow-assets")
run("docs/tools/generate_image_app_workflow_assets.m")
```

## What The Script Produces

```text
assets/
  screenshot_launcher.png
  screenshot_image_enhance_parameters.png
  screenshot_image_match_parameters.png
  screenshot_batch_crop_parameters.png
  workflow_image_enhance_before_after.png
  workflow_image_match_reference_source_output.png
  workflow_batch_crop_source_output.png
  workflow_image_enhance_export.png
  workflow_image_match_export.png
  workflow_batch_crop_export.png

workflow_inputs/
  synthetic input images used by the workflows

workflow_exports/
  app export folders with generated image outputs and manifest CSV files
```

The examples are generated through app-owned code paths:

```matlab
image_enhance.sourceFiles.readImages(...)
image_enhance.analysisRun.makeStep(...)
image_enhance.resultFiles.writeOutputs(...)

image_match.sourceFiles.readImages(...)
image_match.analysisRun.makeStep(...)
image_match.resultFiles.writeOutputs(...)

batch_crop.appState.readItems(...)
batch_crop.resultFiles.writeOutputs(...)
```

This is stronger than taking a static mock screenshot: the guide assets fail
or drift when the app-owned workflow surface changes.

## Maintenance Boundary

Keep workflow-specific guide asset generation in `docs/tools/` or app-owned
packages. Do not promote these flows into `+labkit` unless at least two app
families need the same neutral command-line capture abstraction.

The current script intentionally does not create a PDF. It produces reviewed
source assets that can be used by a PDF, Word, slide, web, or release-note
pipeline. That keeps documentation layout tools separate from app behavior
capture.

## Safety Rules

- Use synthetic inputs for committed scripts and examples.
- Do not commit generated assets unless they are intentionally part of a
  published documentation artifact.
- Do not copy raw lab files, local lab filenames, device serials, timestamps,
  or other identifying sample metadata into guide assets.
- The script opens real MATLAB app figures to capture screenshots. Run it when
  local GUI window creation is acceptable.
- Review the generated images and manifest CSV files before publishing a guide.

## When To Update The Script

Update the asset script when one of these changes:

- visible app tab names or parameter controls
- app-owned export function signatures
- recommended SOP parameter examples
- launcher layout or app list presentation

When app behavior changes but this script still generates the same useful
assets, no documentation update is required beyond regenerating the external
guide artifact.
