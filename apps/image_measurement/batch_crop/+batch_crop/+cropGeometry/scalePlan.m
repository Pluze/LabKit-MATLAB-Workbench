function plan = scalePlan(items, opts)
%SCALEPLAN Plan equal-size physical crops across calibrated images.
%
% Usage:
%   plan = batch_crop.cropGeometry.scalePlan(items, opts)
%
% Description:
%   Converts every image calibration to a requested physical unit, determines
%   a common output pixel density, and calculates native crop and common output
%   dimensions. Automatic density is the median converted source density.
%   Large scale differences produce warnings but do not reject the plan.
%
% Inputs:
%   items - Nonempty structure array. Each element must have a valid
%       scaleCalibration accepted by batch_crop.appState.isScaleCalibrationSet,
%       including a positive pixelsPerUnit value and its source unit.
%   opts - Scalar structure containing the physical crop options below.
%
% Options:
%   physicalWidth - Required positive crop width in scaleUnit.
%   physicalHeight - Required positive crop height in scaleUnit.
%   scaleUnit - Unit used for physical dimensions and pixel densities. Legal
%       values are "m", "cm", "mm", "um", and "nm". Default: "um".
%   targetPixelsPerUnit - Positive common output density in pixels per
%       scaleUnit. Zero, negative, or nonfinite input selects the median source
%       density automatically. Default: 0.
%   maxUpsamplePercent - Largest accepted upsampling above native density
%       before a warning is recorded. Negative input is treated as zero.
%       Default: 15.
%
% Outputs:
%   plan - Scalar structure with these fields:
%
% Plan Fields:
%   mode - "Physical".
%   unit - Effective scaleUnit.
%   targetSource - "Manual" for a positive targetPixelsPerUnit, otherwise
%       "Auto".
%   physicalWidth, physicalHeight - Requested dimensions in unit.
%   sourcePixelsPerUnit - Converted density for each input item.
%   targetPixelsPerUnit - Common output density.
%   resampleFactor - targetPixelsPerUnit ./ sourcePixelsPerUnit.
%   nativeCropWidth, nativeCropHeight - Per-item native crop sizes in pixels,
%       rounded to integers with a minimum of one.
%   outputWidth, outputHeight - Common output size in pixels, rounded to
%       integers with a minimum of one.
%   warnings - Per-item text. Upsampling beyond maxUpsamplePercent reports
%       "upsample ...x"; resample factors below 0.5 report "downsample ...x".
%
% Errors:
%   labkit_BatchImageCrop_app:ScaleCalibrationMissing - Any item lacks a valid
%       calibration convertible to scaleUnit.
%   labkit_BatchImageCrop_app:InvalidPhysicalSize - physicalWidth or
%       physicalHeight is missing, nonscalar, nonfinite, or nonpositive.
%   labkit_BatchImageCrop_app:InvalidScaleUnit - scaleUnit is unsupported.
%
% Example:
%   cal = labkit.ui.interaction.scaleBarCalibration(20, 10, "um");
%   items = struct("scaleCalibration", cal);
%   opts = struct("physicalWidth", 5, "physicalHeight", 3, ...
%       "scaleUnit", "um", "targetPixelsPerUnit", 4);
%   plan = batch_crop.cropGeometry.scalePlan(items, opts);
%   assert(plan.outputWidth == 20 && plan.outputHeight == 12)
%
% See also batch_crop.cropGeometry.cropScaledImage,
%   labkit.ui.interaction.scaleBarCalibration

    if nargin < 2
        opts = struct();
    end
    targetUnit = string(optionValue(opts, 'scaleUnit', "um"));
    sourcePpu = sourcePixelsPerUnit(items, targetUnit);
    if any(~isfinite(sourcePpu) | sourcePpu <= 0)
        error('labkit_BatchImageCrop_app:ScaleCalibrationMissing', ...
            'Physical scale mode requires a valid scale calibration for every loaded image.');
    end

    requestedTarget = double(optionValue(opts, 'targetPixelsPerUnit', 0));
    if isfinite(requestedTarget) && requestedTarget > 0
        targetPpu = requestedTarget;
        source = "Manual";
    else
        targetPpu = median(sourcePpu);
        source = "Auto";
    end

    widthUnit = requiredPositive(opts, 'physicalWidth');
    heightUnit = requiredPositive(opts, 'physicalHeight');
    maxUpsamplePercent = max(0, double(optionValue(opts, 'maxUpsamplePercent', 15)));
    resampleFactor = targetPpu ./ sourcePpu;
    warnings = strings(numel(sourcePpu), 1);
    upsampleLimit = 1 + maxUpsamplePercent / 100;
    for k = 1:numel(sourcePpu)
        if resampleFactor(k) > upsampleLimit
            warnings(k) = sprintf('upsample %.3gx', resampleFactor(k));
        elseif resampleFactor(k) < 0.5
            warnings(k) = sprintf('downsample %.3gx', resampleFactor(k));
        end
    end

    plan = struct();
    plan.mode = "Physical";
    plan.unit = targetUnit;
    plan.targetSource = source;
    plan.physicalWidth = widthUnit;
    plan.physicalHeight = heightUnit;
    plan.sourcePixelsPerUnit = sourcePpu;
    plan.targetPixelsPerUnit = targetPpu;
    plan.resampleFactor = resampleFactor;
    plan.nativeCropWidth = max(1, round(widthUnit .* sourcePpu));
    plan.nativeCropHeight = max(1, round(heightUnit .* sourcePpu));
    plan.outputWidth = max(1, round(widthUnit .* targetPpu));
    plan.outputHeight = max(1, round(heightUnit .* targetPpu));
    plan.warnings = warnings;
end

function values = sourcePixelsPerUnit(items, targetUnit)
    values = NaN(numel(items), 1);
    for k = 1:numel(items)
        if isfield(items(k), 'scaleCalibration') && isstruct(items(k).scaleCalibration) && ...
                isfield(items(k).scaleCalibration, 'pixelsPerUnit')
            values(k) = batch_crop.cropGeometry.pixelsPerUnitForUnit( ...
                items(k).scaleCalibration, targetUnit);
        end
    end
end

function value = requiredPositive(opts, name)
    value = double(optionValue(opts, name, []));
    if isempty(value) || ~isscalar(value) || ~isfinite(value) || value <= 0
        error('labkit_BatchImageCrop_app:InvalidPhysicalSize', ...
            'Physical %s must be a positive real-world size.', name);
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
