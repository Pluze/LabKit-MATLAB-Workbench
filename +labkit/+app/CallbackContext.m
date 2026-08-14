classdef (Sealed) CallbackContext < handle
    %CALLBACKCONTEXT Provide declared App-neutral runtime capabilities.
    %
    % Usage:
    %   context.log(severity, eventName, message, Name=Value)
    %   context.inform(message, title)
    %   context.alert(message, title)
    %   result = context.chooseOption(prompt, choices, Name=Value)
    %   result = context.chooseInputFile(filters, startPath)
    %   result = context.chooseInputFolder(startPath)
    %   result = context.chooseOutputFile(filters, startPath)
    %   result = context.chooseOutputFolder(startPath)
    %   result = context.saveProjectDocument(state, filepath)
    %   state = context.restoreProjectDocument(filepath)
    %   state = context.newProjectDocument()
    %   context.saveRecoveryDocument(state, filepath)
    %   paths = context.resolveSourcePaths(sources)
    %   paths = context.resolveSourcePaths(sources, ids)
    %   context.setResource(scope, id, value, cleanup)
    %   value = context.getResource(scope, id)
    %   context.removeResource(scope, id)
    %   context.clearResourceScope(scope)
    %   context.postEvent(eventId, updateState)
    %   result = context.writeResultPackage(folder, result)
    %
    % Description:
    %   CallbackContext is the sealed callback capability boundary. Each
    %   specifically named method invokes one private runtime operation. Apps
    %   receive this value only as a callback argument and never construct it.
    %   It exposes no figure, registry, component, launch request, debug object,
    %   or nested service bag.
    %
    % Inputs:
    %   state - Complete App-owned state value.
    %   message - Scalar reader-facing text.
    %   severity - Log severity from "trace" through "critical".
    %   eventName - Stable semantic event identifier.
    %   Category - Semantic App capability category. Default: "workflow".
    %   Audience - "user" or "developer"; default: "user".
    %   Attributes - Scalar structured diagnostic details. The Session Log,
    %       persistent journal, and diagnostic export retain these complete
    %       values. Diagnostic bundles are sensitive. Default: struct().
    %   Exception - Scalar MException associated with the event. Default: [].
    %   id - Stable semantic diagnostic or resource identifier.
    %   eventId - Stable semantic identifier used to coalesce pending events.
    %   updateState - Fixed callback
    %       state = callback(state,callbackContext). The callback receives the
    %       latest committed state when Runtime dispatches the event.
    %   count - Nonnegative integer diagnostic count.
    %   title - Scalar reader-facing dialog title. inform presents non-error
    %       information with the native information icon; alert presents a
    %       blocking problem with the native error icon.
    %   prompt - Scalar reader-facing choice prompt.
    %   choices - Row string or cellstr array.
    %   Title - Reader-facing choice-dialog title. Default:
    %       "Choose an option".
    %   DefaultChoice - Choice selected by pressing Enter. Default: the
    %       first choice.
    %   CancelChoice - Choice returned when the dialog is dismissed.
    %       Default: the first choice.
    %   filters - Runtime-supported file-dialog filter value.
    %   startPath - Scalar starting file or folder path.
    %   filepath - Scalar project or recovery source or destination path.
    %   sources - Runtime-owned portable source collection.
    %   ids - Optional source identifiers to resolve.
    %   scope - "event", "interaction", "document", or "application".
    %   value - App-neutral resource value.
    %   cleanup - Empty or fixed callback cleanup(value).
    %   folder - Scalar result-package folder.
    %   result - labkit.app.result.Package value for writeResultPackage.
    %
    % Outputs:
    %   state - Complete restored App state prepared for the current runtime
    %       transaction.
    %   result - labkit.app.dialog.Choice for dialogs, project saves, and result
    %       writing.
    %   paths - Column string array of resolved source paths.
    %   value - Stored resource value.
    %
    % Errors:
    %   labkit:app:contract:InvalidValue - A public argument is malformed.
    %   labkit:app:runtime:InvariantFailure - A private backend operation is
    %       unavailable.
    %
    % Typical Call:
    %   function state = runAnalysis(state,event,callbackContext)
    %       arguments
    %           state (1,1) struct
    %           event
    %           callbackContext (1,1) labkit.app.CallbackContext
    %       end
    %       callbackContext.log("info", "analysis.started", ...
    %           "Analysis started.");
    %   end
    %
    % Typical Call:
    %   callbackContext.postEvent("stream.refresh", @refreshStreamView);
    %
    % See also labkit.app.Definition, labkit.app.dialog.Choice,
    %   labkit.app.result.Package

    properties (Access = private)
        Backend (1, 1) struct
    end

    methods (Access = ?labkit.app.internal.runtime.CallbackContextFactory)
        function obj = CallbackContext(backend)
            if ~isstruct(backend) || ~isscalar(backend)
                error("labkit:app:runtime:InvariantFailure", ...
                    "CallbackContext backend is invalid.");
            end
            names = string(fieldnames(backend));
            if ~all(structfun(@(value) ...
                    isa(value, "function_handle") && isscalar(value), backend))
                error("labkit:app:runtime:InvariantFailure", ...
                    "CallbackContext backend operations must be function handles.");
            end
            if numel(unique(names)) ~= numel(names)
                error("labkit:app:runtime:InvariantFailure", ...
                    "CallbackContext backend operation names repeat.");
            end
            obj.Backend = backend;
        end
    end

    methods
        function log(obj, severity, eventName, message, varargin)
            options = labkit.app.internal.contract.OptionParser.parse( ...
                "labkit.app.CallbackContext.log", ...
                ["Category", "Audience", "Attributes", "Exception"], varargin{:});
            values = labkit.app.internal.diagnostics.SessionEventValidator.logInputs( ...
                severity, eventName, message, ...
                optionValue(options, "Category", "workflow"), ...
                optionValue(options, "Audience", "user"), ...
                optionValue(options, "Attributes", struct()), ...
                optionValue(options, "Exception", []));
            obj.invoke("log", "logging", ...
                {values.severity, values.eventName, values.message, ...
                values.category, values.audience, values.attributes, ...
                values.exception}, 0);
        end

        function alert(obj, message, title)
            obj.invoke("alert", "dialogs", ...
                {scalarText(message, "message"), ...
                 scalarText(title, "title")}, 0);
        end

        function inform(obj, message, title)
            obj.invoke("inform", "dialogs", ...
                {scalarText(message, "message"), ...
                 scalarText(title, "title")}, 0);
        end

        function result = chooseOption(obj, prompt, choices, varargin)
            choices = textRow(choices, "choices");
            if isempty(choices) || numel(unique(choices)) ~= numel(choices)
                error("labkit:app:contract:InvalidValue", ...
                    "CallbackContext choices must be nonempty and unique.");
            end
            options = labkit.app.internal.contract.OptionParser.parse( ...
                "labkit.app.CallbackContext.chooseOption", ...
                ["Title", "DefaultChoice", "CancelChoice"], varargin{:});
            title = scalarText(optionValue( ...
                options, "Title", "Choose an option"), "title");
            defaultChoice = choiceValue(optionValue( ...
                options, "DefaultChoice", choices(1)), ...
                choices, "DefaultChoice");
            cancelChoice = choiceValue(optionValue( ...
                options, "CancelChoice", choices(1)), ...
                choices, "CancelChoice");
            result = obj.invoke("choose", "dialogs", ...
                {scalarText(prompt, "prompt"), choices, title, ...
                 defaultChoice, cancelChoice}, 1);
            requireChoice(result, "chooseOption");
        end

        function result = chooseInputFile(obj, filters, startPath)
            result = obj.dialogPath("chooseInputFile", filters, startPath);
        end

        function result = chooseInputFolder(obj, startPath)
            result = obj.invoke("chooseInputFolder", "dialogs", ...
                {scalarText(startPath, "startPath")}, 1);
            requireChoice(result, "chooseInputFolder");
        end

        function result = chooseOutputFile(obj, filters, startPath)
            result = obj.dialogPath("chooseOutputFile", filters, startPath);
        end

        function result = chooseOutputFolder(obj, startPath)
            result = obj.invoke("chooseOutputFolder", "dialogs", ...
                {scalarText(startPath, "startPath")}, 1);
            requireChoice(result, "chooseOutputFolder");
        end

        function result = saveProjectDocument(obj, state, filepath)
            result = obj.invoke("saveProject", "project", ...
                {state, scalarText(filepath, "filepath")}, 1);
            requireChoice(result, "saveProjectDocument");
        end

        function state = restoreProjectDocument(obj, filepath)
            state = obj.invoke("restoreProject", "project", ...
                {scalarText(filepath, "filepath")}, 1);
            requireApplicationState(state, "restoreProjectDocument");
        end

        function state = newProjectDocument(obj)
            state = obj.invoke("newProject", "project", {}, 1);
            requireApplicationState(state, "newProjectDocument");
        end

        function saveRecoveryDocument(obj, state, filepath)
            obj.invoke("saveRecovery", "project", ...
                {state, scalarText(filepath, "filepath")}, 0);
        end

        function paths = resolveSourcePaths(obj, sources, ids)
            if nargin < 3
                ids = strings(0, 1);
            elseif ~(ischar(ids) || isstring(ids) || iscellstr(ids))
                error("labkit:app:contract:InvalidValue", ...
                    "CallbackContext source ids must be text.");
            elseif isempty(ids)
                ids = strings(0, 1);
            elseif ischar(ids)
                ids = string(ids);
            else
                ids = string(ids(:));
            end
            paths = obj.invoke("sourcePaths", "project", ...
                {sources, ids}, 1);
            if ~isstring(paths) || ~iscolumn(paths)
                error("labkit:app:runtime:InvariantFailure", ...
                    "CallbackContext resolveSourcePaths backend must return " + ...
                    "a column string array.");
            end
        end

        function setResource(obj, scope, id, value, cleanup)
            scope = resourceScope(scope);
            id = nonemptyText(id, "resource id");
            if ~isempty(cleanup) && ...
                    (~isa(cleanup, "function_handle") || ...
                     nargin(cleanup) ~= 1 || nargout(cleanup) > 0)
                error("labkit:app:contract:InvalidValue", ...
                    "CallbackContext cleanup must accept one value and " + ...
                    "return no outputs.");
            end
            obj.invoke("setResource", "resources", ...
                {scope, id, value, cleanup}, 0);
        end

        function value = getResource(obj, scope, id)
            value = obj.invoke("getResource", "resources", ...
                {resourceScope(scope), nonemptyText(id, "resource id")}, 1);
        end

        function removeResource(obj, scope, id)
            obj.invoke("removeResource", "resources", ...
                {resourceScope(scope), nonemptyText(id, "resource id")}, 0);
        end

        function clearResourceScope(obj, scope)
            obj.invoke("clearResourceScope", "resources", ...
                {resourceScope(scope)}, 0);
        end

        function postEvent(obj, eventId, updateState)
            eventId = semanticId(eventId, "eventId");
            if ~isa(updateState, "function_handle") || ...
                    ~isscalar(updateState) || nargin(updateState) ~= 2 || ...
                    nargout(updateState) ~= 1
                error("labkit:app:contract:InvalidValue", ...
                    "CallbackContext updateState must accept state/context " + ...
                    "and return one state value.");
            end
            obj.invoke("postEvent", "events", ...
                {eventId, updateState}, 0);
        end

        function written = writeResultPackage(obj, folder, result)
            folder = scalarText(folder, "result folder");
            if ~isa(result, "labkit.app.result.Package")
                error("labkit:app:contract:InvalidValue", ...
                    "CallbackContext writeResultPackage requires a " + ...
                    "labkit.app.result.Package value.");
            end
            written = obj.invoke("writeResult", "results", ...
                {folder, result}, 1);
            requireChoice(written, "writeResultPackage");
        end
    end

    methods (Access = private)
        function result = dialogPath(obj, operation, filters, startPath)
            result = obj.invoke(operation, "dialogs", ...
                {filters, scalarText(startPath, "startPath")}, 1);
            requireChoice(result, operation);
        end

        function varargout = invoke(obj, operation, ~, inputs, outputs)
            if ~isfield(obj.Backend, operation)
                error("labkit:app:runtime:InvariantFailure", ...
                    "CallbackContext backend operation is unavailable: %s.", ...
                    operation);
            end
            callback = obj.Backend.(operation);
            if outputs == 0
                callback(inputs{:});
                varargout = {};
            else
                [varargout{1:outputs}] = callback(inputs{:});
            end
        end
    end
end

function requireApplicationState(state, operation)
            if ~isstruct(state) || ~isscalar(state) || ...
                    ~all(isfield(state, ["project", "session"]))
                error("labkit:app:runtime:InvariantFailure", ...
                    "CallbackContext %s backend must return scalar " + ...
                    "project/session state.", operation);
            end
end

function value = scalarText(value, label)
    if ~(ischar(value) || (isstring(value) && isscalar(value)))
        error("labkit:app:contract:InvalidValue", ...
            "CallbackContext %s must be scalar text.", label);
    end
    value = string(value);
end

function value = nonemptyText(value, label)
    value = scalarText(value, label);
    if strlength(value) == 0
        error("labkit:app:contract:InvalidValue", ...
            "CallbackContext %s must be nonempty.", label);
    end
end

function value = semanticId(value, label)
value = nonemptyText(value, label);
if isempty(regexp(char(value), "^[A-Za-z][A-Za-z0-9._-]*$", "once"))
    error("labkit:app:contract:InvalidValue", ...
        "CallbackContext %s must be a semantic identifier.", label);
end
end

function values = textRow(values, label)
    if ischar(values)
        values = string(values);
    elseif iscellstr(values)
        values = string(values);
    elseif ~isstring(values)
        error("labkit:app:contract:InvalidValue", ...
            "CallbackContext %s must be text.", label);
    end
    values = reshape(values, 1, []);
end

function value = resourceScope(value)
    value = nonemptyText(value, "resource scope");
    if ~any(value == ["event", "interaction", "document", "application"])
        error("labkit:app:contract:InvalidValue", ...
            "CallbackContext resource scope is unsupported: %s.", value);
    end
end

function requireChoice(value, operation)
    if ~isa(value, "labkit.app.dialog.Choice")
        error("labkit:app:runtime:InvariantFailure", ...
            "CallbackContext %s backend must return Choice.", operation);
    end
end

function value = choiceValue(value, choices, name)
value = scalarText(value, name);
if ~any(choices == value)
    error("labkit:app:contract:InvalidValue", ...
        "CallbackContext %s must name one declared choice.", name);
end
end

function value = optionValue(options, name, fallback)
value = fallback;
if isfield(options, name)
    value = options.(name);
end
end
