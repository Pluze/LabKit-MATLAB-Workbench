% Expected caller: FLIR thermal preview/export helpers. Input is one loaded
% item. Outputs are the display/export matrix, units token, and user-facing
% label. Prefers calibrated Celsius when available and falls back to raw signal.
function [values, units, label] = valueMatrix(item)

    values = [];
    units = "";
    label = "No thermal image";
    if isempty(item)
        return;
    end
    if isfield(item, 'temperatureC') && ~isempty(item.temperatureC) && ...
            any(isfinite(item.temperatureC), 'all')
        values = item.temperatureC;
        units = "C";
        label = "Temperature (deg C)";
    elseif isfield(item, 'raw') && ~isempty(item.raw)
        values = item.raw;
        units = "raw";
        label = "Raw thermal signal";
    end
end
