% App-owned calibration presentation helper. Expected callers are FLIR file
% list and detail-panel renderers. Input is one loaded app item. Output is a
% scalar status struct with severity, shortText, and detailText. No side effects.
function status = calibrationStatus(item)
%CALIBRATIONSTATUS Describe thermal conversion provenance for the user.

    status = struct( ...
        'severity', "unavailable", ...
        'shortText', "temperature unavailable", ...
        'detailText', "Temperature conversion unavailable; displaying raw signal.");
    if ~isfield(item, 'metadata') || ...
            ~isfield(item.metadata, 'temperatureConversion')
        return;
    end
    conversion = item.metadata.temperatureConversion;
    if ~isfield(conversion, 'available') || ~logical(conversion.available)
        return;
    end
    if isfield(conversion, 'usedDefaults') && logical(conversion.usedDefaults)
        fields = string(conversion.defaultedFields);
        status.severity = "warning";
        status.shortText = "calibration defaults used";
        status.detailText = "Warning: default thermal correction parameters used: " + ...
            strjoin(fields, ", ") + ". Absolute temperatures may be less accurate.";
        return;
    end
    correction = string(conversion.correction);
    status.severity = "calibrated";
    status.shortText = "embedded calibration";
    if correction == "planck-basic"
        status.detailText = "Calibration: embedded Planck parameters; environmental correction disabled.";
    else
        status.detailText = "Calibration: embedded FLIR parameters; no correction defaults used.";
    end
end
