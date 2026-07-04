% Private UI app helper. Expected caller: utility bar commands. Input is an
% app figure. Output is the current valid visible preview axes, preferring the
% most recently interacted axes and falling back to a single or first
% registered visible axes.
function ax = currentWorkbenchAxes(fig)
    axesHandles = registeredAxes(fig);
    if isempty(axesHandles)
        error('labkit:ui:app:NoCurrentAxes', ...
            'No LabKit preview axes are available for this utility command.');
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
