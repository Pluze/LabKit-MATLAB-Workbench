% Return one FLIR item with the selected ROI reading updated.
function [item, meanReading] = withRoiReading(item, mode, startXY, endXY)
    [hotSpot, coldSpot, meanReading] = ...
        flir_thermal.analysisRun.roiTemperatureMeanReading( ...
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
