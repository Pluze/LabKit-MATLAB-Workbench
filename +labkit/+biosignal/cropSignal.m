function cropped = cropSignal(signal, timeRangeSec)
%CROPSIGNAL Return a signal clipped to a time range in seconds.

    validateSignal(signal);
    if nargin < 2 || isempty(timeRangeSec)
        cropped = signal;
        return;
    end
    assert(numel(timeRangeSec) == 2 && timeRangeSec(1) < timeRangeSec(2), ...
        'labkit:biosignal:InvalidTimeRange', ...
        'Time range must be [startSec endSec].');

    t = double(signal.time(:));
    keep = t >= timeRangeSec(1) & t <= timeRangeSec(2);
    cropped = signal;
    cropped.time = t(keep);
    if ~isempty(cropped.time)
        cropped.time = cropped.time - cropped.time(1);
    end
    cropped.values = signal.values(keep);
    cropped.fs = inferFs(cropped.time, signal.fs);
    cropped.metadata.cropTimeRangeSec = double(timeRangeSec(:).');
end

function validateSignal(signal)
    assert(isstruct(signal) && isfield(signal, 'time') && ...
        isfield(signal, 'values') && isfield(signal, 'fs'), ...
        'labkit:biosignal:InvalidSignal', ...
        'Signal must contain time, values, and fs fields.');
end

function fs = inferFs(timeSec, fallback)
    fs = fallback;
    if numel(timeSec) < 2
        return;
    end
    dt = diff(double(timeSec(:)));
    dt = dt(isfinite(dt) & dt > 0);
    if ~isempty(dt)
        fs = 1 / median(dt);
    end
end
