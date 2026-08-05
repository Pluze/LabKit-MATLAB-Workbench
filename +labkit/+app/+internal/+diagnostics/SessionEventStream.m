classdef (Hidden, Sealed) SessionEventStream < handle
    %SESSIONEVENTSTREAM Private full-detail in-memory session event stream.
    % Expected callers are the private App Runtime and focused framework tests.
    % Records are validated before entering the bounded ring; persistence and
    % viewer projections intentionally belong to later migration checkpoints.

    properties (Access = private)
        Application
        SessionId (1, 1) string
        StartedAt (1, 1) datetime
        StartedTimer
        Sequence (1, 1) double = 0
        OperationSequence (1, 1) double = 0
        Records
        OperationStack (1, :) cell = {}
        FinishedOperationIds (1, :) string = strings(1, 0)
        ProjectionHook = []
        ProjectionHealthHook = []
        ProjectionHealthUnavailableReported (1, 1) logical = false
        TraceEnabled (1, 1) logical = false
        ErrorOrCriticalObserved (1, 1) logical = false
        ConsumerSequence (1, 1) double = 0
        Consumers (1, :) struct = struct( ...
            "Id", strings(1, 0), "Callback", cell(1, 0))
        Closed (1, 1) logical = false
    end

    properties (Constant, Access = private)
        % A temporary immediate-view bound until Phase 3 profiles durable policy.
        ProvisionalInMemoryRecordLimit = 512
    end

    methods
        function obj = SessionEventStream(application, varargin)
            if ~isa(application, "labkit.app.Definition") || ~isscalar(application)
                error("labkit:app:runtime:InvariantFailure", ...
                    "SessionEventStream requires one Definition.");
            end
            sessionId = optionValue(varargin, "SessionId", ...
                labkit.app.internal.diagnostics.SessionIdentity.create());
            projectionHook = optionValue(varargin, "ProjectionHook", []);
            projectionHealthHook = optionValue(varargin, "ProjectionHealthHook", []);
            traceEnabled = optionValue(varargin, "TraceEnabled", false);
            if ~isempty(projectionHook) && ~isa(projectionHook, "function_handle")
                error("labkit:app:contract:InvalidValue", ...
                    "Session event ProjectionHook must be a function handle.");
            end
            if ~isempty(projectionHealthHook) && ~isa(projectionHealthHook, "function_handle")
                error("labkit:app:contract:InvalidValue", ...
                    "Session event ProjectionHealthHook must be a function handle.");
            end
            if ~(islogical(traceEnabled) && isscalar(traceEnabled))
                error("labkit:app:contract:InvalidValue", ...
                    "Session event TraceEnabled must be scalar logical.");
            end
            obj.Application = application;
            obj.SessionId = labkit.app.internal.diagnostics.SessionEventValidator.semanticIdentifier( ...
                sessionId, "sessionId");
            obj.StartedAt = datetime("now", TimeZone="UTC", ...
                Format="yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
            obj.StartedTimer = tic;
            obj.Records = repmat(recordTemplate(), 0, 1);
            obj.ProjectionHook = projectionHook;
            obj.ProjectionHealthHook = projectionHealthHook;
            obj.TraceEnabled = traceEnabled;
            obj.log("info", "session.started", "Session started.", ...
                Category="runtime.lifecycle", Audience="developer");
        end

        function operation = begin(obj, category, eventName, message, varargin)
            obj.ensureOpen();
            category = labkit.app.internal.diagnostics.SessionEventValidator.semanticIdentifier( ...
                category, "category");
            eventName = labkit.app.internal.diagnostics.SessionEventValidator.semanticIdentifier( ...
                eventName, "eventName");
            values = labkit.app.internal.diagnostics.SessionEventValidator.logInputs( ...
                "debug", eventName, message, category, "developer", ...
                optionValue(varargin, "Attributes", struct()), []);
            message = values.message;
            attributes = values.attributes;
            obj.OperationSequence = obj.OperationSequence + 1;
            parent = obj.currentOperation();
            operation = struct( ...
                "Id", "op-" + string(obj.OperationSequence), ...
                "ParentId", parent.Id, ...
                "RootActionId", parent.RootActionId, ...
                "Category", category, "EventName", eventName, ...
                "SessionId", obj.SessionId, "Timer", tic);
            if strlength(operation.RootActionId) == 0
                operation.RootActionId = operation.Id;
            end
            obj.OperationStack{end + 1} = operation;
            obj.log("debug", eventName + ".started", message, ...
                Category=category, Audience="developer", Attributes=attributes, ...
                Operation=operation);
        end

        function finish(obj, operation, operationResult, stateDisposition, exception)
            if nargin < 4
                error("labkit:app:contract:InvalidValue", ...
                    "Session operation finish requires a state disposition.");
            end
            if nargin < 5
                exception = [];
            end
            obj.ensureOpen();
            operation = validOperation(operation);
            obj.requireActiveTopOperation(operation);
            terminal = labkit.app.internal.diagnostics.SessionEventValidator.terminalFields( ...
                operationResult, stateDisposition);
            if ~isempty(exception) && terminal.operationResult ~= "failed"
                error("labkit:app:contract:InvalidValue", ...
                    "A session exception requires a failed operation result.");
            end
            severity = "debug";
            if ~isempty(exception)
                severity = "error";
            elseif terminal.operationResult ~= "completed"
                severity = "warning";
            end
            obj.log(severity, operation.EventName + "." + terminal.operationResult, ...
                terminalMessage(terminal.operationResult), Category=operation.Category, ...
                Audience="developer", ...
                Attributes=struct("durationSeconds", toc(operation.Timer)), ...
                Terminal=terminal, ...
                Exception=exception, Operation=operation);
            obj.OperationStack(end) = [];
            obj.rememberFinishedOperation(operation.Id);
        end

        function log(obj, severity, eventName, message, varargin)
            obj.ensureOpen();
            values = labkit.app.internal.diagnostics.SessionEventValidator.logInputs( ...
                severity, eventName, message, ...
                optionValue(varargin, "Category", "runtime.lifecycle"), ...
                optionValue(varargin, "Audience", "developer"), ...
                optionValue(varargin, "Attributes", struct()), ...
                optionValue(varargin, "Exception", []));
            severity = values.severity;
            eventName = values.eventName;
            message = values.message;
            category = values.category;
            audience = values.audience;
            attributes = values.attributes;
            exception = exceptionProjection(values.exception);
            if severity == "trace" && ~obj.TraceEnabled
                return;
            end
            operation = optionValue(varargin, "Operation", []);
            if isempty(operation)
                operation = obj.currentOperation();
            else
                operation = validOperation(operation);
                obj.requireActiveOperation(operation);
            end
            obj.Sequence = obj.Sequence + 1;
            record = recordTemplate();
            record.schemaVersion = 1;
            record.sequence = obj.Sequence;
            record.timestampUtc = string(datetime("now", TimeZone="UTC", ...
                Format="yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"));
            record.elapsedSeconds = toc(obj.StartedTimer);
            record.severity = upper(severity);
            record.audience = audience;
            record.category = category;
            record.eventName = eventName;
            record.message = message;
            record.attributes = attributes;
            record.sessionId = obj.SessionId;
            record.appId = obj.Application.AppId;
            record.operationId = operation.Id;
            record.parentOperationId = operation.ParentId;
            record.rootActionId = operation.RootActionId;
            terminal = optionValue(varargin, "Terminal", []);
            if ~isempty(terminal)
                terminal = labkit.app.internal.diagnostics.SessionEventValidator.terminalFields( ...
                    terminal.operationResult, terminal.stateDisposition);
                record.operationResult = terminal.operationResult;
                record.stateDisposition = terminal.stateDisposition;
            end
            if isfield(attributes, "durationSeconds")
                record.durationSeconds = double(attributes.durationSeconds);
            end
            record.exception = exception;
            obj.retain(record);
            if any(severity == ["error", "critical"])
                obj.ErrorOrCriticalObserved = true;
                if ~obj.TraceEnabled
                    obj.setTraceEnabled(true);
                end
            end
        end

        function observed = hasErrorOrCriticalEvent(obj)
            observed = obj.ErrorOrCriticalObserved;
        end

        function records = records(obj)
            records = obj.Records;
        end

        function snapshot = captureSnapshot(obj)
            snapshot = struct( ...
                "events", obj.Records, ...
                "traceEnabled", obj.TraceEnabled, ...
                "inMemoryTruncated", obj.Sequence > numel(obj.Records), ...
                "retainedRecordCount", numel(obj.Records), ...
                "totalRecordCount", obj.Sequence);
        end

        function setTraceEnabled(obj, enabled)
            obj.ensureOpen();
            if ~(islogical(enabled) && isscalar(enabled))
                error("labkit:app:contract:InvalidValue", ...
                    "Trace capture state must be scalar logical.");
            end
            if obj.TraceEnabled == enabled
                return;
            end
            obj.TraceEnabled = enabled;
            if enabled
                obj.log("info", "trace.capture_enabled", ...
                    "Trace capture enabled.", ...
                    Category="runtime.lifecycle", Audience="developer");
            else
                obj.log("info", "trace.capture_disabled", ...
                    "Trace capture disabled.", ...
                    Category="runtime.lifecycle", Audience="developer");
            end
        end

        function token = subscribe(obj, callback)
            obj.ensureOpen();
            if ~isa(callback, "function_handle")
                error("labkit:app:contract:InvalidValue", ...
                    "Session event consumer must be a function handle.");
            end
            obj.ConsumerSequence = obj.ConsumerSequence + 1;
            token = "consumer-" + string(obj.ConsumerSequence);
            obj.Consumers(end + 1) = struct( ...
                "Id", token, "Callback", callback);
        end

        function unsubscribe(obj, token)
            token = string(token);
            if ~isscalar(token) || ismissing(token)
                return;
            end
            keep = string({obj.Consumers.Id}) ~= token;
            obj.Consumers = obj.Consumers(keep);
        end

        function refreshProjectionHealth(obj)
            % Allow private close teardown to expose a final sink failure.
            obj.drainProjectionHealth();
        end

        function close(obj)
            if obj.Closed
                return;
            end
            while ~isempty(obj.OperationStack)
                obj.finish(obj.OperationStack{end}, "abandoned", "unknown");
            end
            obj.log("info", "session.closed", "Session closed.", ...
                Category="runtime.lifecycle", Audience="developer");
            obj.Closed = true;
        end
    end

    methods (Access = private)
        function operation = currentOperation(obj)
            operation = emptyOperation();
            if ~isempty(obj.OperationStack)
                operation = obj.OperationStack{end};
            end
        end

        function ensureOpen(obj)
            if obj.Closed
                error("labkit:app:runtime:OperationClosed", ...
                    "Session event stream is closed.");
            end
        end

        function requireActiveOperation(obj, operation)
            if operation.SessionId ~= obj.SessionId
                error("labkit:app:runtime:UnknownOperation", ...
                    "Session operation does not belong to this stream.");
            end
            ids = string(cellfun(@(entry) entry.Id, obj.OperationStack, ...
                UniformOutput=false));
            if ~any(ids == operation.Id)
                if any(obj.FinishedOperationIds == operation.Id)
                    error("labkit:app:runtime:OperationAlreadyFinished", ...
                        "Session operation already has a terminal result.");
                end
                error("labkit:app:runtime:UnknownOperation", ...
                    "Session operation is not active.");
            end
        end

        function requireActiveTopOperation(obj, operation)
            obj.requireActiveOperation(operation);
            if obj.OperationStack{end}.Id ~= operation.Id
                error("labkit:app:runtime:OutOfOrderOperation", ...
                    "Nested session operations must finish in stack order.");
            end
        end

        function rememberFinishedOperation(obj, id)
            obj.FinishedOperationIds(end + 1) = string(id);
            if numel(obj.FinishedOperationIds) > obj.ProvisionalInMemoryRecordLimit
                obj.FinishedOperationIds(1) = [];
            end
        end

        function retain(obj, record, notifyProjection)
            if nargin < 3
                notifyProjection = true;
            end
            obj.Records(end + 1, 1) = record;
            if numel(obj.Records) > obj.ProvisionalInMemoryRecordLimit
                obj.Records(1) = [];
            end
            if notifyProjection
                obj.notifyProjectionHook(record);
            end
            obj.notifyConsumers(record);
            if notifyProjection
                obj.drainProjectionHealth(record);
            end
        end

        function notifyProjectionHook(obj, record)
            if isempty(obj.ProjectionHook)
                return;
            end
            try
                obj.ProjectionHook(record);
            catch
                % Downstream projections must not alter canonical history.
            end
        end

        function drainProjectionHealth(obj, contextRecord)
            if nargin < 2
                contextRecord = [];
            end
            if isempty(obj.ProjectionHealthHook)
                return;
            end
            try
                notifications = obj.ProjectionHealthHook();
                if isempty(notifications)
                    return;
                end
                if ~isstruct(notifications)
                    error("labkit:app:runtime:InvariantFailure", ...
                        "Projection health notifications must be structs.");
                end
                for index = 1:numel(notifications)
                    [eventName, attributes] = projectionHealthNotification( ...
                        notifications(index));
                    obj.retainProjectionHealth(eventName, attributes, contextRecord);
                end
            catch
                obj.ProjectionHealthHook = [];
                if ~obj.ProjectionHealthUnavailableReported
                    obj.ProjectionHealthUnavailableReported = true;
                    obj.retainProjectionHealth("journal.degraded", ...
                        struct("reason", "health-unavailable"), contextRecord);
                end
            end
        end

        function retainProjectionHealth(obj, eventName, attributes, contextRecord)
            if nargin < 4
                contextRecord = [];
            end
            attributes = labkit.app.internal.diagnostics.SessionEventValidator.privacySafeAttributes( ...
                attributes);
            if isempty(contextRecord)
                operation = obj.currentOperation();
                operationId = operation.Id;
                parentOperationId = operation.ParentId;
                rootActionId = operation.RootActionId;
            else
                contextFields = ["operationId", "parentOperationId", "rootActionId"];
                if ~isstruct(contextRecord) || ~isscalar(contextRecord) || ...
                        ~all(isfield(contextRecord, contextFields))
                    error("labkit:app:runtime:InvariantFailure", ...
                        "Projection health context record is invalid.");
                end
                operationId = string(contextRecord.operationId);
                parentOperationId = string(contextRecord.parentOperationId);
                rootActionId = string(contextRecord.rootActionId);
            end
            obj.Sequence = obj.Sequence + 1;
            record = recordTemplate();
            record.schemaVersion = 1;
            record.sequence = obj.Sequence;
            record.timestampUtc = string(datetime("now", TimeZone="UTC", ...
                Format="yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"));
            record.elapsedSeconds = toc(obj.StartedTimer);
            record.severity = "WARNING";
            record.audience = "developer";
            record.category = "runtime.journal";
            record.eventName = eventName;
            record.message = projectionHealthMessage(eventName);
            record.attributes = attributes;
            record.sessionId = obj.SessionId;
            record.appId = obj.Application.AppId;
            record.operationId = operationId;
            record.parentOperationId = parentOperationId;
            record.rootActionId = rootActionId;
            record.exception = emptyException();
            obj.retain(record, false);
        end

        function notifyConsumers(obj, record)
            if isempty(obj.Consumers)
                return;
            end
            keep = true(1, numel(obj.Consumers));
            for index = 1:numel(obj.Consumers)
                try
                    obj.Consumers(index).Callback(record);
                catch
                    keep(index) = false;
                end
            end
            obj.Consumers = obj.Consumers(keep);
        end
    end
end

function record = recordTemplate()
record = struct( ...
    "schemaVersion", 1, "sequence", 0, "timestampUtc", "", ...
    "elapsedSeconds", 0, "severity", "", "audience", "", ...
    "category", "", "eventName", "", "message", "", ...
    "attributes", struct(), "sessionId", "", "appId", "", ...
    "operationId", "", "parentOperationId", "", "rootActionId", "", ...
    "operationResult", "", "stateDisposition", "", "durationSeconds", [], ...
    "exception", emptyException());
end

function operation = emptyOperation()
operation = struct("Id", "", "ParentId", "", "RootActionId", "", ...
    "Category", "", "EventName", "", "SessionId", "", "Timer", []);
end

function value = optionValue(values, name, defaultValue)
value = defaultValue;
if mod(numel(values), 2) ~= 0
    error("labkit:app:contract:InvalidValue", ...
        "Session event options must be name-value pairs.");
end
for index = 1:2:numel(values)
    optionName = string(values{index});
    if optionName == string(name)
        value = values{index + 1};
        return;
    end
end
end

function operation = validOperation(operation)
needed = ["Id", "ParentId", "RootActionId", "Category", "EventName", "SessionId", "Timer"];
if ~isstruct(operation) || ~isscalar(operation) || ~all(isfield(operation, needed))
    error("labkit:app:runtime:InvariantFailure", "Session operation is invalid.");
end
end

function message = terminalMessage(operationResult)
if operationResult == "completed"
    message = "Operation completed.";
elseif operationResult == "failed"
    message = "Operation failed.";
else
    message = "Operation settled.";
end
end

function exception = emptyException()
exception = struct("identifier", "", "message", "", "stack", strings(0, 1));
end

function [eventName, attributes] = projectionHealthNotification(notification)
if ~isstruct(notification) || ~isscalar(notification) || ...
        ~isequal(string(fieldnames(notification)), ["eventName"; "reason"; "count"])
    error("labkit:app:runtime:InvariantFailure", ...
        "Projection health notification is invalid.");
end
eventName = string(notification.eventName);
attributes = labkit.app.internal.diagnostics.SessionEventValidator.privacySafeAttributes( ...
    struct("reason", notification.reason));
count = notification.count;
if eventName == "journal.degraded"
    if ~(isnumeric(count) && isreal(count) && isscalar(count) && ...
            isfinite(count) && count == 0)
        error("labkit:app:runtime:InvariantFailure", ...
            "Journal degradation notifications use a fixed count.");
    end
elseif eventName == "journal.records_dropped"
    if ~(isnumeric(count) && isreal(count) && isscalar(count) && ...
            isfinite(count) && count >= 1 && count == fix(count))
        error("labkit:app:runtime:InvariantFailure", ...
            "Journal drop notifications require a positive integer delta.");
    end
    attributes.count = double(count);
else
    error("labkit:app:runtime:InvariantFailure", ...
        "Projection health event is not part of the closed protocol.");
end
end

function message = projectionHealthMessage(eventName)
if eventName == "journal.degraded"
    message = "Detailed session logging became unavailable; in-memory diagnostics continue.";
elseif eventName == "journal.records_dropped"
    message = "Some detailed session log records could not be saved.";
else
    error("labkit:app:runtime:InvariantFailure", ...
        "Projection health event is not part of the closed protocol.");
end
end


function exception = exceptionProjection(value)
exception = emptyException();
if isempty(value)
    return;
end
if ~isa(value, "MException") || ~isscalar(value)
    error("labkit:app:contract:InvalidValue", ...
        "Session event Exception must be a scalar MException.");
end
exception.identifier = string(value.identifier);
exception.message = string(value.message);
stack = value.stack;
exception.stack = strings(numel(stack), 1);
for index = 1:numel(stack)
    exception.stack(index) = string(stack(index).name) + " (" + ...
        string(stack(index).file) + ":" + string(stack(index).line) + ")";
end
end
