function connection = stopSampling(sampler)
%STOPSAMPLING Stop background sampling and return the current connection.
%
% Usage:
%   connection = labkit.mark10.stopSampling(sampler)
%
% Description:
%   Stops client batch delivery, asks the background driver to stop reading,
%   and delivers its final batch before returning. The operation is idempotent
%   and leaves the serial port connected.
%
% Inputs:
%   sampler - Opaque token returned by labkit.mark10.startSampling.
%
% Outputs:
%   connection - Updated Mark-10 connection containing the final sample
%       count, acquisition mode, and last failure.
%
% Errors:
%   labkit:mark10:InvalidSampler - Sampler token is malformed.
%
% Typical Call:
%   connection = labkit.mark10.stopSampling(sampler);
%
% See also labkit.mark10.startSampling, labkit.mark10.disconnect
state = requireMark10Sampler(sampler);
connection = stopMark10SamplingState(state);
end
