classdef (Sealed) RuntimeContext < handle
    %RUNTIMECONTEXT Provide declared App-neutral runtime capabilities.
    %
    % Usage:
    %   context = labkit.ui.RuntimeContext()
    %   context.dispatch(command, payload)
    %   state = context.appendStatus(state, message)
    %   context.reportError(operation, exception)
    %   context.alert(message, title)
    %   result = context.choose(prompt, choices)
    %   result = context.chooseInputFile(filters, startPath)
    %   result = context.chooseInputFolder(startPath)
    %   result = context.chooseOutputFile(filters, startPath)
    %   result = context.chooseOutputFolder(startPath)
    %   result = context.saveProject(state, filepath)
    %   context.saveRecovery(state, filepath)
    %   record = context.sourceRecord(id, role, path, required)
    %   sources = context.upsertSource(sources, record)
    %   sources = context.reconcileSources(current, incoming)
    %   surface = context.acquireRenderSurface(target)
    %   context.setResource(scope, id, value, cleanup)
    %   value = context.getResource(scope, id)
    %   context.removeResource(scope, id)
    %   context.clearResourceScope(scope)
    %   result = context.writeResult(folder, result)
    %
    % Description:
    %   RuntimeContext is the sealed callback capability boundary. Application
    %   declares capability groups before launch; every method verifies that
    %   declaration before invoking a private runtime backend. The public
    %   zero-argument constructor creates a no-capability context for tests
    %   whose callbacks must remain pure. It exposes no figure, registry,
    %   component, launch request, debug object, or nested service bag.
    %
    % Inputs:
    %   command - Declared labkit.ui.Command value.
    %   payload - Value documented by the Command Role or interaction.
    %   state - Complete App-owned state value.
    %   message - Scalar reader-facing text.
    %   operation - Scalar diagnostic operation text.
    %   exception - Scalar MException.
    %   title - Scalar reader-facing dialog title.
    %   prompt - Scalar reader-facing choice prompt.
    %   choices - Row string or cellstr array.
    %   filters - Runtime-supported file-dialog filter value.
    %   startPath - Scalar starting file or folder path.
    %   filepath - Scalar project or recovery destination path.
    %   id - Nonempty semantic source or resource identifier.
    %   role - Nonempty semantic source role.
    %   path - Scalar source path.
    %   required - Logical scalar source requirement.
    %   sources - Runtime-owned portable source collection.
    %   record - Runtime-owned portable source value.
    %   current - Existing runtime-owned portable source collection.
    %   incoming - Replacement runtime-owned portable source collection.
    %   target - Declared renderer target ID.
    %   scope - "event", "interaction", "document", or "application".
    %   value - App-neutral resource value.
    %   cleanup - Empty or fixed callback cleanup(value).
    %   folder - Scalar result-package folder.
    %   result - labkit.ui.Result value for writeResult.
    %
    % Outputs:
    %   context - Sealed labkit.ui.RuntimeContext value.
    %   state - State returned by the workflow backend.
    %   result - labkit.ui.DialogResult for dialogs, project saves, and result
    %       writing.
    %   record - Opaque runtime-owned portable source value.
    %   sources - Updated runtime-owned portable source collection.
    %   surface - Event-scoped restricted render surface.
    %   value - Stored resource value.
    %
    % Errors:
    %   labkit:ui:contract:InvalidValue - A public argument is malformed.
    %   labkit:ui:contract:UnknownReference - A Command or renderer target is
    %       undeclared.
    %   labkit:ui:runtime:InvariantFailure - A method capability was not
    %       declared or its private backend operation is unavailable.
    %
    % Example:
    %   context = labkit.ui.RuntimeContext();
    %   try
    %       context.alert("Message", "Title");
    %   catch ME
    %       assert(ME.identifier == "labkit:ui:runtime:InvariantFailure")
    %   end
    %
    % See also labkit.ui.Application, labkit.ui.Command,
    %   labkit.ui.DialogResult, labkit.ui.Result

    properties (SetAccess = private)
        Capabilities (1, :) string
    end

    properties (Access = private)
        Backend (1, 1) struct
        CommandIds (1, :) string
        TargetIds (1, :) string
    end

    methods
        function obj = RuntimeContext()
            obj.Capabilities = strings(1, 0);
            obj.Backend = struct();
            obj.CommandIds = strings(1, 0);
            obj.TargetIds = strings(1, 0);
        end

        function dispatch(obj, command, payload)
            if ~isa(command, "labkit.ui.Command") || ...
                    ~any(obj.CommandIds == command.Id)
                error("labkit:ui:contract:UnknownReference", ...
                    "RuntimeContext dispatch Command is undeclared.");
            end
            obj.invoke("dispatch", "dispatch", {command, payload}, 0);
        end

        function state = appendStatus(obj, state, message)
            message = scalarText(message, "message");
            state = obj.invoke("appendStatus", "workflow", ...
                {state, message}, 1);
        end

        function reportError(obj, operation, exception)
            operation = scalarText(operation, "operation");
            if ~isa(exception, "MException") || ~isscalar(exception)
                error("labkit:ui:contract:InvalidValue", ...
                    "RuntimeContext exception must be a scalar MException.");
            end
            obj.invoke("reportError", "diagnostics", ...
                {operation, exception}, 0);
        end

        function alert(obj, message, title)
            obj.invoke("alert", "dialogs", ...
                {scalarText(message, "message"), ...
                 scalarText(title, "title")}, 0);
        end

        function result = choose(obj, prompt, choices)
            choices = textRow(choices, "choices");
            result = obj.invoke("choose", "dialogs", ...
                {scalarText(prompt, "prompt"), choices}, 1);
            requireDialogResult(result, "choose");
        end

        function result = chooseInputFile(obj, filters, startPath)
            result = obj.dialogPath("chooseInputFile", filters, startPath);
        end

        function result = chooseInputFolder(obj, startPath)
            result = obj.dialogPath( ...
                "chooseInputFolder", [], startPath);
        end

        function result = chooseOutputFile(obj, filters, startPath)
            result = obj.dialogPath("chooseOutputFile", filters, startPath);
        end

        function result = chooseOutputFolder(obj, startPath)
            result = obj.dialogPath( ...
                "chooseOutputFolder", [], startPath);
        end

        function result = saveProject(obj, state, filepath)
            result = obj.invoke("saveProject", "project", ...
                {state, scalarText(filepath, "filepath")}, 1);
            requireDialogResult(result, "saveProject");
        end

        function saveRecovery(obj, state, filepath)
            obj.invoke("saveRecovery", "project", ...
                {state, scalarText(filepath, "filepath")}, 0);
        end

        function record = sourceRecord(obj, id, role, path, required)
            id = nonemptyText(id, "source id");
            role = nonemptyText(role, "source role");
            path = scalarText(path, "source path");
            if ~(islogical(required) && isscalar(required))
                error("labkit:ui:contract:InvalidValue", ...
                    "RuntimeContext source required must be logical scalar.");
            end
            record = obj.invoke("sourceRecord", "project", ...
                {id, role, path, required}, 1);
        end

        function sources = upsertSource(obj, sources, record)
            sources = obj.invoke("upsertSource", "project", ...
                {sources, record}, 1);
        end

        function sources = reconcileSources(obj, current, incoming)
            sources = obj.invoke("reconcileSources", "project", ...
                {current, incoming}, 1);
        end

        function surface = acquireRenderSurface(obj, target)
            target = nonemptyText(target, "render target");
            if ~any(obj.TargetIds == target)
                error("labkit:ui:contract:UnknownReference", ...
                    "RuntimeContext render target is undeclared: %s.", target);
            end
            surface = obj.invoke("acquireRenderSurface", "render", ...
                {target}, 1);
        end

        function setResource(obj, scope, id, value, cleanup)
            scope = resourceScope(scope);
            id = nonemptyText(id, "resource id");
            if ~isempty(cleanup) && ...
                    (~isa(cleanup, "function_handle") || ...
                     nargin(cleanup) ~= 1 || nargout(cleanup) ~= 0)
                error("labkit:ui:contract:InvalidValue", ...
                    "RuntimeContext cleanup must accept one value and " + ...
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

        function written = writeResult(obj, folder, result)
            folder = scalarText(folder, "result folder");
            if ~isa(result, "labkit.ui.Result")
                error("labkit:ui:contract:InvalidValue", ...
                    "RuntimeContext writeResult requires a Result value.");
            end
            written = obj.invoke("writeResult", "results", ...
                {folder, result}, 1);
            requireDialogResult(written, "writeResult");
        end
    end

    methods (Static, Hidden)
        function obj = createForRuntime(application, backend)
            if ~isa(application, "labkit.ui.Application") || ...
                    ~isstruct(backend) || ~isscalar(backend)
                error("labkit:ui:runtime:InvariantFailure", ...
                    "RuntimeContext factory inputs are invalid.");
            end
            names = string(fieldnames(backend));
            if ~all(structfun(@(value) ...
                    isa(value, "function_handle") && isscalar(value), backend))
                error("labkit:ui:runtime:InvariantFailure", ...
                    "RuntimeContext backend operations must be function handles.");
            end
            obj = labkit.ui.RuntimeContext();
            obj.Capabilities = application.Capabilities;
            obj.Backend = backend;
            obj.CommandIds = application.commandIdsForRuntime();
            obj.TargetIds = application.TargetIds;
            if numel(unique(names)) ~= numel(names)
                error("labkit:ui:runtime:InvariantFailure", ...
                    "RuntimeContext backend operation names repeat.");
            end
        end
    end

    methods (Access = private)
        function result = dialogPath(obj, operation, filters, startPath)
            result = obj.invoke(operation, "dialogs", ...
                {filters, scalarText(startPath, "startPath")}, 1);
            requireDialogResult(result, operation);
        end

        function varargout = invoke(obj, operation, capability, inputs, outputs)
            if ~any(obj.Capabilities == capability)
                error("labkit:ui:runtime:InvariantFailure", ...
                    "RuntimeContext capability is undeclared: %s.", capability);
            end
            if ~isfield(obj.Backend, operation)
                error("labkit:ui:runtime:InvariantFailure", ...
                    "RuntimeContext backend operation is unavailable: %s.", ...
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

function value = scalarText(value, label)
    if ~(ischar(value) || (isstring(value) && isscalar(value)))
        error("labkit:ui:contract:InvalidValue", ...
            "RuntimeContext %s must be scalar text.", label);
    end
    value = string(value);
end

function value = nonemptyText(value, label)
    value = scalarText(value, label);
    if strlength(value) == 0
        error("labkit:ui:contract:InvalidValue", ...
            "RuntimeContext %s must be nonempty.", label);
    end
end

function values = textRow(values, label)
    if ischar(values)
        values = string(values);
    elseif iscellstr(values)
        values = string(values);
    elseif ~isstring(values)
        error("labkit:ui:contract:InvalidValue", ...
            "RuntimeContext %s must be text.", label);
    end
    values = reshape(values, 1, []);
end

function value = resourceScope(value)
    value = nonemptyText(value, "resource scope");
    if ~any(value == ["event", "interaction", "document", "application"])
        error("labkit:ui:contract:InvalidValue", ...
            "RuntimeContext resource scope is unsupported: %s.", value);
    end
end

function requireDialogResult(value, operation)
    if ~isa(value, "labkit.ui.DialogResult")
        error("labkit:ui:runtime:InvariantFailure", ...
            "RuntimeContext %s backend must return DialogResult.", operation);
    end
end
