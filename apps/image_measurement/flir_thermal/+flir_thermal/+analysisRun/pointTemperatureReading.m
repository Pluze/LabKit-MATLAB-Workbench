function reading = pointTemperatureReading(temperatureC, pointXY)
%POINTTEMPERATUREREADING Read the nearest calibrated thermal pixel.
%
% Usage:
%   reading = flir_thermal.analysisRun.pointTemperatureReading( ...
%       temperatureC, pointXY)
%
% Description:
%   Samples the nearest pixel in a calibrated temperature image. Coordinates
%   are rounded to integers and limited to the image bounds, so a point outside
%   the image samples the nearest edge pixel. The function does not change the
%   image, draw a marker, or apply display color limits.
%
% Inputs:
%   temperatureC - Two-dimensional numeric temperature matrix in degrees
%       Celsius. The values are converted to double before sampling.
%   pointXY - Numeric image coordinate [x y], where x is the column and y is
%       the row. Additional values are ignored. Both selected values must be
%       finite.
%
% Outputs:
%   reading - Scalar structure with x, y, and temperatureC fields. x and y are
%       the effective one-based integer pixel coordinates. An empty or
%       nonmatrix image, or a coordinate without two finite values, returns NaN
%       in all fields. A nonfinite sampled pixel remains nonfinite in the result.
%
% Example:
%   T = [10 20 30; 40 50 60];
%   reading = flir_thermal.analysisRun.pointTemperatureReading(T, [2.2 1.7]);
%   assert(reading.x == 2 && reading.y == 2 && reading.temperatureC == 50)
%
% See also flir_thermal.analysisRun.roiTemperatureMeanReading,
%   flir_thermal.analysisRun.extremeTemperatureReadings

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
