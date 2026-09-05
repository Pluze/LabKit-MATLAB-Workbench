function handles = visiblePlotAxes(workspace)
%VISIBLEPLOTAXES Return axes from selected native workspace tabs only.
% Clipboard actions pass the workspace container, excluding control panels.
% Hidden test windows remain eligible; selection is determined by tab ownership.
if isempty(workspace) || ~isgraphics(workspace)
    handles = gobjects(0, 1);
    return;
end
handles = findall(workspace, "Type", "axes");
keep = true(size(handles));
for k = 1:numel(handles)
    parent = handles(k).Parent;
    while ~isempty(parent) && ~isequal(parent, workspace)
        if isa(parent, "matlab.ui.container.Tab") && ...
                ~isequal(parent.Parent.SelectedTab, parent)
            keep(k) = false;
            break;
        end
        parent = parent.Parent;
    end
end
handles = handles(keep);
end
