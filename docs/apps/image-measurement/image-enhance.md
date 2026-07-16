# Image Enhance

Image Enhance builds a repeatable per-image enhancement pipeline and applies
the same operations during preview and export.

## Launch

```matlab
labkit_ImageEnhance_app
```

## Workflow

Add images, select an image, append brightness, contrast, clarity, color, or
white-balance steps, and review the history. Each image retains its own
pipeline when switching files. Undo and reset update both state and preview.

## Processing Contract

Operations run in displayed history order. Numeric controls are stored as
finite scalar values, and export calls the same app-owned pipeline as preview.
This avoids a visually plausible preview whose saved pixels were computed by a
different path.

## Use Without The GUI

```matlab
image = imread("input.png");
step = image_enhance.analysisRun.makeStep( ...
    "Brightness / Contrast", 8, 15, 0);
processed = image_enhance.analysisRun.applyPipeline({image}, step);
imwrite(processed{1}, "enhanced.png");
```

`makeStep(kind, amount, secondary, referenceIndex)` creates the complete
history record expected by the pipeline. The meaning and legal range of the
two numeric controls depend on `kind`; query
`image_enhance.analysisRun.defaultStepValues(kind)` when constructing a tool
programmatically. The optional third `contexts` argument to `applyPipeline`
supplies per-image context for operations that use a reference image.

Inputs are normalized to RGB double precision in `[0, 1]`. The function always
returns a column cell array, even when the input was one numeric image. Steps
run in array order, making the history directly replayable.

## Errors And Limitations

- Reordering nonlinear operations can change pixels substantially.
- Repeated lossy file export is not equivalent to replaying the original
  pipeline from the source image.
- Step factories sanitize scalar values, but callers still own choosing
  scientifically or visually justified parameters.

## See Also

- `image_enhance.analysisRun.applyPipeline`
- `image_enhance.analysisRun.makeStep`
- [Image Library](../../api/image.md)
