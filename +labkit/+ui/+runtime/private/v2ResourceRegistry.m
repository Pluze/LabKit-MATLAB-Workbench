% Private UI runtime helper. Expected callers: v2 handler services and runtime
% cleanup. Inputs are a figure, command, and command arguments. The registry
% owns nonsemantic handles/listeners/tools outside app state and guarantees
% idempotent cleanup on replacement, scope disposal, and figure deletion.
function varargout = v2ResourceRegistry(fig, command, varargin)
    command = string(command);
    switch command
        case "set"
            setResource(fig, varargin{:});
        case "get"
            varargout{1} = getResource(fig, varargin{:});
        case "remove"
            removeResource(fig, varargin{:});
        case "clearScope"
            clearScope(fig, varargin{:});
        case "clearAll"
            clearAll(fig);
        case "listIds"
            varargout{1} = listIds(fig, varargin{1});
        otherwise
            error('labkit:ui:runtime:InvalidResourceCommand', ...
                'Unsupported resource registry command "%s".', command);
    end
end

function ids = listIds(fig, scope)
    runtime = runtimeFromFigure(fig);
    if isempty(runtime.resources)
        ids = strings(1, 0);
        return;
    end
    matches = [runtime.resources.scope] == string(scope);
    if ~any(matches)
        ids = strings(1, 0);
    else
        ids = string({runtime.resources(matches).id});
    end
end

function setResource(fig, scope, id, value, cleanup)
    scope = validateText(scope, "scope");
    id = validateText(id, "id");
    if nargin < 5 || isempty(cleanup)
        cleanup = defaultCleanup(value);
    end
    if ~isa(cleanup, 'function_handle')
        error('labkit:ui:runtime:InvalidResourceCleanup', ...
            'Resource cleanup must be a function handle.');
    end
    runtime = runtimeFromFigure(fig);
    index = findResource(runtime.resources, scope, id);
    if ~isempty(index)
        disposeEntry(runtime.resources(index));
        runtime.resources(index) = [];
    end
    entry = struct();
    entry.scope = scope;
    entry.id = id;
    entry.value = value;
    entry.cleanup = cleanup;
    entry.disposed = false;
    runtime.resources(end + 1) = entry;
    setappdata(fig, appRuntimeKey(), runtime);
end

function value = getResource(fig, scope, id)
    runtime = runtimeFromFigure(fig);
    index = findResource(runtime.resources, string(scope), string(id));
    if isempty(index)
        value = [];
    else
        value = runtime.resources(index).value;
    end
end

function removeResource(fig, scope, id)
    runtime = runtimeFromFigure(fig);
    index = findResource(runtime.resources, string(scope), string(id));
    if isempty(index)
        return;
    end
    disposeEntry(runtime.resources(index));
    runtime.resources(index) = [];
    setappdata(fig, appRuntimeKey(), runtime);
end

function clearScope(fig, scope)
    if isempty(fig) || ~isappdata(fig, appRuntimeKey())
        return;
    end
    runtime = getappdata(fig, appRuntimeKey());
    if isempty(runtime.resources)
        return;
    end
    matches = [runtime.resources.scope] == string(scope);
    disposeEntries(runtime.resources(matches));
    runtime.resources(matches) = [];
    setappdata(fig, appRuntimeKey(), runtime);
end

function clearAll(fig)
    if isempty(fig) || ~isappdata(fig, appRuntimeKey())
        return;
    end
    runtime = getappdata(fig, appRuntimeKey());
    disposeEntries(runtime.resources);
    runtime.resources = emptyResources();
    if isvalid(fig)
        setappdata(fig, appRuntimeKey(), runtime);
    end
end

function runtime = runtimeFromFigure(fig)
    if isempty(fig) || ~isvalid(fig) || ~isappdata(fig, appRuntimeKey())
        error('labkit:ui:runtime:MissingRuntime', ...
            'The figure does not have a LabKit app runtime.');
    end
    runtime = getappdata(fig, appRuntimeKey());
end

function index = findResource(resources, scope, id)
    index = [];
    if isempty(resources)
        return;
    end
    index = find([resources.scope] == scope & [resources.id] == id, 1, 'first');
end

function disposeEntries(entries)
    for k = numel(entries):-1:1
        disposeEntry(entries(k));
    end
end

function disposeEntry(entry)
    if entry.disposed
        return;
    end
    try
        entry.cleanup(entry.value);
    catch
    end
end

function cleanup = defaultCleanup(value)
    if isa(value, 'onCleanup')
        cleanup = @(item) delete(item);
    elseif isobject(value) || isgraphics(value)
        cleanup = @deleteIfValid;
    else
        cleanup = @(~) [];
    end
end

function deleteIfValid(value)
    try
        if isvalid(value)
            delete(value);
        end
    catch
    end
end

function value = validateText(value, label)
    value = string(value);
    if ~isscalar(value) || strlength(value) == 0
        error('labkit:ui:runtime:InvalidResourceId', ...
            'Resource %s must be nonempty scalar text.', label);
    end
end

function resources = emptyResources()
    resources = struct("scope", {}, "id", {}, "value", {}, ...
        "cleanup", {}, "disposed", {});
end
