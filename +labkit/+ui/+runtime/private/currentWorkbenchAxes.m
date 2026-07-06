% Private UI runtime helper. Expected caller: utility bar commands. Input is an
% app figure and optional "All" logical flag. Output is the current valid
% visible preview axes, preferring the most recently interacted axes and
% falling back to a single or first registered visible axes. When All is true,
% output is every registered visible axes in registration order.
function ax = currentWorkbenchAxes(fig, varargin)
    allAxes = false;
    for k = 1:2:numel(varargin)
        if string(varargin{k}) == "All"
            allAxes = logical(varargin{k + 1});
        end
    end
    axesHandles = registeredAxes(fig);
    if isempty(axesHandles)
        error('labkit:ui:runtime:NoCurrentAxes', ...
            'No LabKit preview axes are available for this utility command.');
    end
    if allAxes
        ax = axesHandles;
        return;
    end
    if isappdata(fig, 'labkitUiActiveAxes')
        active = getappdata(fig, 'labkitUiActiveAxes');
        if ~isempty(active) && isvalid(active) && any(active == axesHandles)
            ax = active;
            return;
        end
    end
    ax = axesHandles(1);
end

function axesHandles = registeredAxes(fig)
    axesHandles = gobjects(1, 0);
    if ~isappdata(fig, 'labkitUiWorkbenchAxes')
        return;
    end
    candidate = getappdata(fig, 'labkitUiWorkbenchAxes');
    for k = 1:numel(candidate)
        ax = candidate(k);
        if isempty(ax) || ~isvalid(ax) || ~isprop(ax, 'Visible') || ...
                ~strcmp(ax.Visible, 'on')
            continue;
        end
        axesHandles(end + 1) = ax;
    end
end
