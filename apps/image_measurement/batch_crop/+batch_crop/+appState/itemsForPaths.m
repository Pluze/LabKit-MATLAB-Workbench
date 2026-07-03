% App-owned state factory. Expected caller: batch-crop file chooser callback.
% Input is a selected path collection. Output is an unloaded item vector with
% paths recorded and no file or image-processing side effects.
function items = itemsForPaths(paths)
%ITEMSFORPATHS Create batch-crop items without reading image pixels.

    pathValues = reshape(string(paths), [], 1);
    items = repmat(batch_crop.appState.emptyItem(), numel(pathValues), 1);
    for k = 1:numel(pathValues)
        items(k).path = pathValues(k);
    end
end
