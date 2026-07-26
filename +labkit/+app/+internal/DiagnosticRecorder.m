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

        function finish(obj, operation, outcome, exception)
            if nargin < 4
                exception = [];
            end
            obj.Stream.finish(operation, outcome, exception);
        end

        function log(obj, severity, eventName, message, varargin)
            obj.Stream.log(severity, eventName, message, varargin{:});
        end

        function note(obj, category, targetId, signal, outcome)
            if nargin < 5
                outcome = "completed";
            end
            [eventName, attributes] = legacyEvent(targetId, signal, outcome);
            obj.Stream.log("debug", eventName, "Legacy diagnostic checkpoint.", ...
                Category=legacyCategory(category, obj.Application), ...
                Audience="developer", Attributes=attributes);
        end

        function count(obj, id, value)
            if ~(isnumeric(value) && isscalar(value) && isfinite(value) && ...
                    value >= 0 && value == fix(value))
                error("labkit:app:contract:InvalidValue", ...
                    "Diagnostic count must be a nonnegative integer.");
            end
            eventName = legacyIdentifier(id, "legacy.count", "diagnostic id");
            obj.Stream.log("debug", eventName, "Legacy diagnostic count.", ...
                Category=legacyCategory("app", obj.Application), ...
                Audience="developer", Attributes=struct( ...
                "signal", "count", "count", double(value), "outcome", "completed"));
        end

        function reportError(obj, operation, exception)
            if ~isa(exception, "MException") || ~isscalar(exception)
                error("labkit:app:contract:InvalidValue", ...
                    "Diagnostic reportError requires one MException.");
            end
            eventName = legacyErrorEventName(operation);
            diagnosticOperation = obj.Stream.begin( ...
                legacyCategory("app", obj.Application), eventName, ...
                "Legacy error reported.");
            obj.Stream.finish(diagnosticOperation, "failed", exception);
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
            obj.Stream.close();
            if ~isempty(obj.ProjectionCloseHook)
                try
                    obj.ProjectionCloseHook();
                catch
                    % Projection teardown must not change Runtime close semantics.
                end
            end
            obj.Closed = true;
        end

        function delete(obj)
            obj.close();
        end
    end
end

function category = legacyCategory(value, application)
value = lower(labkit.app.internal.SessionEventValidator.semanticIdentifier( ...
    value, "legacy diagnostic category"));
if value == "app"
    category = "app." + application.AppId + ".legacy";
elseif value == "lifecycle"
    category = "runtime.lifecycle";
else
    category = "runtime.callback";
end
end

function [eventName, attributes] = legacyEvent(targetId, signal, outcome)
eventName = legacyIdentifier(targetId, "legacy.checkpoint", ...
    "legacy diagnostic id");
signal = legacyIdentifier(signal, "checkpoint", "legacy diagnostic signal");
outcome = lower(legacyIdentifier(outcome, "completed", ...
    "legacy diagnostic outcome"));
if outcome == "reported"
    outcome = "failed";
end
attributes = struct("signal", signal, "outcome", outcome);
end

function eventName = legacyErrorEventName(operation)
eventName = legacyIdentifier(operation, "legacy.reported_error", ...
    "legacy diagnostic operation");
end

function value = legacyIdentifier(value, fallback, name)
try
    value = labkit.app.internal.SessionEventValidator.semanticIdentifier(value, name);
catch
    value = fallback;
end
end
