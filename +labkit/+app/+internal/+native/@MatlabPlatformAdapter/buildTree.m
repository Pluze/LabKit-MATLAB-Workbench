function buildTree(obj)
% Class-folder implementation of MatlabPlatformAdapter.buildTree.
    nodes = obj.Plan.Nodes;
    style = obj.Appearance;
    controlSubtree = false(1, numel(nodes));
    for k = 1:numel(nodes)
        node = nodes(k);
        parent = obj.parentFor(node);
        if isfield(obj.ParentIndices, node.Id)
            parentIndex = obj.ParentIndices.(node.Id);
            controlSubtree(k) = (controlSubtree(parentIndex) || ...
                nodes(parentIndex).Kind == "workbench") && ...
                ~any(node.Kind == ["workspace", "plotArea"]);
        end
        component = obj.createComponent(node, parent, controlSubtree(k));
        if ~isempty(component) && node.Kind ~= "workbench"
            component.Tag = char(node.Id);
        end
        if controlSubtree(k) || any(node.Kind == ["group", "section", "button", ...
                "field", "slider", "rangeField", "fileList", "statusPanel"])
            surface = labkit.app.internal.native.NativeAdapterValues.layoutHandle(component);
            containerColor = style.Surface;
            if controlSubtree(k) && isa(obj.WorkbenchControls,"matlab.ui.container.GridLayout")
                containerColor = obj.WorkbenchControls.BackgroundColor;
            end
            labkit.app.internal.native.styleControlSurface(surface, style, containerColor);
            if node.Kind == "button" && parent == obj.Header
                component.BackgroundColor = style.Primary;
                component.FontColor = style.OnPrimary;
                component.FontWeight = "bold";
                component.Layout.Column = numel(obj.Header.ColumnWidth);
            end
            if node.Kind == "group" && ~controlSubtree(k) && ...
                    obj.groupLayout(node) == "horizontal" && ~obj.isGrowableTabChild(node)
                content = obj.contentParent(node.Id);
                content.Padding = [12 4 12 4];
                content.ColumnSpacing = 10;
            end
            if node.Kind == "statusPanel" && node.Configuration.Presentation == "label"
                surface.BackgroundColor = style.Background;
            end
            if node.Kind == "fileList" && ~component.UserData.Compact
                files = component.UserData;
                files.EmptyLabel.BackgroundColor = style.Background;
                files.EmptyLabel.FontColor = style.Muted;
            end
        end
        obj.placeInParent(node, component);
        obj.Components(char(node.Id)) = component;
    end
    for node = reshape(nodes,1,[])
        if node.Kind ~= "group" || obj.groupLayout(node) ~= "horizontal" || numel(node.ChildIds) ~= 2
            continue
        end
        children = obj.nodes(node.ChildIds);
        owner = obj.owningNode(node.Id);
        if owner.Kind == "workspacePage" && owner.Configuration.Heading ~= "" && ...
                isequal(string({children.Kind}),["plotArea","section"])
            panel = obj.component(node.Id);
            grid = obj.contentParent(node.Id);
            plotPanel = obj.component(children(1).Id);
            options = obj.component(children(2).Id);
            widths = grid.ColumnWidth;
            panel.AutoResizeChildren = "off";
            page = obj.component(owner.Id);
            split = obj.WorkbenchWorkspace.Parent;
            reflow = @() fitPlotControls(obj.Figure,split,grid,plotPanel,options,widths);
            panel.SizeChangedFcn = @(~,~) reflow();
            page.UserData.Reflow = reflow;
            reflow();
        end
    end
    index = find(string({nodes.Kind}) == "workspace", 1);
    if ~isempty(index) && strlength(nodes(index).InitialPage) > 0
        workspace = obj.component(nodes(index).Id);
        if isa(workspace,"matlab.ui.container.TabGroup")
            workspace.SelectedTab = obj.component(nodes(index).InitialPage);
        end
    end
end

function fitPlotControls(figureHandle,split,grid,plotPanel,options,widths)
    width = figureHandle.Position(3) - split.ColumnWidth{1} - split.ColumnWidth{2} - 36;
    if width < 760
        grid.Scrollable = "on";
        grid.RowHeight = {max(340,figureHandle.Position(4)-420),250};
        options.Layout.Row = 2;
        options.Layout.Column = 1;
        grid.ColumnWidth = {'1x'};
    else
        grid.ColumnWidth = widths;
        options.Layout.Column = 2;
        options.Layout.Row = 1;
        grid.RowHeight = {'1x'};
        grid.Scrollable = "off";
    end
    plotPanel.Layout.Row = 1;
    plotPanel.Layout.Column = 1;
end
