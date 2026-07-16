# Batch Image Crop

Batch Image Crop applies one calibrated crop geometry to a set of images while
making padding and scale normalization explicit.

## Launch

```matlab
labkit_BatchImageCrop_app
```

## Workflow

Add images, choose the reference image, drag or resize the ROI, review the
preview, then apply the crop to the selected batch. The interactive rectangle
is constrained to the reference image and retains its position until the user
changes or resets it.

## Geometry And Outputs

The app can crop at the original pixel scale or first normalize images to a
common scale. Out-of-bounds regions use the configured padding policy rather
than silently changing the requested crop size. Exports preserve the input
files and write cropped images plus operation metadata to the selected output
folder.

## Use Without The GUI

```matlab
image = imread("input.png");
rect = [120 80 640 640];
cropped = batch_crop.cropGeometry.cropImage(image, rect);
imwrite(cropped, "cropped.png");
```

For calibrated batches, use `batch_crop.cropGeometry.scalePlan` followed by
`batch_crop.cropGeometry.cropScaledImage`.

## Troubleshooting

- Confirm the ROI is inside the visible image before applying it.
- Use one common physical-scale policy when input resolutions differ.
- Padding is part of the output geometry and should be recorded in methods.

## See Also

- `batch_crop.cropGeometry.cropImage`
- [Image Library](../../api/image.md)

