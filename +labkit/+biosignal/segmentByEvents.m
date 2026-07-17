function segments = segmentByEvents(signal, events, windowSec)
%SEGMENTBYEVENTS Extract fixed windows around event anchors.
%
% Usage:
%   segments = labkit.biosignal.segmentByEvents(signal, events)
%   segments = labkit.biosignal.segmentByEvents(signal, events, windowSec)
%
% Description:
%   Extracts one fixed-length signal segment around each event index. Events
%   whose requested window would extend beyond the signal are omitted rather
%   than padded. The returned columns therefore correspond only to interior
%   events, and eventIndex and eventTime identify which events were retained.
%
%   Window boundaries are converted to sample counts by rounding after
%   multiplication by signal.fs. The default window is 0.35 seconds before
%   through 0.35 seconds after each event.
%
% Inputs:
%   signal - Biosignal structure with values, fs, and displayName fields.
%   events - Event structure returned by labkit.biosignal.detectEcgPeaks.
%            index contains 1-based sample positions and time contains the
%            corresponding event times.
%   windowSec - Optional two-element vector [startSec endSec] relative to an
%               event. Use a negative start and nonnegative end to span the
%               event. The default is [-0.35 0.35] seconds.
%
% Outputs:
%   segments - Structure containing the retained waveform segments.
%
% Output Fields:
%   type - String scalar "biosignalSegments".
%   values - M-by-N matrix with one retained event segment per column.
%   timeOffset - M-by-1 vector of sample times relative to the event.
%   eventIndex - N-by-1 source sample indices of retained events.
%   eventTime - N-by-1 source times of retained events.
%   fs - Sample rate in hertz copied from signal.
%   sourceName - signal.displayName.
%   metadata.windowSec - Requested window in seconds.
%
% Errors:
%   labkit:biosignal:InvalidSignal - signal lacks values or fs.
%   labkit:biosignal:InvalidEvents - events lacks index or time.
%   labkit:biosignal:InvalidWindow - windowSec is not an increasing
%                                   two-element vector.
%
% Example:
%   signal = struct('values', (1:21)', 'fs', 10, 'displayName', "ECG");
%   events = struct('index', [6; 16], 'time', [0.5; 1.5]);
%   segments = labkit.biosignal.segmentByEvents(signal, events, [-0.2 0.2]);
%
% See also labkit.biosignal.detectEcgPeaks,
%   labkit.biosignal.buildTemplate,
%   labkit.biosignal.measureSegments

    if nargin < 3 || isempty(windowSec)
        windowSec = [-0.35 0.35];
    end
    validateInputs(signal, events, windowSec);

    fs = double(signal.fs);
    pre = round(abs(min(windowSec)) * fs);
    post = round(max(windowSec) * fs);
    offsets = (-pre:post).' / fs;
    values = double(signal.values(:));

    keep = false(numel(events.index), 1);
    matrix = zeros(numel(offsets), numel(events.index));
    sourceIndex = zeros(numel(events.index), 1);
    n = 0;
    for k = 1:numel(events.index)
        center = events.index(k);
        i1 = center - pre;
        i2 = center + post;
        if i1 < 1 || i2 > numel(values)
            continue;
        end
        n = n + 1;
        matrix(:, n) = values(i1:i2);
        sourceIndex(n) = center;
        keep(k) = true;
    end

    segments = struct();
    segments.type = "biosignalSegments";
    segments.values = matrix(:, 1:n);
    segments.timeOffset = offsets;
    segments.eventIndex = sourceIndex(1:n);
    segments.eventTime = events.time(keep);
    segments.fs = fs;
    segments.sourceName = signal.displayName;
    segments.metadata = struct('windowSec', windowSec);
end

function validateInputs(signal, events, windowSec)
    assert(isstruct(signal) && isfield(signal, 'values') && isfield(signal, 'fs'), ...
        'labkit:biosignal:InvalidSignal', 'Invalid signal struct.');
    assert(isstruct(events) && isfield(events, 'index') && isfield(events, 'time'), ...
        'labkit:biosignal:InvalidEvents', 'Invalid events struct.');
    assert(numel(windowSec) == 2 && windowSec(1) < windowSec(2), ...
        'labkit:biosignal:InvalidWindow', ...
        'Segment window must be [startSec endSec].');
end
