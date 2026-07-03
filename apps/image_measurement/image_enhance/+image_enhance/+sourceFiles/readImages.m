% Expected caller: labkit_ImageEnhance_app and batch export tests. Inputs are
% a filePanel string column and optional progressFcn. Output is an item struct
% array with RGB double images normalized to [0, 1]. Alpha channels are ignored.
function items = readImages(paths, opts)

    if nargin < 2 || isempty(opts)
        opts = struct();
    end

    records = labkit.image.readFiles(paths, opts);
    template = image_enhance.appState.emptyItem();
    items = repmat(template, numel(records), 1);
    for k = 1:numel(records)
        items(k) = template;
        items(k).path = records(k).path;
        items(k).name = records(k).name;
        items(k).image = records(k).image;
    end
end
