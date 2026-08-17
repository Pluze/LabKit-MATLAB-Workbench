function connection = connect(port, varargin)
%CONNECT Open a background-owned ESM303 connection.
%
% Usage:
%   connection = labkit.mark10.connect(port)
%   connection = labkit.mark10.connect(port,Timeout=seconds)
%
% Description:
%   Starts one persistent background driver worker which exclusively owns
%   the physical serial port from Connect through Disconnect. Device
%   acquisition therefore continues while MATLAB's client thread renders a
%   GUI. The returned token is a command-and-snapshot proxy; callers never
%   own or transfer the serialport object.
%
% Inputs:
%   port - Nonempty scalar serial port name.
%
% Options:
%   Timeout - Positive scalar response timeout in seconds. Default: 0.3.
%
% Outputs:
%   connection - Opaque token for other labkit.mark10 functions.
%
% Errors:
%   labkit:mark10:InvalidValue - Port or Timeout is malformed.
%   labkit:mark10:ConnectionFailed - The worker cannot open or probe the
%       selected ESM303.
%
% See also labkit.mark10.disconnect, labkit.mark10.startSampling
port = string(port);
if ~isscalar(port) || strlength(strip(port)) == 0
    error("labkit:mark10:InvalidValue", ...
        "Mark-10 port must be nonempty scalar text.");
end
p = inputParser;
p.FunctionName = "labkit.mark10.connect";
p.addParameter("Timeout", 0.3, @(v) isnumeric(v) && isscalar(v) && ...
    isfinite(v) && v > 0);
p.parse(varargin{:});
timeout = double(p.Results.Timeout);

events = parallel.pool.PollableDataQueue;
service = containers.Map("KeyType", "char", "ValueType", "any");
service("commands") = [];
service("events") = events;
service("responses") = containers.Map("KeyType", "char", "ValueType", "any");
service("nextRequestId") = uint64(0);
service("consumer") = [];
service("metadata") = struct();
service("closed") = false;
service("future") = parfeval(backgroundPool, @mark10ServiceLoop, 0, ...
    port, timeout, events);
try
    ready = mark10ServiceAwait(service, "ready", max(15, 10 * timeout));
catch cause
    stopService(service);
    if startsWith(string(cause.identifier), "labkit:mark10:")
        rethrow(cause);
    end
    failure = MException("labkit:mark10:ConnectionFailed", ...
        "Could not open or probe Mark-10 port %s.", port);
    failure = addCause(failure, cause);
    throwAsCaller(failure);
end
service("metadata") = ready.Metadata;
service("commands") = ready.Payload{1};
connection = mark10ServiceConnection(service);
end

function stopService(service)
service("closed") = true;
future = service("future");
if ~isempty(future) && isvalid(future) && string(future.State) ~= "finished"
    cancel(future);
end
end
