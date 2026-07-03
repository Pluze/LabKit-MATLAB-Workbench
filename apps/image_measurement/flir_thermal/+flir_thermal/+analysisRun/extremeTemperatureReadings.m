% Expected caller: FLIR thermal IO and tests. Input is a Celsius temperature
% matrix. Outputs are hot/cold point readings with pixel coordinates and
% Celsius values. Side effects: none.
function [hotSpot, coldSpot] = extremeTemperatureReadings(temperatureC)

    values = double(temperatureC);
    hotSpot = emptyReading();
    coldSpot = emptyReading();
    if isempty(values) || ndims(values) ~= 2
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
