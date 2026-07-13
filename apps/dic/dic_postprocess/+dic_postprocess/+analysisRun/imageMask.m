% DIC Postprocess ops helper. Expected caller: labkit_DICPostprocess_app.
% Inputs are mask image data and target size. Output is resized logical mask.
% Side effects: none.
function mask = imageMask(maskImage, targetSize)
    maskImage = labkit.image.toDouble(maskImage);
    if ndims(maskImage) == 3
        maskImage = labkit.image.toLuma(maskImage);
    end
    % Preserve the legacy uint8 mask contract of "pixel value > 128" after
    % normalizing through labkit.image.toDouble.
    normalizedBinaryMaskThreshold = double(128) / double(intmax('uint8'));
    mask = maskImage > normalizedBinaryMaskThreshold;
    mask = dic_postprocess.analysisRun.resizeNearest(mask, targetSize);
end
