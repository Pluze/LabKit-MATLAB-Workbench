% DIC Postprocess ops helper. Expected caller: dic_postprocess.ops helpers.
% Input is grayscale or RGB image data. Output is RGB image data. Side effects:
% none.
function out = ensureRgb(imageData)
    if ndims(imageData) == 2
        out = repmat(imageData, [1 1 3]);
    else
        out = imageData;
    end
end
