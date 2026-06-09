% App-owned batch crop export helper. Expected caller: batch-crop app export
% callback and package tests. Inputs are crop items and export options. This
% helper writes cropped images and a CSV manifest.
function payload = writeOutputs(items, opts)
%WRITEOUTPUTS Write cropped images and a manifest CSV.
% Expected caller: labkit_BatchImageCrop_app and batch_crop package tests. Items
% must contain path, image, angleDeg, and centerXY fields. Options contain
% outputFolder, format, cropWidth, cropHeight, and fillMode/fillValue.

    if nargin < 2
        opts = struct();
    end
    if isempty(items)
        error('labkit_BatchImageCrop_app:NoImagesLoaded', ...
            'Load at least one image before exporting crops.');
    end

    outputFolder = string(optionValue(opts, 'outputFolder', ""));
    if strlength(outputFolder) == 0 || ~isfolder(outputFolder)
        error('labkit_BatchImageCrop_app:InvalidOutputFolder', ...
            'Select an existing output folder before exporting crops.');
    end

    outputFormat = normalizeOutputFormat(optionValue(opts, 'format', 'PNG'));
    results = repmat(batch_crop.state.emptyResult(), numel(items), 1);
    reservedPaths = strings(0, 1);
    for k = 1:numel(items)
        result = batch_crop.state.emptyResult();
        result.sourcePath = string(items(k).path);
        try
            cropOpts = opts;
            cropOpts.angleDeg = items(k).angleDeg;
            cropOpts.centerXY = items(k).centerXY;
            crop = batch_crop.ops.cropImage(items(k).image, cropOpts);
            outputPath = uniqueBatchCropOutputPath(outputFolder, ...
                string(items(k).path), outputFormat.extension, reservedPaths, "_crop");
            reservedPaths(end+1, 1) = outputPath;
            imwrite(crop.image, char(outputPath));

            result = crop;
            result.image = [];
            result.sourcePath = string(items(k).path);
            result.outputPath = outputPath;
            result.status = "saved";
            result.message = "Saved";
        catch ME
            result.status = "failed";
            result.message = string(ME.message);
        end
        results(k) = result;
    end

    manifest = batch_crop.export.buildManifest(results);
    manifestPath = uniqueBatchCropOutputPath(outputFolder, ...
        "batch_crop_manifest.csv", ".csv", reservedPaths, "");
    writetable(manifest, char(manifestPath));

    payload = struct();
    payload.results = results;
    payload.manifest = manifest;
    payload.manifestPath = manifestPath;
    payload.outputFolder = outputFolder;
end

function outputFormat = normalizeOutputFormat(formatValue)
    label = upper(char(string(formatValue)));
    switch label
        case 'PNG'
            outputFormat = struct('label', 'PNG', 'extension', ".png");
        case {'TIFF', 'TIF'}
            outputFormat = struct('label', 'TIFF', 'extension', ".tif");
        case {'JPEG', 'JPG'}
            outputFormat = struct('label', 'JPEG', 'extension', ".jpg");
        otherwise
            error('labkit_BatchImageCrop_app:UnsupportedOutputFormat', ...
                'Unsupported crop output format: %s.', char(string(formatValue)));
    end
end

function path = uniqueBatchCropOutputPath(outputFolder, sourcePath, extension, reservedPaths, suffix)
    if nargin < 5
        suffix = "";
    end
    [~, base, ext] = fileparts(char(sourcePath));
    if strlength(string(extension)) == 0
        extension = string(ext);
    end
    if isempty(base)
        base = 'batch_crop';
    end
    base = matlab.lang.makeValidName(base);
    candidate = string(fullfile(outputFolder, [base char(suffix) char(extension)]));
    index = 1;
    while isfile(candidate) || any(reservedPaths == candidate)
        candidate = string(fullfile(outputFolder, ...
            sprintf('%s%s_%03d%s', base, char(suffix), index, char(extension))));
        index = index + 1;
    end
    path = candidate;
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
