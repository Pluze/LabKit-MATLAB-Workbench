classdef (Hidden, Sealed) SessionLogProjection < handle
    %SESSIONLOGPROJECTION Filter one canonical Runtime session for display.
    % SessionLogViewer is the production caller. This class owns only
    % projection state: it never mutates or deletes the canonical event stream.

    properties (Access = private)
        Events
        TraceEnabled (1, 1) logical = false
        InMemoryTruncated (1, 1) logical = false
        RetainedRecordCount (1, 1) double = 0
        TotalRecordCount (1, 1) double = 0
        JournalAvailable (1, 1) logical = false
        JournalState (1, 1) string = "unavailable"
        DroppedRecordCount (1, 1) double = 0
        CoalescedRecordCount (1, 1) double = 0
        ExpiredSegmentCount (1, 1) double = 0
        DegradationReason (1, 1) string = ""
        ClearedThroughSequence (1, 1) double = 0
        LevelFilter (1, 1) string = "default"
        AudienceFilter (1, 1) string = "default"
        CategoryFilter (1, 1) string = ""
        RootActionFilter (1, 1) string = ""
        SearchText (1, 1) string = ""
    end

    properties (Constant, Access = private)
        RetainedViewLimit = 512
    end

    methods
        function obj = SessionLogProjection(snapshot)
            obj.Events = emptyEvents();
            if nargin > 0
                obj.update(snapshot);
            end
        end

        function update(obj, snapshot)
            snapshot = validateSnapshot(snapshot);
            obj.Events = snapshot.events(:);
            obj.TraceEnabled = snapshot.traceEnabled;
            obj.InMemoryTruncated = snapshot.inMemoryTruncated;
            obj.RetainedRecordCount = snapshot.retainedRecordCount;
            obj.TotalRecordCount = snapshot.totalRecordCount;
            obj.JournalAvailable = snapshot.journalAvailable;
            obj.JournalState = snapshot.journalState;
            obj.DroppedRecordCount = snapshot.droppedRecordCount;
            obj.CoalescedRecordCount = snapshot.coalescedRecordCount;
            obj.ExpiredSegmentCount = snapshot.expiredSegmentCount;
            obj.DegradationReason = snapshot.degradationReason;
        end

        function append(obj, record)
            record = validateRecord(record);
            obj.Events(end + 1, 1) = record;
            obj.TotalRecordCount = max( ...
                obj.TotalRecordCount + 1, double(record.sequence));
            if numel(obj.Events) > obj.RetainedViewLimit
                obj.Events(1) = [];
                obj.InMemoryTruncated = true;
            end
            obj.RetainedRecordCount = numel(obj.Events);
        end

        function setFilters(obj, varargin)
            options = labkit.app.internal.OptionParser.parse( ...
                "SessionLogProjection.setFilters", ...
                ["Level", "Audience", "Category", "RootAction", "Search"], ...
                varargin{:});
            if isfield(options, "Level")
                obj.LevelFilter = oneOf(options.Level, ...
                    ["default", "trace", "debug", "info", ...
                    "warning", "error", "critical"], "Level");
            end
            if isfield(options, "Audience")
                obj.AudienceFilter = oneOf(options.Audience, ...
                    ["default", "all", "user", "developer"], "Audience");
            end
            if isfield(options, "Category")
                obj.CategoryFilter = optionalText( ...
                    options.Category, "Category");
            end
            if isfield(options, "RootAction")
                obj.RootActionFilter = optionalText( ...
                    options.RootAction, "RootAction");
            end
            if isfield(options, "Search")
                obj.SearchText = lower(optionalText( ...
                    options.Search, "Search"));
            end
        end

        function clearView(obj)
            if isempty(obj.Events)
                return;
            end
            obj.ClearedThroughSequence = max( ...
                double([obj.Events.sequence]));
        end

        function projection = view(obj)
            selected = obj.filteredEvents();
            [rootActionIds, rootActionLabels] = ...
                actionChoices(obj.Events);
            projection = struct( ...
                "rows", rowsFor(selected), ...
                "events", selected, ...
                "severityCounts", severityCounts(selected), ...
                "categories", choices(string({obj.Events.category})), ...
                "rootActions", rootActionIds, ...
                "rootActionLabels", rootActionLabels, ...
                "notices", obj.notices(), ...
                "clearedThroughSequence", obj.ClearedThroughSequence);
        end

        function record = detail(obj, sequence)
            sequence = finiteInteger(sequence, "sequence");
            match = obj.Events( ...
                double([obj.Events.sequence]) == sequence);
            if isempty(match)
                record = [];
            else
                record = match(end);
            end
        end
    end

    methods (Access = private)
        function selected = filteredEvents(obj)
            selected = obj.Events;
            if isempty(selected)
                return;
            end
            sequence = double([selected.sequence]);
            keep = sequence > obj.ClearedThroughSequence;
            levels = lower(string({selected.severity}));
            audiences = lower(string({selected.audience}));
            if obj.LevelFilter == "default"
                rank = severityRank(levels);
                keep = keep & ((audiences == "user" & rank >= 3) | ...
                    rank >= 4);
            else
                keep = keep & severityRank(levels) >= ...
                    severityRank(obj.LevelFilter);
            end
            if obj.AudienceFilter == "user"
                keep = keep & audiences == "user";
            elseif obj.AudienceFilter == "developer"
                keep = keep & audiences == "developer";
            elseif obj.AudienceFilter == "default"
                rank = severityRank(levels);
                keep = keep & (audiences == "user" | rank >= 4);
            end
            if strlength(obj.CategoryFilter) > 0
                keep = keep & ...
                    string({selected.category}) == obj.CategoryFilter;
            end
            if strlength(obj.RootActionFilter) > 0
                keep = keep & ...
                    string({selected.rootActionId}) == ...
                    obj.RootActionFilter;
            end
            if strlength(obj.SearchText) > 0
                searchable = lower( ...
                    string({selected.eventName}) + " " + ...
                    string({selected.category}) + " " + ...
                    string({selected.message}));
                keep = keep & contains(searchable, obj.SearchText);
            end
            selected = selected(keep);
        end

        function value = notices(obj)
            value = strings(0, 1);
            if ~obj.TraceEnabled
                value(end + 1, 1) = ...
                    "TRACE detail is off; DEBUG lifecycle and all warnings and errors " + ...
                    "are still captured. Earlier TRACE detail is unavailable.";
            end
            if obj.InMemoryTruncated
                value(end + 1, 1) = ...
                    "Older in-memory records expired from the live view.";
            end
            if obj.CoalescedRecordCount > 0
                value(end + 1, 1) = ...
                    string(obj.CoalescedRecordCount) + ...
                    " repeated low-level record(s) were coalesced.";
            end
            if obj.ExpiredSegmentCount > 0
                value(end + 1, 1) = ...
                    string(obj.ExpiredSegmentCount) + ...
                    " older journal segment(s) expired.";
            end
            if obj.DroppedRecordCount > 0
                value(end + 1, 1) = ...
                    string(obj.DroppedRecordCount) + ...
                    " journal record(s) were dropped.";
            end
            if ~obj.JournalAvailable
                reason = obj.DegradationReason;
                if strlength(reason) == 0
                    reason = obj.JournalState;
                end
                value(end + 1, 1) = ...
                    "Persistent journal unavailable (" + reason + ").";
            end
        end
    end
end

function snapshot = validateSnapshot(snapshot)
fields = ["events", "traceEnabled", "inMemoryTruncated", ...
    "retainedRecordCount", "totalRecordCount", "journalAvailable", ...
    "journalState", "droppedRecordCount", "coalescedRecordCount", ...
    "expiredSegmentCount", "degradationReason"];
if ~isstruct(snapshot) || ~isscalar(snapshot) || ...
        ~isequal(string(fieldnames(snapshot)), fields.')
    error("labkit:app:runtime:InvariantFailure", ...
        "Session log snapshot is invalid.");
end
if ~(islogical(snapshot.traceEnabled) && ...
        isscalar(snapshot.traceEnabled)) || ...
        ~(islogical(snapshot.inMemoryTruncated) && ...
        isscalar(snapshot.inMemoryTruncated)) || ...
        ~(islogical(snapshot.journalAvailable) && ...
        isscalar(snapshot.journalAvailable))
    error("labkit:app:runtime:InvariantFailure", ...
        "Session log snapshot state is invalid.");
end
for name = ["retainedRecordCount", "totalRecordCount", ...
        "droppedRecordCount", "coalescedRecordCount", ...
        "expiredSegmentCount"]
    snapshot.(name) = finiteInteger(snapshot.(name), name);
end
snapshot.journalState = optionalText(snapshot.journalState, "journalState");
snapshot.degradationReason = optionalText( ...
    snapshot.degradationReason, "degradationReason");
if isempty(snapshot.events)
    snapshot.events = emptyEvents();
elseif ~isstruct(snapshot.events)
    error("labkit:app:runtime:InvariantFailure", ...
        "Session log snapshot events are invalid.");
else
    for index = 1:numel(snapshot.events)
        validateRecord(snapshot.events(index));
    end
end
end

function record = validateRecord(record)
fields = ["schemaVersion", "sequence", "timestampUtc", "elapsedSeconds", ...
    "severity", "audience", "category", "eventName", "message", ...
    "attributes", "sessionId", "appId", "operationId", ...
    "parentOperationId", "rootActionId", "operationResult", ...
    "stateDisposition", "durationSeconds", "exception"];
if ~isstruct(record) || ~isscalar(record) || ...
        ~isequal(string(fieldnames(record)), fields.')
    error("labkit:app:runtime:InvariantFailure", ...
        "Session log record is invalid.");
end
end

function value = rowsFor(events)
if isempty(events)
    value = table( ...
        strings(0, 1), strings(0, 1), strings(0, 1), ...
        strings(0, 1), zeros(0, 1), ...
        VariableNames=["Time", "Level", "Area", "Message", "Sequence"]);
    return;
end
value = table( ...
    string({events.timestampUtc}).', ...
    string({events.severity}).', ...
    string({events.category}).', ...
    string({events.message}).', ...
    double([events.sequence]).', ...
    VariableNames=["Time", "Level", "Area", "Message", "Sequence"]);
end

function value = severityCounts(events)
levels = ["TRACE", "DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"];
value = struct();
for level = levels
    value.(lower(level)) = sum(string({events.severity}) == level);
end
end

function value = choices(values)
values = values(strlength(values) > 0);
value = unique(values, "stable");
end

function [ids, labels] = actionChoices(events)
ids = choices(string({events.rootActionId}));
labels = strings(size(ids));
for index = 1:numel(ids)
    actionEvents = events( ...
        string({events.rootActionId}) == ids(index));
    labels(index) = actionLabel(actionEvents, ids(index));
end
end

function label = actionLabel(events, id)
first = events(1);
preferred = find( ...
    string({events.audience}) == "user" & ...
    strlength(string({events.message})) > 0, 1);
if isempty(preferred)
    severity = string({events.severity});
    preferred = find(any(severity.' == ...
        ["WARNING", "ERROR", "CRITICAL"], 2), 1);
end
if isempty(preferred)
    preferred = 1;
end
record = events(preferred);
summary = actionSummary(record, first);
if strlength(summary) > 72
    summary = extractBefore(summary, 70) + "...";
end
time = regexp(string(first.timestampUtc), ...
    '\d{2}:\d{2}:\d{2}', "match", "once");
if strlength(time) > 0
    label = time + "  " + summary + "  [" + id + "]";
else
    label = summary + "  [" + id + "]";
end
end

function summary = actionSummary(record, first)
summary = string(record.message);
generic = [
    "Dispatching callback."
    "Operation completed."
    "Operation failed."
    "Operation cancelled."
    "Operation abandoned."
    ];
if ~any(summary == generic)
    return;
end
if isfield(first.attributes, "runtimeAlias") && ...
        (ischar(first.attributes.runtimeAlias) || ...
        (isstring(first.attributes.runtimeAlias) && ...
        isscalar(first.attributes.runtimeAlias)))
    summary = "Callback: " + string(first.attributes.runtimeAlias);
    return;
end
eventName = erase(string(first.eventName), ".started");
summary = replace(eventName, [".", "_"], " ");
end

function value = severityRank(values)
values = lower(string(values));
legal = ["trace", "debug", "info", "warning", "error", "critical"];
value = zeros(size(values));
for index = 1:numel(legal)
    value(values == legal(index)) = index;
end
end

function value = oneOf(value, legal, name)
value = lower(optionalText(value, name));
if ~any(value == legal)
    error("labkit:app:contract:InvalidValue", ...
        "Session log %s filter is invalid.", name);
end
end

function value = optionalText(value, name)
if ~(ischar(value) || (isstring(value) && isscalar(value)))
    error("labkit:app:contract:InvalidValue", ...
        "Session log %s must be scalar text.", name);
end
value = string(value);
if ismissing(value)
    error("labkit:app:contract:InvalidValue", ...
        "Session log %s must not be missing.", name);
end
end

function value = finiteInteger(value, name)
if ~(isnumeric(value) && isreal(value) && isscalar(value) && ...
        isfinite(value) && value >= 0 && value == fix(value))
    error("labkit:app:contract:InvalidValue", ...
        "Session log %s must be a nonnegative integer.", name);
end
value = double(value);
end

function value = emptyEvents()
value = repmat(struct( ...
    "schemaVersion", 1, "sequence", 0, "timestampUtc", "", ...
    "elapsedSeconds", 0, "severity", "", "audience", "", ...
    "category", "", "eventName", "", "message", "", ...
    "attributes", struct(), "sessionId", "", "appId", "", ...
    "operationId", "", "parentOperationId", "", "rootActionId", "", ...
    "operationResult", "", "stateDisposition", "", ...
    "durationSeconds", [], "exception", struct()), 0, 1);
end
