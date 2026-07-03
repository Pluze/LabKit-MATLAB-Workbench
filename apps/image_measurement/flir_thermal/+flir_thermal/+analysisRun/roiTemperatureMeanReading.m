% Expected caller: FLIR thermal drag callback and tests. Inputs are a Celsius
% temperature matrix and two image points. Outputs are clamped ROI hot, cold,
% and mean readings. Side effects: none.
function [hotSpot, coldSpot, meanReading] = roiTemperatureMeanReading( ...
        temperatureC, startXY, endXY)

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
