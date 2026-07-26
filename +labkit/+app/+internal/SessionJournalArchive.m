classdef (Hidden, Sealed) SessionJournalArchive
    %SESSIONJOURNALARCHIVE Inspect, recover, retain, and export closed journals.
    % This private archive boundary never receives live events or decides their
    % privacy semantics; it consumes only the canonical journal representation.

    methods (Static)
        function inspection = inspect(rootFolder, varargin)
            options = parseOptions(varargin{:});
            inspection = inspectRoot(string(rootFolder), options);
        end

        function snapshot = snapshot(rootFolder, sessionId)
            sessionId = semanticSessionId(sessionId, "SessionId");
            rootFolder = string(rootFolder);
            folder = fullfile(rootFolder, "sessions", sessionId);
            manifest = readJson(fullfile(folder, "manifest.json"));
            if isempty(manifest)
                error("labkit:app:runtime:JournalUnavailable", ...
                    "The requested session journal is unavailable.");
            end
            [events, corruptRecordCount] = readCanonicalEvents(folder);
            retention = readJson(fullfile(rootFolder, "retention.json"));
            if isempty(retention)
                retention = emptyRetention();
            end
            snapshot = struct("manifest", manifest, "events", events, ...
                "timeline", timeline(events), "degradation", ...
                degradation(manifest, retention, corruptRecordCount), ...
                "redaction", redactionMetadata());
        end

        function exportFolder = exportSnapshot(rootFolder, sessionId, exportFolder)
            snapshot = labkit.app.internal.SessionJournalArchive.snapshot( ...
                rootFolder, sessionId);
            exportFolder = string(exportFolder);
            if exist(char(exportFolder), "dir") ~= 7
                mkdir(char(exportFolder));
            end
            atomicJson(fullfile(exportFolder, "manifest.json"), snapshot.manifest);
            writeEvents(fullfile(exportFolder, "events.jsonl"), snapshot.events);
            writeLines(fullfile(exportFolder, "timeline.txt"), snapshot.timeline);
            atomicJson(fullfile(exportFolder, "degradation.json"), snapshot.degradation);
            atomicJson(fullfile(exportFolder, "redaction.json"), snapshot.redaction);
        end
    end
end

function options = parseOptions(varargin)
% These migration-ledger hypotheses bound stale sessions until profiling fixes
% the production contract. Global storage equals five ordinary App budgets.
options = struct("ClosedSessionLimitPerApp", 10, "ClosedSessionAgeDays", 14, ...
    "AppByteLimit", 50 * 1024 * 1024, "GlobalByteLimit", 250 * 1024 * 1024, ...
    "ProtectedSessionIds", strings(0, 1));
if mod(numel(varargin), 2) ~= 0
    error("labkit:app:contract:InvalidValue", ...
        "SessionJournalArchive options must be name-value pairs.");
end
for index = 1:2:numel(varargin)
    name = string(varargin{index});
    if ~isfield(options, name)
        error("labkit:app:contract:InvalidValue", ...
            "Unknown SessionJournalArchive option: %s.", name);
    end
    options.(name) = varargin{index + 1};
end
for name = ["ClosedSessionLimitPerApp", "ClosedSessionAgeDays", ...
        "AppByteLimit", "GlobalByteLimit"]
    value = options.(name);
    if ~(isnumeric(value) && isscalar(value) && isfinite(value) && value >= 0 && ...
            value == fix(value))
        error("labkit:app:contract:InvalidValue", ...
            "SessionJournalArchive %s must be a nonnegative integer.", name);
    end
    options.(name) = double(value);
end
options.ProtectedSessionIds = string(options.ProtectedSessionIds(:));
for index = 1:numel(options.ProtectedSessionIds)
    options.ProtectedSessionIds(index) = semanticSessionId( ...
        options.ProtectedSessionIds(index), "ProtectedSessionId");
end
end

function inspection = inspectRoot(rootFolder, options)
sessionRoot = fullfile(rootFolder, "sessions");
if exist(char(sessionRoot), "dir") ~= 7
    inspection = struct("retention", emptyRetention(), "sessionCount", 0, ...
        "recoveredSessionCount", 0, "corruptTailCount", 0);
    return;
end
sessions = discover(sessionRoot);
recoveredSessionCount = 0;
corruptTailCount = 0;
for index = 1:numel(sessions)
    if any(sessions(index).SessionId == options.ProtectedSessionIds)
        continue;
    end
    [didRecover, tailCount] = recover(sessions(index).Folder);
    recoveredSessionCount = recoveredSessionCount + didRecover;
    corruptTailCount = corruptTailCount + tailCount;
end
sessions = discover(sessionRoot);
[sessions, retention] = prune(sessions, options);
retention.recoveredSessionCount = recoveredSessionCount;
retention.corruptTailCount = corruptTailCount;
retention.updatedAtUtc = utcNow();
atomicJson(fullfile(rootFolder, "retention.json"), retention);
inspection = struct("retention", retention, "sessionCount", numel(sessions), ...
    "recoveredSessionCount", recoveredSessionCount, "corruptTailCount", corruptTailCount);
end

function sessions = discover(sessionRoot)
folders = dir(sessionRoot);
folders = folders([folders.isdir]);
folders = folders(~ismember(string({folders.name}), [".", ".."]));
template = struct("Folder", "", "SessionId", "", "State", "", ...
    "AppId", "", "Timestamp", "", "Bytes", 0);
sessions = repmat(template, 0, 1);
for index = 1:numel(folders)
    folder = string(fullfile(folders(index).folder, folders(index).name));
    manifest = readJson(fullfile(folder, "manifest.json"));
    if isempty(manifest) || ~isfield(manifest, "sessionId") || ...
            ~isfield(manifest, "state") || ~isfield(manifest, "appId")
        continue;
    end
    try
        sessionId = semanticSessionId(manifest.sessionId, "SessionId");
    catch
        continue;
    end
    sessions(end + 1, 1) = struct("Folder", folder, "SessionId", sessionId, ...
        "State", string(manifest.state), "AppId", string(manifest.appId), ...
        "Timestamp", sessionTimestamp(manifest), "Bytes", folderBytes(folder));
end
end

function [didRecover, corruptTailCount] = recover(folder)
manifestFile = fullfile(folder, "manifest.json");
manifest = readJson(manifestFile);
didRecover = false;
corruptTailCount = 0;
if isempty(manifest)
    return;
end
segments = journalSegments(folder);
for index = 1:numel(segments)
    if recoverTail(fullfile(segments(index).folder, segments(index).name))
        corruptTailCount = corruptTailCount + 1;
    end
end
if corruptTailCount > 0
    manifest.recovery = recoveryMetadata(manifest, corruptTailCount, false);
    didRecover = true;
end
if string(manifest.state) == "active"
    manifest.state = "abandoned";
    manifest.abandonedAtUtc = utcNow();
    manifest.recovery = recoveryMetadata(manifest, corruptTailCount, true);
    active = fullfile(folder, "active.json");
    if exist(char(active), "file") == 2
        delete(char(active));
    end
    didRecover = true;
end
if didRecover
    manifest.updatedAtUtc = utcNow();
    atomicJson(manifestFile, manifest);
end
end

function metadata = recoveryMetadata(manifest, tailCount, abandoned)
metadata = struct("corruptTailCount", tailCount, "inspectedAtUtc", utcNow(), ...
    "abandoned", abandoned);
if isfield(manifest, "recovery") && isstruct(manifest.recovery) && ...
        isfield(manifest.recovery, "corruptTailCount")
    metadata.corruptTailCount = double(manifest.recovery.corruptTailCount) + tailCount;
end
end

function didRecover = recoverTail(filepath)
didRecover = false;
content = fileread(char(filepath));
if isempty(content)
    return;
end
breaks = find(content == char(10));
starts = [1, breaks + 1];
ends = [breaks - 1, numel(content)];
for index = numel(starts):-1:1
    line = strtrim(string(content(starts(index):ends(index))));
    if strlength(line) == 0
        continue;
    end
    try
        record = jsondecode(line);
        if ~isCanonicalRecord(record)
            error("labkit:app:runtime:JournalCorruptTail", ...
                "The final journal record is not canonical.");
        end
    catch
        truncate(filepath, content(1:starts(index) - 1));
        didRecover = true;
    end
    return;
end
end

function [sessions, retention] = prune(sessions, options)
retention = emptyRetention();
expiry = datetime("now", TimeZone="UTC") - days(options.ClosedSessionAgeDays);
for index = 1:numel(sessions)
    if isPrunable(sessions(index), options.ProtectedSessionIds) && ...
            parseUtc(sessions(index).Timestamp) < expiry
        removeSession(sessions(index).Folder);
        sessions(index).State = "deleted";
        retention.expiredSessionCount = retention.expiredSessionCount + 1;
    end
end
sessions = sessions(string({sessions.State}) ~= "deleted");
for appId = unique(string({sessions.AppId}))
    candidates = find(string({sessions.AppId}) == appId);
    [sessions, removed] = enforce(sessions, candidates, ...
        options.ClosedSessionLimitPerApp, options.AppByteLimit, ...
        options.ProtectedSessionIds);
    retention.perAppPrunedSessionCount = retention.perAppPrunedSessionCount + removed;
    retainedAppSessions = find(string({sessions.AppId}) == appId);
    retainedAppBytes = sum([sessions(retainedAppSessions).Bytes]);
    if retainedAppBytes > options.AppByteLimit
        retention.unsatisfiedAppIds(end + 1, 1) = appId;
    end
end
[sessions, removed] = enforce(sessions, 1:numel(sessions), inf, ...
    options.GlobalByteLimit, options.ProtectedSessionIds);
retention.globalPrunedSessionCount = retention.globalPrunedSessionCount + removed;
retention.retainedGlobalBytes = sum([sessions.Bytes]);
retention.unsatisfiedGlobalByteLimit = ...
    retention.retainedGlobalBytes > options.GlobalByteLimit;
end

function [sessions, removed] = enforce(sessions, candidates, countLimit, byteLimit, protected)
removed = 0;
while true
    scope = candidates(candidates <= numel(sessions));
    removable = scope(arrayfun(@(index) isPrunable(sessions(index), protected), scope));
    if isempty(removable) || ...
            (numel(removable) <= countLimit && sum([sessions(scope).Bytes]) <= byteLimit)
        return;
    end
    [~, order] = sort(string({sessions(removable).Timestamp}) + "|" + ...
        string({sessions(removable).SessionId}));
    removeIndex = removable(order(1));
    removeSession(sessions(removeIndex).Folder);
    sessions(removeIndex) = [];
    candidates = candidates(candidates ~= removeIndex);
    candidates(candidates > removeIndex) = candidates(candidates > removeIndex) - 1;
    removed = removed + 1;
end
end

function tf = isPrunable(session, protected)
tf = any(session.State == ["closed", "abandoned"]) && ...
    ~any(session.SessionId == protected);
end

function removeSession(folder)
if exist(char(folder), "dir") == 7
    rmdir(char(folder), "s");
end
end

function retention = emptyRetention()
retention = struct("expiredSessionCount", 0, "perAppPrunedSessionCount", 0, ...
    "globalPrunedSessionCount", 0, "recoveredSessionCount", 0, ...
    "corruptTailCount", 0, "retainedGlobalBytes", 0, ...
    "unsatisfiedAppIds", strings(0, 1), "unsatisfiedGlobalByteLimit", false, ...
    "updatedAtUtc", "");
end

function value = sessionTimestamp(manifest)
for field = ["closedAtUtc", "abandonedAtUtc", "updatedAtUtc", "startedAtUtc"]
    if isfield(manifest, field) && strlength(string(manifest.(field))) > 0
        value = string(manifest.(field));
        return;
    end
end
value = "";
end

function value = parseUtc(text)
try
    value = datetime(text, InputFormat="yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", ...
        TimeZone="UTC");
catch
    value = NaT(TimeZone="UTC");
end
end

function value = folderBytes(folder)
children = dir(folder);
value = 0;
for index = 1:numel(children)
    if ismember(string(children(index).name), [".", ".."])
        continue;
    end
    child = fullfile(children(index).folder, children(index).name);
    if children(index).isdir
        value = value + folderBytes(child);
    else
        value = value + children(index).bytes;
    end
end
end

function [events, corruptRecordCount] = readCanonicalEvents(folder)
events = repmat(canonicalTemplate(), 0, 1);
corruptRecordCount = 0;
segments = journalSegments(folder);
for segmentIndex = 1:numel(segments)
    lines = splitlines(string(fileread(fullfile(segments(segmentIndex).folder, ...
        segments(segmentIndex).name))));
    for lineIndex = 1:numel(lines)
        line = strtrim(lines(lineIndex));
        if strlength(line) == 0
            continue;
        end
        try
            record = jsondecode(line);
            if ~isCanonicalRecord(record)
                error("labkit:app:runtime:JournalCorruptRecord", ...
                    "A retained journal record is not canonical.");
            end
            events(end + 1, 1) = record;
        catch
            corruptRecordCount = corruptRecordCount + 1;
        end
    end
end
end

function template = canonicalTemplate()
template = struct("schemaVersion", [], "sequence", [], "timestampUtc", "", ...
    "elapsedSeconds", [], "severity", "", "audience", "", "category", "", ...
    "eventName", "", "message", "", "attributes", struct(), "sessionId", "", ...
    "appId", "", "operationId", "", "parentOperationId", "", ...
    "rootActionId", "", "operationResult", "", "stateDisposition", "", ...
    "durationSeconds", [], "exception", struct());
end

function value = timeline(events)
value = strings(numel(events), 1);
for index = 1:numel(events)
    value(index) = string(events(index).timestampUtc) + " [" + ...
        string(events(index).severity) + "] " + string(events(index).category) + ...
        " - " + string(events(index).message);
end
end

function value = degradation(manifest, retention, corruptRecordCount)
if isfield(manifest, "degradation")
    value = manifest.degradation;
else
    value = struct();
end
if isfield(manifest, "recovery")
    value.recovery = manifest.recovery;
end
value.snapshotCorruptRecordCount = corruptRecordCount;
value.retention = retention;
end

function value = redactionMetadata()
value = struct("semanticEventPrivacy", "validated-before-retention", ...
    "exportProjection", "canonical-safe-events-only", ...
    "excludedData", ["paths", "filenames", "input-content", ...
        "scientific-data", "workspace-values"]);
end

function writeEvents(filepath, events)
file = fopen(char(filepath), "w", "n", "UTF-8");
if file < 0
    error("labkit:app:runtime:JournalWriteFailure", "Could not write export events.");
end
cleanup = onCleanup(@() fclose(file));
for index = 1:numel(events)
    fprintf(file, "%s\n", jsonencode(events(index)));
end
clear cleanup
end

function writeLines(filepath, lines)
file = fopen(char(filepath), "w", "n", "UTF-8");
if file < 0
    error("labkit:app:runtime:JournalWriteFailure", "Could not write export timeline.");
end
cleanup = onCleanup(@() fclose(file));
for index = 1:numel(lines)
    fprintf(file, "%s\n", lines(index));
end
clear cleanup
end

function truncate(filepath, content)
file = fopen(char(filepath), "w", "n", "UTF-8");
if file < 0
    error("labkit:app:runtime:JournalWriteFailure", "Could not recover journal tail.");
end
cleanup = onCleanup(@() fclose(file));
fprintf(file, "%s", content);
clear cleanup
end

function segments = journalSegments(folder)
segments = dir(fullfile(folder, "events-*.jsonl"));
if ~isempty(segments)
    [~, order] = sort(string({segments.name}));
    segments = segments(order);
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
    labkit.app.internal.SessionEventValidator.canonicalTerminalPair( ...
    record.operationResult, record.stateDisposition);
end

function value = semanticSessionId(value, label)
value = labkit.app.internal.SessionEventValidator.semanticIdentifier(value, label);
end

function value = utcNow()
value = string(datetime("now", TimeZone="UTC", ...
    Format="yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"));
end

function payload = readJson(filepath)
payload = [];
if exist(char(filepath), "file") ~= 2
    return;
end
try
    payload = jsondecode(fileread(char(filepath)));
catch
end
end

function atomicJson(filepath, payload)
temporary = string(tempname(fileparts(filepath)));
file = fopen(char(temporary), "w", "n", "UTF-8");
if file < 0
    error("labkit:app:runtime:JournalWriteFailure", "Could not write journal metadata.");
end
cleanup = onCleanup(@() fclose(file));
fprintf(file, "%s\n", jsonencode(payload, PrettyPrint=true));
clear cleanup
[moved, message] = movefile(char(temporary), char(filepath), "f");
if ~moved
    error("labkit:app:runtime:JournalWriteFailure", "%s", message);
end
end
