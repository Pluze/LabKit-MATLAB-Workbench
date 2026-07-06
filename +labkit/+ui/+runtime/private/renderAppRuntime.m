% Private UI runtime helper. Expected caller: app runtime and snapshot restore
% services. Inputs are a figure with stored LabKit runtime. Side effects:
% invokes the app definition Render hook with the current runtime state.
function renderAppRuntime(fig)
    runtime = getAppRuntime(fig);
    renderFcn = runtime.definition.render;
    services = runtimeServices(fig, runtime);
    n = nargin(renderFcn);
    if n < 0
        n = 3;
    end
    if n == 0
        renderFcn();
    elseif n == 1
        renderFcn(runtime.state);
    elseif n == 2
        renderFcn(runtime.state, runtime.ui);
    else
        renderFcn(runtime.state, runtime.ui, services);
    end
end

function services = runtimeServices(fig, runtime)
    services = struct();
    services.figure = fig;
    services.ui = runtime.ui;
    services.debug = runtime.debug;
    services.dispatch = @(id, varargin) dispatchUnavailable(id, varargin{:});
end

function dispatchUnavailable(id, varargin)
    error('labkit:ui:runtime:SnapshotDispatchUnavailable', ...
        'Programmatic dispatch is not available while rendering snapshot state "%s".', ...
        char(string(id)));
end
