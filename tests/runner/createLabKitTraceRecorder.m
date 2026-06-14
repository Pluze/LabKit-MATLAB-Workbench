function recorder = createLabKitTraceRecorder(varargin)
%CREATELABKITTRACERECORDER Create a structured diagnostic trace recorder.
%
% Expected caller: official tests and future GUI diagnostics. The returned
% struct exposes record, events, writeJsonl, and writeText function handles.
% Trace details are sanitized to avoid local paths and sensitive sample tokens.

    p = inputParser;
    p.addParameter("AppName", "", @(v) ischar(v) || isstring(v));
    p.addParameter("TestName", "", @(v) ischar(v) || isstring(v));
    p.addParameter("RunId", "", @(v) ischar(v) || isstring(v));
    p.addParameter("SessionId", "", @(v) ischar(v) || isstring(v));
    p.addParameter("Level", "info", @(v) ischar(v) || isstring(v));
    p.parse(varargin{:});

    state.events = struct([]);
    state.seq = 0;
    state.start = tic;

    defaults = p.Results;
    if strlength(string(defaults.RunId)) == 0
        defaults.RunId = defaultRunId();
    end

    recorder = struct();
    recorder.record = @record;
    recorder.events = @events;
    recorder.writeJsonl = @writeJsonl;
    recorder.writeText = @writeText;
    recorder.runId = string(defaults.RunId);

    function eventRecord = record(component, eventName, reason, details, varargin)
        if nargin < 4
            details = struct();
        end
        local = parseRecordOptions(defaults, varargin{:});
        reason = validatestring(char(reason), ...
            {'user', 'internal', 'programmatic', 'test'});
        state.seq = state.seq + 1;
        eventRecord = struct( ...
            "schemaVersion", 1, ...
            "timestamp", string(datetime("now", "TimeZone", "UTC", ...
                "Format", "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")), ...
            "elapsedMs", round(toc(state.start) * 1000, 3), ...
            "seq", state.seq, ...
            "runId", string(local.RunId), ...
            "appName", string(local.AppName), ...
            "testName", string(local.TestName), ...
            "component", string(component), ...
            "event", string(eventName), ...
            "reason", string(reason), ...
            "level", string(local.Level), ...
            "sessionId", string(local.SessionId), ...
            "details", sanitizeDetails(details));
        state.events = appendEvent(state.events, eventRecord);
    end

    function value = events()
        value = state.events;
    end

    function writeJsonl(filepath)
        writeLabKitJsonlArtifact(filepath, state.events);
    end

    function writeText(filepath)
        writeLabKitTextArtifact(filepath, renderLabKitTraceText(state.events));
    end
end

function opts = parseRecordOptions(defaults, varargin)
    p = inputParser;
    p.addParameter("AppName", defaults.AppName, @(v) ischar(v) || isstring(v));
    p.addParameter("TestName", defaults.TestName, @(v) ischar(v) || isstring(v));
    p.addParameter("RunId", defaults.RunId, @(v) ischar(v) || isstring(v));
    p.addParameter("SessionId", defaults.SessionId, @(v) ischar(v) || isstring(v));
    p.addParameter("Level", defaults.Level, @(v) ischar(v) || isstring(v));
    p.parse(varargin{:});
    opts = p.Results;
end

function events = appendEvent(events, eventRecord)
    if isempty(events)
        events = eventRecord;
    else
        events(end+1) = eventRecord;
    end
end

function runId = defaultRunId()
    runId = "run-" + string(datetime("now", "Format", "yyyyMMdd'T'HHmmssSSS")) ...
        + "-" + string(randi([100000, 999999]));
end

function value = sanitizeDetails(value)
    if isstruct(value)
        fields = fieldnames(value);
        for k = 1:numel(value)
            for f = 1:numel(fields)
                field = fields{f};
                if isSensitiveField(field)
                    value(k).(field) = "[redacted]";
                else
                    value(k).(field) = sanitizeDetails(value(k).(field));
                end
            end
        end
    elseif iscell(value)
        for k = 1:numel(value)
            value{k} = sanitizeDetails(value{k});
        end
    elseif ischar(value) || isstring(value)
        value = sanitizeText(value);
    end
end

function tf = isSensitiveField(field)
    field = lower(string(field));
    tokens = ["path", "filepath", "filename", "sourcefile", ...
        "subject", "user", "device", "serial", "timestamp"];
    tf = any(contains(field, tokens));
end

function value = sanitizeText(value)
    value = string(value);
    values = cellstr(value);
    driveRootPattern = "[A-Za-z]:[\\/]";
    homePathPattern = "(^|[^A-Za-z0-9])[/\\](Users|home)[/\\]";
    dateTokenPattern = "\d{4}[-_]\d{2}[-_]\d{2}";
    sensitive = ~cellfun(@isempty, regexp(values, driveRootPattern, "once")) ...
        | ~cellfun(@isempty, regexp(values, homePathPattern, "once")) ...
        | ~cellfun(@isempty, regexp(values, dateTokenPattern, "once"));
    value(sensitive) = "[redacted]";
end
