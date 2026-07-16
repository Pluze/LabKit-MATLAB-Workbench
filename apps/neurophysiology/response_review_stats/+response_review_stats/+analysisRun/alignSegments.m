function aligned = alignSegments(segments, opts)
%ALIGNSEGMENTS Interpolate segment traces to a shared time grid.
%
% Usage:
%   aligned = response_review_stats.analysisRun.alignSegments(segments)
%   aligned = response_review_stats.analysisRun.alignSegments(segments, opts)
%
% Description:
%   Shifts each segment's time axis to a common alignment origin, constructs a
%   shared uniformly spaced grid, and linearly interpolates every trace onto
%   that grid. Duplicate source timestamps retain their first sample. Values
%   outside a segment's aligned source range remain NaN. An optional baseline
%   subtraction is performed after interpolation.
%
% Inputs:
%   segments - Structure array with timeSec and values vectors of matching
%       length and a name value for each segment. A segment-specific
%       alignTimeSec may identify the source time that should become zero.
%   opts - Optional scalar structure containing the alignment options below.
%
% Options:
%   sampleIntervalSec - Positive output-grid interval in seconds. When omitted,
%       the median of every finite positive source time difference is used. If
%       no source supplies a usable difference, the fallback is 0.0001 seconds.
%   windowSec - Two-element [start end] output interval in aligned seconds.
%       When omitted, the function uses the intersection of all source ranges
%       after alignment-time shifts.
%   alignTimeSec - Global source time shifted to zero for segments without their
%       own alignTimeSec field. Default: 0 seconds.
%   baselineWindowSec - Optional inclusive [start end] interval in aligned
%       seconds. The finite mean in this output-grid interval is subtracted from
%       the entire corresponding segment. Default: no subtraction.
%
% Outputs:
%   aligned - Scalar structure with these fields:
%
% Aligned Fields:
%   timeSec - G-by-1 uniformly spaced aligned time vector in seconds.
%   values - G-by-N double matrix with one interpolated segment per column.
%   segmentNames - N-by-1 string vector copied from segments.name.
%   status - "ok", or "empty" when segments is empty.
%
% Example:
%   segments = struct( ...
%       "timeSec", {[10; 11; 12], [20; 21; 22]}, ...
%       "values", {[1; 2; 3], [4; 5; 6]}, ...
%       "name", {"first", "second"}, ...
%       "alignTimeSec", {10, 20});
%   aligned = response_review_stats.analysisRun.alignSegments( ...
%       segments, struct("sampleIntervalSec", 1));
%   assert(isequal(aligned.timeSec, [0; 1; 2]))
%   assert(isequal(aligned.values, [1 4; 2 5; 3 6]))
%
% See also response_review_stats.analysisRun.measureAlignedSegments,
%   response_review_stats.analysisRun.summarizeMetrics

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
