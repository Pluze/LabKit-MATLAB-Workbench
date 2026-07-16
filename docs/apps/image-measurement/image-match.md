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
matched = image_match.analysisRun.applyMatch(source, reference, struct());
imwrite(matched, "matched.png");
```

Pipelines can be replayed with `image_match.analysisRun.applyPipeline`.

## See Also

- `image_match.analysisRun.applyMatch`
- [Image Library](../../api/image.md)

