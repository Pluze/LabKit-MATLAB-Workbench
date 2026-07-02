% App-owned lazy image loader. Expected caller: batch-crop export callback.
% Input is crop item state that may contain path-only items. Output is the same
% item vector with all missing image pixels loaded.
function items = loadMissingImages(items)
%LOADMISSINGIMAGES Load all deferred crop items before batch export.

    for k = 1:numel(items)
        [items, loaded] = batch_crop.state.loadImageForIndex(items, k);
        if ~loaded
            error('labkit_BatchImageCrop_app:ImageNotLoaded', ...
                'Image %d could not be loaded.', k);
        end
    end
end
