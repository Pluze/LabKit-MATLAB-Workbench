classdef (Hidden, Sealed) SessionJournalArchive
    %SESSIONJOURNALARCHIVE Read one retained journal for verification or analysis.
    % This private boundary never receives live events or decides their privacy
    % semantics; journals retain the complete canonical representation.

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
