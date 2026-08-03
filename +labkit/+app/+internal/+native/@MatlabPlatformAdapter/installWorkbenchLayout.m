function installWorkbenchLayout(obj, node, component)
% Class-folder implementation of MatlabPlatformAdapter.installWorkbenchLayout.
    policy = labkit.app.internal.native.NativeAdapterValues.layoutPolicy();
    nodes = obj.nodes(node.ChildIds);
    hasWorkspace = any(string({nodes.Kind}) == "workspace");
    columns = 1 + hasWorkspace;
    gridColumns = columns + hasWorkspace;
    grid = uigridlayout(component, [1 gridColumns], ...
        Padding=policy.OuterPadding, ...
        RowSpacing=0, ...
        ColumnSpacing=policy.SplitterSpacing);
    grid.Tag = "labkitAppWorkbenchGrid";
    if hasWorkspace
        grid.ColumnWidth = {policy.ControlPaneWidth, ...
            policy.SplitterThickness, '1x'};
    else
        grid.ColumnWidth = {'1x'};
    end
    controls = nodes(string({nodes.Kind}) ~= "workspace");
    if ~isempty(controls) && ...
            all(string({controls.Kind}) == "tab")
        controlPanel = uipanel(grid, Title="Controls");
        controlPanel.Tag = "labkitAppControlsPanel";
        controlGrid = uigridlayout(controlPanel, [1 1], ...
            Padding=[10 8 10 8]);
        controlParent = uitabgroup(controlGrid);
        controlContainer = controlPanel;
    else
        controlPanel = uipanel(grid, BorderType="none");
        controlGrid = uigridlayout(controlPanel, ...
            [max(1, numel(controls)) 1], ...
            Padding=[0 0 0 0], RowSpacing=5, ColumnSpacing=0);
        if ~isempty(controls)
            controlGrid.RowHeight = ...
                obj.childRowHeights(string({controls.Id}));
        end
        controlParent = controlGrid;
        controlContainer = controlPanel;
    end
    controlContainer.Layout.Row = 1;
    controlContainer.Layout.Column = 1;
    obj.WorkbenchControls = controlParent;
    if hasWorkspace
        labkit.app.internal.native.NativeAdapterValues.installColumnDivider(obj.Figure, grid, 1, 2);
        workspaceNode = nodes(string({nodes.Kind}) == "workspace");
        workspace = uipanel(grid, ...
            Title=char(workspaceNode.Configuration.Title), ...
            Tag="labkitAppWorkspacePanel");
        workspace.Layout.Row = 1;
        workspace.Layout.Column = 3;
        workspaceGrid = uigridlayout(workspace, [1 1], ...
            Padding=[0 0 0 0], RowSpacing=0, ColumnSpacing=0);
        obj.WorkbenchWorkspace = workspaceGrid;
    else
        obj.WorkbenchWorkspace = component;
    end
end
