% Expected caller: response_review_stats.run or tests. Input is a table
% loaded from a segment CSV. Output is a struct array with name, timeSec, and
% values. No side effects.
function segments = parseSegmentTable(T)
%PARSESEGMENTTABLE Normalize supported segment CSV layouts.

    if ~istable(T)
        error("response_review_stats:InvalidSegmentTable", ...
            "Segment input must be a table.");
    end
    names = string(T.Properties.VariableNames);
    segments = struct("name", {}, "timeSec", {}, "values", {});

    timeIdx = find(normalizeName(names) == "times", 1);
    if isempty(timeIdx)
        timeIdx = find(normalizeName(names) == "time", 1);
    end
    if ~isempty(timeIdx)
        timeSec = double(T{:, timeIdx});
        signalIdx = setdiff(1:width(T), timeIdx);
        segmentCells = {};
        for k = signalIdx
            if ~isnumeric(T{:, k})
                continue;
            end
            segmentCells{end+1} = makeSegment(names(k), timeSec, ...
                double(T{:, k}));
        end
        if ~isempty(segmentCells)
            segments = [segmentCells{:}];
        end
        return;
    end

    timeCols = find(endsWith(normalizeName(names), "times"));
    segmentCells = {};
    for k = 1:numel(timeCols)
        timeCol = timeCols(k);
        prefix = erase(normalizeName(names(timeCol)), "times");
        signalCol = pairedSignalColumn(names, prefix, timeCol);
        if isempty(signalCol)
            continue;
        end
        label = erase(string(names(timeCol)), "_Time_s");
        label = erase(label, "_Time");
        segmentCells{end+1} = makeSegment(label, double(T{:, timeCol}), ...
            double(T{:, signalCol}));
    end
    if ~isempty(segmentCells)
        segments = [segmentCells{:}];
    end

    if isempty(segments)
        error("response_review_stats:UnsupportedSegmentTable", ...
            "Segment table must contain Time_s plus signal columns or paired segment time/signal columns.");
    end
end

function segment = makeSegment(name, timeSec, values)
    mask = isfinite(timeSec) & isfinite(values);
    segment = struct( ...
        "name", string(name), ...
        "timeSec", timeSec(mask), ...
        "values", values(mask));
end

function signalCol = pairedSignalColumn(names, prefix, timeCol)
    normalized = normalizeName(names);
    candidates = find(startsWith(normalized, prefix) & ...
        (endsWith(normalized, "signal") | endsWith(normalized, "value")));
    candidates = setdiff(candidates, timeCol);
    if isempty(candidates) && timeCol < numel(names)
        candidates = timeCol + 1;
    end
    signalCol = [];
    if ~isempty(candidates)
        signalCol = candidates(1);
    end
end

function out = normalizeName(value)
    out = lower(regexprep(string(value), "[^A-Za-z0-9]", ""));
end
