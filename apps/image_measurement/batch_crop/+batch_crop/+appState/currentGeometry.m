% App-owned geometry cache helper. Expected caller: batch_crop/run. Inputs
% are the current cache, item index, crop item, and padding percent. Outputs
% are prepared crop geometry and the updated cache.
function [geometry, cache] = currentGeometry(cache, itemIndex, item, paddingPercent)
    key = batch_crop.appState.canvasCacheKey(itemIndex, item, paddingPercent);
    if cache.valid && isequal(cache.key, key)
        geometry = cache.geometry;
        return;
    end
    % Constant: 1.2 megapixels balances draggable crop responsiveness with
    % enough preview detail to place the crop accurately.
    previewCanvasPixels = 1.2e6;
    geometry = batch_crop.cropGeometry.prepareCropCanvas(item.image, struct( ...
        'angleDeg', item.angleDeg, ...
        'paddingPercent', paddingPercent, ...
        'maxCanvasPixels', previewCanvasPixels));
    cache = struct('valid', true, 'key', key, 'geometry', geometry);
end
