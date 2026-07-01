% Expected caller: labkit_FLIRThermal_app and export tests. Inputs are one
% selected thermal item with ROI state and export options. Output describes
% the ROI Celsius CSV. Side effect: creates the output folder and writes CSV.
function result = writeRoiCsv(item, opts)

    if nargin < 2 || isempty(opts)
        opts = struct();
    end
    outputFolder = char(string(optionValue(opts, 'outputFolder', tempdir)));
    if exist(outputFolder, 'dir') ~= 7
        mkdir(outputFolder);
    end

    [values, rect] = flir_thermal.export.roiTemperatureMatrix(item);
    roiCsvPath = uniqueOutputPath(outputFolder, item.path, ...
        "_roi_temperature_c", "CSV");
    writematrix(values, roiCsvPath);

    result = struct( ...
        'sourcePath', string(item.path), ...
        'roiCsvPath', string(roiCsvPath), ...
        'roiX', rect(1), ...
        'roiY', rect(2), ...
        'roiWidth', rect(3), ...
        'roiHeight', rect(4), ...
        'units', "C", ...
        'status', "saved", ...
        'message', "Saved");
end

function outputPath = uniqueOutputPath(outputFolder, sourcePath, suffix, formatName)
    [~, base, ~] = fileparts(char(sourcePath));
    outputPath = uniquePath(fullfile(char(outputFolder), ...
        sprintf('%s%s%s', base, suffix, extensionFor(formatName))));
    outputPath = string(outputPath);
end

function extension = extensionFor(formatName)
    switch upper(string(formatName))
        case "CSV"
            extension = '.csv';
        otherwise
            extension = '.csv';
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
