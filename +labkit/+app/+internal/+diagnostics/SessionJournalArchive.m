classdef (Hidden, Sealed) SessionJournalArchive
    %SESSIONJOURNALARCHIVE Read one retained journal for diagnostic export.
    % This private archive boundary never receives live events or decides their
    % privacy semantics; journals retain the complete canonical representation.

    methods (Static)
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
            snapshot = struct("manifest", manifest, "events", events, ...
                "degradation", degradation(manifest, corruptRecordCount));
        end

        function snapshot = latestActive(rootFolder, appId, excludeSessionId)
            rootFolder = string(rootFolder);
            appId = string(appId);
            excludeSessionId = string(excludeSessionId);
            folders = dir(fullfile(rootFolder, "sessions", "*"));
            folders = folders([folders.isdir]);
            folderNames = string({folders.name});
            folders = folders(~ismember(folderNames, [".", ".."]));
            selectedId = "";
            selectedUpdated = "";
            for index = 1:numel(folders)
                manifest = readJson(fullfile(folders(index).folder, ...
                    folders(index).name, "manifest.json"));
                if isempty(manifest) || ~isfield(manifest, "state") || ...
                        ~isfield(manifest, "appId") || ...
                        ~isfield(manifest, "sessionId") || ...
                        string(manifest.state) ~= "active" || ...
                        string(manifest.appId) ~= appId || ...
                        string(manifest.sessionId) == excludeSessionId
                    continue;
                end
                updated = "";
                if isfield(manifest, "updatedAtUtc")
                    updated = string(manifest.updatedAtUtc);
                end
                if strlength(selectedId) == 0 || ...
                        compareTimestamps(updated, selectedUpdated) > 0
                    selectedId = string(manifest.sessionId);
                    selectedUpdated = updated;
                end
            end
            if strlength(selectedId) == 0
                error("labkit:app:runtime:NoPreviousActiveSession", ...
                    "No previous active session journal is available for this App.");
            end
            snapshot = ...
                labkit.app.internal.diagnostics.SessionJournalArchive.snapshot( ...
                rootFolder, selectedId);
        end
    end
end

function order = compareTimestamps(left, right)
left = char(left);
right = char(right);
order = 0;
if strcmp(left, right)
    return;
end
ordered = sort(string({left, right}));
if ordered(2) == string(left)
    order = 1;
else
    order = -1;
end
end

function [events, corruptRecordCount] = readCanonicalEvents(folder)
corruptRecordCount = 0;
segments = journalSegments(folder);
segmentEvents = cell(numel(segments), 1);
for segmentIndex = 1:numel(segments)
    lines = splitlines(string(fileread(fullfile(segments(segmentIndex).folder, ...
        segments(segmentIndex).name))));
    events = repmat(canonicalTemplate(), numel(lines), 1);
    eventCount = 0;
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
            eventCount = eventCount + 1;
            events(eventCount, 1) = record;
        catch
            corruptRecordCount = corruptRecordCount + 1;
        end
    end
    segmentEvents{segmentIndex} = events(1:eventCount);
end
events = repmat(canonicalTemplate(), 0, 1);
segmentEvents = segmentEvents(~cellfun(@isempty, segmentEvents));
if ~isempty(segmentEvents)
    events = vertcat(segmentEvents{:});
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

function value = degradation(manifest, corruptRecordCount)
if isfield(manifest, "degradation")
    value = manifest.degradation;
else
    value = struct();
end
value.snapshotCorruptRecordCount = corruptRecordCount;
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
    "parentOperationId", "rootActionId", "operationResult", ...
    "stateDisposition", "durationSeconds", "exception"];
tf = isstruct(record) && isscalar(record) && ...
    isequal(string(fieldnames(record)), fields.') && ...
    labkit.app.internal.diagnostics.SessionEventValidator.canonicalTerminalPair( ...
    record.operationResult, record.stateDisposition);
end

function value = semanticSessionId(value, label)
value = labkit.app.internal.diagnostics.SessionEventValidator.semanticIdentifier( ...
    value, label);
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
