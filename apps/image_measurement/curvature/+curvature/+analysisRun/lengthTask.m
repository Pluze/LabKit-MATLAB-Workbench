% Expected caller: Curvature length action and package
% tests. Inputs are current curve points, displayed length path, and scale
% calibration. Output is an immutable length task snapshot with a deterministic
% fingerprint. Side effects: none.
function task = lengthTask(points, lengthPath, calibration)
%LENGTHTASK Build the curvature length-measurement task snapshot.

    if nargin < 2 || isempty(lengthPath)
        lengthPath = points;
    end
    if nargin < 3 || isempty(calibration)
        calibration = curvature.analysisRun.normalizeScaleCalibration();
    else
        calibration = curvature.analysisRun.normalizeScaleCalibration(calibration);
    end

    task = struct();
    task.points = normalizePoints(points);
    task.lengthPath = normalizePoints(lengthPath);
    task.calibration = calibration;
    task.fingerprint = taskFingerprint(task);
end

function fingerprint = taskFingerprint(task)
    lines = [
        "app=curvature"
        "task=length"
        calibrationToken(task.calibration)
        pointBlock("point", task.points)
        pointBlock("lengthPath", task.lengthPath)];
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
