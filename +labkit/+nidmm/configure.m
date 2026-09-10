function [connection, configuration] = configure(connection, options)
%CONFIGURE Set an NI-DMM measurement mode, range, and resolution.
%
% Usage:
%   [connection,configuration] = labkit.nidmm.configure(connection)
%   [connection,configuration] = labkit.nidmm.configure(connection,Name=Value)
%
% Name-Value Options:
%   Mode - One of dc_voltage, ac_voltage, dc_current, ac_current,
%       resistance_2wire, resistance_4wire, or diode. Default:
%       resistance_4wire.
%   Range - Positive finite full-scale value in the output unit, or "auto".
%       Automatic range performs one settling measurement and locks the
%       resolved range before returning. Default: "auto".
%   Digits - Resolution digits: 4.5, 5.5, or 6.5. Default: 5.5.
%
% Outputs:
%   connection - Updated opaque connection token.
%   configuration - Scalar MATLAB structure with Mode, Unit, Range,
%       RangeMode, Digits, and MeasurementPeriod_s.
%
% Errors:
%   labkit:nidmm:InvalidMode - Mode is unknown.
%   labkit:nidmm:InvalidRange - Range is neither "auto" nor positive finite.
%   labkit:nidmm:InvalidDigits - Digits is unsupported.
%   labkit:nidmm:ConfigurationFailed - The driver rejects the configuration.
%
% Typical Call:
%   [connection,configuration] = labkit.nidmm.configure(connection, ...
%       Mode="resistance_4wire", Range=1000, Digits=5.5);
%
% See also labkit.nidmm.readSample, labkit.nidmm.startSampling
arguments
    connection (1, 1) struct
    options.Mode = "resistance_4wire"
    options.Range = "auto"
    options.Digits (1, 1) double = 5.5
end
state = requireConnection(connection);
[mode, unit] = normalizeMode(options.Mode);
requestedRange = normalizeRange(options.Range);
if ~any(options.Digits == [4.5, 5.5, 6.5])
    error("labkit:nidmm:InvalidDigits", ...
        "NI-DMM resolution must be 4.5, 5.5, or 6.5 digits.");
end
backend = state("backend");
actualRange = backend.configure(mode, requestedRange, options.Digits);
rangeMode = "fixed";
if isstring(requestedRange) && requestedRange == "auto"
    rangeMode = "auto_locked";
end
configuration = struct("Mode", mode, "Unit", unit, ...
    "Range", actualRange, "RangeMode", rangeMode, ...
    "Digits", options.Digits, ...
    "MeasurementPeriod_s", backend.measurementPeriod());
state("configured") = true;
state("configuration") = configuration;
connection.State = state;
connection.Configuration = configuration;
end

function value = normalizeRange(value)
if ischar(value) || (isstring(value) && isscalar(value))
    value = lower(strip(string(value)));
    if value == "auto"
        return;
    end
    error("labkit:nidmm:InvalidRange", ...
        "NI-DMM range text must be ""auto"".");
end
if ~(isnumeric(value) && isscalar(value) && isfinite(value) && value > 0)
    error("labkit:nidmm:InvalidRange", ...
        "NI-DMM fixed range must be a positive finite scalar.");
end
value = double(value);
end
