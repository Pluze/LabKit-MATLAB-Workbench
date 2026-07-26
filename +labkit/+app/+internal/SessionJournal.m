classdef (Hidden, Sealed) SessionJournal < handle
    %SESSIONJOURNAL Persist already-validated canonical session event records.
    % Expected callers are private SessionEventStream projection hooks and
    % focused framework tests. This store owns no semantic validation, Runtime
    % lifecycle policy, viewer projection, or App workflow behavior.

    properties (Access = private)
        Application
        RootFolder (1, 1) string
        SessionId (1, 1) string
        Folder (1, 1) string
        ManifestFile (1, 1) string
        ActiveFile (1, 1) string
        SegmentFile (1, 1) string = ""
        SegmentHandle (1, 1) double = -1
        SegmentIndex (1, 1) double = 0
        SegmentBytes (1, 1) double = 0
        BufferLines (1, :) string = strings(1, 0)
        BufferBytes (1, 1) double = 0
        StartedAt (1, 1) datetime
        Closed (1, 1) logical = false
        Available (1, 1) logical = false
        SegmentByteLimit (1, 1) double
        SegmentLimit (1, 1) double
        SessionByteLimit (1, 1) double
        BufferRecordLimit (1, 1) double
        BufferByteLimit (1, 1) double
        DroppedRecordCount (1, 1) double = 0
        CoalescedRecordCount (1, 1) double = 0
        ExpiredSegmentCount (1, 1) double = 0
        WriteFailureCount (1, 1) double = 0
        FaultInjector = []
        TestObserver = []
    end

    methods
        function obj = SessionJournal(application, varargin)
            if ~isa(application, "labkit.app.Definition") || ~isscalar(application)
                error("labkit:app:runtime:InvariantFailure", ...
                    "SessionJournal requires one Definition.");
            end
            options = parseOptions(varargin{:});
            obj.Application = application;
            obj.RootFolder = options.RootFolder;
            obj.SessionId = options.SessionId;
            obj.Folder = fullfile(obj.RootFolder, "sessions", obj.SessionId);
            obj.ManifestFile = fullfile(obj.Folder, "manifest.json");
            obj.ActiveFile = fullfile(obj.Folder, "active.json");
            obj.SegmentByteLimit = options.SegmentByteLimit;
            obj.SegmentLimit = options.SegmentLimit;
            obj.SessionByteLimit = options.SessionByteLimit;
            obj.BufferRecordLimit = options.BufferRecordLimit;
            obj.BufferByteLimit = options.BufferByteLimit;
            obj.FaultInjector = options.FaultInjector;
            obj.TestObserver = options.TestObserver;
            obj.StartedAt = datetime("now", TimeZone="UTC", ...
                Format="yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
            obj.initialize();
        end

        function append(obj, record)
            if obj.Closed || ~obj.Available
                return;
            end
            if ~isCanonicalRecord(record)
                obj.DroppedRecordCount = obj.DroppedRecordCount + 1;
                obj.writeManifest();
                return;
            end
            try
                line = string(jsonencode(record));
                lineBytes = utf8Bytes(line) + 1;
                if isFlushSeverity(record.severity)
                    obj.flush();
                end
                obj.BufferLines(end + 1) = line;
                obj.BufferBytes = obj.BufferBytes + lineBytes;
                if isFlushSeverity(record.severity) || ...
                        numel(obj.BufferLines) >= obj.BufferRecordLimit || ...
                        obj.BufferBytes >= obj.BufferByteLimit
                    obj.flush();
                end
            catch
                obj.recordWriteFailure();
            end
        end

        function flush(obj)
            if obj.Closed || ~obj.Available || isempty(obj.BufferLines)
                return;
            end
            try
                obj.ensureSegmentForBufferedRecords();
                obj.invokeFault("write");
                for index = 1:numel(obj.BufferLines)
                    fprintf(obj.SegmentHandle, "%s\n", obj.BufferLines(index));
                end
                obj.SegmentBytes = obj.SegmentBytes + obj.BufferBytes;
                obj.notifyObserver("flush", numel(obj.BufferLines));
                obj.BufferLines = strings(1, 0);
                obj.BufferBytes = 0;
                obj.writeActiveMarker();
                obj.enforceSessionRetention();
                obj.writeManifest();
            catch
                obj.recordWriteFailure();
            end
        end

        function close(obj)
            if obj.Closed
                return;
            end
            obj.flush();
            obj.closeSegment();
            obj.Closed = true;
            obj.removeActiveMarker();
            obj.writeManifest();
        end

        function folder = folder(obj)
            folder = obj.Folder;
        end

        function manifest = manifest(obj)
            manifest = manifestPayload(obj);
        end

        function delete(obj)
            obj.close();
        end
    end

    methods (Access = private)
        function initialize(obj)
            try
                obj.invokeFault("initialize");
                if exist(char(obj.Folder), "dir") ~= 7
                    mkdir(char(obj.Folder));
                end
                obj.Available = true;
                obj.writeActiveMarker();
                obj.writeManifest();
            catch
                obj.Available = false;
                obj.WriteFailureCount = obj.WriteFailureCount + 1;
            end
        end

        function ensureSegmentForBufferedRecords(obj)
            if obj.SegmentHandle < 0
                obj.openNextSegment();
            elseif obj.SegmentBytes + obj.BufferBytes > obj.SegmentByteLimit && ...
                    obj.SegmentBytes > 0
                obj.closeSegment();
                obj.openNextSegment();
            end
        end

        function openNextSegment(obj)
            obj.SegmentIndex = obj.SegmentIndex + 1;
            obj.SegmentFile = fullfile(obj.Folder, ...
                "events-" + compose("%04d", obj.SegmentIndex) + ".jsonl");
            obj.invokeFault("open");
            obj.SegmentHandle = fopen(char(obj.SegmentFile), "a", "n", "UTF-8");
            if obj.SegmentHandle < 0
                error("labkit:app:runtime:JournalWriteFailure", ...
                    "Could not open the active session segment.");
            end
            obj.SegmentBytes = fileBytes(obj.SegmentFile);
            obj.notifyObserver("open", obj.SegmentIndex);
        end

        function closeSegment(obj)
            if obj.SegmentHandle < 0
                return;
            end
            fclose(obj.SegmentHandle);
            obj.SegmentHandle = -1;
            obj.notifyObserver("close", obj.SegmentIndex);
        end

        function enforceSessionRetention(obj)
            segments = sessionSegments(obj.Folder);
            totalBytes = sum([segments.bytes]);
            while numel(segments) > obj.SegmentLimit || totalBytes > obj.SessionByteLimit
                candidate = segments(1);
                if string(fullfile(candidate.folder, candidate.name)) == obj.SegmentFile
                    break;
                end
                delete(fullfile(candidate.folder, candidate.name));
                obj.ExpiredSegmentCount = obj.ExpiredSegmentCount + 1;
                segments = sessionSegments(obj.Folder);
                totalBytes = sum([segments.bytes]);
            end
        end

        function recordWriteFailure(obj)
            obj.WriteFailureCount = obj.WriteFailureCount + 1;
            obj.closeSegment();
            obj.BufferLines = strings(1, 0);
            obj.BufferBytes = 0;
            obj.writeManifest();
            obj.Available = false;
        end

        function writeActiveMarker(obj)
            if ~obj.Available
                return;
            end
            atomicWriteJson(obj.ActiveFile, struct( ...
                "sessionId", obj.SessionId, "state", "active", ...
                "updatedAtUtc", utcNow()));
        end

        function removeActiveMarker(obj)
            if exist(char(obj.ActiveFile), "file") == 2
                delete(char(obj.ActiveFile));
            end
        end

        function writeManifest(obj)
            if ~obj.Available || exist(char(obj.Folder), "dir") ~= 7
                return;
            end
            try
                atomicWriteJson(obj.ManifestFile, manifestPayload(obj));
            catch
                obj.Available = false;
            end
        end

        function invokeFault(obj, stage)
            if ~isempty(obj.FaultInjector)
                obj.FaultInjector(stage);
            end
        end

        function notifyObserver(obj, stage, value)
            if isempty(obj.TestObserver)
                return;
            end
            try
                obj.TestObserver(stage, value);
            catch
            end
        end
    end
end

function options = parseOptions(varargin)
% These are provisional private bounds for the headless session journal:
% segment rotation avoids one unbounded file; five segments cap ordinary
% retained context; 64 records/64 KiB bound the in-memory write buffer.
% Focused tests inject smaller values to exercise each boundary deterministically.
options = struct( ...
    "RootFolder", string(fullfile(prefdir, "LabKit", "logs")), ...
    "SessionId", newSessionId(), ...
    "SegmentByteLimit", 10 * 1024 * 1024, ...
    "SegmentLimit", 5, ...
    "SessionByteLimit", 50 * 1024 * 1024, ...
    "BufferRecordLimit", 64, ...
    "BufferByteLimit", 64 * 1024, ...
    "FaultInjector", [], ...
    "TestObserver", []);
if mod(numel(varargin), 2) ~= 0
    error("labkit:app:contract:InvalidValue", ...
        "SessionJournal options must be name-value pairs.");
end
for index = 1:2:numel(varargin)
    name = string(varargin{index});
    if ~isfield(options, name)
        error("labkit:app:contract:InvalidValue", ...
            "Unknown SessionJournal option: %s.", name);
    end
    options.(name) = varargin{index + 1};
end
options.RootFolder = string(options.RootFolder);
options.SessionId = labkit.app.internal.SessionEventValidator.semanticIdentifier( ...
    options.SessionId, "SessionId");
for name = ["SegmentByteLimit", "SegmentLimit", "SessionByteLimit", ...
        "BufferRecordLimit", "BufferByteLimit"]
    value = options.(name);
    if ~(isnumeric(value) && isscalar(value) && isfinite(value) && value > 0 && ...
            value == fix(value))
        error("labkit:app:contract:InvalidValue", ...
            "SessionJournal %s must be a positive integer.", name);
    end
    options.(name) = double(value);
end
for name = ["FaultInjector", "TestObserver"]
    value = options.(name);
    if ~isempty(value) && ~isa(value, "function_handle")
        error("labkit:app:contract:InvalidValue", ...
            "SessionJournal %s must be a function handle.", name);
    end
end
end

function tf = isCanonicalRecord(record)
fields = [ ...
    "schemaVersion", "sequence", "timestampUtc", "elapsedSeconds", ...
    "severity", "audience", "category", "eventName", "message", ...
    "attributes", "sessionId", "appId", "operationId", ...
    "parentOperationId", "rootActionId", "outcome", "durationSeconds", ...
    "exception"];
tf = isstruct(record) && isscalar(record) && ...
    isequal(string(fieldnames(record)), fields.');
end

function tf = isFlushSeverity(severity)
tf = any(string(severity) == ["WARNING", "ERROR", "CRITICAL"]);
end

function segments = sessionSegments(folder)
segments = dir(fullfile(folder, "events-*.jsonl"));
if isempty(segments)
    return;
end
[~, order] = sort(string({segments.name}));
segments = segments(order);
end

function value = fileBytes(filepath)
info = dir(filepath);
if isempty(info)
    value = 0;
else
    value = info.bytes;
end
end

function value = utf8Bytes(text)
value = numel(unicode2native(char(text), "UTF-8"));
end

function payload = manifestPayload(obj)
segments = sessionSegments(obj.Folder);
payload = struct( ...
    "schemaVersion", 1, ...
    "sessionId", obj.SessionId, ...
    "appId", obj.Application.AppId, ...
    "state", ternary(obj.Closed, "closed", "active"), ...
    "startedAtUtc", string(obj.StartedAt), ...
    "updatedAtUtc", utcNow(), ...
    "segmentCount", numel(segments), ...
    "retainedBytes", sum([segments.bytes]), ...
    "degradation", struct( ...
    "droppedRecordCount", obj.DroppedRecordCount, ...
    "coalescedRecordCount", obj.CoalescedRecordCount, ...
    "expiredSegmentCount", obj.ExpiredSegmentCount, ...
    "writeFailureCount", obj.WriteFailureCount));
end

function value = ternary(condition, trueValue, falseValue)
if condition
    value = trueValue;
else
    value = falseValue;
end
end

function value = utcNow()
value = string(datetime("now", TimeZone="UTC", ...
    Format="yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"));
end

function value = newSessionId()
value = "session-" + string(datetime("now", Format="yyyyMMddHHmmssSSS")) + ...
    "-" + string(randi([0, 999999]));
end

function atomicWriteJson(filepath, payload)
temporary = string(tempname(fileparts(filepath)));
file = fopen(char(temporary), "w", "n", "UTF-8");
if file < 0
    error("labkit:app:runtime:JournalWriteFailure", ...
        "Could not write the session manifest.");
end
cleanup = onCleanup(@() fclose(file));
fprintf(file, "%s\n", jsonencode(payload, PrettyPrint=true));
clear cleanup
[moved, message] = movefile(char(temporary), char(filepath), "f");
if ~moved
    error("labkit:app:runtime:JournalWriteFailure", "%s", message);
end
end
