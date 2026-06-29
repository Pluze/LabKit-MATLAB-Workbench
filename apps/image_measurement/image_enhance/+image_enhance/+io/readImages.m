% Expected caller: labkit_ImageEnhance_app and batch export tests. Inputs are
% a filePanel string column and optional progressFcn. Output is an item struct
% array with RGB double images normalized to [0, 1]. Alpha channels are ignored.
function items = readImages(paths, opts)

    if nargin < 2 || isempty(opts)
        opts = struct();
    end

    template = image_enhance.state.emptyItem();
    items = repmat(template, numel(paths), 1);
    progressFcn = optionValue(opts, 'progressFcn', []);

    for k = 1:numel(paths)
        reportProgress(progressFcn, "beforeRead", k, numel(paths), paths(k));
        imageData = imread(char(paths(k)));
        items(k) = template;
        items(k).path = paths(k);
        items(k).name = displayName(paths(k));
        items(k).image = normalizeImage(imageData);
        reportProgress(progressFcn, "afterRead", k, numel(paths), paths(k));
    end
end

function reportProgress(progressFcn, stage, index, count, path)
    if isempty(progressFcn) || ~isa(progressFcn, 'function_handle')
        return;
    end
    progressFcn(struct( ...
        'stage', string(stage), ...
        'index', index, ...
        'count', count, ...
        'path', string(path), ...
        'name', image_enhance.io.displayName(path)));
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

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
