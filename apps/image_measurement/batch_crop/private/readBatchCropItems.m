% App-owned image loading helper. Expected caller: batch-crop app open-files
% callback. Input is a string vector of image paths. Output is an item struct
% vector with images loaded through imread.
function items = readBatchCropItems(paths)
%READBATCHCROPITEMS Load selected image paths into crop item structs.

    items = repmat(emptyBatchCropItem(), numel(paths), 1);
    for k = 1:numel(paths)
        img = imread(paths(k));
        items(k).path = string(paths(k));
        items(k).image = img;
        items(k).angleDeg = 0;
        items(k).centerXY = [NaN, NaN];
        items(k).centerSet = false;
    end
end
