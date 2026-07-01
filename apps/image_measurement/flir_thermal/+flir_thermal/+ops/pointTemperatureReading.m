% Expected caller: FLIR thermal plot callbacks and tests. Inputs are a
% Celsius temperature matrix and an image point in pixel coordinates. Output
% is the clamped nearest-pixel reading. Side effects: none.
function reading = pointTemperatureReading(temperatureC, pointXY)

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
