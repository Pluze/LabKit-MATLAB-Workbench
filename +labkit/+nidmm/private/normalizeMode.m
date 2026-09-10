function [mode, unit] = normalizeMode(value)
% Normalize one public NI-DMM mode and return its SI display unit.
if ~(ischar(value) || (isstring(value) && isscalar(value)))
    error("labkit:nidmm:InvalidMode", ...
        "NI-DMM mode must be a text scalar.");
end
mode = lower(strip(string(value)));
legal = ["dc_voltage", "ac_voltage", "dc_current", "ac_current", ...
    "resistance_2wire", "resistance_4wire", "diode"];
if ~any(mode == legal)
    error("labkit:nidmm:InvalidMode", ...
        "NI-DMM mode must be one of: %s.", strjoin(legal, ", "));
end
if contains(mode, "voltage") || mode == "diode"
    unit = "V";
elseif contains(mode, "current")
    unit = "A";
else
    unit = "ohm";
end
end
