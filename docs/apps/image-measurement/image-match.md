# Image Match

Image Match transfers selected appearance properties from a reference image to
one or more source images.

## Launch

```matlab
labkit_ImageMatch_app
```

## Workflow

Choose a reference, add source images, select the match method, and inspect the
preview and history before export. Switching files restores that image's real
persisted operations. Overlay markers do not alter the viewport.

## Processing Semantics

Methods may match tone, histogram, or color-space statistics. The reference
defines the target appearance but does not supply spatial content. Results
depend on compatible image types and representative reference content.

## Use Without The GUI

```matlab
source = imread("source.png");
reference = imread("reference.png");
step = image_match.analysisRun.makeStep("Balanced", 100, 100, 100);
matched = image_match.analysisRun.applyMatch(source, reference, step);
imwrite(matched, "matched.png");
```

The four step arguments are method, overall strength, tone strength, and color
strength, expressed as percentages. Supported methods are defined by
`image_match.userInterface.matchMethods`; callers should use those values
instead of inventing method strings. `applyMatch` converts inputs to RGB
double precision in `[0, 1]` and returns the same display-ready representation.

Pipelines can be replayed over one image, a numeric stack, or a cell array:

```matlab
steps = [ ...
    image_match.analysisRun.makeStep("White balance", 80, 100, 100)
    image_match.analysisRun.makeStep("Tone only", 50, 70, 0)];
processed = image_match.analysisRun.applyPipeline( ...
    {source}, steps, reference);
matched = processed{1};
```

The reference is immutable and is never included in `processed`.

## Errors And Limitations

- Appearance matching does not register geometry or align objects.
- A non-representative reference can produce technically valid but misleading
  color or tone statistics.
- Use the normalized step factory so missing fields cannot silently change the
  algorithm branch.

## See Also

- `image_match.analysisRun.applyMatch`
- `image_match.analysisRun.applyPipeline`
- [Image Library](../../api/image.md)
