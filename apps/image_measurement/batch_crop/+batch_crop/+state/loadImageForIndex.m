% App-owned lazy image loader. Expected caller: batch-crop runner refresh and
% export callbacks. Inputs are crop items and a one-based item index. Output is
% the updated item vector plus whether the indexed item has image pixels.
function [items, loaded] = loadImageForIndex(items, index)
%LOADIMAGEFORINDEX Load one deferred crop item when pixels are needed.

    loaded = false;
    if index < 1 || index > numel(items)
        return;
    end
    if ~isempty(items(index).image)
        loaded = true;
        return;
    end

    loadedItems = batch_crop.state.readItems(items(index).path);
    if isempty(loadedItems)
        error('labkit_BatchImageCrop_app:ImageNotLoaded', ...
            'No image was loaded for item %d.', index);
    end
    items(index).image = loadedItems(1).image;
    items(index).path = loadedItems(1).path;
    loaded = true;
end
