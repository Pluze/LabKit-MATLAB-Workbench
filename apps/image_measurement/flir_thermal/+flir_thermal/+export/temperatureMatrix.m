% Expected caller: FLIR thermal export helpers and tests. Input is one app
% item. Output is the calibrated Celsius matrix. Throws when no Celsius matrix
% is available; no file or GUI side effects.
function values = temperatureMatrix(item)

    values = [];
    if isfield(item, 'temperatureC')
        values = double(item.temperatureC);
    end
    if isempty(values) || ~any(isfinite(values), "all")
        error('labkit_FLIRThermal_app:NoCelsiusData', ...
            'No calibrated Celsius temperature matrix is available for %s.', ...
            char(string(item.name)));
    end
end
