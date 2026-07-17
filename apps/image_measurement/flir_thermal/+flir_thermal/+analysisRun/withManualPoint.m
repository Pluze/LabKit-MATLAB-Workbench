% Return one FLIR item with its manual point reading updated.
function [item, reading] = withManualPoint(item, pointXY)
    reading = flir_thermal.analysisRun.pointTemperatureReading( ...
        item.temperatureC, pointXY);
    if isfinite(reading.temperatureC)
        item.manualPoint = reading;
    end
end
