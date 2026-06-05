% App-owned DIC helper extracted from labkit_DICPostprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function mask = imageMask(maskImage, targetSize)
    if ndims(maskImage) == 3
        maskImage = rgb2gray(maskImage);
    end
    mask = maskImage > 128;
    mask = imresize(mask, targetSize, 'nearest');
end
