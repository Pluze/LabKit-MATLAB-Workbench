function connection = connect(port, varargin)
%CONNECT Open an ESM303 connection.
%
% Usage:
%   connection = labkit.mark10.connect(port)
%   connection = labkit.mark10.connect(port,Timeout=seconds)
%
% Description:
%   Opens and probes one physical serial port using Base MATLAB. The opaque
%   returned token owns the serial transport until disconnect. Sampling is
%   paced separately by startSampling without exposing timer or transport
%   details to Apps.
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
%   labkit:mark10:ConnectionFailed - The selected ESM303 cannot be opened or
%       probed.
%
% See also labkit.mark10.disconnect, labkit.mark10.startSampling
connection = mark10ConnectLocal(port, varargin{:});
end
