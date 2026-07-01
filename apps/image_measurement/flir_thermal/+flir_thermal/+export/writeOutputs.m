% Expected caller: labkit_FLIRThermal_app and export tests. Inputs are loaded
% thermal items and export options. Output includes per-image export results
% and a manifest path. Side effects: creates output folder and writes image,
% colorbar, and manifest files.
function payload = writeOutputs(items, opts)

    if isempty(items)
        error('labkit_FLIRThermal_app:NoImagesLoaded', ...
            'Load FLIR radiometric images before exporting.');
    end
    opts = normalizeOptions(opts);
    if exist(opts.outputFolder, 'dir') ~= 7
        mkdir(opts.outputFolder);
    end

    resultTemplate = emptyResult();
    results = repmat(resultTemplate, numel(items), 1);
    for k = 1:numel(items)
        result = resultTemplate;
        result.sourcePath = items(k).path;
        result.palette = opts.palette;
        try
            [values, units] = flir_thermal.view.valueMatrix(items(k));
            range = itemRange(items(k), opts.range);
            result.rangeMin = range(1);
            result.rangeMax = range(2);
            result.units = units;
            imagePath = uniqueOutputPath(opts.outputFolder, items(k).path, ...
                "_thermal", opts.format);
            colorbarPath = uniqueOutputPath(opts.outputFolder, items(k).path, ...
                "_colorbar", "PNG");
            temperatureCsvPath = uniqueOutputPath(opts.outputFolder, items(k).path, ...
                "_temperature_c", "CSV");
            rgb = labkit.thermal.renderImage(values, ...
                struct('Limits', range, 'Palette', opts.palette));
            labkit.image.writeFile(rgb, imagePath);
            labkit.image.writeFile(colorbarImage(range, opts.palette), colorbarPath);
            writematrix(flir_thermal.export.temperatureMatrix(items(k)), ...
                temperatureCsvPath);
            result.thermalImagePath = imagePath;
            result.colorbarPath = colorbarPath;
            result.temperatureCsvPath = temperatureCsvPath;
            result.status = "saved";
            result.message = "Saved";
        catch ME
            result.status = "failed";
            result.message = string(ME.message);
        end
        results(k) = result;
    end

    manifestPath = uniquePath(fullfile(char(opts.outputFolder), ...
        'flir_thermal_manifest.csv'));
    writetable(buildManifest(results), manifestPath);

    payload = struct();
    payload.results = results;
    payload.manifestPath = string(manifestPath);
end

function opts = normalizeOptions(opts)
    if nargin < 1 || isempty(opts)
        opts = struct();
    end
    opts = struct( ...
        'outputFolder', string(optionValue(opts, 'outputFolder', tempdir)), ...
        'format', string(optionValue(opts, 'format', "PNG")), ...
        'palette', string(optionValue(opts, 'palette', "turbo")), ...
        'range', double(optionValue(opts, 'range', [])));
    opts.outputFolder = char(opts.outputFolder);
    opts.format = upper(opts.format);
    if ~any(opts.format == ["PNG", "TIFF", "JPEG"])
        opts.format = "PNG";
    end
    opts.range = opts.range(:).';
    if ~(isempty(opts.range) || (numel(opts.range) == 2 && ...
            all(isfinite(opts.range)) && opts.range(2) > opts.range(1)))
        opts.range = [];
    end
end

function range = itemRange(item, fallbackRange)
    range = fallbackRange;
    if isfield(item, 'displayRange') && ~isempty(item.displayRange)
        range = double(item.displayRange(:)).';
    end
    if numel(range) ~= 2 || ~all(isfinite(range)) || range(2) <= range(1)
        [values] = flir_thermal.view.valueMatrix(item);
        values = values(isfinite(values));
        if isempty(values)
            range = [20 40];
        else
            range = [min(values), max(values)];
        end
    end
    if range(2) <= range(1)
        range(2) = range(1) + 1;
    end
end

function result = emptyResult()
    result = struct( ...
        'sourcePath', "", ...
        'thermalImagePath', "", ...
        'colorbarPath', "", ...
        'temperatureCsvPath', "", ...
        'status', "pending", ...
        'palette', "", ...
        'units', "", ...
        'rangeMin', NaN, ...
        'rangeMax', NaN, ...
        'message', "");
end

function image = colorbarImage(range, palette)
    values = linspace(range(2), range(1), 256).';
    values = repmat(values, 1, 32);
    image = labkit.thermal.renderImage(values, ...
        struct('Limits', range, 'Palette', palette));
end

function tableOut = buildManifest(results)
    tableOut = struct2table(results);
end

function outputPath = uniqueOutputPath(outputFolder, sourcePath, suffix, formatName)
    [~, base, ~] = fileparts(char(sourcePath));
    outputPath = uniquePath(fullfile(char(outputFolder), ...
        sprintf('%s%s%s', base, suffix, extensionFor(formatName))));
    outputPath = string(outputPath);
end

function extension = extensionFor(formatName)
    switch upper(string(formatName))
        case "TIFF"
            extension = '.tif';
        case "JPEG"
            extension = '.jpg';
        case "CSV"
            extension = '.csv';
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

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name) && ~isempty(opts.(name))
        value = opts.(name);
    end
end
