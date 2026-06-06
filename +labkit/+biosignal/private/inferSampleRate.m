% Private biosignal helper. Expected caller: labkit.biosignal facade and
% internal import/recording pipeline. Inputs and outputs use internal signal,
% recording, time, or option values. Side effects: file reads only in importer
% helpers; assumes public callers own workflow validation and user-facing errors.
function fs = inferSampleRate(timeSec)
%INFERSAMPLERATE Estimate sampling frequency from a seconds time vector.
%
% Inputs:
%   timeSec - numeric time vector in seconds.
%
% Output:
%   fs - median positive-sample-interval estimate in Hz. Returns NaN when
%        fewer than two usable increasing time samples are available.
%
% Notes:
%   Non-finite, zero, and negative intervals are ignored so repaired CSV
%   time axes can still produce a stable sample-rate estimate.

    fs = NaN;
    if numel(timeSec) < 2
        return;
    end
    dt = diff(double(timeSec(:)));
    dt = dt(isfinite(dt) & dt > 0);
    if isempty(dt)
        return;
    end
    fs = 1 / median(dt);
end
