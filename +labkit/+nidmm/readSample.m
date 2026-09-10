function [connection, sample] = readSample(connection)
%READSAMPLE Read one configured NI-DMM value with host timing bounds.
%
% Usage:
%   [connection,sample] = labkit.nidmm.readSample(connection)
%
% Inputs:
%   connection - Configured token returned by labkit.nidmm.configure.
%
% Outputs:
%   connection - Unchanged opaque connection token.
%   sample - Scalar structure with Valid, Value, Unit, Mode, Range, Digits,
%       TimestampUTC, ReceivedAtUTC, TimeUncertainty_s, and FailureStatus.
%       TimestampUTC is the midpoint of the host-observed read interval.
%
% Errors:
%   labkit:nidmm:NotConfigured - Configuration has not been applied.
%   labkit:nidmm:ReadFailed - The device cannot complete the reading.
%
% Typical Call:
%   [connection,sample] = labkit.nidmm.readSample(connection);
%
% See also labkit.nidmm.configure, labkit.nidmm.startSampling
state = requireConnection(connection);
if ~state("configured")
    error("labkit:nidmm:NotConfigured", ...
        "Configure the NI-DMM connection before reading.");
end
configuration = state("configuration");
backend = state("backend");
result = backend.read();
sample = struct("Valid", isfinite(result.Value), ...
    "Value", result.Value, "Unit", configuration.Unit, ...
    "Mode", configuration.Mode, "Range", configuration.Range, ...
    "Digits", configuration.Digits, "Sequence", 1, ...
    "Elapsed_s", 0, "TimestampUTC", result.TimestampUTC, ...
    "ReceivedAtUTC", result.ReceivedAtUTC, ...
    "TimeUncertainty_s", result.TimeUncertainty_s, ...
    "FailureStatus", "");
if ~sample.Valid
    sample.FailureStatus = "nonfinite_reading";
end
end
