% Expected caller: labkit_ImageMatch_app and image_match export tests.
% Inputs are loaded source image items, one reference image item, ordered
% reference-match steps, and export options.
% Output includes per-image result structs and the manifest CSV path.
function payload = writeOutputs(items, referenceItem, steps, opts)

    if isempty(items)
        error('labkit_ImageMatch_app:NoImagesLoaded', ...
            'Load images before exporting matched outputs.');
    end
    if nargin < 2 || isempty(referenceItem)
        error('labkit_ImageMatch_app:NoReferenceImage', ...
            'Load a reference image before exporting matched outputs.');
    end
    if nargin < 4 || isempty(opts)
        opts = struct();
    end
    outputFolder = optionValue(opts, 'outputFolder', string(pwd));
    outputFormat = optionValue(opts, 'format', 'PNG');

    if exist(outputFolder, 'dir') ~= 7
        mkdir(outputFolder);
    end

    images = cell(numel(items), 1);
    for k = 1:numel(items)
        images{k} = items(k).image;
    end
    processed = image_match.ops.applyPipeline(images, steps, referenceItem.image);

    resultTemplate = emptyResult();
    results = repmat(resultTemplate, numel(items), 1);
    for k = 1:numel(items)
        result = resultTemplate;
        result.sourcePath = items(k).path;
        result.stepCount = numel(steps);
        result.widthPx = size(processed{k}, 2);
        result.heightPx = size(processed{k}, 1);

        outputPath = uniqueOutputPath(outputFolder, items(k).path, outputFormat);
        result.outputPath = outputPath;
        try
            imwrite(processed{k}, outputPath);
            result.status = "saved";
            result.message = "Saved";
        catch ME
            result.status = "failed";
            result.message = string(ME.message);
        end
        results(k) = result;
    end

    manifestPath = uniquePath(fullfile(char(outputFolder), ...
        'image_match_manifest.csv'));
    writetable(image_match.export.buildManifest(results), manifestPath);

    payload = struct();
    payload.results = results;
    payload.manifestPath = string(manifestPath);
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isfield(opts, name) && ~isempty(opts.(name))
        value = opts.(name);
    end
end

function result = emptyResult()
    result = struct( ...
        'sourcePath', "", ...
        'outputPath', "", ...
        'status', "pending", ...
        'widthPx', 0, ...
        'heightPx', 0, ...
        'stepCount', 0, ...
        'message', "");
end

function outputPath = uniqueOutputPath(outputFolder, sourcePath, formatName)
    [~, base, ~] = fileparts(char(sourcePath));
    extension = formatExtension(formatName);
    outputPath = uniquePath(fullfile(char(outputFolder), ...
        sprintf('%s_matched%s', base, extension)));
    outputPath = string(outputPath);
end

function extension = formatExtension(formatName)
    switch upper(string(formatName))
        case "TIFF"
            extension = '.tif';
        case "JPEG"
            extension = '.jpg';
        otherwise
            extension = '.png';
    end
end

function path = uniquePath(path)
    [folder, base, ext] = fileparts(path);
    candidate = fullfile(folder, [base ext]);
    index = 1;
    while isfile(candidate)
        candidate = fullfile(folder, sprintf('%s_%03d%s', base, index, ext));
        index = index + 1;
    end
    path = candidate;
end
