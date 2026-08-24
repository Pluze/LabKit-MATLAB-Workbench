classdef (Hidden, Sealed) RuntimeDiagnostics < handle
    % Own Runtime session-log viewing and capture control.
    % Caller: RuntimeKernel. SessionDiagnostics remains the event/journal
    % primitive; this owner supplies the App-named live viewer boundary.

    properties (Access = private)
        Recorder
        DisplayName (1, 1) string
    end

    methods
        function obj = RuntimeDiagnostics(recorder, displayName)
            if ~isa(recorder, ...
                    "labkit.app.internal.diagnostics.SessionDiagnostics") || ...
                    ~isscalar(recorder)
                error("labkit:app:runtime:InvariantFailure", ...
                    "Runtime diagnostic dependencies are invalid.");
            end
            obj.Recorder = recorder;
            obj.DisplayName = string(displayName);
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

    end
end
