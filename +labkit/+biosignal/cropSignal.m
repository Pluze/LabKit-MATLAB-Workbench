function cropped = cropSignal(signal, timeRangeSec)
%CROPSIGNAL Return a signal clipped to a time range in seconds.
%
% Usage:
%   cropped = labkit.biosignal.cropSignal(signal, timeRangeSec)
%   cropped = labkit.biosignal.cropSignal(signal)
%
% Description:
%   Keeps samples whose timestamps lie between the requested start and end
%   times, including both endpoints. For a nonempty result, time is shifted
%   so that the first retained sample occurs at zero. The sample rate is
%   recalculated from the median positive time step when at least two usable
%   timestamps remain; otherwise the input sample rate is preserved.
%
%   Omitting timeRangeSec or passing [] returns signal unchanged. A valid
%   range that contains no samples returns empty time and values vectors.
%
% Inputs:
%   signal - Biosignal structure with time, values, fs, and metadata fields.
%            time and values must describe corresponding samples.
%   timeRangeSec - Two-element numeric vector [startSec endSec], expressed
%                  on signal.time, with startSec less than endSec. The value
%                  may be omitted or empty to skip cropping.
%
% Outputs:
%   cropped - Copy of signal containing only the selected samples. The
%             original range is recorded in metadata.cropTimeRangeSec.
%
% Errors:
%   labkit:biosignal:InvalidSignal - signal does not contain time, values,
%                                   and fs fields.
%   labkit:biosignal:InvalidTimeRange - timeRangeSec is not an increasing
%                                      two-element vector.
%
% Example:
%   signal = struct('time', (0:0.5:3)', 'values', (10:16)', ...
%       'fs', 2, 'metadata', struct());
%   cropped = labkit.biosignal.cropSignal(signal, [0.75 2.25]);

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
