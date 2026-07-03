% DIC Postprocess ops helper. Expected caller: labkit_DICPostprocess_app.
% Inputs are mask image data and target size. Output is resized logical mask.
% Side effects: none.
function mask = imageMask(maskImage, targetSize)
    if ndims(maskImage) == 3
        maskImage = rgb2gray(maskImage);
    end
    mask = maskImage > 128;
    mask = imresize(mask, targetSize, 'nearest');
end
