classdef (Hidden, Sealed) SessionJournal < handle
    %SESSIONJOURNAL Buffered writer for full-detail canonical events.
    % This private projection owns one live session only. Reading retained
    % events for diagnostic export belongs to SessionJournalArchive.

    properties (Access = private)
        Application
        RootFolder (1, 1) string
        SessionId (1, 1) string
        Folder (1, 1) string
        ManifestFile (1, 1) string
        SegmentFile (1, 1) string = ""
        SegmentHandle (1, 1) double = -1
        SegmentIndex (1, 1) double = 0
        SegmentBytes (1, 1) double = 0
        BufferLines (1, :) string = strings(1, 0)
        BufferBytes (1, 1) double = 0
        StartedAt (1, 1) datetime
        Closed (1, 1) logical = false
        ClosedAtUtc (1, 1) string = ""
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
        InvalidRecordDropCount (1, 1) double = 0
        WriteFailureDropCount (1, 1) double = 0
        LastFailureReason (1, 1) string = ""
        DegradationReason (1, 1) string = ""
        LastCoalescingKey (1, 1) string = ""
        LastCoalescingElapsedSeconds (1, 1) double = -inf
        FaultInjector = []
        TestObserver = []
    end

    properties (Constant, Access = private)
        % Consecutive low-level duplicates only; terminal/visible events remain exact.
        CoalescingWindowSeconds = 1
    end

    methods
        function obj = SessionJournal(application, varargin)
            if ~isa(application, "labkit.app.Definition") || ~isscalar(application)
                error("labkit:app:runtime:InvariantFailure", ...
                    "SessionJournal requires one Definition.");
            end
            options = parseOptions(varargin{:});
            if strlength(options.RootFolder) == 0
                options.RootFolder = ...
                    labkit.app.internal.diagnostics.SessionJournal.defaultRootFolder();
            end
            obj.Application = application;
            obj.RootFolder = options.RootFolder;
            obj.SessionId = options.SessionId;
            obj.Folder = fullfile(obj.RootFolder, "sessions", obj.SessionId);
            obj.ManifestFile = fullfile(obj.Folder, "manifest.json");
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
            if obj.Closed
                return;
            end
            if ~obj.Available
                obj.recordUnavailableDrop();
                return;
            end
            if ~isCanonicalRecord(record)
                obj.DroppedRecordCount = obj.DroppedRecordCount + 1;
                obj.InvalidRecordDropCount = obj.InvalidRecordDropCount + 1;
                return;
            end
            try
                if isFlushSeverity(record.severity) && ~obj.flush( ...
                        DeferFailureManifest=true)
                    obj.recordUnavailableDrop();
                    obj.writeManifest(Force=true);
                    return;
                end
                candidateKey = obj.coalescingCandidateKey(record);
                if obj.shouldCoalesce(candidateKey, record.elapsedSeconds)
                    obj.CoalescedRecordCount = obj.CoalescedRecordCount + 1;
                    return;
                end
                line = string(jsonencode(record));
                lineBytes = utf8Bytes(line) + 1;
                obj.BufferLines(end + 1) = line;
                obj.BufferBytes = obj.BufferBytes + lineBytes;
                obj.rememberCoalescingCandidate(candidateKey, record.elapsedSeconds);
                if isFlushSeverity(record.severity) || ...
                        numel(obj.BufferLines) >= obj.BufferRecordLimit || ...
                        obj.BufferBytes >= obj.BufferByteLimit
                    obj.flush();
                end
            catch
                obj.recordWriteFailure("write-failure");
                obj.writeManifest(Force=true);
            end
        end

        function written = flush(obj, varargin)
            deferFailureManifest = false;
            if ~isempty(varargin)
                options = labkit.app.internal.contract.OptionParser.parse( ...
                    "SessionJournal.flush", "DeferFailureManifest", varargin{:});
                deferFailureManifest = optionValue(options, ...
                    "DeferFailureManifest", false);
            end
            written = false;
            if obj.Closed || ~obj.Available || isempty(obj.BufferLines)
                written = obj.Available;
                return;
            end
            failureReason = "open-failure";
            try
                obj.ensureSegmentForBufferedRecords();
                failureReason = "write-failure";
                obj.invokeFault("write");
                for index = 1:numel(obj.BufferLines)
                    fprintf(obj.SegmentHandle, "%s\n", obj.BufferLines(index));
                end
                obj.SegmentBytes = obj.SegmentBytes + obj.BufferBytes;
                obj.notifyObserver("flush", numel(obj.BufferLines));
                obj.BufferLines = strings(1, 0);
                obj.BufferBytes = 0;
                failureReason = "flush-failure";
                obj.enforceSessionRetention();
                written = obj.writeManifest();
            catch
                obj.recordWriteFailure(failureReason);
                if ~deferFailureManifest
                    obj.writeManifest(Force=true);
                end
            end
        end

        function close(obj)
            if obj.Closed
                return;
            end
            obj.flush();
            try
                obj.closeSegment();
            catch
                obj.recordPersistenceFailure("close-failure");
            end
            obj.Closed = true;
            obj.ClosedAtUtc = utcNow();
            obj.writeManifest(Force=true);
        end

        function folder = folder(obj)
            folder = obj.Folder;
        end

        function folder = rootFolder(obj)
            folder = obj.RootFolder;
        end

        function manifest = manifest(obj)
            manifest = manifestPayload(obj);
        end

        function sessionId = sessionId(obj)
            sessionId = obj.SessionId;
        end

        function snapshot = healthSnapshot(obj)
            % Return fixed in-memory health only; this method performs no I/O.
            try
                state = "healthy";
                if obj.Closed
                    state = "closed";
                elseif ~obj.Available
                    state = "unavailable";
                end
                snapshot = struct("state", state, "available", obj.Available, ...
                    "droppedRecordCount", obj.DroppedRecordCount, ...
                    "invalidCanonicalRecordDropCount", obj.InvalidRecordDropCount, ...
                    "writeFailureDropCount", obj.WriteFailureDropCount, ...
                    "writeFailureCount", obj.WriteFailureCount, ...
                    "lastFailureReason", obj.LastFailureReason, ...
                    "degradationReason", obj.DegradationReason);
            catch
                snapshot = struct("state", "unavailable", "available", false, ...
                    "droppedRecordCount", 0, "invalidCanonicalRecordDropCount", 0, ...
                    "writeFailureDropCount", 0, "writeFailureCount", 0, ...
                    "lastFailureReason", "health-unavailable", ...
                    "degradationReason", "health-unavailable");
            end
        end

        function delete(obj)
            obj.close();
        end
    end

    methods (Static)
        function folder = defaultRootFolder()
            % RuntimeFactory uses the installation-owned artifact boundary.
            folder = labkit.app.internal.artifact.Store.folder("logs");
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
                if ~obj.writeManifest()
                    return;
                end
            catch
                obj.recordPersistenceFailure("initialize-failure");
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

        function recordWriteFailure(obj, reason)
            if nargin < 2
                reason = "write-failure";
            end
            obj.WriteFailureCount = obj.WriteFailureCount + 1;
            dropped = numel(obj.BufferLines);
            obj.DroppedRecordCount = obj.DroppedRecordCount + dropped;
            obj.WriteFailureDropCount = obj.WriteFailureDropCount + dropped;
            obj.closeSegment();
            obj.BufferLines = strings(1, 0);
            obj.BufferBytes = 0;
            obj.Available = false;
            obj.LastFailureReason = string(reason);
            obj.rememberDegradationReason(reason);
            obj.LastCoalescingKey = "";
            obj.LastCoalescingElapsedSeconds = -inf;
        end

        function written = writeManifest(obj, varargin)
            written = false;
            force = false;
            if ~isempty(varargin)
                options = labkit.app.internal.contract.OptionParser.parse( ...
                    "SessionJournal.writeManifest", "Force", varargin{:});
                force = optionValue(options, "Force", false);
            end
            if (~obj.Available && ~force) || exist(char(obj.Folder), "dir") ~= 7
                return;
            end
            try
                obj.invokeFault("manifest");
                atomicWriteJson(obj.ManifestFile, manifestPayload(obj));
                obj.notifyObserver("manifest", []);
                written = true;
            catch
                obj.recordPersistenceFailure("manifest-failure");
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

        function key = coalescingCandidateKey(obj, record)
            key = "";
            if ~any(string(record.severity) == ["TRACE", "DEBUG"]) || ...
                    isTerminalRecord(record) || ~isEmptyException(record.exception)
                obj.LastCoalescingKey = "";
                obj.LastCoalescingElapsedSeconds = -inf;
                return;
            end
            key = coalescingKey(record);
        end

        function tf = shouldCoalesce(obj, key, elapsedSeconds)
            withinWindow = elapsedSeconds - obj.LastCoalescingElapsedSeconds <= ...
                obj.CoalescingWindowSeconds;
            tf = strlength(obj.LastCoalescingKey) > 0 && ...
                strlength(key) > 0 && obj.LastCoalescingKey == key && withinWindow;
        end

        function rememberCoalescingCandidate(obj, key, elapsedSeconds)
            if strlength(key) == 0
                return;
            end
            obj.LastCoalescingKey = key;
            obj.LastCoalescingElapsedSeconds = elapsedSeconds;
        end

        function recordUnavailableDrop(obj)
            obj.DroppedRecordCount = obj.DroppedRecordCount + 1;
            obj.WriteFailureDropCount = obj.WriteFailureDropCount + 1;
            if strlength(obj.LastFailureReason) == 0
                obj.LastFailureReason = "journal-unavailable";
            end
            obj.rememberDegradationReason("journal-unavailable");
        end

        function recordPersistenceFailure(obj, reason)
            obj.WriteFailureCount = obj.WriteFailureCount + 1;
            obj.LastFailureReason = string(reason);
            obj.rememberDegradationReason(reason);
            obj.Available = false;
        end

        function rememberDegradationReason(obj, reason)
            if strlength(obj.DegradationReason) == 0
                obj.DegradationReason = string(reason);
            end
        end
    end
end

function options = parseOptions(varargin)
% Provisional private bounds: rotation avoids one unbounded file; five
% segments cap ordinary context; 64 records/64 KiB bound buffered writes.
options = struct( ...
    "RootFolder", "", ...
    "SessionId", labkit.app.internal.diagnostics.SessionIdentity.create(), ...
    "SegmentByteLimit", 10 * 1024 * 1024, ...
    "SegmentLimit", 5, ...
    "SessionByteLimit", 50 * 1024 * 1024, ...
    "BufferRecordLimit", 64, ...
    "BufferByteLimit", 64 * 1024, ...
    "FaultInjector", [], "TestObserver", []);
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
options.SessionId = labkit.app.internal.diagnostics.SessionEventValidator.semanticIdentifier( ...
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
    if ~isempty(options.(name)) && ~isa(options.(name), "function_handle")
        error("labkit:app:contract:InvalidValue", ...
            "SessionJournal %s must be a function handle.", name);
    end
end
end

function value = optionValue(options, name, defaultValue)
value = defaultValue;
if isfield(options, name)
    value = options.(name);
end
end

function tf = isCanonicalRecord(record)
fields = ["schemaVersion", "sequence", "timestampUtc", "elapsedSeconds", ...
    "severity", "audience", "category", "eventName", "message", ...
    "attributes", "sessionId", "appId", "operationId", ...
    "parentOperationId", "rootActionId", "operationResult", "stateDisposition", "durationSeconds", ...
    "exception"];
tf = isstruct(record) && isscalar(record) && ...
    isequal(string(fieldnames(record)), fields.') && ...
    labkit.app.internal.diagnostics.SessionEventValidator.canonicalTerminalPair( ...
    record.operationResult, record.stateDisposition);
end

function tf = isFlushSeverity(severity)
tf = any(string(severity) == ["WARNING", "ERROR", "CRITICAL"]);
end

function tf = isTerminalRecord(record)
terminalNames = ["completed", "failed", "abandoned"];
tf = strlength(string(record.operationResult)) > 0 || any(endsWith( ...
    string(record.eventName), "." + terminalNames));
end

function tf = isEmptyException(exception)
tf = isstruct(exception) && isscalar(exception) && ...
    isfield(exception, "identifier") && strlength(string(exception.identifier)) == 0;
end

function key = coalescingKey(record)
key = string(jsonencode(struct( ...
    "severity", record.severity, "audience", record.audience, ...
    "category", record.category, "eventName", record.eventName, ...
    "message", record.message, "attributes", record.attributes, ...
    "operationId", record.operationId, ...
    "parentOperationId", record.parentOperationId, ...
    "rootActionId", record.rootActionId)));
end

function segments = sessionSegments(folder)
segments = dir(fullfile(folder, "events-*.jsonl"));
if ~isempty(segments)
    [~, order] = sort(string({segments.name}));
    segments = segments(order);
end
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
payload = struct("schemaVersion", 1, "sessionId", obj.SessionId, ...
    "appId", obj.Application.AppId, "state", ternary(obj.Closed, "closed", "active"), ...
    "startedAtUtc", string(obj.StartedAt), "closedAtUtc", obj.ClosedAtUtc, ...
    "updatedAtUtc", utcNow(), "segmentCount", numel(segments), ...
    "retainedBytes", sum([segments.bytes]), "degradation", struct( ...
    "droppedRecordCount", obj.DroppedRecordCount, ...
    "dropReasons", struct("invalidCanonicalRecord", obj.InvalidRecordDropCount, ...
    "writeFailure", obj.WriteFailureDropCount), ...
    "coalescedRecordCount", obj.CoalescedRecordCount, ...
    "coalescing", struct("reason", "repeated-low-severity", ...
    "windowSeconds", obj.CoalescingWindowSeconds), ...
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
