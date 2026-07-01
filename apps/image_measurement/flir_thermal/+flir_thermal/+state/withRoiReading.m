% Expected caller: FLIR thermal runner and tests. Inputs are one item, ROI
% mode, and two image points. Output is the item with only that ROI result
% updated plus the computed ROI mean. Side effects: none.
function [item, meanReading] = withRoiReading(item, mode, startXY, endXY)

    [hotSpot, coldSpot, meanReading] = ...
        flir_thermal.ops.roiTemperatureMeanReading( ...
        item.temperatureC, startXY, endXY);
    if ~isfinite(meanReading.temperatureC)
        return;
    end

    switch string(mode)
        case "hot"
            item.roiHotSpot = hotSpot;
            item.roiHotBox = roiBoxFromMean(meanReading);
        case "cold"
            item.roiColdSpot = coldSpot;
            item.roiColdBox = roiBoxFromMean(meanReading);
        otherwise
            item.roiMean = meanReading;
    end
end

function box = roiBoxFromMean(reading)
    box = struct('x', reading.x, 'y', reading.y, ...
        'width', reading.width, 'height', reading.height, ...
        'pixelCount', reading.pixelCount);
end
