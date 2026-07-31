function [hotSpot, coldSpot] = extremeTemperatureReadings(temperatureC)
%EXTREMETEMPERATUREREADINGS Locate finite global thermal extrema.
%
% Usage:
%   [hotSpot, coldSpot] = ...
%       flir_thermal.analysisRun.extremeTemperatureReadings(temperatureC)
%
% Description:
%   Finds the highest and lowest finite values in a calibrated temperature
%   image. NaN, Inf, and -Inf pixels are ignored. Coordinates are one-based
%   image coordinates: x is the column and y is the row. If an extreme occurs
%   more than once, MATLAB column-major order selects the first occurrence.
%   Display palettes and color limits do not affect this calculation.
%
% Inputs:
%   temperatureC - Two-dimensional numeric temperature matrix in degrees
%       Celsius. The values are converted to double before calculation.
%
% Outputs:
%   hotSpot - Scalar structure containing the finite maximum's x, y, and
%       temperatureC fields.
%   coldSpot - Scalar structure containing the finite minimum's x, y, and
%       temperatureC fields. Empty, nonmatrix, or all-nonfinite input returns
%       NaN in every field of both outputs.
%
% Failure Behavior:
%   Empty, nonmatrix, or all-nonfinite input returns NaN readings. Values must
%   otherwise be convertible to double; unsupported MATLAB types propagate the
%   originating conversion error.
%
% Example:
%   T = [NaN 24; 18 31];
%   [hot, cold] = flir_thermal.analysisRun.extremeTemperatureReadings(T);
%   assert(hot.x == 2 && hot.y == 2 && hot.temperatureC == 31)
%   assert(cold.x == 1 && cold.y == 2 && cold.temperatureC == 18)
%
% See also labkit.thermal.readFile,
%   flir_thermal.analysisRun.roiTemperatureMeanReading

    values = double(temperatureC);
    hotSpot = emptyReading();
    coldSpot = emptyReading();
    if isempty(values) || ~ismatrix(values)
        return;
    end
    finiteMask = isfinite(values);
    if ~any(finiteMask, "all")
        return;
    end

    hotValues = values;
    hotValues(~finiteMask) = -Inf;
    [hotValue, hotIndex] = max(hotValues(:));
    hotSpot = readingFromIndex(size(values), hotIndex, hotValue);

    coldValues = values;
    coldValues(~finiteMask) = Inf;
    [coldValue, coldIndex] = min(coldValues(:));
    coldSpot = readingFromIndex(size(values), coldIndex, coldValue);
end

function reading = readingFromIndex(matrixSize, index, value)
    [row, col] = ind2sub(matrixSize, index);
    reading = struct('x', double(col), 'y', double(row), ...
        'temperatureC', double(value));
end

function reading = emptyReading()
    reading = struct('x', NaN, 'y', NaN, 'temperatureC', NaN);
end
