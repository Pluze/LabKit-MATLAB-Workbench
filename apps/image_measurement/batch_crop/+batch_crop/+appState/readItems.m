% App-owned image loading helper. Expected caller: batch-crop app open-files
% callback. Input is a filePanel string column. Output is an item struct vector
% with images loaded through imread.
function items = readItems(paths)
%READITEMS Load selected image paths into crop item structs.

    records = labkit.image.readFiles(paths, struct("Normalize", false));
    items = repmat(batch_crop.appState.emptyItem(), numel(records), 1);
    for k = 1:numel(records)
        items(k).path = records(k).path;
        items(k).image = records(k).image;
        items(k).angleDeg = 0;
        items(k).centerXY = [NaN, NaN];
        items(k).centerSet = false;
    end
end
