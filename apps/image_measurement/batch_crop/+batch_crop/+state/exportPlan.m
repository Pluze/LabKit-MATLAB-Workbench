% App-owned batch crop lifecycle helper. Expected caller: batch-crop export
% callback and package tests. Inputs are crop items and export options. Output
% is an immutable export plan with per-item fingerprints; this helper has no
% GUI, file, or image-processing side effects.
function plan = exportPlan(items, opts)
%EXPORTPLAN Build the batch-crop export plan snapshot.

    if nargin < 2 || isempty(opts)
        opts = struct();
    end

    plan = struct();
    plan.sourcePaths = string({items.path}).';
    plan.outputFolder = string(optionValue(opts, 'outputFolder', ""));
    plan.options = normalizeOptions(opts);
    plan.itemFingerprints = strings(numel(items), 1);
    for k = 1:numel(items)
        plan.itemFingerprints(k) = itemFingerprint(items(k), plan.options, k);
    end
    plan.fingerprint = strjoin([
        "app=batch_crop"
        "outputFolder=" + plan.outputFolder
        optionLines(plan.options)
        "itemCount=" + string(numel(items))
        plan.itemFingerprints], sprintf('\n'));
end

function optsOut = normalizeOptions(opts)
    optsOut = struct();
    optsOut.format = string(optionValue(opts, 'format', "PNG"));
    optsOut.cropWidth = double(optionValue(opts, 'cropWidth', 0));
    optsOut.cropHeight = double(optionValue(opts, 'cropHeight', 0));
    optsOut.paddingPercent = double(optionValue(opts, 'paddingPercent', 0));
    optsOut.scaleMode = string(optionValue(opts, 'scaleMode', "Pixels"));
    optsOut.scaleUnit = string(optionValue(opts, 'scaleUnit', ""));
    optsOut.physicalWidth = double(optionValue(opts, 'physicalWidth', 0));
    optsOut.physicalHeight = double(optionValue(opts, 'physicalHeight', 0));
    optsOut.targetPixelsPerUnit = double(optionValue(opts, 'targetPixelsPerUnit', 0));
    optsOut.maxUpsamplePercent = double(optionValue(opts, 'maxUpsamplePercent', 0));
end

function lines = optionLines(opts)
    lines = [
        "format=" + opts.format
        "cropWidth=" + numberToken(opts.cropWidth)
        "cropHeight=" + numberToken(opts.cropHeight)
        "fallbackPaddingPercent=" + numberToken(opts.paddingPercent)
        "scaleMode=" + opts.scaleMode
        "scaleUnit=" + opts.scaleUnit
        "physicalWidth=" + numberToken(opts.physicalWidth)
        "physicalHeight=" + numberToken(opts.physicalHeight)
        "targetPixelsPerUnit=" + numberToken(opts.targetPixelsPerUnit)
        "maxUpsamplePercent=" + numberToken(opts.maxUpsamplePercent)];
end

function fingerprint = itemFingerprint(item, opts, index)
    fingerprint = strjoin([
        "item[" + string(index) + "]=" + string(item.path)
        "image=" + imageToken(item.image)
        "angleDeg=" + numberToken(item.angleDeg)
        "paddingPercent=" + numberToken(batch_crop.state.itemPaddingPercent(item, opts.paddingPercent))
        "centerXY=" + numberToken(item.centerXY)
        "centerSet=" + string(logical(item.centerSet))
        "scale=" + calibrationToken(item.scaleCalibration, opts.scaleUnit)], "|");
end

function token = imageToken(imageData)
    token = "size=" + strjoin(string(size(imageData)), "x") + ...
        "|class=" + string(class(imageData));
end

function token = calibrationToken(cal, scaleUnit)
    token = "unit=" + scaleUnit + "|unset";
    if ~isstruct(cal)
        return;
    end
    token = "referencePixels=" + numberToken(fieldValue(cal, 'referencePixels', NaN)) + ...
        "|referenceLength=" + numberToken(fieldValue(cal, 'referenceLength', NaN)) + ...
        "|unit=" + string(fieldValue(cal, 'unit', scaleUnit)) + ...
        "|pixelsPerUnit=" + numberToken(fieldValue(cal, 'pixelsPerUnit', 0)) + ...
        "|isCalibrated=" + string(logical(fieldValue(cal, 'isCalibrated', false))) + ...
        "|referenceLine=" + numberToken(fieldValue(cal, 'referenceLine', zeros(0, 2)));
end

function value = fieldValue(s, name, defaultValue)
    value = defaultValue;
    if isstruct(s) && isfield(s, name)
        value = s.(name);
    end
end

function token = numberToken(value)
    token = string(mat2str(double(value), 17));
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name) && ~isempty(opts.(name))
        value = opts.(name);
    end
end
