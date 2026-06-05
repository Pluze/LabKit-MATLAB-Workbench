% App-owned export manifest helper. Expected caller: batch-crop app export
% callback and package tests. Input is a result struct vector. Output is a
% table suitable for CSV export and has no file side effects.
function T = buildManifest(results)
%BUILDMANIFEST Build a per-image crop/export manifest table.
% Expected caller: labkit_BatchImageCrop_app and batch_crop package tests.
% Input is a struct vector returned by cropImage or writeOutputs.
% Output columns describe source/output files, crop geometry, and status.

    if isempty(results)
        T = table(strings(0, 1), strings(0, 1), strings(0, 1), ...
            zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
            zeros(0, 1), zeros(0, 1), zeros(0, 1), strings(0, 1), ...
            'VariableNames', manifestColumns());
        return;
    end

    n = numel(results);
    sourceImage = strings(n, 1);
    outputImage = strings(n, 1);
    status = strings(n, 1);
    rotationDeg = zeros(n, 1);
    centerX = zeros(n, 1);
    centerY = zeros(n, 1);
    cropWidth = zeros(n, 1);
    cropHeight = zeros(n, 1);
    canvasWidth = zeros(n, 1);
    canvasHeight = zeros(n, 1);
    message = strings(n, 1);

    for k = 1:n
        sourceImage(k) = string(fieldOr(results(k), 'sourcePath', ""));
        outputImage(k) = string(fieldOr(results(k), 'outputPath', ""));
        status(k) = string(fieldOr(results(k), 'status', ""));
        rotationDeg(k) = double(fieldOr(results(k), 'rotationDeg', NaN));
        centerX(k) = double(fieldOr(results(k), 'centerX', NaN));
        centerY(k) = double(fieldOr(results(k), 'centerY', NaN));
        cropWidth(k) = double(fieldOr(results(k), 'cropWidth', NaN));
        cropHeight(k) = double(fieldOr(results(k), 'cropHeight', NaN));
        canvasWidth(k) = double(fieldOr(results(k), 'canvasWidth', NaN));
        canvasHeight(k) = double(fieldOr(results(k), 'canvasHeight', NaN));
        message(k) = string(fieldOr(results(k), 'message', ""));
    end

    T = table(sourceImage, outputImage, status, rotationDeg, centerX, centerY, ...
        cropWidth, cropHeight, canvasWidth, canvasHeight, message, ...
        'VariableNames', manifestColumns());
end

function names = manifestColumns()
    names = {'SourceImage', 'OutputImage', 'Status', 'RotationDeg', ...
        'CenterX_px', 'CenterY_px', 'CropWidth_px', 'CropHeight_px', ...
        'CanvasWidth_px', 'CanvasHeight_px', 'Message'};
end

function value = fieldOr(s, name, defaultValue)
    value = defaultValue;
    if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
        value = s.(name);
    end
end
