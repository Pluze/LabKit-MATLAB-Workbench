classdef (Hidden, Sealed) SessionEventStream < handle
    %SESSIONEVENTSTREAM Private privacy-safe in-memory session event stream.
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
        Closed (1, 1) logical = false
    end

    methods
        function obj = SessionEventStream(application, varargin)
            if ~isa(application, "labkit.app.Definition") || ~isscalar(application)
                error("labkit:app:runtime:InvariantFailure", ...
                    "SessionEventStream requires one Definition.");
            end
            sessionId = optionValue(varargin, "SessionId", newSessionId());
            obj.Application = application;
            obj.SessionId = semanticText(sessionId, "sessionId");
            obj.StartedAt = datetime("now", TimeZone="UTC", ...
                Format="yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
            obj.StartedTimer = tic;
            obj.Records = repmat(recordTemplate(), 0, 1);
            obj.log("info", "session.started", "Session started.", ...
                Category="runtime.lifecycle", Audience="developer");
        end

        function operation = begin(obj, category, eventName, message, varargin)
            category = semanticText(category, "category");
            eventName = semanticText(eventName, "eventName");
            message = privacySafeText(message, "message");
            attributes = optionValue(varargin, "Attributes", struct());
            attributes = privacySafeAttributes(attributes);
            obj.OperationSequence = obj.OperationSequence + 1;
            parent = obj.currentOperation();
            operation = struct( ...
                "Id", "op-" + string(obj.OperationSequence), ...
                "ParentId", parent.Id, ...
                "RootActionId", parent.RootActionId, ...
                "Category", category, "EventName", eventName, "Timer", tic);
            if strlength(operation.RootActionId) == 0
                operation.RootActionId = operation.Id;
            end
            obj.OperationStack{end + 1} = operation;
            obj.log("debug", eventName + ".started", message, ...
                Category=category, Audience="developer", Attributes=attributes, ...
                Operation=operation);
        end

        function finish(obj, operation, outcome, exception)
            if nargin < 4
                exception = [];
            end
            operation = validOperation(operation);
            outcome = semanticText(outcome, "outcome");
            severity = "debug";
            if ~isempty(exception)
                severity = "error";
            elseif outcome ~= "completed"
                severity = "warning";
            end
            obj.log(severity, operation.EventName + ".completed", ...
                "Operation completed.", Category=operation.Category, ...
                Audience="developer", ...
                Attributes=struct("outcome", outcome, ...
                "durationSeconds", toc(operation.Timer)), ...
                Exception=exception, Operation=operation);
            obj.removeOperation(operation.Id);
        end

        function log(obj, severity, eventName, message, varargin)
            if obj.Closed
                return;
            end
            severity = severityText(severity);
            eventName = semanticText(eventName, "eventName");
            message = privacySafeText(message, "message");
            category = semanticText(optionValue(varargin, "Category", "runtime.lifecycle"), ...
                "category");
            audience = audienceText(optionValue(varargin, "Audience", "developer"));
            attributes = privacySafeAttributes(optionValue(varargin, "Attributes", struct()));
            exception = exceptionProjection(optionValue(varargin, "Exception", []));
            operation = optionValue(varargin, "Operation", []);
            if isempty(operation)
                operation = obj.currentOperation();
            else
                operation = validOperation(operation);
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
            if isfield(attributes, "outcome")
                record.outcome = string(attributes.outcome);
            end
            if isfield(attributes, "durationSeconds")
                record.durationSeconds = double(attributes.durationSeconds);
            end
            record.exception = exception;
            obj.retain(record);
        end

        function records = records(obj)
            records = obj.Records;
        end

        function close(obj)
            if obj.Closed
                return;
            end
            obj.log("info", "session.closed", "Session closed.", ...
                Category="runtime.lifecycle", Audience="developer");
            obj.OperationStack = {};
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

        function removeOperation(obj, id)
            if isempty(obj.OperationStack)
                return;
            end
            ids = string(cellfun(@(entry) entry.Id, obj.OperationStack, ...
                UniformOutput=false));
            index = find(ids == string(id), 1, "last");
            if ~isempty(index)
                obj.OperationStack(index) = [];
            end
        end

        function retain(obj, record)
            obj.Records(end + 1, 1) = record;
            if numel(obj.Records) > 512
                obj.Records(1) = [];
            end
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
    "outcome", "", "durationSeconds", [], "exception", emptyException());
end

function operation = emptyOperation()
operation = struct("Id", "", "ParentId", "", "RootActionId", "", ...
    "Category", "", "EventName", "", "Timer", []);
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

function value = semanticText(value, name)
if ~(ischar(value) || (isstring(value) && isscalar(value))) || strlength(strip(string(value))) == 0
    error("labkit:app:contract:InvalidValue", ...
        "Session event %s must be nonempty scalar text.", name);
end
value = string(value);
if ~isempty(regexp(char(value), "^[A-Za-z][A-Za-z0-9._-]*$", "once"))
    return;
end
error("labkit:app:contract:InvalidValue", ...
    "Session event %s must be a semantic identifier.", name);
end

function value = severityText(value)
value = lower(semanticText(value, "severity"));
if ~any(value == ["trace", "debug", "info", "warning", "error", "critical"])
    error("labkit:app:contract:InvalidValue", "Unsupported log severity: %s.", value);
end
end

function value = audienceText(value)
value = lower(semanticText(value, "audience"));
if ~any(value == ["user", "developer"])
    error("labkit:app:contract:InvalidValue", ...
        "Session event audience must be user or developer.");
end
end

function value = privacySafeText(value, name)
if ~(ischar(value) || (isstring(value) && isscalar(value)))
    error("labkit:app:contract:InvalidValue", ...
        "Session event %s must be scalar text.", name);
end
value = string(value);
if strlength(value) > 512
    error("labkit:app:contract:InvalidValue", ...
        "Session event %s exceeds the retained-text limit.", name);
end
if ~isempty(regexp(char(value), ...
        "(?i)([A-Z]:[\\\\/]|\\\\\\\\|\\b[^\\s\\\\/]+\\.(csv|mat|json|txt|png|jpg|jpeg|tif|tiff|avi|xlsx|dta|rhs)\\b)", "once"))
    error("labkit:app:contract:UnsafeLogData", ...
        "Session event %s must not contain a path or original filename.", name);
end
end

function attributes = privacySafeAttributes(attributes)
if ~isstruct(attributes) || ~isscalar(attributes) || numel(fieldnames(attributes)) > 16
    error("labkit:app:contract:InvalidValue", ...
        "Session event attributes must be one bounded scalar struct.");
end
names = string(fieldnames(attributes));
for index = 1:numel(names)
    name = semanticText(names(index), "attribute key");
    value = attributes.(name);
    if ischar(value) || (isstring(value) && isscalar(value))
        attributes.(name) = privacySafeText(value, "attribute value");
    elseif isnumeric(value) || islogical(value)
        if numel(value) > 16 || any(~isfinite(double(value)), "all")
            error("labkit:app:contract:InvalidValue", ...
                "Session event numeric attributes must be finite and bounded.");
        end
    elseif isstruct(value) && isscalar(value)
        attributes.(name) = privacySafeAttributes(value);
    else
        error("labkit:app:contract:InvalidValue", ...
            "Session event attributes must use privacy-safe scalar values.");
    end
end
end

function operation = validOperation(operation)
needed = ["Id", "ParentId", "RootActionId", "Category", "EventName", "Timer"];
if ~isstruct(operation) || ~isscalar(operation) || ~all(isfield(operation, needed))
    error("labkit:app:runtime:InvariantFailure", "Session operation is invalid.");
end
end

function exception = emptyException()
exception = struct("identifier", "", "message", "", "stack", strings(0, 1));
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
exception.message = "Exception captured.";
exception.stack = string({value.stack.name}).';
end

function value = newSessionId()
value = "session-" + string(datetime("now", Format="yyyyMMddHHmmssSSS")) + ...
    "-" + string(randi([0, 999999]));
end
