function projection = projectSessionLog(snapshot, level)
%PROJECTSESSIONLOG Project the canonical retained snapshot without another buffer.
% The Runtime owns retention and health. The viewer supplies its closed severity
% selector and keeps this result only while the corresponding rows are displayed.
selected = snapshot.events(:);
if ~isempty(selected)
    selected = selected(severityRank({selected.severity}) >= severityRank(level));
end
projection = struct( ...
    "rows", rowsFor(selected), "events", selected, ...
    "severityCounts", severityCounts(selected), ...
    "traceEnabled", snapshot.traceEnabled, "notices", notices(snapshot));
end

function value = notices(snapshot)
value = strings(0, 1);
if ~snapshot.traceEnabled
    value(end + 1, 1) = ...
        "TRACE capture is disabled; DEBUG and higher detail is retained.";
end
if snapshot.inMemoryTruncated
    value(end + 1, 1) = ...
        "Older in-memory records expired from the live view.";
end
if snapshot.coalescedRecordCount > 0
    value(end + 1, 1) = string(snapshot.coalescedRecordCount) + ...
        " repeated low-level record(s) were coalesced.";
end
if snapshot.expiredSegmentCount > 0
    value(end + 1, 1) = string(snapshot.expiredSegmentCount) + ...
        " older journal segment(s) expired.";
end
if snapshot.droppedRecordCount > 0
    value(end + 1, 1) = string(snapshot.droppedRecordCount) + ...
        " journal record(s) were dropped.";
end
if ~snapshot.journalAvailable
    reason = snapshot.degradationReason;
    if strlength(reason) == 0
        reason = snapshot.journalState;
    end
    value(end + 1, 1) = ...
        "Persistent journal unavailable (" + reason + ").";
end
end

function value = rowsFor(events)
if isempty(events)
    value = table(strings(0, 1), strings(0, 1), strings(0, 1), ...
        strings(0, 1), zeros(0, 1), ...
        VariableNames=["Time", "Level", "Area", "Message", "Sequence"]);
    return;
end
value = table(string({events.timestampUtc}).', ...
    string({events.severity}).', string({events.category}).', ...
    string({events.message}).', double([events.sequence]).', ...
    VariableNames=["Time", "Level", "Area", "Message", "Sequence"]);
end

function value = severityCounts(events)
levels = ["TRACE", "DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"];
value = struct();
for level = levels
    value.(lower(level)) = sum(string({events.severity}) == level);
end
end

function value = severityRank(values)
values = lower(string(values));
legal = ["trace", "debug", "info", "warning", "error", "critical"];
value = zeros(size(values));
for index = 1:numel(legal)
    value(values == legal(index)) = index;
end
end
