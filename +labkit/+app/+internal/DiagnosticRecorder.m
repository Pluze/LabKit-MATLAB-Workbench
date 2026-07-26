classdef (Hidden, Sealed) DiagnosticRecorder < handle
    %DIAGNOSTICRECORDER Bridge legacy diagnostics into canonical session events.
    % Expected callers are the private Runtime and transitional legacy adapters.
    % The Runtime may attach a private durable-projection close hook.

    properties (Access = private)
        Application
        Stream
        ProjectionCloseHook = []
        Closed (1, 1) logical = false
    end

    methods
        function obj = DiagnosticRecorder(application, streamOrOptions, projectionCloseHook)
            if ~isa(application, "labkit.app.Definition") || ~isscalar(application)
                error("labkit:app:runtime:InvariantFailure", ...
                    "DiagnosticRecorder requires one Definition.");
            end
            if nargin < 2 || isempty(streamOrOptions)
                streamOrOptions = labkit.app.diagnostic.Options();
            end
            if nargin < 3
                projectionCloseHook = [];
            end
            if isa(streamOrOptions, "labkit.app.internal.SessionEventStream")
                stream = streamOrOptions;
            elseif isa(streamOrOptions, "labkit.app.diagnostic.Options") && ...
                    isscalar(streamOrOptions)
                stream = labkit.app.internal.SessionEventStream(application);
            else
                error("labkit:app:runtime:InvariantFailure", ...
                    "DiagnosticRecorder requires diagnostic Options or SessionEventStream.");
            end
            obj.Application = application;
            obj.Stream = stream;
            if ~isempty(projectionCloseHook) && ~isa(projectionCloseHook, "function_handle")
                error("labkit:app:runtime:InvariantFailure", ...
                    "DiagnosticRecorder projection close hook must be a function handle.");
            end
            obj.ProjectionCloseHook = projectionCloseHook;
        end

        function operation = begin(obj, category, eventName, message, varargin)
            operation = obj.Stream.begin(category, eventName, message, varargin{:});
        end

        function finish(obj, operation, operationResult, stateDisposition, exception)
            if nargin < 4
                error("labkit:app:contract:InvalidValue", ...
                    "Diagnostic finish requires a state disposition.");
            end
            if nargin < 5
                exception = [];
            end
            obj.Stream.finish(operation, operationResult, stateDisposition, exception);
        end

        function log(obj, severity, eventName, message, varargin)
            obj.Stream.log(severity, eventName, message, varargin{:});
        end

        function events = events(obj)
            events = obj.Stream.records();
        end

        function folder = artifactFolder(~)
            folder = "";
        end

        function close(obj)
            if obj.Closed
                return;
            end
            try
                obj.Stream.close();
            catch
                % Stream teardown must not prevent projection cleanup.
            end
            if ~isempty(obj.ProjectionCloseHook)
                try
                    obj.ProjectionCloseHook();
                catch
                    % Projection teardown must not change Runtime close semantics.
                end
            end
            try
                obj.Stream.refreshProjectionHealth();
            catch
                % Health refresh must not change Runtime close semantics.
            end
            obj.Closed = true;
        end

        function delete(obj)
            obj.close();
        end
    end
end
