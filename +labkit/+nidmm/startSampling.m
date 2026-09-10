function sampler = startSampling(connection, period, onSamples)
%STARTSAMPLING Begin hardware-paced buffered NI-DMM acquisition.
%
% Usage:
%   sampler = labkit.nidmm.startSampling(connection,period,onSamples)
%
% Description:
%   Starts NI-DMM multipoint interval acquisition and drains completed values
%   with a lightweight Base MATLAB timer. No backgroundPool worker is used,
%   leaving the Base MATLAB worker available to another device facade.
%
% Inputs:
%   connection - Configured token returned by labkit.nidmm.configure.
%   period - Requested positive sample interval in seconds, at least 0.001.
%   onSamples - Callback invoked as callback(connection,samples), where
%       samples is a column structure array of one or more real readings.
%
% Outputs:
%   sampler - Opaque token accepted by labkit.nidmm.stopSampling.
%
% Errors:
%   labkit:nidmm:InvalidValue - Inputs are malformed.
%   labkit:nidmm:NotConfigured - Configuration has not been applied.
%   labkit:nidmm:AcquisitionFailed - Buffered acquisition cannot start.
%
% Typical Call:
%   sampler = labkit.nidmm.startSampling(connection,0.02,@consumeSamples);
%   cleanup = onCleanup(@() labkit.nidmm.stopSampling(sampler));
%
% See also labkit.nidmm.stopSampling, labkit.nidmm.readSample
state = requireConnection(connection);
if ~state("configured")
    error("labkit:nidmm:NotConfigured", ...
        "Configure the NI-DMM connection before starting acquisition.");
end
if ~(isnumeric(period) && isscalar(period) && isfinite(period) && period >= 0.001)
    error("labkit:nidmm:InvalidValue", ...
        "NI-DMM sampling period must be a finite scalar of at least 0.001 seconds.");
end
if ~(isa(onSamples, "function_handle") && isscalar(onSamples) && ...
        nargin(onSamples) == 2)
    error("labkit:nidmm:InvalidValue", ...
        "NI-DMM sample callback must accept connection and samples inputs.");
end
backend = state("backend");
timing = backend.startBuffered(double(period));
samplerState = containers.Map("KeyType", "char", "ValueType", "any");
samplerState("backend") = backend;
samplerState("connection") = connection;
samplerState("configuration") = state("configuration");
samplerState("timing") = timing;
samplerState("onSamples") = onSamples;
samplerState("active") = true;
samplerState("failure") = [];
deliveryTimer = timer("ExecutionMode", "fixedSpacing", ...
    "Period", 0.05, "BusyMode", "drop", ...
    "TimerFcn", @(~, ~) pollSampler(samplerState));
samplerState("timer") = deliveryTimer;
sampler = struct("Type", "labkit.nidmm.sampler", "State", samplerState, ...
    "StartedAtUTC", timing.StartedAtUTC, ...
    "RequestedPeriod_s", double(period));
start(deliveryTimer);
end
