classdef (Hidden, Sealed) SessionDiagnosticBundle
    %SESSIONDIAGNOSTICBUNDLE Write one diagnostic ZIP snapshot.
    % SessionDiagnostics supplies full retained events and manifest metadata.
    % Redaction is applied only after the user selects a redacted export.

    methods (Static)
        function destination = write(snapshot, destination, ...
                includeSensitiveDetails, privateState)
            if nargin < 3
                includeSensitiveDetails = false;
            end
            if nargin < 4
                privateState = [];
            end
            snapshot = validateSnapshot(snapshot);
            includeSensitiveDetails = logical(includeSensitiveDetails);
            if ~includeSensitiveDetails
                snapshot.events = ...
                    labkit.app.internal.SessionEventValidator.redactedRecords( ...
                    snapshot.events);
            end
            includesPrivateState = includeSensitiveDetails && ~isempty(privateState);
            if includesPrivateState && ...
                    (~isstruct(privateState) || ~isscalar(privateState))
                error("labkit:app:runtime:InvariantFailure", ...
                    "Private diagnostic App state must be one scalar struct.");
            end
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
                readmeLines(snapshot, includeSensitiveDetails, includesPrivateState));
            writeJson(fullfile(staging, "manifest.json"), ...
                snapshot.manifest);
            writeEvents(fullfile(staging, "events.jsonl"), ...
                snapshot.events);
            writeText(fullfile(staging, "session.log.txt"), ...
                timeline(snapshot.events));
            writeJson(fullfile(staging, "errors.json"), ...
                errorRecords(snapshot.events));
            writeJson(fullfile(staging, "redaction-report.json"), ...
                redactionReport(snapshot, includeSensitiveDetails, includesPrivateState));
            if includesPrivateState
                writePrivateState(fullfile(staging, "app-state.mat"), ...
                    privateState);
            end

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
            if includesPrivateState
                files(end + 1, 1) = "app-state.mat";
            end
            zip(char(temporaryZip), cellstr(files), char(staging));
            [moved, message] = movefile( ...
                char(temporaryZip), char(destination), "f");
            if ~moved
                error("labkit:app:runtime:DiagnosticWriteFailed", ...
                    "Could not publish the diagnostic bundle: %s", message);
            end
            clear zipCleanup cleanup
        end

        function destination = writeFallback( ...
                snapshot, preferredDestination, includeSensitiveDetails)
            if nargin < 3
                includeSensitiveDetails = false;
            end
            snapshot = validateFallbackSnapshot(snapshot);
            includeSensitiveDetails = logical(includeSensitiveDetails);
            if ~includeSensitiveDetails
                snapshot.events = ...
                    labkit.app.internal.SessionEventValidator.redactedRecords( ...
                    snapshot.events);
            end
            destination = fallbackPath(preferredDestination);
            folder = string(fileparts(destination));
            if strlength(folder) == 0
                folder = string(pwd);
                destination = fullfile(folder, destination);
            end
            if exist(char(folder), "dir") ~= 7
                error("labkit:app:runtime:DiagnosticWriteFailed", ...
                    "The diagnostic text fallback folder is unavailable.");
            end
            writeText(destination, fallbackLines( ...
                snapshot, includeSensitiveDetails));
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
try
    jsonencode(record);
catch
    error("labkit:app:runtime:InvariantFailure", ...
        "Diagnostic bundle record is not serializable.");
end
end

function snapshot = validateFallbackSnapshot(snapshot)
fields = ["application", "events", "capture", "failureIdentifier"];
if ~isstruct(snapshot) || ~isscalar(snapshot) || ...
        ~isequal(string(fieldnames(snapshot)), fields.') || ...
        ~isstruct(snapshot.application) || ...
        ~isscalar(snapshot.application) || ...
        ~isstruct(snapshot.capture) || ~isscalar(snapshot.capture)
    error("labkit:app:runtime:InvariantFailure", ...
        "Diagnostic text fallback snapshot is invalid.");
end
if isempty(snapshot.events)
    snapshot.events = emptyEvents();
elseif ~isstruct(snapshot.events)
    error("labkit:app:runtime:InvariantFailure", ...
        "Diagnostic text fallback events are invalid.");
else
    for index = 1:numel(snapshot.events)
        validateRecord(snapshot.events(index));
    end
    [~, order] = sort(double([snapshot.events.sequence]));
    snapshot.events = snapshot.events(order);
end
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

function value = readmeLines( ...
        snapshot, includeSensitiveDetails, includesPrivateState)
capture = snapshot.capture;
degradation = snapshot.degradation;
value = [
    "LabKit Diagnostic Bundle"
    ""
    privacyDescription(includeSensitiveDetails, includesPrivateState)
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

function value = privacyDescription( ...
        includeSensitiveDetails, includesPrivateState)
if includeSensitiveDetails
    value = [ ...
        "Sensitive export was explicitly enabled by the user."
        "Session events contain the complete retained messages, attributes, exception messages, and stack locations and may include paths, filenames, and scientific values."
        "External source files and screenshots are not copied into this bundle."
        ];
    if includesPrivateState
        value(end + 1, 1) = "app-state.mat contains the current App project and session state and may include paths, filenames, scientific values, results, and decoded images.";
    end
else
    value = [ ...
        "This bundle contains privacy-safe Runtime session records only."
        "It does not contain projects, scientific inputs or results, images, screenshots, or source files."
        ];
end
end

function value = fallbackLines(snapshot, includeSensitiveDetails)
application = snapshot.application;
capture = snapshot.capture;
value = [
    "LabKit Diagnostic Text Fallback"
    ""
    fallbackPrivacyLines(includeSensitiveDetails)
    ""
    "Application:"
    "- Name: " + textField(application, "title")
    "- App ID: " + textField(application, "appId")
    "- App version: " + textField(application, "appVersion")
    "- LabKit App SDK version: " + ...
        textField(application, "labkitAppVersion")
    "- ZIP failure identifier: " + string(snapshot.failureIdentifier)
    ""
    "Capture notes:"
    "- TRACE enabled at fallback: " + ...
        yesNo(logicalField(capture, "traceEnabled"))
    "- In-memory live view truncated: " + ...
        yesNo(logicalField(capture, "inMemoryTruncated"))
    "- Retained canonical event count: " + ...
        string(numel(snapshot.events))
    ""
    "Session timeline:"
    timeline(snapshot.events)
    ""
    "Structured session records:"
    fallbackEventLines(snapshot.events)
    ""
    "Structured failure records:"
    fallbackErrorLines(snapshot.events)
    ];
end

function value = fallbackPrivacyLines(includeSensitiveDetails)
if includeSensitiveDetails
    value = [ ...
        "The normal diagnostic ZIP could not be written. This fallback preserves the selected complete-log mode."
        "It contains full retained messages, attributes, exception messages, and stack locations and may contain sensitive paths, filenames, and scientific values."
        ];
else
    value = [ ...
        "The normal diagnostic ZIP could not be written. This fallback preserves the selected redacted-log mode."
        "It excludes projects, scientific inputs or results, images, screenshots, source files, paths, and original filenames."
        ];
end
end

function value = fallbackEventLines(events)
if isempty(events)
    value = "(none)";
    return;
end
value = strings(numel(events), 1);
for index = 1:numel(events)
    value(index) = string(jsonencode(events(index)));
end
end

function value = fallbackErrorLines(events)
records = errorRecords(events);
if isempty(records)
    value = "(none)";
    return;
end
value = strings(numel(records), 1);
for index = 1:numel(records)
    value(index) = string(jsonencode(records(index)));
end
end

function value = textField(structure, name)
if isfield(structure, name)
    value = string(structure.(name));
else
    value = "unknown";
end
end

function value = logicalField(structure, name)
value = false;
if isfield(structure, name) && isscalar(structure.(name))
    value = logical(structure.(name));
end
end

function destination = fallbackPath(preferredDestination)
if ~(ischar(preferredDestination) || ...
        (isstring(preferredDestination) && isscalar(preferredDestination))) || ...
        strlength(strip(string(preferredDestination))) == 0
    error("labkit:app:contract:InvalidValue", ...
        "Diagnostic text fallback destination must be nonempty scalar text.");
end
preferredDestination = string(preferredDestination);
[folder, name, extension] = fileparts(preferredDestination);
if strcmpi(extension, ".txt")
    destination = preferredDestination;
else
    destination = fullfile(folder, name + "-fallback.txt");
end
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

function value = redactionReport( ...
        snapshot, includeSensitiveDetails, includesPrivateState)
if includeSensitiveDetails
    projection = "complete-retained-events-plus-opt-in-app-state";
    excluded = ["screenshots"; "source-files"];
else
    projection = "redacted-at-export";
    excluded = [ ...
        "paths"
        "filenames"
        "input-content"
        "scientific-data"
        "workspace-values"
        "projects"
        "images"
        "screenshots"
        "source-files"
        ];
end
value = struct( ...
    "schemaVersion", 1, ...
    "privacyBoundary", "redacted-only-after-export-selection", ...
    "exportProjection", projection, ...
    "includesPrivateAppState", includesPrivateState, ...
    "excludedData", excluded, ...
    "removedValueCount", 0, ...
    "degradation", snapshot.degradation);
end

function writePrivateState(filepath, privateState)
applicationState = privateState;
save(char(filepath), "applicationState", "-mat");
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
