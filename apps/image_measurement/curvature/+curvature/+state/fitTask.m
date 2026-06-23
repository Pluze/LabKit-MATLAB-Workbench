% Expected caller: labkit_CurvatureMeasurement_app run callback and package
% tests. Inputs are current curve points, displayed fit path, scale
% calibration, and densify controls. Output is an immutable fit task snapshot
% with a deterministic fingerprint. Side effects: none.
function task = fitTask(points, fitPath, calibration, opts)
%FITTASK Build the curvature-fit computation task snapshot.

    if nargin < 2 || isempty(fitPath)
        fitPath = points;
    end
    if nargin < 3 || isempty(calibration)
        calibration = curvature.ops.normalizeScaleCalibration();
    else
        calibration = curvature.ops.normalizeScaleCalibration(calibration);
    end
    if nargin < 4 || isempty(opts)
        opts = struct();
    end

    task = struct();
    task.points = normalizePoints(points);
    task.fitPath = normalizePoints(fitPath);
    task.calibration = calibration;
    task.options = struct( ...
        'doDensify', logical(optionValue(opts, 'doDensify', true)), ...
        'denseN', max(3, round(double(optionValue(opts, 'denseN', 300)))));
    task.fingerprint = taskFingerprint(task);
end

function fingerprint = taskFingerprint(task)
    lines = [
        "app=curvature"
        "task=fit"
        "doDensify=" + string(task.options.doDensify)
        "denseN=" + numberToken(task.options.denseN)
        calibrationToken(task.calibration)
        pointBlock("point", task.points)
        pointBlock("fitPath", task.fitPath)];
    fingerprint = strjoin(lines, sprintf('\n'));
end

function points = normalizePoints(points)
    if isempty(points)
        points = zeros(0, 2);
        return;
    end

    points = double(points);
    if size(points, 2) ~= 2
        points = reshape(points, [], 2);
    end
end

function lines = pointBlock(label, points)
    lines = label + "Count=" + string(size(points, 1));
    for k = 1:size(points, 1)
        lines(end + 1, 1) = label + "[" + string(k) + "]=" + ...
            numberToken(points(k, 1)) + "," + numberToken(points(k, 2));
    end
end

function token = calibrationToken(calibration)
    referenceLine = normalizePoints(calibration.referenceLine);
    token = strjoin([
        "referencePixels=" + numberToken(calibration.referencePixels)
        "referenceLength=" + numberToken(calibration.referenceLength)
        "unit=" + string(calibration.unit)
        "pixelsPerUnit=" + numberToken(calibration.pixelsPerUnit)
        "isCalibrated=" + string(logical(calibration.isCalibrated))
        pointBlock("referenceLine", referenceLine)], sprintf('\n'));
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
