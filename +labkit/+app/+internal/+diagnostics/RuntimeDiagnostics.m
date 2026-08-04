classdef (Hidden, Sealed) RuntimeDiagnostics < handle
    % Own Runtime diagnostic viewing, capture, and export workflows.
    % Caller: RuntimeKernel. SessionDiagnostics remains the event/journal
    % primitive; this owner coordinates user choices, artifacts, and fallback.

    properties (Access = private)
        Recorder
        Context
        Artifacts
        DisplayName (1, 1) string
        NotifyUser
    end

    methods
        function obj = RuntimeDiagnostics( ...
                recorder, context, artifacts, displayName, notifyUser)
            if ~isa(recorder, ...
                    "labkit.app.internal.diagnostics.SessionDiagnostics") || ...
                    ~isscalar(recorder) || ...
                    ~isa(context, "labkit.app.CallbackContext") || ...
                    ~isscalar(context) || ...
                    ~isa(artifacts, ...
                    "labkit.app.internal.artifact.Store") || ...
                    ~isscalar(artifacts) || ...
                    ~isa(notifyUser, "function_handle") || ...
                    ~isscalar(notifyUser)
                error("labkit:app:runtime:InvariantFailure", ...
                    "Runtime diagnostic dependencies are invalid.");
            end
            obj.Recorder = recorder;
            obj.Context = context;
            obj.Artifacts = artifacts;
            obj.DisplayName = string(displayName);
            obj.NotifyUser = notifyUser;
        end

        function events = events(obj)
            events = obj.Recorder.events();
        end

        function snapshot = snapshot(obj)
            snapshot = obj.Recorder.captureSnapshot();
        end

        function title = title(obj)
            title = obj.DisplayName + " — Session Log";
        end

        function token = subscribe(obj, callback)
            token = obj.Recorder.subscribe(callback);
        end

        function unsubscribe(obj, token)
            obj.Recorder.unsubscribe(token);
        end

        function setTraceCapture(obj, enabled)
            obj.Recorder.setTraceEnabled(enabled);
        end

        function destination = exportBundle( ...
                obj, destination, state, stateMode)
            if nargin < 4
                stateMode = "exact";
            end
            stateMode = validateStateMode(stateMode);
            operation = obj.Recorder.begin( ...
                "runtime.lifecycle", "diagnostics.bundle_exported", ...
                "Exporting diagnostic bundle.");
            try
                destination = obj.Recorder.exportBundle( ...
                    destination, operation.Id, state, stateMode);
                obj.Recorder.finish( ...
                    operation, "completed", "notApplicable", []);
            catch cause
                obj.Recorder.finish( ...
                    operation, "failed", "notApplicable", cause);
                destination = obj.exportTextFallback( ...
                    destination, cause, stateMode);
            end
        end

        function destination = exportInteractive(obj, state)
            selection = obj.Context.chooseOption( ...
                "Every bundle contains complete sensitive logs and App " + ...
                 "state. Compact MAT replaces supported state values over " + ...
                 "1 MiB with structural synthetic placeholders.", ...
                ["Complete bundle (exact MAT)", ...
                 "Complete bundle (compact synthetic MAT)", ...
                 "Cancel"], ...
                Title="Export Diagnostic Bundle", ...
                DefaultChoice="Complete bundle (exact MAT)", ...
                CancelChoice="Cancel");
            if selection.Cancelled || selection.Value == "Cancel"
                destination = "";
                return
            end
            stateMode = "exact";
            if selection.Value == "Complete bundle (compact synthetic MAT)"
                stateMode = "compact";
            end
            destination = "";
            try
                automaticDestination = obj.automaticDestination(stateMode);
                destination = obj.exportBundle( ...
                    automaticDestination, state, stateMode);
                if endsWith(destination, ".txt", IgnoreCase=true)
                    obj.alertTextFallback(destination);
                else
                    obj.NotifyUser( ...
                        "Diagnostic bundle written to:" + newline + ...
                        string(destination), ...
                        "Diagnostic Bundle Exported");
                end
                return
            catch automaticFailure
                fallbackName = diagnosticFallbackName( ...
                    obj.automaticFilename(stateMode));
            end
            choice = obj.Context.chooseOutputFile( ...
                {"*.txt", "Diagnostic text fallback (*.txt)"}, ...
                fallbackName);
            if choice.Cancelled
                return
            end
            destination = obj.exportTextFallback( ...
                choice.Value, automaticFailure, stateMode);
            obj.alertTextFallback(destination);
        end

        function destination = exportTextFallback( ...
                obj, preferredDestination, cause, stateMode)
            if nargin < 4
                stateMode = "exact";
            end
            stateMode = validateStateMode(stateMode);
            obj.Recorder.log( ...
                "warning", "diagnostics.text_fallback.started", ...
                "Diagnostic ZIP export failed; writing a plain-text fallback.", ...
                Category="runtime.lifecycle", Audience="user", ...
                Exception=cause);
            destination = obj.Recorder.exportTextFallback( ...
                preferredDestination, cause, stateMode);
        end

        function alertTextFallback(obj, destination)
            obj.Context.alert( ...
                "The diagnostic ZIP could not be exported. A plain-text " + ...
                "diagnostic fallback was written to:" + newline + ...
                string(destination), ...
                "Diagnostic Text Fallback");
        end
    end

    methods (Access = private)
        function destination = automaticDestination(obj, stateMode)
            destination = obj.Artifacts.destination( ...
                "diagnostics", diagnosticArtifactStem(stateMode), ".zip");
        end

        function filename = automaticFilename(obj, stateMode)
            filename = obj.Artifacts.filename( ...
                diagnosticArtifactStem(stateMode), ".zip");
        end
    end
end

function stateMode = validateStateMode(stateMode)
stateMode = ...
    labkit.app.internal.diagnostics.SessionDiagnosticStateProjection.validateMode( ...
    stateMode);
end

function stem = diagnosticArtifactStem(stateMode)
if stateMode == "exact"
    stem = "diagnostics-sensitive-state";
else
    stem = "diagnostics-sensitive-compact-state";
end
end

function filename = diagnosticFallbackName(zipFilename)
[~, name] = fileparts(string(zipFilename));
filename = name + "-fallback.txt";
end
