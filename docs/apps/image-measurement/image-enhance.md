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
steps = struct("type", "brightness", "amount", 0.1);
enhanced = image_enhance.analysisRun.applyPipeline(image, steps);
imwrite(enhanced, "enhanced.png");
```

## See Also

- `image_enhance.analysisRun.applyPipeline`
- [Image Library](../../api/image.md)

