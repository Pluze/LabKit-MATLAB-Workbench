function value = configuration(sessionConfiguration)
%CONFIGURATION Convert App labels into one facade configuration request.
options = ni_dmm_recorder.measurement.options();
modeIndex = find(options.ModeLabels == sessionConfiguration.mode, 1);
if isempty(modeIndex)
    error("ni_dmm_recorder:InvalidMode", ...
        "Select a supported measurement mode.");
end
range = sessionConfiguration.fixedRange;
if sessionConfiguration.rangeMode == "Automatic"
    range = "auto";
elseif sessionConfiguration.rangeMode ~= "Fixed"
    error("ni_dmm_recorder:InvalidRangeMode", ...
        "Select Automatic or Fixed range.");
end
digits = str2double(sessionConfiguration.digits);
rate_Hz = sscanf(char(sessionConfiguration.rate), "%f Hz");
if ~(isscalar(rate_Hz) && isfinite(rate_Hz) && rate_Hz > 0)
    error("ni_dmm_recorder:InvalidRate", ...
        "Select a supported acquisition rate.");
end
value = struct("Mode", options.ModeValues(modeIndex), ...
    "Range", range, "Digits", digits, "Rate_Hz", rate_Hz);
end
