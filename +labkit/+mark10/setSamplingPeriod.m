function sampler = setSamplingPeriod(sampler, period)
%SETSAMPLINGPERIOD Change the sampling timer period.
%
% Usage:
%   sampler = labkit.mark10.setSamplingPeriod(sampler,period)
%
% Description:
%   Changes the Base MATLAB background worker period without replacing the
%   serial connection or changing an App's independent presentation rate.
%
% Inputs:
%   sampler - Opaque token returned by labkit.mark10.startSampling.
%   period - New positive finite sampling period in seconds.
%
% Outputs:
%   sampler - The same opaque sampler token with its updated period.
%
% Errors:
%   labkit:mark10:InvalidSampler - Sampler is malformed or already stopped.
%   labkit:mark10:InvalidValue - Period is not a positive finite scalar.
%
% See also labkit.mark10.startSampling, labkit.mark10.stopSampling
state = requireMark10Sampler(sampler);
if state("stopped")
    error("labkit:mark10:InvalidSampler", ...
        "Cannot change the period of a stopped Mark-10 sampler.");
end
if ~(isnumeric(period) && isscalar(period) && isfinite(period) && period > 0)
    error("labkit:mark10:InvalidValue", ...
        "Mark-10 sampling period must be a positive finite scalar.");
end
[connection, ~] = mark10ServiceRequest(state("connection"), ...
    "setPeriod", struct("Period", double(period)));
mark10StoreState(state, "connection", connection);
mark10StoreState(state, "period", double(period));
end
