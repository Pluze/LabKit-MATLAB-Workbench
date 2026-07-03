% App-owned scale planning helper. Expected caller: batch-crop export and
% tests. Inputs are loaded items plus physical scale options. Output is a
% scalar plan struct and has no file side effects.
function plan = scalePlan(items, opts)
%SCALEPLAN Choose physical-mode output pixel density and per-image warnings.
% Items must carry scaleCalibration structs with pixelsPerUnit. Options may
% include physicalWidth, physicalHeight, scaleUnit, targetPixelsPerUnit, and
% maxUpsamplePercent. Auto target density uses the median source density so
% exports stay permissive; large mismatches are warnings, not blockers.

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
