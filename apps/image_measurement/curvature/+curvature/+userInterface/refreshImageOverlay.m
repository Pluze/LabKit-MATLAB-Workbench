% Debug-compatible callback bridge for the dense-points checkbox. Expected
% caller: curvature.userInterface.buildWorkbenchSpec. Inputs are the UI control and event from
% MATLAB. Side effects: dispatches the app-owned runtime action while keeping
% this function name visible to debug callback instrumentation.
function refreshImageOverlay(control, event)
    fig = callbackFigure(control, event);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    payload = struct( ...
        'id', "onShowDenseChanged", ...
        'kind', "action", ...
        'source', "user", ...
        'control', control, ...
        'event', event);
    services = struct( ...
        'figure', fig, ...
        'ui', runtime.ui, ...
        'debug', runtime.debug);
    handler = runtime.actions.onShowDenseChanged;
    try
        runtime.state = handler(runtime.state, payload, services);
        setappdata(fig, 'labkitUiAppRuntime', runtime);
    catch ME
        reportDebugException(runtime.debug, ME);
        rethrow(ME);
    end
end

function fig = callbackFigure(control, event)
    fig = [];
    if isstruct(event) && isfield(event, 'ui') && isstruct(event.ui) && ...
            isfield(event.ui, 'figure')
        fig = event.ui.figure;
    elseif isstruct(control) && isfield(control, 'handle')
        fig = ancestor(control.handle, 'figure');
    elseif ~isstruct(control)
        fig = ancestor(control, 'figure');
    end
    if isempty(fig) || ~isvalid(fig)
        error('curvature:actions:MissingRuntimeFigure', ...
            'Curvature callback could not resolve the app figure.');
    end
end

function reportDebugException(debugLog, exception)
    if isstruct(debugLog) && isfield(debugLog, 'reportException') && ...
            isa(debugLog.reportException, 'function_handle')
        debugLog.reportException('curvature', ...
            'Dense-points refresh callback failed', exception);
    end
end
