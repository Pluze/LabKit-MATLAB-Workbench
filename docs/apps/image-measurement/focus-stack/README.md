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
options = struct( ...
    "focusWindow", 31, ...
    "smoothRadius", 4, ...
    "minConfidence", 0.05, ...
    "pyramidLevels", 4);
result = focus_stack.analysisRun.computeFocusStack(images, options);
imwrite(result.fused, "stacked.png");
```

Inputs may be a cell array of grayscale/RGB images or a numeric stack. At
least two images are required. `focusWindow` is normalized to an odd window of
at least three pixels; `smoothRadius` regularizes the spatial selection;
`minConfidence` is constrained to `[0, 1]`; and `pyramidLevels` is limited by
the image size. Differently sized inputs are resized to the common working
geometry and counted in `result.resizedCount`.

The result contains `fused`, `focusIndex`, `confidence`, per-input
`focusCoverage`, image geometry, normalized options, and method metadata.
`focusIndex` is an explanatory selection map, while `confidence` reports how
strongly the winning focus evidence separated from the next candidate.

## Errors And Limitations

- The function rejects fewer than two inputs and invalid confidence values.
- Local fusion cannot recover detail absent from every input.
- Parallax, exposure changes, and moving objects can create seams even when
  the focus score is locally confident.

## See Also

- `focus_stack.analysisRun.computeFocusStack`
- [Image Library](../../../libraries/image/README.md)
