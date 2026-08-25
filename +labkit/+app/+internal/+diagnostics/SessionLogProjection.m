classdef (Hidden, Sealed) SessionLogProjection < handle
    %SESSIONLOGPROJECTION Filter one canonical Runtime session by severity.
    % SessionLogViewer is the production caller. This class owns only display
    % projection state and never mutates the canonical event stream.

    properties (Access = private)
        Events
        EventBytes (1, :) double = zeros(1, 0)
        RetainedBytes (1, 1) double = 0
        TraceEnabled (1, 1) logical = false
        InMemoryTruncated (1, 1) logical = false
        JournalAvailable (1, 1) logical = false
        JournalState (1, 1) string = "unavailable"
        DroppedRecordCount (1, 1) double = 0
        CoalescedRecordCount (1, 1) double = 0
        ExpiredSegmentCount (1, 1) double = 0
        DegradationReason (1, 1) string = ""
        LevelFilter (1, 1) string = "trace"
    end

    properties (Constant, Access = private)
        RetainedViewLimit = 512
        RetainedViewByteLimit = 512 * 1024
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
            obj.InMemoryTruncated = snapshot.inMemoryTruncated;
            obj.rebuildByteAccounting();
            obj.enforceViewLimit();
            obj.TraceEnabled = snapshot.traceEnabled;
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
            recordBytes = utf8ByteCount(jsonencode(record));
            obj.EventBytes(end + 1) = recordBytes;
            obj.RetainedBytes = obj.RetainedBytes + recordBytes;
            obj.enforceViewLimit();
        end

        function setFilters(obj, varargin)
            options = labkit.app.internal.contract.OptionParser.parse( ...
                "SessionLogProjection.setFilters", "Level", varargin{:});
            if isfield(options, "Level")
                obj.LevelFilter = oneOf(options.Level, ...
                    ["trace", "debug", "info", "warning", ...
                    "error", "critical"], "Level");
            end
        end

        function projection = view(obj)
            selected = obj.filteredEvents();
            projection = struct( ...
                "rows", rowsFor(selected), ...
                "events", selected, ...
                "severityCounts", severityCounts(selected), ...
                "traceEnabled", obj.TraceEnabled, ...
                "notices", obj.notices());
        end

        function record = detail(obj, sequence)
            sequence = finiteInteger(sequence, "sequence");
            match = obj.Events(double([obj.Events.sequence]) == sequence);
            if isempty(match)
                record = [];
            else
                record = match(end);
            end
        end
    end

    methods (Access = private)
        function rebuildByteAccounting(obj)
            obj.EventBytes = zeros(1, numel(obj.Events));
            for index = 1:numel(obj.Events)
                obj.EventBytes(index) = utf8ByteCount(jsonencode(obj.Events(index)));
            end
            obj.RetainedBytes = sum(obj.EventBytes);
        end

        function enforceViewLimit(obj)
            while numel(obj.Events) > obj.RetainedViewLimit || ...
                    obj.RetainedBytes > obj.RetainedViewByteLimit
                obj.RetainedBytes = obj.RetainedBytes - obj.EventBytes(1);
                obj.Events(1) = [];
                obj.EventBytes(1) = [];
                obj.InMemoryTruncated = true;
            end
        end

        function selected = filteredEvents(obj)
            selected = obj.Events;
            if isempty(selected)
                return;
            end
            levels = lower(string({selected.severity}));
            selected = selected(severityRank(levels) >= ...
                severityRank(obj.LevelFilter));
        end

        function value = notices(obj)
            value = strings(0, 1);
            if ~obj.TraceEnabled
                value(end + 1, 1) = ...
                    "TRACE capture is disabled; DEBUG and higher detail is retained.";
            end
            if obj.InMemoryTruncated
                value(end + 1, 1) = ...
                    "Older in-memory records expired from the live view.";
            end
            if obj.CoalescedRecordCount > 0
                value(end + 1, 1) = string(obj.CoalescedRecordCount) + ...
                    " repeated low-level record(s) were coalesced.";
            end
            if obj.ExpiredSegmentCount > 0
                value(end + 1, 1) = string(obj.ExpiredSegmentCount) + ...
                    " older journal segment(s) expired.";
            end
            if obj.DroppedRecordCount > 0
                value(end + 1, 1) = string(obj.DroppedRecordCount) + ...
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
if ~(islogical(snapshot.traceEnabled) && isscalar(snapshot.traceEnabled)) || ...
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

function count = utf8ByteCount(value)
count = numel(unicode2native(char(string(value)), "UTF-8"));
end
