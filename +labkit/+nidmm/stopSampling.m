function connection = stopSampling(sampler)
%STOPSAMPLING Stop NI-DMM acquisition and return the connected token.
%
% Usage:
%   connection = labkit.nidmm.stopSampling(sampler)
%
% Inputs:
%   sampler - Opaque token returned by labkit.nidmm.startSampling.
%
% Outputs:
%   connection - Configured connection token. The device remains open.
%
% Errors:
%   labkit:nidmm:InvalidSampler - The token is malformed.
%
% Typical Call:
%   connection = labkit.nidmm.stopSampling(sampler);
%
% See also labkit.nidmm.startSampling, labkit.nidmm.disconnect
state = requireSampler(sampler);
connection = state("connection");
if state("active")
    pollSampler(state);
end
state("active") = false;
timerValue = state("timer");
if isvalid(timerValue)
    stop(timerValue);
    delete(timerValue);
end
backend = state("backend");
backend.stopBuffered();
end
