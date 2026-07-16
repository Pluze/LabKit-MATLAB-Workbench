% Expected caller: response_review_stats.run or tests. Input is a segment
% struct array and optional alignment/baseline options. Output is an aligned
% matrix data model. No side effects.
function aligned = alignSegments(segments, opts)
%ALIGNSEGMENTS Interpolate segment traces to a shared time grid.
%   aligned = response_review_stats.analysisRun.alignSegments(segments, opts)
%   accepts a struct array with timeSec, values, name, and optional
%   alignTimeSec. opts may contain sampleIntervalSec, windowSec,
%   baselineWindowSec, and alignTimeSec. Missing sample interval uses the
%   median positive source step; an unavailable interval falls back to 1e-4 s.
%
%   Output fields are timeSec, values (samples-by-segments), segmentNames, and
%   status. Linear interpolation returns NaN outside each source range. An
%   omitted window uses the intersection shared by all segments. Empty input
%   returns a stable empty model with status "empty". No side effects.
%
%   See also response_review_stats.analysisRun.measureAlignedSegments.

    if nargin < 2 || isempty(opts)
        opts = struct();
    end
    if isempty(segments)
        aligned = struct("timeSec", zeros(0, 1), "values", zeros(0, 0), ...
            "segmentNames", strings(0, 1), "status", "empty");
        return;
    end

    dt = double(fieldOrDefault(opts, "sampleIntervalSec", estimateDt(segments)));
    if ~isfinite(dt) || dt <= 0
        % Constant: 100 microseconds provides a 10 kHz fallback grid when
        % segment timestamps cannot supply a valid sample interval.
        fallbackSampleIntervalSec = 1e-4;
        dt = fallbackSampleIntervalSec;
    end
    windowSec = fieldOrDefault(opts, "windowSec", []);
    if isempty(windowSec)
        [starts, stops] = alignedTimeBounds(segments, opts);
        windowSec = [max(starts) min(stops)];
    end
    grid = (windowSec(1):dt:windowSec(2)).';
    values = NaN(numel(grid), numel(segments));
    segmentNames = strings(numel(segments), 1);
    baselineWindowSec = fieldOrDefault(opts, "baselineWindowSec", []);

    for k = 1:numel(segments)
        timeSec = double(segments(k).timeSec(:));
        trace = double(segments(k).values(:));
        alignTimeSec = double(fieldOrDefault(segments(k), "alignTimeSec", ...
            fieldOrDefault(opts, "alignTimeSec", 0)));
        timeSec = timeSec - alignTimeSec;
        [timeSec, uniqueIdx] = unique(timeSec, "stable");
        trace = trace(uniqueIdx);
        values(:, k) = interp1(timeSec, trace, grid, "linear", NaN);
        if ~isempty(baselineWindowSec)
            mask = grid >= baselineWindowSec(1) & grid <= baselineWindowSec(2);
            if any(mask)
                values(:, k) = values(:, k) - mean(values(mask, k), "omitnan");
            end
        end
        segmentNames(k) = string(segments(k).name);
    end

    aligned = struct( ...
        "timeSec", grid, ...
        "values", values, ...
        "segmentNames", segmentNames, ...
        "status", "ok");
end

function [starts, stops] = alignedTimeBounds(segments, opts)
    starts = NaN(size(segments));
    stops = NaN(size(segments));
    for k = 1:numel(segments)
        alignTimeSec = double(fieldOrDefault(segments(k), "alignTimeSec", ...
            fieldOrDefault(opts, "alignTimeSec", 0)));
        alignedTimeSec = double(segments(k).timeSec(:)) - alignTimeSec;
        starts(k) = min(alignedTimeSec);
        stops(k) = max(alignedTimeSec);
    end
end

function value = fieldOrDefault(S, fieldName, defaultValue)
    value = defaultValue;
    if isstruct(S) && isfield(S, fieldName)
        value = S.(fieldName);
    end
end

function dt = estimateDt(segments)
    stepCells = cell(numel(segments), 1);
    for k = 1:numel(segments)
        t = double(segments(k).timeSec(:));
        if numel(t) > 1
            stepCells{k} = diff(t);
        end
    end
    stepCells = stepCells(~cellfun("isempty", stepCells));
    steps = [];
    if ~isempty(stepCells)
        steps = vertcat(stepCells{:});
    end
    steps = steps(isfinite(steps) & steps > 0);
    if isempty(steps)
        dt = NaN;
    else
        dt = median(steps);
    end
end
