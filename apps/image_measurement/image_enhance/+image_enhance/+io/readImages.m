% Expected caller: labkit_ImageEnhance_app and batch export tests. Input is a
% string vector of image paths. Output is an item struct array with RGB double
% images normalized to [0, 1]. Alpha channels are ignored.
function items = readImages(paths)

    paths = string(paths(:));
    template = image_enhance.state.emptyItem();
    items = repmat(template, numel(paths), 1);

    for k = 1:numel(paths)
        imageData = imread(paths(k));
        items(k) = template;
        items(k).path = paths(k);
        items(k).name = displayName(paths(k));
        items(k).image = normalizeImage(imageData);
    end
end

function name = displayName(path)
    [~, base, ext] = fileparts(char(path));
    name = string([base ext]);
end

function imageData = normalizeImage(imageData)
    if ndims(imageData) == 2
        imageData = repmat(imageData, 1, 1, 3);
    elseif size(imageData, 3) > 3
        imageData = imageData(:, :, 1:3);
    end

    imageData = im2double(imageData);
    imageData = min(max(imageData, 0), 1);
end
