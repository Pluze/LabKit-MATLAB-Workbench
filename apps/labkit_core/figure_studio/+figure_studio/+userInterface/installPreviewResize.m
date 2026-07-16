% Expected caller: Figure Studio Start hook. Input is the registered preview
% axes. Output is an ephemeral timer/listener resource for resize reflow.
function resource = installPreviewResize(ax)
    resource = struct("axes", ax, "listeners", {{}}, "timer", []);
    if isempty(ax) || ~isvalid(ax)
        return;
    end
    targets = {ax, ax.Parent, ancestor(ax, 'figure')};
    listeners = cell(1, numel(targets));
    for k = 1:numel(targets)
        try
            listeners{k} = addlistener(targets{k}, 'Position', 'PostSet', ...
                @(~, ~) reflow(ax));
        catch
            listeners{k} = [];
        end
    end
    resizeTimer = timer( ...
        'ExecutionMode', 'fixedSpacing', ...
        'Period', 0.25, ...
        'BusyMode', 'drop', ...
        'TimerFcn', @(~, ~) reflow(ax));
    start(resizeTimer);
    resource.listeners = listeners;
    resource.timer = resizeTimer;
end

function reflow(ax)
    if isempty(ax) || ~isvalid(ax) || ...
            ~isappdata(ax, 'labkitFigureStudioPreviewStyle')
        return;
    end
    guardKey = 'labkitFigureStudioReflowing';
    if isappdata(ax, guardKey) && getappdata(ax, guardKey)
        return;
    end
    setappdata(ax, guardKey, true);
    cleanup = onCleanup(@() clearGuard(ax, guardKey));
    style = getappdata(ax, 'labkitFigureStudioPreviewStyle');
    if ~isempty(ax.Children)
        figure_studio.resultFiles.applyFigureStyle(ax, style);
    end
end

function clearGuard(ax, key)
    if ~isempty(ax) && isvalid(ax) && isappdata(ax, key)
        rmappdata(ax, key);
    end
end
