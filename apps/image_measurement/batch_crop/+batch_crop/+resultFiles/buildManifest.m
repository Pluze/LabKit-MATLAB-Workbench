% App-owned export manifest helper. Expected caller: batch-crop app export
% callback and package tests. Input is a result struct vector. Output is a
% table suitable for CSV export and has no file side effects.
function T = buildManifest(results, opts)
%BUILDMANIFEST Build a per-image crop/export manifest table.
% Usage:
%   T = batch_crop.resultFiles.buildManifest(results)
%   T = batch_crop.resultFiles.buildManifest(results, opts)
%
% Inputs:
%   results - Struct vector returned by cropImage or writeOutputs.
%   opts - Optional export-option struct. PhysicalWidth, PhysicalHeight,
%       MaxUpsamplePercent, and OutputFormat are retained when available so a
%       later manifest restore can reproduce the export settings.
%
% Outputs:
%   T - Table with one row per crop task and stable source, output, geometry,
%       scale, format, status, and message columns.

    if nargin < 2
        opts = struct();
    end

    if isempty(results)
        T = table(strings(0, 1), strings(0, 1), strings(0, 1), ...
            zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
            zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
            strings(0, 1), strings(0, 1), zeros(0, 1), zeros(0, 1), ...
            zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
            zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
            strings(0, 1), strings(0, 1), strings(0, 1), ...
            'VariableNames', manifestColumns());
        return;
    end

    n = numel(results);
    sourceImage = strings(n, 1);
    outputImage = strings(n, 1);
    status = strings(n, 1);
    taskIndex = (1:n).';
    rotationDeg = zeros(n, 1);
    paddingPercent = zeros(n, 1);
    centerX = zeros(n, 1);
    centerY = zeros(n, 1);
    cropWidth = zeros(n, 1);
    cropHeight = zeros(n, 1);
    sourceWidth = zeros(n, 1);
    sourceHeight = zeros(n, 1);
    scaleMode = strings(n, 1);
    scaleUnit = strings(n, 1);
    sourcePixelsPerUnit = zeros(n, 1);
    targetPixelsPerUnit = zeros(n, 1);
    resampleFactor = zeros(n, 1);
    nativeCropWidth = zeros(n, 1);
    nativeCropHeight = zeros(n, 1);
    outputWidth = zeros(n, 1);
    outputHeight = zeros(n, 1);
    physicalWidth = repmat(double(optionValue(opts, ...
        'physicalWidth', NaN)), n, 1);
    physicalHeight = repmat(double(optionValue(opts, ...
        'physicalHeight', NaN)), n, 1);
    maxUpsamplePercent = repmat(double(optionValue(opts, ...
        'maxUpsamplePercent', NaN)), n, 1);
    outputFormat = repmat(string(optionValue(opts, 'format', "")), n, 1);
    scaleWarning = strings(n, 1);
    message = strings(n, 1);

    for k = 1:n
        sourceImage(k) = string(fieldOr(results(k), 'sourcePath', ""));
        outputImage(k) = string(fieldOr(results(k), 'outputPath', ""));
        status(k) = string(fieldOr(results(k), 'status', ""));
        rotationDeg(k) = double(fieldOr(results(k), 'rotationDeg', NaN));
        paddingPercent(k) = double(fieldOr(results(k), 'paddingPercent', NaN));
        centerX(k) = double(fieldOr(results(k), 'centerX', NaN));
        centerY(k) = double(fieldOr(results(k), 'centerY', NaN));
        cropWidth(k) = double(fieldOr(results(k), 'cropWidth', NaN));
        cropHeight(k) = double(fieldOr(results(k), 'cropHeight', NaN));
        sourceWidth(k) = double(fieldOr(results(k), 'sourceWidth', NaN));
        sourceHeight(k) = double(fieldOr(results(k), 'sourceHeight', NaN));
        scaleMode(k) = string(fieldOr(results(k), 'scaleMode', ""));
        scaleUnit(k) = string(fieldOr(results(k), 'scaleUnit', ""));
        sourcePixelsPerUnit(k) = double(fieldOr(results(k), 'sourcePixelsPerUnit', NaN));
        targetPixelsPerUnit(k) = double(fieldOr(results(k), 'targetPixelsPerUnit', NaN));
        resampleFactor(k) = double(fieldOr(results(k), 'resampleFactor', NaN));
        nativeCropWidth(k) = double(fieldOr(results(k), 'nativeCropWidth', NaN));
        nativeCropHeight(k) = double(fieldOr(results(k), 'nativeCropHeight', NaN));
        outputWidth(k) = double(fieldOr(results(k), 'outputWidth', NaN));
        outputHeight(k) = double(fieldOr(results(k), 'outputHeight', NaN));
        scaleWarning(k) = string(fieldOr(results(k), 'scaleWarning', ""));
        message(k) = string(fieldOr(results(k), 'message', ""));
    end

    T = table(sourceImage, outputImage, status, taskIndex, ...
        rotationDeg, paddingPercent, ...
        centerX, centerY, cropWidth, cropHeight, sourceWidth, sourceHeight, ...
        scaleMode, scaleUnit, sourcePixelsPerUnit, targetPixelsPerUnit, ...
        resampleFactor, nativeCropWidth, nativeCropHeight, outputWidth, ...
        outputHeight, physicalWidth, physicalHeight, maxUpsamplePercent, ...
        outputFormat, scaleWarning, message, ...
        'VariableNames', manifestColumns());
end

function names = manifestColumns()
    names = {'SourceImage', 'OutputImage', 'Status', 'TaskIndex', 'RotationDeg', ...
        'PaddingPercent', 'CenterX_px', 'CenterY_px', 'CropWidth_px', ...
        'CropHeight_px', 'SourceWidth_px', 'SourceHeight_px', 'ScaleMode', ...
        'ScaleUnit', 'SourcePixelsPerUnit', 'TargetPixelsPerUnit', ...
        'ResampleFactor', 'NativeCropWidth_px', 'NativeCropHeight_px', ...
        'OutputWidth_px', 'OutputHeight_px', 'PhysicalWidth', ...
        'PhysicalHeight', 'MaxUpsamplePercent', 'OutputFormat', ...
        'ScaleWarning', 'Message'};
end

function value = optionValue(opts, name, defaultValue)
value = defaultValue;
if isstruct(opts) && isscalar(opts) && isfield(opts, name) && ...
        ~isempty(opts.(name))
    value = opts.(name);
end
end

function value = fieldOr(s, name, defaultValue)
    value = defaultValue;
    if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
        value = s.(name);
    end
end
