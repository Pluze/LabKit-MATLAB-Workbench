% Expected caller: FLIR thermal runner and tests. Inputs are one item and an
% image point. Output is the item with manualPoint updated. Side effects: none.
function [item, reading] = withManualPoint(item, pointXY)

    reading = flir_thermal.analysisRun.pointTemperatureReading( ...
        item.temperatureC, pointXY);
    if isfinite(reading.temperatureC)
        item.manualPoint = reading;
    end
end
