% Private UI runtime helper. Expected caller: successful v2 project commits.
% Input is an app figure. Side effect replaces one debounced timer resource;
% the timer writes a bounded recovery generation only while the queue is idle
% and no load, export, or drag is active.
function scheduleV2Autosave(fig)
    runtime = getAppRuntime(fig);
    if ~runtime.document.dirty || autosaveDisabled(runtime.request)
        return;
    end
    delay = autosaveDelay(runtime.request);
    autosaveTimer = timer( ...
        "ExecutionMode", "singleShot", ...
        "StartDelay", delay, ...
        "TimerFcn", @(~, ~) runAutosave(fig), ...
        "ErrorFcn", @(~, ~) []);
    v2ResourceRegistry(fig, "set", "figure", "autosaveTimer", ...
        autosaveTimer, @disposeTimer);
    start(autosaveTimer);
end

function runAutosave(fig)
    if isempty(fig) || ~isvalid(fig) || ~isappdata(fig, appRuntimeKey())
        return;
    end
    runtime = getAppRuntime(fig);
    blocked = runtime.processing || runtime.document.loading || ...
        runtime.document.exporting || runtime.interactionHub.isDragging();
    if blocked
        scheduleV2Autosave(fig);
        return;
    end
    current = writeV2RecoveryFile(runtime);
    setappdata(fig, 'labkitV2RecoveryFile', string(current));
end

function tf = autosaveDisabled(request)
    tf = isstruct(request) && isfield(request, 'autosave') && ...
        ~logical(request.autosave);
end

function delay = autosaveDelay(request)
    delay = 2;
    if isstruct(request) && isfield(request, 'autosaveDelay')
        candidate = double(request.autosaveDelay);
        if isscalar(candidate) && isfinite(candidate) && candidate >= 0
            delay = candidate;
        end
    end
end

function disposeTimer(value)
    if isempty(value) || ~isvalid(value)
        return;
    end
    stop(value);
    delete(value);
end
