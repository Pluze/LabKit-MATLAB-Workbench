# Focus Stack

Focus Stack aligns a set of differently focused images and fuses their
best-focused regions into one output.

## Launch

```matlab
labkit_FocusStack_app
```

## Workflow

Add an ordered image stack, select alignment and fusion options, inspect the
preview, then export the fused image. Inputs should depict the same scene with
similar exposure and only focus changing between frames.

## Algorithm

The app registers the stack to a reference, evaluates local focus evidence,
and combines the selected pixels or bands. Alignment prevents camera movement
from appearing as double edges; it cannot correct large parallax or an object
that moved between exposures.

## Use Without The GUI

```matlab
images = {imread("z1.png"), imread("z2.png"), imread("z3.png")};
options = struct();
result = focus_stack.analysisRun.computeFocusStack(images, options);
imwrite(result.image, "stacked.png");
```

## See Also

- `focus_stack.analysisRun.computeFocusStack`
- [Image Library](../../api/image.md)

