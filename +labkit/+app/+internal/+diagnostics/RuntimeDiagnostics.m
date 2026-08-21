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

        function destination = exportBundle(obj, destination, state)
            operation = obj.Recorder.begin( ...
                "runtime.lifecycle", "diagnostics.bundle_exported", ...
                "Exporting diagnostic bundle.");
            try
                destination = obj.Recorder.exportBundle( ...
                    destination, operation.Id, state);
                obj.Recorder.finish( ...
                    operation, "completed", "notApplicable", []);
            catch cause
                obj.Recorder.finish( ...
                    operation, "failed", "notApplicable", cause);
                destination = obj.exportTextFallback( ...
                    destination, cause);
            end
        end

        function destination = exportAfterErrorOnClose(obj, state)
            destination = "";
            if ~obj.Recorder.hasErrorOrCriticalEvent()
                return
            end
            try
                destination = obj.exportBundle( ...
                    obj.automaticDestination(), state);
            catch
                % Diagnostic persistence must not change Runtime close semantics.
            end
        end

        function destination = exportInteractive(obj, state)
            destination = "";
            try
                automaticDestination = obj.automaticDestination();
                destination = obj.exportBundle( ...
                    automaticDestination, state);
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
                    obj.automaticFilename());
            end
            choice = obj.Context.chooseOutputFile( ...
                {"*.txt", "Diagnostic text fallback (*.txt)"}, ...
                fallbackName);
            if choice.Cancelled
                return
            end
            destination = obj.exportTextFallback( ...
                choice.Value, automaticFailure);
            obj.alertTextFallback(destination);
        end

        function destination = exportPreviousActive(obj)
            destination = "";
            try
                destination = obj.Recorder.exportLatestActive( ...
                    obj.Artifacts.destination( ...
                    "diagnostics", "previous-active-session", ".zip"));
                obj.NotifyUser( ...
                    "Previous active session bundle written to:" + newline + ...
                    destination, "Previous Session Exported");
            catch cause
                if string(cause.identifier) == ...
                        "labkit:app:runtime:NoPreviousActiveSession"
                    obj.Context.inform( ...
                        "No previous active session journal is available for this App.", ...
                        "Previous Session");
                    return;
                end
                rethrow(cause);
            end
        end

        function destination = exportTextFallback( ...
                obj, preferredDestination, cause)
            obj.Recorder.log( ...
                "warning", "diagnostics.text_fallback.started", ...
                "Diagnostic ZIP export failed; writing a plain-text fallback.", ...
                Category="runtime.lifecycle", Audience="user", ...
                Exception=cause);
            destination = obj.Recorder.exportTextFallback( ...
                preferredDestination, cause);
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
        function destination = automaticDestination(obj)
            destination = obj.Artifacts.destination( ...
                "diagnostics", diagnosticArtifactStem(), ".zip");
        end

        function filename = automaticFilename(obj)
            filename = obj.Artifacts.filename( ...
                diagnosticArtifactStem(), ".zip");
        end
    end
end

function stem = diagnosticArtifactStem()
stem = "diagnostics-sensitive-compact-state";
end

function filename = diagnosticFallbackName(zipFilename)
[~, name] = fileparts(string(zipFilename));
filename = name + "-fallback.txt";
end
