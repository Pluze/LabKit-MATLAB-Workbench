% Expected caller: labkit_ImageMatch_app and batch export tests. Input is a
% filePanel string column. Output is an item struct array with RGB double images
% normalized to [0, 1]. Alpha channels are ignored.
function items = readImages(paths)

    records = labkit.image.readFiles(paths);
    template = image_match.state.emptyItem();
    items = repmat(template, numel(records), 1);
    for k = 1:numel(records)
        items(k) = template;
        items(k).path = records(k).path;
        items(k).name = records(k).name;
        items(k).image = records(k).image;
    end
end
