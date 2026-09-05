function handles = currentPlotAxes(obj)
% Resolve only the plotted content of the currently selected workspace page.
workspace = obj.WorkbenchWorkspace;
if isempty(workspace)
    workspace = obj.Figure;
end
handles = labkit.app.internal.native.visiblePlotAxes(workspace);
end
