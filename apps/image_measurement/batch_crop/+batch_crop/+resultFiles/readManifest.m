function plan = readManifest(filepath)
%READMANIFEST Read and validate a restorable Batch Crop CSV manifest.
%
% Usage:
%   plan = batch_crop.resultFiles.readManifest(filepath)
%
% Inputs:
%   filepath - Scalar path to a Batch Crop CSV manifest. SourceImage entries
%       may be absolute, relative to the manifest, or relocatable by filename
%       beside the manifest.
%
% Outputs:
%   plan - Scalar struct with paths, tasks, and restorable project parameters.
%       Source image dimensions are verified without decoding full pixels.
%       Only rows whose final status is saved are restored. The reader accepts
%       the current manifest format only and performs no legacy migration.
%
% Errors:
%   batch_crop:ManifestNotFound - filepath is not an existing file.
%   batch_crop:InvalidManifest - Required columns, rows, values, or shared
%       settings are invalid or inconsistent.
%   batch_crop:ManifestSourceMissing - A recorded source cannot be resolved.
%   batch_crop:ManifestSourceChanged - A resolved source has different pixel
%       dimensions from the recorded source.
%
% See also batch_crop.resultFiles.buildManifest

filepath = string(filepath);
if ~isscalar(filepath) || strlength(filepath) == 0 || ~isfile(filepath)
    error("batch_crop:ManifestNotFound", ...
        "Select an existing Batch Crop manifest.");
end
data = readtable(char(filepath), TextType="string", ...
    VariableNamingRule="preserve");
required = ["SourceImage", "OutputImage", "Status", "TaskIndex", ...
    "RotationDeg", ...
    "PaddingPercent", "CenterX_px", "CenterY_px", "CropWidth_px", ...
    "CropHeight_px", "SourceWidth_px", "SourceHeight_px", ...
    "ScaleMode", "ScaleUnit", "SourcePixelsPerUnit", ...
    "TargetPixelsPerUnit", "PhysicalWidth", "PhysicalHeight", ...
    "MaxUpsamplePercent", "OutputFormat"];
names = string(data.Properties.VariableNames);
if isempty(data) || ~all(ismember(required, names))
    error("batch_crop:InvalidManifest", ...
        "The selected CSV is not a restorable Batch Crop manifest.");
end
saved = lower(textColumn(data, "Status")) == "saved";
data = data(saved, :);
if isempty(data)
    error("batch_crop:InvalidManifest", ...
        "The manifest does not contain any successfully saved crops.");
end
taskIndex = numericColumn(data, "TaskIndex");
if ~positiveIntegerColumn(taskIndex) || numel(unique(taskIndex)) ~= numel(taskIndex)
    error("batch_crop:InvalidManifest", ...
        "Manifest task indices must be unique positive integers.");
end
[~, order] = sort(taskIndex);
data = data(order, :);

sourcePaths = resolveSources(textColumn(data, "SourceImage"), filepath);
rotation = numericColumn(data, "RotationDeg");
padding = numericColumn(data, "PaddingPercent");
centerX = numericColumn(data, "CenterX_px");
centerY = numericColumn(data, "CenterY_px");
cropWidth = numericColumn(data, "CropWidth_px");
cropHeight = numericColumn(data, "CropHeight_px");
sourceWidth = numericColumn(data, "SourceWidth_px");
sourceHeight = numericColumn(data, "SourceHeight_px");
if any(~isfinite([rotation; padding; centerX; centerY])) || ...
        any(padding < 0) || ...
        ~positiveIntegerColumn(cropWidth) || ...
        ~positiveIntegerColumn(cropHeight) || ...
        ~positiveIntegerColumn(sourceWidth) || ...
        ~positiveIntegerColumn(sourceHeight) || ...
        ~oneSharedValue(cropWidth) || ~oneSharedValue(cropHeight)
    error("batch_crop:InvalidManifest", ...
        "Manifest crop geometry must be finite, positive, and consistent.");
end
verifySourceDimensions(sourcePaths, sourceWidth, sourceHeight);

mode = normalizedSharedText(textColumn(data, "ScaleMode"));
if ~any(mode == ["Pixels", "Physical"])
    error("batch_crop:InvalidManifest", ...
        "Manifest ScaleMode must be consistently Pixels or Physical.");
end
unit = "um";
sourcePixelsPerUnit = numericColumn(data, "SourcePixelsPerUnit");
targetPixelsPerUnit = numericColumn(data, "TargetPixelsPerUnit");
if mode == "Physical"
    unit = normalizedSharedText(textColumn(data, "ScaleUnit"));
    if strlength(unit) == 0 || any(~isfinite(sourcePixelsPerUnit)) || ...
            any(sourcePixelsPerUnit <= 0) || ...
            any(~isfinite(targetPixelsPerUnit)) || ...
            any(targetPixelsPerUnit <= 0) || ...
            ~oneSharedValue(targetPixelsPerUnit)
        error("batch_crop:InvalidManifest", ...
            "Physical manifests require consistent positive scale values.");
    end
end

tasks = repmat(batch_crop.cropTasks.emptyTask(), height(data), 1);
for index = 1:height(data)
    tasks(index).sourceId = "image-" + string(index);
    tasks(index).angleDeg = rotation(index);
    tasks(index).paddingPercent = padding(index);
    tasks(index).centerXY = [centerX(index), centerY(index)];
    tasks(index).centerSet = true;
    if mode == "Physical"
        tasks(index).scaleCalibration = ...
            labkit.app.interaction.scaleCalibration( ...
                sourcePixelsPerUnit(index), 1, unit);
    end
end

parameters = struct( ...
    "cropWidth", cropWidth(1), ...
    "cropHeight", cropHeight(1), ...
    "scaleMode", mode, ...
    "scaleUnit", unit, ...
    "physicalWidth", NaN, ...
    "physicalHeight", NaN, ...
    "targetPixelsPerUnit", 0, ...
    "maxUpsamplePercent", sharedNumeric(data, "MaxUpsamplePercent"), ...
    "format", manifestFormat(data), ...
    "outputFolder", string(fileparts(char(filepath))));
if ~isfinite(parameters.maxUpsamplePercent) || ...
        parameters.maxUpsamplePercent < 0
    error("batch_crop:InvalidManifest", ...
        "Manifest max-upsample percentage must be nonnegative.");
end
if mode == "Physical"
    parameters.targetPixelsPerUnit = targetPixelsPerUnit(1);
    parameters.physicalWidth = sharedNumeric(data, "PhysicalWidth");
    parameters.physicalHeight = sharedNumeric(data, "PhysicalHeight");
    if ~isfinite(parameters.physicalWidth) || ...
            parameters.physicalWidth <= 0 || ...
            ~isfinite(parameters.physicalHeight) || ...
            parameters.physicalHeight <= 0
        error("batch_crop:InvalidManifest", ...
            "Physical manifest dimensions must be positive.");
    end
end
plan = struct("paths", sourcePaths, "tasks", tasks, ...
    "parameters", parameters);
end

function paths = resolveSources(recorded, manifestPath)
folder = string(fileparts(char(manifestPath)));
paths = strings(numel(recorded), 1);
for index = 1:numel(recorded)
    candidate = recorded(index);
    if ~isfile(candidate)
        candidate = string(fullfile(folder, char(recorded(index))));
    end
    if ~isfile(candidate)
        [~, name, extension] = fileparts(char(recorded(index)));
        candidate = string(fullfile(folder, [name extension]));
    end
    if ~isfile(candidate)
        error("batch_crop:ManifestSourceMissing", ...
            "One or more manifest source images could not be resolved.");
    end
    paths(index) = candidate;
end
end

function verifySourceDimensions(paths, widths, heights)
for index = 1:numel(paths)
    info = imfinfo(char(paths(index)));
    if isempty(info) || double(info(1).Width) ~= widths(index) || ...
            double(info(1).Height) ~= heights(index)
        error("batch_crop:ManifestSourceChanged", ...
            "One or more source images no longer match the manifest dimensions.");
    end
end
end

function values = numericColumn(data, name)
values = data.(char(name));
if ~isnumeric(values)
    values = str2double(string(values));
end
values = double(values(:));
end

function values = textColumn(data, name)
values = string(data.(char(name)));
values = strip(values(:));
end

function accepted = positiveIntegerColumn(values)
accepted = all(isfinite(values) & values >= 1 & values == round(values));
end

function accepted = oneSharedValue(values)
accepted = ~isempty(values) && all(values == values(1));
end

function value = normalizedSharedText(values)
matches = unique(lower(values));
if numel(matches) ~= 1
    value = "";
    return
end
match = matches(1);
if match == "pixels"
    value = "Pixels";
elseif match == "physical"
    value = "Physical";
else
    value = values(1);
end
end

function value = sharedNumeric(data, name)
values = numericColumn(data, name);
finiteValues = values(isfinite(values));
if isempty(finiteValues) || numel(finiteValues) ~= numel(values) || ...
        ~oneSharedValue(finiteValues)
    error("batch_crop:InvalidManifest", ...
        "Manifest shared settings must be consistent across rows.");
end
value = finiteValues(1);
end

function format = manifestFormat(data)
format = upper(normalizedSharedText(textColumn(data, "OutputFormat")));
if ~any(format == ["PNG", "TIFF", "JPEG"])
    error("batch_crop:InvalidManifest", ...
        "Manifest output format must be consistently PNG, TIFF, or JPEG.");
end
end
