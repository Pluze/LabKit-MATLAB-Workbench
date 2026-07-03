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
        result = addReadingResults(result, items(k));
        try
            [values, units] = flir_thermal.userInterface.valueMatrix(items(k));
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
            writematrix(flir_thermal.resultFiles.temperatureMatrix(items(k)), ...
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
    manifest = buildManifest(results);
    writetable(manifest, manifestPath);

    payload = struct();
    payload.results = results;
    payload.manifest = manifest;
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
        [values] = flir_thermal.userInterface.valueMatrix(item);
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
        'imageHotX', NaN, ...
        'imageHotY', NaN, ...
        'imageHotTempC', NaN, ...
        'imageColdX', NaN, ...
        'imageColdY', NaN, ...
        'imageColdTempC', NaN, ...
        'manualPointSet', false, ...
        'manualX', NaN, ...
        'manualY', NaN, ...
        'manualTempC', NaN, ...
        'roiHotSet', false, ...
        'roiHotBoxX', NaN, ...
        'roiHotBoxY', NaN, ...
        'roiHotBoxWidth', NaN, ...
        'roiHotBoxHeight', NaN, ...
        'roiHotPixelCount', NaN, ...
        'roiHotX', NaN, ...
        'roiHotY', NaN, ...
        'roiHotTempC', NaN, ...
        'roiColdSet', false, ...
        'roiColdBoxX', NaN, ...
        'roiColdBoxY', NaN, ...
        'roiColdBoxWidth', NaN, ...
        'roiColdBoxHeight', NaN, ...
        'roiColdPixelCount', NaN, ...
        'roiColdX', NaN, ...
        'roiColdY', NaN, ...
        'roiColdTempC', NaN, ...
        'roiMeanSet', false, ...
        'roiMeanX', NaN, ...
        'roiMeanY', NaN, ...
        'roiMeanWidth', NaN, ...
        'roiMeanHeight', NaN, ...
        'roiMeanPixelCount', NaN, ...
        'roiMeanTempC', NaN, ...
        'imageHotMinusImageColdC', NaN, ...
        'manualMinusImageHotC', NaN, ...
        'manualMinusImageColdC', NaN, ...
        'manualMinusRoiHotC', NaN, ...
        'manualMinusRoiColdC', NaN, ...
        'manualMinusRoiMeanC', NaN, ...
        'roiHotMinusRoiColdC', NaN, ...
        'roiHotMinusRoiMeanC', NaN, ...
        'roiMeanMinusRoiColdC', NaN, ...
        'message', "");
end

function result = addReadingResults(result, item)
    result = addPoint(result, item, 'hotSpot', 'imageHot');
    result = addPoint(result, item, 'coldSpot', 'imageCold');
    result = addPoint(result, item, 'manualPoint', 'manual');
    result.manualPointSet = isPointReading(item, 'manualPoint');
    result = addBox(result, item, 'roiHotBox', 'roiHotBox');
    result = addPoint(result, item, 'roiHotSpot', 'roiHot');
    result.roiHotSet = isPointReading(item, 'roiHotSpot');
    result = addBox(result, item, 'roiColdBox', 'roiColdBox');
    result = addPoint(result, item, 'roiColdSpot', 'roiCold');
    result.roiColdSet = isPointReading(item, 'roiColdSpot');
    result = addRoiMean(result, item);
    result = addTemperatureDifferences(result);
end

function result = addPoint(result, item, fieldName, prefix)
    if ~isPointReading(item, fieldName)
        return;
    end
    reading = item.(fieldName);
    result.([prefix 'X']) = double(reading.x);
    result.([prefix 'Y']) = double(reading.y);
    result.([prefix 'TempC']) = double(reading.temperatureC);
end

function result = addBox(result, item, fieldName, prefix)
    if ~isBoxReading(item, fieldName)
        return;
    end
    reading = item.(fieldName);
    result.([prefix 'X']) = double(reading.x);
    result.([prefix 'Y']) = double(reading.y);
    result.([prefix 'Width']) = double(reading.width);
    result.([prefix 'Height']) = double(reading.height);
    result.([prefix(1:end-3) 'PixelCount']) = double(reading.pixelCount);
end

function result = addRoiMean(result, item)
    if ~isRoiMeanReading(item)
        return;
    end
    reading = item.roiMean;
    result.roiMeanSet = true;
    result.roiMeanX = double(reading.x);
    result.roiMeanY = double(reading.y);
    result.roiMeanWidth = double(reading.width);
    result.roiMeanHeight = double(reading.height);
    result.roiMeanPixelCount = double(reading.pixelCount);
    result.roiMeanTempC = double(reading.temperatureC);
end

function result = addTemperatureDifferences(result)
    result.imageHotMinusImageColdC = diffValue( ...
        result.imageHotTempC, result.imageColdTempC);
    result.manualMinusImageHotC = diffValue( ...
        result.manualTempC, result.imageHotTempC);
    result.manualMinusImageColdC = diffValue( ...
        result.manualTempC, result.imageColdTempC);
    result.manualMinusRoiHotC = diffValue( ...
        result.manualTempC, result.roiHotTempC);
    result.manualMinusRoiColdC = diffValue( ...
        result.manualTempC, result.roiColdTempC);
    result.manualMinusRoiMeanC = diffValue( ...
        result.manualTempC, result.roiMeanTempC);
    result.roiHotMinusRoiColdC = diffValue( ...
        result.roiHotTempC, result.roiColdTempC);
    result.roiHotMinusRoiMeanC = diffValue( ...
        result.roiHotTempC, result.roiMeanTempC);
    result.roiMeanMinusRoiColdC = diffValue( ...
        result.roiMeanTempC, result.roiColdTempC);
end

function value = diffValue(a, b)
    if isfinite(a) && isfinite(b)
        value = a - b;
    else
        value = NaN;
    end
end

function tf = isPointReading(item, fieldName)
    tf = isfield(item, fieldName) && isstruct(item.(fieldName)) && ...
        all(isfield(item.(fieldName), {'x', 'y', 'temperatureC'})) && ...
        all(isfinite([item.(fieldName).x, item.(fieldName).y, ...
        item.(fieldName).temperatureC]));
end

function tf = isBoxReading(item, fieldName)
    tf = isfield(item, fieldName) && isstruct(item.(fieldName)) && ...
        all(isfield(item.(fieldName), ...
        {'x', 'y', 'width', 'height', 'pixelCount'})) && ...
        all(isfinite([item.(fieldName).x, item.(fieldName).y, ...
        item.(fieldName).width, item.(fieldName).height, ...
        item.(fieldName).pixelCount]));
end

function tf = isRoiMeanReading(item)
    tf = isfield(item, 'roiMean') && isstruct(item.roiMean) && ...
        all(isfield(item.roiMean, ...
        {'x', 'y', 'width', 'height', 'temperatureC', 'pixelCount'})) && ...
        all(isfinite([item.roiMean.x, item.roiMean.y, item.roiMean.width, ...
        item.roiMean.height, item.roiMean.temperatureC, ...
        item.roiMean.pixelCount]));
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
