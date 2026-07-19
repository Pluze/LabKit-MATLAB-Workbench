classdef (Sealed) CallbackContext < handle
    %CALLBACKCONTEXT Provide declared App-neutral runtime capabilities.
    %
    % Usage:
    %   context = labkit.app.CallbackContext()
    %   context.appendStatus(message)
    %   context.reportError(operation, exception)
    %   context.alert(message, title)
    %   result = context.chooseOption(prompt, choices)
    %   result = context.chooseInputFile(filters, startPath)
    %   result = context.chooseInputFolder(startPath)
    %   result = context.chooseOutputFile(filters, startPath)
    %   result = context.chooseOutputFolder(startPath)
    %   result = context.saveProjectDocument(state, filepath)
    %   context.saveRecoveryDocument(state, filepath)
    %   record = context.createSourceRecord(id, role, path, required)
    %   paths = context.resolveSourcePaths(sources)
    %   paths = context.resolveSourcePaths(sources, ids)
    %   sources = context.upsertSourceRecord(sources, record)
    %   sources = context.reconcileSourceRecords(current, incoming)
    %   surface = context.acquireRenderSurface(target)
    %   context.setResource(scope, id, value, cleanup)
    %   value = context.getResource(scope, id)
    %   context.removeResource(scope, id)
    %   context.clearResourceScope(scope)
    %   result = context.writeResultPackage(folder, result)
    %
    % Description:
    %   CallbackContext is the sealed callback capability boundary. Each
    %   specifically named method invokes one private runtime operation. The
    %   public zero-argument constructor creates an unconnected context for tests
    %   whose callbacks must remain pure. It exposes no figure, registry,
    %   component, launch request, debug object, or nested service bag.
    %
    % Inputs:
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
    %   result - labkit.app.result.Package value for writeResultPackage.
    %
    % Outputs:
    %   context - Sealed labkit.app.CallbackContext value.
    %   state - State returned by the workflow backend.
    %   result - labkit.app.dialog.Choice for dialogs, project saves, and result
    %       writing.
    %   record - Opaque runtime-owned portable source value.
    %   sources - Updated runtime-owned portable source collection.
    %   paths - Column string array of resolved source paths.
    %   surface - Event-scoped restricted render surface.
    %   value - Stored resource value.
    %
    % Errors:
    %   labkit:app:contract:InvalidValue - A public argument is malformed.
    %   labkit:app:contract:UnknownReference - A renderer target is undeclared.
    %   labkit:app:runtime:InvariantFailure - A private backend operation is
    %       unavailable.
    %
    % Example:
    %   context = labkit.app.CallbackContext();
    %   try
    %       context.alert("Message", "Title");
    %   catch ME
    %       assert(ME.identifier == "labkit:app:runtime:InvariantFailure")
    %   end
    %
    % See also labkit.app.Definition, labkit.app.dialog.Choice,
    %   labkit.app.result.Package

    properties (Access = private)
        Backend (1, 1) struct
        TargetIds (1, :) string
    end

    methods
        function obj = CallbackContext()
            obj.Backend = struct();
            obj.TargetIds = strings(1, 0);
        end

        function appendStatus(obj, message)
            message = scalarText(message, "message");
            obj.invoke("appendStatus", "workflow", {message}, 0);
        end

        function reportError(obj, operation, exception)
            operation = scalarText(operation, "operation");
            if ~isa(exception, "MException") || ~isscalar(exception)
                error("labkit:app:contract:InvalidValue", ...
                    "CallbackContext exception must be a scalar MException.");
            end
            obj.invoke("reportError", "diagnostics", ...
                {operation, exception}, 0);
        end

        function alert(obj, message, title)
            obj.invoke("alert", "dialogs", ...
                {scalarText(message, "message"), ...
                 scalarText(title, "title")}, 0);
        end

        function result = chooseOption(obj, prompt, choices)
            choices = textRow(choices, "choices");
            result = obj.invoke("choose", "dialogs", ...
                {scalarText(prompt, "prompt"), choices}, 1);
            requireChoice(result, "chooseOption");
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

        function result = saveProjectDocument(obj, state, filepath)
            result = obj.invoke("saveProject", "project", ...
                {state, scalarText(filepath, "filepath")}, 1);
            requireChoice(result, "saveProjectDocument");
        end

        function saveRecoveryDocument(obj, state, filepath)
            obj.invoke("saveRecovery", "project", ...
                {state, scalarText(filepath, "filepath")}, 0);
        end

        function record = createSourceRecord(obj, id, role, path, required)
            id = nonemptyText(id, "source id");
            role = nonemptyText(role, "source role");
            path = scalarText(path, "source path");
            if ~(islogical(required) && isscalar(required))
                error("labkit:app:contract:InvalidValue", ...
                    "CallbackContext source required must be logical scalar.");
            end
            record = obj.invoke("sourceRecord", "project", ...
                {id, role, path, required}, 1);
        end

        function sources = upsertSourceRecord(obj, sources, record)
            sources = obj.invoke("upsertSource", "project", ...
                {sources, record}, 1);
        end

        function sources = reconcileSourceRecords(obj, current, incoming)
            sources = obj.invoke("reconcileSources", "project", ...
                {current, incoming}, 1);
        end

        function paths = resolveSourcePaths(obj, sources, ids)
            if nargin < 3
                ids = strings(0, 1);
            elseif ~(ischar(ids) || isstring(ids) || iscellstr(ids))
                error("labkit:app:contract:InvalidValue", ...
                    "CallbackContext source ids must be text.");
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

        function surface = acquireRenderSurface(obj, target)
            target = nonemptyText(target, "render target");
            if ~any(obj.TargetIds == target)
                error("labkit:app:contract:UnknownReference", ...
                    "CallbackContext render target is undeclared: %s.", target);
            end
            surface = obj.invoke("acquireRenderSurface", "render", ...
                {target}, 1);
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

    methods (Static, Hidden)
        function obj = createForRuntime(application, backend)
            if ~isa(application, "labkit.app.Definition") || ...
                    ~isstruct(backend) || ~isscalar(backend)
                error("labkit:app:runtime:InvariantFailure", ...
                    "CallbackContext factory inputs are invalid.");
            end
            names = string(fieldnames(backend));
            if ~all(structfun(@(value) ...
                    isa(value, "function_handle") && isscalar(value), backend))
                error("labkit:app:runtime:InvariantFailure", ...
                    "CallbackContext backend operations must be function handles.");
            end
            obj = labkit.app.CallbackContext();
            obj.Backend = backend;
            obj.TargetIds = application.TargetIds;
            if numel(unique(names)) ~= numel(names)
                error("labkit:app:runtime:InvariantFailure", ...
                    "CallbackContext backend operation names repeat.");
            end
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
