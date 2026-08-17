function sampler = startSampling(connection, period, onSample)
%STARTSAMPLING Start background synchronized force/travel acquisition.
%
% Usage:
%   sampler = labkit.mark10.startSampling(connection,period,onSample)
%
% Description:
%   Starts acquisition in the persistent background driver that owns the
%   physical serial port. The driver timestamps samples at receipt and sends
%   them to the MATLAB client in batches. A lightweight delivery timer invokes
%   the consumer without allowing GUI rendering to set the acquisition pace.
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
%   labkit:mark10:InvalidConnection - Connection is malformed or is not a
%       background-owned connection.
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
if ~mark10IsServiceConnection(connection)
    error("labkit:mark10:InvalidConnection", ...
        "Sampling requires a background-owned Mark-10 connection.");
end

service = connection.Service;
service("consumer") = onSample;
[connection, ~] = mark10ServiceRequest( ...
    connection, "start", struct("Period", double(period)));
state = containers.Map("KeyType", "char", "ValueType", "any");
state("connection") = connection;
state("period") = double(period);
state("stopped") = false;
state("service") = service;
deliveryTimer = timer( ...
    "ExecutionMode", "fixedSpacing", "BusyMode", "drop", ...
    "Period", 0.05, "TimerFcn", @(~, ~) deliverSamples(state));
state("timer") = deliveryTimer;
try
    start(deliveryTimer);
catch cause
    service("consumer") = [];
    try
        mark10ServiceRequest(connection, "stop", struct());
    catch
    end
    delete(deliveryTimer);
    rethrow(cause);
end
sampler = struct("Type", "labkit.mark10.sampler", "State", state);
end

function deliverSamples(state)
if state("stopped")
    return;
end
service = state("service");
mark10ServiceDrain(service);
state("connection") = mark10ServiceConnection(service);
end
