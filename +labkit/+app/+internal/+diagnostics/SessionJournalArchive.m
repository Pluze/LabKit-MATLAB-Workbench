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
                "timeline", timeline(events), "degradation", ...
                degradation(manifest, corruptRecordCount), ...
                "redaction", redactionMetadata());
        end

        function exportFolder = exportSnapshot(rootFolder, sessionId, exportFolder)
            snapshot = labkit.app.internal.diagnostics.SessionJournalArchive.snapshot( ...
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

function value = timeline(events)
value = strings(numel(events), 1);
for index = 1:numel(events)
    value(index) = string(events(index).timestampUtc) + " [" + ...
        string(events(index).severity) + "] " + string(events(index).category) + ...
        " - " + string(events(index).message);
end
end

function value = degradation(manifest, corruptRecordCount)
if isfield(manifest, "degradation")
    value = manifest.degradation;
else
    value = struct();
end
if isfield(manifest, "recovery")
    value.recovery = manifest.recovery;
end
value.snapshotCorruptRecordCount = corruptRecordCount;
end

function value = redactionMetadata()
value = struct("semanticEventPrivacy", "complete-retained-details", ...
    "exportProjection", "none", "excludedData", strings(0, 1));
end

function writeEvents(filepath, events)
file = fopen(char(filepath), "w", "n", "UTF-8");
if file < 0
    error("labkit:app:runtime:JournalWriteFailure", ...
        "Could not write export events.");
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
    error("labkit:app:runtime:JournalWriteFailure", ...
        "Could not write export timeline.");
end
cleanup = onCleanup(@() fclose(file));
for index = 1:numel(lines)
    fprintf(file, "%s\n", lines(index));
end
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

function atomicJson(filepath, payload)
temporary = string(tempname(fileparts(filepath)));
file = fopen(char(temporary), "w", "n", "UTF-8");
if file < 0
    error("labkit:app:runtime:JournalWriteFailure", ...
        "Could not write journal metadata.");
end
cleanup = onCleanup(@() fclose(file));
fprintf(file, "%s\n", jsonencode(payload, PrettyPrint=true));
clear cleanup
[moved, message] = movefile(char(temporary), char(filepath), "f");
if ~moved
    error("labkit:app:runtime:JournalWriteFailure", "%s", message);
end
end
