function [hotSpot, coldSpot, meanReading] = roiTemperatureMeanReading(temperatureC, startXY, endXY)
%ROITEMPERATUREMEANREADING Measure an inclusive rectangular thermal ROI.
%
% Usage:
%   [hotSpot, coldSpot, meanReading] = ...
%       flir_thermal.analysisRun.roiTemperatureMeanReading( ...
%       temperatureC, startXY, endXY)
%
% Description:
%   Interprets two points as opposite corners of an inclusive rectangular ROI.
%   Bounds are rounded, ordered, and limited to the image. NaN, Inf, and -Inf
%   pixels are excluded from the extrema and arithmetic mean. Coordinates are
%   one-based: x is the column and y is the row. No graphics are created.
%
% Inputs:
%   temperatureC - Two-dimensional numeric temperature matrix in degrees
%       Celsius. The values are converted to double before calculation.
%   startXY - Numeric [x y] image coordinate at one ROI corner.
%   endXY - Numeric [x y] image coordinate at the opposite corner. Corner
%       order is irrelevant. Additional values are ignored; the first two
%       values of each corner must be finite.
%
% Outputs:
%   hotSpot - Scalar structure with x, y, and temperatureC for the finite ROI
%       maximum.
%   coldSpot - Scalar structure with x, y, and temperatureC for the finite ROI
%       minimum. Ties select the first value in column-major order.
%   meanReading - Scalar structure with x and y at the clamped upper-left ROI
%       corner, inclusive width and height, mean temperatureC, and pixelCount.
%       pixelCount counts only finite pixels, whereas width and height describe
%       the entire clamped rectangle.
%
% Failure Behavior:
%   Empty or nonmatrix temperature data, invalid corners, or an ROI with no
%   finite pixels returns NaN point fields. meanReading contains NaN geometry
%   and temperature and a pixelCount of zero.
%
% Example:
%   T = [10 NaN 30; 40 50 60; 70 80 90];
%   [hot, cold, avg] = ...
%       flir_thermal.analysisRun.roiTemperatureMeanReading(T, [1 1], [2 2]);
%   assert(hot.temperatureC == 50 && cold.temperatureC == 10)
%   assert(avg.temperatureC == 100/3 && avg.pixelCount == 3)
%
% See also flir_thermal.analysisRun.pointTemperatureReading,
%   flir_thermal.analysisRun.extremeTemperatureReadings

    values = double(temperatureC);
    hotSpot = emptyPointReading();
    coldSpot = emptyPointReading();
    meanReading = emptyRoiReading();
    if isempty(values) || ndims(values) ~= 2
        return;
    end
    startXY = double(startXY(:)).';
    endXY = double(endXY(:)).';
    if numel(startXY) < 2 || numel(endXY) < 2 || ...
            ~all(isfinite([startXY(1:2), endXY(1:2)]))
        return;
    end

    width = size(values, 2);
    height = size(values, 1);
    x1 = min(width, max(1, round(min(startXY(1), endXY(1)))));
    x2 = min(width, max(1, round(max(startXY(1), endXY(1)))));
    y1 = min(height, max(1, round(min(startXY(2), endXY(2)))));
    y2 = min(height, max(1, round(max(startXY(2), endXY(2)))));
    roiValues = values(y1:y2, x1:x2);
    finiteValues = roiValues(isfinite(roiValues));
    if isempty(finiteValues)
        return;
    end

    roiOrigin = [x1, y1];
    [hotSpot, coldSpot] = roiExtremeReadings(roiValues, roiOrigin);
    meanReading = struct( ...
        'x', double(x1), ...
        'y', double(y1), ...
        'width', double(x2 - x1 + 1), ...
        'height', double(y2 - y1 + 1), ...
        'temperatureC', double(mean(finiteValues)), ...
        'pixelCount', double(numel(finiteValues)));
end

function [hotSpot, coldSpot] = roiExtremeReadings(roiValues, roiOrigin)
    finiteMask = isfinite(roiValues);
    hotValues = roiValues;
    hotValues(~finiteMask) = -Inf;
    [hotValue, hotIndex] = max(hotValues(:));
    hotSpot = pointFromRoiIndex(size(roiValues), hotIndex, hotValue, roiOrigin);

    coldValues = roiValues;
    coldValues(~finiteMask) = Inf;
    [coldValue, coldIndex] = min(coldValues(:));
    coldSpot = pointFromRoiIndex(size(roiValues), coldIndex, coldValue, roiOrigin);
end

function reading = pointFromRoiIndex(matrixSize, index, value, roiOrigin)
    [row, col] = ind2sub(matrixSize, index);
    reading = struct('x', double(roiOrigin(1) + col - 1), ...
        'y', double(roiOrigin(2) + row - 1), ...
        'temperatureC', double(value));
end

function reading = emptyPointReading()
    reading = struct('x', NaN, 'y', NaN, 'temperatureC', NaN);
end

function reading = emptyRoiReading()
    reading = struct('x', NaN, 'y', NaN, 'width', NaN, 'height', NaN, ...
        'temperatureC', NaN, 'pixelCount', 0);
end
