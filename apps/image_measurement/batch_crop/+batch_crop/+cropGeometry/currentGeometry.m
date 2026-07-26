% App-owned geometry cache helper. Expected caller: Batch Crop actions. Inputs
% are the current cache, item index, crop item, and padding percent. Outputs
% are prepared crop geometry and the updated cache.
function [geometry, cache] = currentGeometry(cache, itemIndex, item, paddingPercent)
    key = batch_crop.cropGeometry.canvasCacheKey( ...
        itemIndex, item, paddingPercent);
    if cache.valid && isequal(cache.key, key)
        geometry = cache.geometry;
        return;
    end
    % Constant: images through 12 megapixels retain native preview pixels;
    % larger inputs are sampled to keep interaction responsive.
    previewCanvasPixels = 12e6;
    geometry = batch_crop.cropGeometry.prepareCropCanvas(item.image, struct( ...
        'angleDeg', item.angleDeg, ...
        'paddingPercent', paddingPercent, ...
        'maxCanvasPixels', previewCanvasPixels));
    cache = struct('valid', true, 'key', key, 'geometry', geometry);
end
