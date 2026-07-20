classdef (Hidden, Sealed) DiagnosticRecorder < handle
    %DIAGNOSTICRECORDER Record sanitized App SDK semantic operations.
    %
    % Expected callers are RuntimeKernel and focused framework tests. Inputs
    % are one compiled Definition and one diagnostic Options value. Events use
    % a fixed schema, relative elapsed time, semantic IDs, and sanitized error
    % details. Verbose sessions append JSON lines and atomically maintain the
    % active-operation marker. Recorder failures never alter App execution.

    properties (Access = private)
        Application
        Options
        StartTimer
        Sequence (1, 1) double = 0
        OperationSequence (1, 1) double = 0
        EventBuffer (1, :) cell = {}
        OperationStack (1, :) cell = {}
        EventsFile (1, 1) string = ""
        ActiveFile (1, 1) string = ""
        ManifestFile (1, 1) string = ""
        DiskEnabled (1, 1) logical = false
        Closed (1, 1) logical = false
    end

    methods
        function obj = DiagnosticRecorder(application, options)
            if ~isa(application, "labkit.app.Definition") || ...
                    ~isscalar(application)
                error("labkit:app:runtime:InvariantFailure", ...
                    "DiagnosticRecorder requires one Definition.");
            end
            if nargin < 2 || isempty(options)
                options = labkit.app.diagnostic.Options();
            end
            if ~isa(options, "labkit.app.diagnostic.Options") || ...
                    ~isscalar(options)
                error("labkit:app:runtime:InvariantFailure", ...
                    "DiagnosticRecorder requires diagnostic Options.");
            end
            obj.Application = application;
            obj.Options = options;
            obj.StartTimer = tic;
            obj.initializeDisk();
            obj.note("lifecycle", "runtime", "created", "completed");
        end

        function operation = begin(obj, category, targetId, signal)
            operation = struct( ...
                "Id", obj.nextOperationId(), ...
                "ParentId", obj.currentOperationId(), ...
                "Category", semanticText(category), ...
                "TargetId", semanticText(targetId), ...
                "Signal", semanticText(signal), ...
                "Timer", tic);
            obj.OperationStack{end + 1} = operation;
            if obj.Options.Level == "verbose"
                obj.appendEvent(operation.Category, operation.Id, ...
                    operation.ParentId, operation.TargetId, ...
                    operation.Signal, "begin", [], [], []);
                obj.writeActiveOperation(operation);
            end
        end

        function finish(obj, operation, outcome, exception)
            if nargin < 4
                exception = [];
            end
            duration = elapsed(operation);
            outcome = semanticText(outcome);
            failed = outcome ~= "completed";
            if obj.Options.Level == "verbose" || failed || duration >= 30
                obj.appendEvent(operation.Category, operation.Id, ...
                    operation.ParentId, operation.TargetId, ...
                    operation.Signal, outcome, duration, exception, []);
            end
            obj.removeOperation(operation.Id);
            obj.refreshActiveOperation();
        end

        function note(obj, category, targetId, signal, outcome)
            category = semanticText(category);
            outcome = semanticText(outcome);
            if obj.Options.Level == "verbose" || ...
                    category == "lifecycle" || outcome ~= "completed"
                obj.appendEvent(category, "", obj.currentOperationId(), ...
                    semanticText(targetId), semanticText(signal), ...
                    outcome, [], [], []);
            end
        end

        function count(obj, id, value)
            if ~(isnumeric(value) && isscalar(value) && isfinite(value) && ...
                    value >= 0 && value == fix(value))
                error("labkit:app:contract:InvalidValue", ...
                    "Diagnostic count must be a nonnegative integer.");
            end
            if obj.Options.Level == "verbose"
                obj.appendEvent("app", "", obj.currentOperationId(), ...
                    semanticText(id), "count", "completed", ...
                    [], [], double(value));
            end
        end

        function events = events(obj)
            if isempty(obj.EventBuffer)
                events = repmat(eventTemplate(), 0, 1);
            else
                events = vertcat(obj.EventBuffer{:});
            end
        end

        function folder = artifactFolder(obj)
            folder = obj.Options.ArtifactFolder;
        end

        function close(obj)
            if obj.Closed
                return;
            end
            obj.note("lifecycle", "runtime", "closed", "completed");
            obj.Closed = true;
            obj.OperationStack = {};
            obj.removeActiveFile();
            obj.writeManifest("closed");
        end

        function delete(obj)
            obj.close();
        end
    end

    methods (Access = private)
        function initializeDisk(obj)
            if obj.Options.Level ~= "verbose" || ...
                    strlength(obj.Options.ArtifactFolder) == 0
                return;
            end
            try
                folder = obj.Options.ArtifactFolder;
                if exist(char(folder), "dir") ~= 7
                    mkdir(char(folder));
                end
                obj.EventsFile = string(fullfile(folder, "events.jsonl"));
                obj.ActiveFile = string(fullfile( ...
                    folder, "active-operation.json"));
                obj.ManifestFile = string(fullfile(folder, "manifest.json"));
                initializeTextFile(obj.EventsFile);
                obj.DiskEnabled = true;
                obj.writeManifest("active");
            catch
                obj.DiskEnabled = false;
                obj.EventsFile = "";
                obj.ActiveFile = "";
                obj.ManifestFile = "";
            end
        end

        function id = nextOperationId(obj)
            obj.OperationSequence = obj.OperationSequence + 1;
            id = "op-" + string(obj.OperationSequence);
        end

        function id = currentOperationId(obj)
            id = "";
            if ~isempty(obj.OperationStack)
                id = string(obj.OperationStack{end}.Id);
            end
        end

        function appendEvent(obj, category, operationId, parentId, ...
                targetId, signal, outcome, duration, exception, count)
            obj.Sequence = obj.Sequence + 1;
            event = eventTemplate();
            event.Sequence = obj.Sequence;
            event.ElapsedSeconds = toc(obj.StartTimer);
            event.Level = obj.Options.Level;
            event.Category = string(category);
            event.OperationId = string(operationId);
            event.ParentOperationId = string(parentId);
            event.TargetId = string(targetId);
            event.Signal = string(signal);
            event.Outcome = string(outcome);
            event.DurationSeconds = duration;
            event.Count = count;
            if isa(exception, "MException") && isscalar(exception)
                event.ErrorId = string(exception.identifier);
                event.ErrorMessage = obj.sanitizeText(exception.message);
                stack = exception.stack;
                event.ErrorStack = strings(numel(stack), 1);
                for k = 1:numel(stack)
                    event.ErrorStack(k) = string(stack(k).name) + ...
                        ":" + string(stack(k).line);
                end
            end
            obj.EventBuffer{1, end + 1} = event;
            if numel(obj.EventBuffer) > 512
                obj.EventBuffer(1) = [];
            end
            obj.appendJsonLine(event);
        end

        function appendJsonLine(obj, event)
            if ~obj.DiskEnabled
                return;
            end
            try
                file = fopen(char(obj.EventsFile), "a", "n", "UTF-8");
                if file < 0
                    obj.DiskEnabled = false;
                    return;
                end
                cleanup = onCleanup(@() fclose(file));
                fprintf(file, "%s\n", jsonencode(event));
                clear cleanup
            catch
                obj.DiskEnabled = false;
            end
        end

        function writeActiveOperation(obj, operation)
            if ~obj.DiskEnabled
                return;
            end
            payload = struct( ...
                "operationId", operation.Id, ...
                "parentOperationId", operation.ParentId, ...
                "category", operation.Category, ...
                "targetId", operation.TargetId, ...
                "signal", operation.Signal, ...
                "elapsedSeconds", toc(obj.StartTimer));
            obj.writeJsonAtomically(obj.ActiveFile, payload);
        end

        function refreshActiveOperation(obj)
            if ~obj.DiskEnabled
                return;
            end
            if isempty(obj.OperationStack)
                obj.removeActiveFile();
            else
                obj.writeActiveOperation(obj.OperationStack{end});
            end
        end

        function removeOperation(obj, id)
            if isempty(obj.OperationStack)
                return;
            end
            ids = string(cellfun(@(value) value.Id, obj.OperationStack, ...
                "UniformOutput", false));
            index = find(ids == string(id), 1, "last");
            if ~isempty(index)
                obj.OperationStack(index) = [];
            end
        end

        function removeActiveFile(obj)
            if strlength(obj.ActiveFile) == 0
                return;
            end
            try
                if exist(char(obj.ActiveFile), "file") == 2
                    delete(char(obj.ActiveFile));
                end
            catch
            end
        end

        function writeManifest(obj, status)
            if ~obj.DiskEnabled && status ~= "active"
                return;
            end
            try
                sdk = labkit.app.version();
                payload = struct( ...
                    "schemaVersion", 1, ...
                    "status", string(status), ...
                    "appId", obj.Application.AppId, ...
                    "entrypoint", obj.Application.Entrypoint, ...
                    "appVersion", obj.Application.AppVersion, ...
                    "appSdkVersion", sdk.current, ...
                    "matlabRelease", string(version("-release")), ...
                    "platform", string(computer), ...
                    "level", obj.Options.Level, ...
                    "sample", obj.Options.Sample, ...
                    "eventCount", obj.Sequence);
                obj.writeJsonAtomically(obj.ManifestFile, payload);
            catch
                obj.DiskEnabled = false;
            end
        end

        function writeJsonAtomically(obj, filepath, payload)
            if ~obj.DiskEnabled || strlength(filepath) == 0
                return;
            end
            temporary = string(tempname(fileparts(filepath)));
            try
                file = fopen(char(temporary), "w", "n", "UTF-8");
                if file < 0
                    obj.DiskEnabled = false;
                    return;
                end
                cleanup = onCleanup(@() fclose(file));
                fprintf(file, "%s\n", jsonencode(payload, PrettyPrint=true));
                clear cleanup
                [moved, ~] = movefile(char(temporary), char(filepath), "f");
                if ~moved
                    obj.DiskEnabled = false;
                end
            catch
                obj.DiskEnabled = false;
            end
            if exist(char(temporary), "file") == 2
                try
                    delete(char(temporary));
                catch
                end
            end
        end

        function text = sanitizeText(obj, value)
            text = string(value);
            roots = [ ...
                string(getenv("USERPROFILE"))
                string(getenv("HOME"))
                string(userpath)
                string(tempdir)
                obj.Options.ArtifactFolder];
            roots = unique(roots(strlength(roots) > 0));
            for root = reshape(roots, 1, [])
                pattern = regexptranslate("escape", root);
                if ispc
                    text = regexprep(text, pattern, "<path>", "ignorecase");
                else
                    text = regexprep(text, pattern, "<path>");
                end
            end
            text = regexprep(text, ...
                '(?<![A-Za-z0-9_])[A-Za-z]:[\\/][^\s,;]+', '<path>');
            text = regexprep(text, ...
                '(?<![A-Za-z0-9_])/(?:Users|home|tmp)/[^\s,;]+', ...
                '<path>');
            text = regexprep(text, ...
                '(?i)\b[^\s\\/]+\.(csv|mat|json|txt|png|jpg|jpeg|tif|tiff|avi|xlsx|dta|rhs)\b', ...
                '<file>');
        end
    end
end

function event = eventTemplate()
event = struct( ...
    "Sequence", 0, ...
    "ElapsedSeconds", 0, ...
    "Level", "", ...
    "Category", "", ...
    "OperationId", "", ...
    "ParentOperationId", "", ...
    "TargetId", "", ...
    "Signal", "", ...
    "Outcome", "", ...
    "DurationSeconds", [], ...
    "ErrorId", "", ...
    "ErrorMessage", "", ...
    "ErrorStack", strings(0, 1), ...
    "Count", []);
end

function value = semanticText(value)
if ~(ischar(value) || (isstring(value) && isscalar(value)))
    error("labkit:app:runtime:InvariantFailure", ...
        "Diagnostic semantic values must be scalar text.");
end
value = string(value);
end

function seconds = elapsed(operation)
seconds = 0;
try
    seconds = toc(operation.Timer);
catch
end
end

function initializeTextFile(filepath)
file = fopen(char(filepath), "w", "n", "UTF-8");
if file < 0
    error("labkit:app:runtime:InvariantFailure", ...
        "Could not initialize diagnostic events file.");
end
cleanup = onCleanup(@() fclose(file));
clear cleanup
end
