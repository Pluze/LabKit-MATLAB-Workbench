classdef (Hidden, Sealed) SessionDiagnosticBundle
    %SESSIONDIAGNOSTICBUNDLE Write one privacy-safe diagnostic ZIP snapshot.
    % SessionDiagnostics supplies canonical events and manifest metadata.
    % This writer never receives App state, source files, results, or images.

    methods (Static)
        function destination = write(snapshot, destination)
            snapshot = validateSnapshot(snapshot);
            destination = diagnosticZipPath(destination);
            parent = string(fileparts(destination));
            if strlength(parent) == 0
                parent = string(pwd);
                destination = fullfile(parent, destination);
            end
            if exist(char(parent), "dir") ~= 7
                error("labkit:app:runtime:DiagnosticWriteFailed", ...
                    "The diagnostic bundle destination folder is unavailable.");
            end
            staging = string(tempname);
            mkdir(char(staging));
            cleanup = onCleanup(@() removeStaging(staging));
            writeText(fullfile(staging, "README.txt"), ...
                readmeLines(snapshot));
            writeJson(fullfile(staging, "manifest.json"), ...
                snapshot.manifest);
            writeEvents(fullfile(staging, "events.jsonl"), ...
                snapshot.events);
            writeText(fullfile(staging, "session.log.txt"), ...
                timeline(snapshot.events));
            writeJson(fullfile(staging, "errors.json"), ...
                errorRecords(snapshot.events));
            writeJson(fullfile(staging, "redaction-report.json"), ...
                redactionReport(snapshot));

            temporaryZip = string(tempname(char(parent))) + ".zip";
            zipCleanup = onCleanup(@() removeFile(temporaryZip));
            files = [
                "README.txt"
                "manifest.json"
                "events.jsonl"
                "session.log.txt"
                "errors.json"
                "redaction-report.json"
                ];
            zip(char(temporaryZip), cellstr(files), char(staging));
            [moved, message] = movefile( ...
                char(temporaryZip), char(destination), "f");
            if ~moved
                error("labkit:app:runtime:DiagnosticWriteFailed", ...
                    "Could not publish the diagnostic bundle: %s", message);
            end
            clear zipCleanup cleanup
        end
    end
end

function snapshot = validateSnapshot(snapshot)
fields = ["manifest", "events", "degradation", "capture"];
if ~isstruct(snapshot) || ~isscalar(snapshot) || ...
        ~isequal(string(fieldnames(snapshot)), fields.')
    error("labkit:app:runtime:InvariantFailure", ...
        "Diagnostic bundle snapshot is invalid.");
end
if ~isstruct(snapshot.manifest) || ~isscalar(snapshot.manifest) || ...
        ~isstruct(snapshot.degradation) || ...
        ~isscalar(snapshot.degradation) || ...
        ~isstruct(snapshot.capture) || ~isscalar(snapshot.capture)
    error("labkit:app:runtime:InvariantFailure", ...
        "Diagnostic bundle metadata is invalid.");
end
if isempty(snapshot.events)
    snapshot.events = emptyEvents();
elseif ~isstruct(snapshot.events)
    error("labkit:app:runtime:InvariantFailure", ...
        "Diagnostic bundle events are invalid.");
else
    for index = 1:numel(snapshot.events)
        validateRecord(snapshot.events(index));
    end
    [~, order] = sort(double([snapshot.events.sequence]));
    snapshot.events = snapshot.events(order);
end
end

function validateRecord(record)
fields = ["schemaVersion", "sequence", "timestampUtc", "elapsedSeconds", ...
    "severity", "audience", "category", "eventName", "message", ...
    "attributes", "sessionId", "appId", "operationId", ...
    "parentOperationId", "rootActionId", "operationResult", ...
    "stateDisposition", "durationSeconds", "exception"];
if ~isstruct(record) || ~isscalar(record) || ...
        ~isequal(string(fieldnames(record)), fields.') || ...
        ~labkit.app.internal.SessionEventValidator.canonicalTerminalPair( ...
            record.operationResult, record.stateDisposition)
    error("labkit:app:runtime:InvariantFailure", ...
        "Diagnostic bundle record is not canonical.");
end
labkit.app.internal.SessionEventValidator.privacySafeText( ...
    record.message, "message");
labkit.app.internal.SessionEventValidator.privacySafeAttributes( ...
    record.attributes);
end

function destination = diagnosticZipPath(destination)
if ~(ischar(destination) || ...
        (isstring(destination) && isscalar(destination))) || ...
        strlength(strip(string(destination))) == 0
    error("labkit:app:contract:InvalidValue", ...
        "Diagnostic bundle destination must be nonempty scalar text.");
end
destination = string(destination);
[folder, name, extension] = fileparts(destination);
if strlength(extension) == 0
    destination = fullfile(folder, name + ".zip");
elseif ~strcmpi(extension, ".zip")
    error("labkit:app:contract:InvalidValue", ...
        "Diagnostic bundle destination must use the .zip extension.");
end
end

function value = readmeLines(snapshot)
capture = snapshot.capture;
degradation = snapshot.degradation;
value = [
    "LabKit Diagnostic Bundle"
    ""
    "This bundle contains privacy-safe Runtime session records only."
    "It does not contain projects, scientific inputs or results, images, screenshots, or source files."
    ""
    "Capture notes:"
    "- TRACE enabled at export: " + yesNo(capture.traceEnabled)
    "- In-memory live view truncated: " + ...
        yesNo(capture.inMemoryTruncated)
    "- Retained canonical event count: " + ...
        string(numel(snapshot.events))
    "- Journal dropped records: " + ...
        numericField(degradation, "droppedRecordCount")
    "- Journal coalesced records: " + ...
        numericField(degradation, "coalescedRecordCount")
    "- Expired journal segments: " + ...
        numericField(degradation, "expiredSegmentCount")
    ""
    "Use manifest.json for session/component context, events.jsonl for structured history, session.log.txt for a readable timeline, errors.json for failures, and redaction-report.json for excluded-data categories."
    ];
end

function value = timeline(events)
value = strings(numel(events), 1);
for index = 1:numel(events)
    value(index) = string(events(index).timestampUtc) + " [" + ...
        string(events(index).severity) + "] " + ...
        string(events(index).category) + " " + ...
        string(events(index).eventName) + " - " + ...
        string(events(index).message);
end
end

function value = errorRecords(events)
if isempty(events)
    value = repmat(errorTemplate(), 0, 1);
    return;
end
levels = string({events.severity});
events = events(ismember(levels, ["ERROR", "CRITICAL"]));
value = repmat(errorTemplate(), numel(events), 1);
for index = 1:numel(events)
    record = events(index);
    value(index) = struct( ...
        "sequence", double(record.sequence), ...
        "timestampUtc", string(record.timestampUtc), ...
        "severity", string(record.severity), ...
        "category", string(record.category), ...
        "eventName", string(record.eventName), ...
        "message", string(record.message), ...
        "rootActionId", string(record.rootActionId), ...
        "exception", record.exception);
end
end

function value = errorTemplate()
value = struct( ...
    "sequence", 0, "timestampUtc", "", "severity", "", ...
    "category", "", "eventName", "", "message", "", ...
    "rootActionId", "", "exception", struct());
end

function value = redactionReport(snapshot)
value = struct( ...
    "schemaVersion", 1, ...
    "privacyBoundary", "validated-before-retention", ...
    "exportProjection", "canonical-safe-events-only", ...
    "excludedData", [ ...
        "paths"
        "filenames"
        "input-content"
        "scientific-data"
        "workspace-values"
        "projects"
        "images"
        "screenshots"
        "source-files"
        ], ...
    "removedValueCount", 0, ...
    "degradation", snapshot.degradation);
end

function writeEvents(filepath, events)
file = fopen(char(filepath), "w", "n", "UTF-8");
if file < 0
    error("labkit:app:runtime:DiagnosticWriteFailed", ...
        "Could not write diagnostic events.");
end
cleanup = onCleanup(@() fclose(file));
for index = 1:numel(events)
    fprintf(file, "%s\n", jsonencode(events(index)));
end
clear cleanup
end

function writeText(filepath, lines)
file = fopen(char(filepath), "w", "n", "UTF-8");
if file < 0
    error("labkit:app:runtime:DiagnosticWriteFailed", ...
        "Could not write diagnostic text.");
end
cleanup = onCleanup(@() fclose(file));
for index = 1:numel(lines)
    fprintf(file, "%s\n", lines(index));
end
clear cleanup
end

function writeJson(filepath, payload)
file = fopen(char(filepath), "w", "n", "UTF-8");
if file < 0
    error("labkit:app:runtime:DiagnosticWriteFailed", ...
        "Could not write diagnostic metadata.");
end
cleanup = onCleanup(@() fclose(file));
fprintf(file, "%s\n", jsonencode(payload, PrettyPrint=true));
clear cleanup
end

function value = numericField(structure, name)
if isfield(structure, name)
    value = string(structure.(name));
else
    value = "unknown";
end
end

function value = yesNo(tf)
if tf
    value = "yes";
else
    value = "no";
end
end

function removeStaging(folder)
if exist(char(folder), "dir") == 7
    rmdir(char(folder), "s");
end
end

function removeFile(filepath)
if exist(char(filepath), "file") == 2
    delete(char(filepath));
end
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
