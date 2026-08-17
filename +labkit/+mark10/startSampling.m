function sampler = startSampling(connection, period, onSample)
%STARTSAMPLING Start paced synchronized force/travel acquisition.
%
% Usage:
%   sampler = labkit.mark10.startSampling(connection,period,onSample)
%
% Description:
%   Uses a Base MATLAB fixed-rate timer to request samples at the specified
%   period. Busy callbacks are dropped instead of queued, so delayed work does
%   not create a stale backlog. Each completed sample is timestamped at receipt
%   and delivered directly to the consumer. Apps remain independent of the
%   timer implementation and can keep presentation slower than acquisition.
%
% Inputs:
%   connection - Opaque token returned by labkit.mark10.connect.
%   period - Requested positive sampling period in seconds.
%   onSample - Function handle called as onSample(connection,sample).
%
% Outputs:
%   sampler - Opaque token accepted by labkit.mark10.stopSampling.
%
% Errors:
%   labkit:mark10:InvalidConnection - Connection is malformed.
%   labkit:mark10:InvalidValue - Period or callback is malformed.
%
% Typical Call:
%   sampler = labkit.mark10.startSampling(connection,0.02,@consumeSample);
%   cleanup = onCleanup(@() labkit.mark10.stopSampling(sampler));
%
% See also labkit.mark10.stopSampling, labkit.mark10.connect
connection = requireMark10Connection(connection);
if ~(isnumeric(period) && isscalar(period) && isfinite(period) && period > 0)
    error("labkit:mark10:InvalidValue", ...
        "Mark-10 sampling period must be a positive finite scalar.");
end
if ~isa(onSample, "function_handle")
    error("labkit:mark10:InvalidValue", ...
        "Mark-10 sample consumer must be a function handle.");
end
callbackInputs = nargin(onSample);
if callbackInputs >= 0 && callbackInputs ~= 2
    error("labkit:mark10:InvalidValue", ...
        "Mark-10 sample consumer must accept connection and sample inputs.");
end
connection = mark10EnsureForceConvention(connection);
state = containers.Map("KeyType", "char", "ValueType", "any");
state("connection") = connection;
state("period") = double(period);
state("stopped") = false;
state("consumer") = onSample;
state("started") = tic;
% Let the owning App transaction publish its starting view before polling.
startupDeferral_s = 0.25;
samplingTimer = timer( ...
    "ExecutionMode", "fixedRate", "BusyMode", "drop", ...
    "StartDelay", startupDeferral_s, "Period", double(period), ...
    "TimerFcn", @(~, ~) acquireSample(state));
state("timer") = samplingTimer;
try
    start(samplingTimer);
catch cause
    delete(samplingTimer);
    rethrow(cause);
end
sampler = struct("Type", "labkit.mark10.sampler", "State", state);
end

function acquireSample(state)
if state("stopped")
    return;
end
connection = state("connection");
[connection, sample] = labkit.mark10.readSample(connection);
sample.HostTime_s = toc(state("started"));
state("connection") = connection;
consumer = state("consumer");
consumer(connection, sample);
end
