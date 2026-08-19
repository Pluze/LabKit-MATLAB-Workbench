function sampler = startSampling(connection, period, onSample)
%STARTSAMPLING Start background synchronized force/travel acquisition.
%
% Usage:
%   sampler = labkit.mark10.startSampling(connection,period,onSample)
%
% Description:
%   Starts absolute-deadline acquisition on the persistent Base MATLAB
%   background worker that owns the serial port. The worker timestamps real
%   responses and sends bounded batches to a lightweight client delivery
%   timer, so GUI rendering cannot set the acquisition pace.
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
mark10StoreState(service, "consumer", onSample);
try
    [connection, ~] = mark10ServiceRequest( ...
        connection, "start", struct("Period", double(period)));
catch cause
    mark10StoreState(service, "consumer", []);
    rethrow(cause);
end
state = containers.Map("KeyType", "char", "ValueType", "any");
mark10StoreState(state, "connection", connection);
mark10StoreState(state, "period", double(period));
mark10StoreState(state, "stopped", false);
mark10StoreState(state, "service", service);
deliveryTimer = timer( ...
    "ExecutionMode", "fixedSpacing", "BusyMode", "drop", ...
    "Period", 0.05, "TimerFcn", @(~, ~) deliverSamples(state));
mark10StoreState(state, "timer", deliveryTimer);
try
    start(deliveryTimer);
catch cause
    mark10StoreState(service, "consumer", []);
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
mark10StoreState(state, "connection", mark10ServiceConnection(service));
end
