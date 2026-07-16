% Expected caller: FLIR thermal plot callbacks and tests. Inputs are a
% Celsius temperature matrix and an image point in pixel coordinates. Output
% is the clamped nearest-pixel reading. Side effects: none.
function reading = pointTemperatureReading(temperatureC, pointXY)
%POINTTEMPERATUREREADING Read the nearest calibrated thermal pixel.
%   reading = flir_thermal.analysisRun.pointTemperatureReading(temperatureC, pointXY)
%   accepts a 2-D Celsius matrix and an [x y] image coordinate. The coordinate
%   is rounded to the nearest pixel and clamped to the matrix bounds. reading
%   contains x, y, and temperatureC. Invalid matrices or coordinates return
%   the same fields filled with NaN. The function has no graphics side effects.
%
%   Example:
%     reading = flir_thermal.analysisRun.pointTemperatureReading(T, [120 80]);
%
%   See also labkit.thermal.readFile,
%   flir_thermal.analysisRun.roiTemperatureMeanReading.

    values = double(temperatureC);
    reading = emptyReading();
    if isempty(values) || ndims(values) ~= 2
        return;
    end
    pointXY = double(pointXY(:)).';
    if numel(pointXY) < 2 || ~all(isfinite(pointXY(1:2)))
        return;
    end

    width = size(values, 2);
    height = size(values, 1);
    x = min(width, max(1, round(pointXY(1))));
    y = min(height, max(1, round(pointXY(2))));
    reading = struct('x', double(x), 'y', double(y), ...
        'temperatureC', double(values(y, x)));
end

function reading = emptyReading()
    reading = struct('x', NaN, 'y', NaN, 'temperatureC', NaN);
end
