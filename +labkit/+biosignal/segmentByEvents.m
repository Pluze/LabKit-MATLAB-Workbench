function segments = segmentByEvents(signal, events, windowSec)
%SEGMENTBYEVENTS Extract fixed windows around event anchors.

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
