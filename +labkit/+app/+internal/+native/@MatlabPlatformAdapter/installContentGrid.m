function grid = installContentGrid(obj, node, component)
% Class-folder implementation of MatlabPlatformAdapter.installContentGrid.
    if isempty(node.ChildIds)
        grid = [];
        return;
    end
    policy = labkit.app.internal.native.NativeAdapterValues.layoutPolicy();
    padding = policy.ContentPadding;
    if node.Kind == "group" || (node.Kind == "tab" && ~isa(component,"matlab.ui.container.Tab"))
        padding = [0 0 0 0];
    end
    layout = obj.groupLayout(node);
    if layout == "actions"
        [rows, columns] = obj.actionGridSize(node);
        grid = uigridlayout(component, [rows columns], ...
            Padding=padding, ...
            RowSpacing=policy.ContentSpacing, ...
            ColumnSpacing=policy.ContentSpacing);
        grid.RowHeight = repmat({policy.ButtonHeight}, 1, rows);
        grid.ColumnWidth = repmat({'1x'}, 1, columns);
    elseif layout == "horizontal"
        grid = uigridlayout(component, [1 numel(node.ChildIds)], ...
            Padding=padding, ...
            RowSpacing=policy.ContentSpacing, ...
            ColumnSpacing=policy.ContentSpacing);
        allButtons = true;
        for k = 1:numel(node.ChildIds)
            allButtons = allButtons && obj.node(node.ChildIds(k)).Kind == "button";
        end
        if allButtons
            grid.RowHeight = {policy.ButtonHeight};
        end
        grid.ColumnWidth = repmat({'1x'}, 1, numel(node.ChildIds));
        if ~isempty(node.Configuration.ColumnWidths)
            grid.ColumnWidth = node.Configuration.ColumnWidths;
        end
    else
        rowCount = numel(node.ChildIds);
        if node.Kind == "tab"
            rowCount = max(1, 2 * rowCount - 1);
        end
        grid = uigridlayout(component, [rowCount 1], ...
            Padding=padding, ...
            RowSpacing=policy.ContentSpacing, ...
            ColumnSpacing=policy.ContentSpacing);
        heights = obj.childRowHeights(node.ChildIds);
        singleGrowable = isscalar(node.ChildIds) && ...
            obj.isGrowableTabChild(obj.node(node.ChildIds(1)));
        if node.Kind == "workspacePage"
            for k = 1:numel(node.ChildIds)
                if obj.isGrowableTabChild(obj.node(node.ChildIds(k)))
                    heights{k} = "1x";
                    child = obj.node(node.ChildIds(k));
                    if node.Configuration.Heading ~= "" && child.Kind == "plotArea" && child.Configuration.Layout == "single" && numel(node.ChildIds) > 1
                        heights{k} = "1.28x";
                    end
                end
            end
        elseif singleGrowable
            heights{1} = "1x";
        end
        if node.Kind == "tab"
            expanded = cell(1, max(1, 2 * numel(heights) - 1));
            expanded(1:2:end) = heights;
            if numel(heights) > 1
                expanded(2:2:end) = {policy.SplitterThickness};
            end
            heights = expanded;
        end
        grid.RowHeight = heights;
        if node.Kind == "tab" && isprop(grid, "Scrollable")
            grid.Scrollable = labkit.app.internal.native.NativeAdapterValues.onOff(~singleGrowable);
        end
    end
    grid.Tag = char(node.Id + ".layout");
    obj.Layouts(char(node.Id)) = grid;
    if node.Kind == "tab"
        for k = 1:max(0, numel(node.ChildIds) - 1)
            labkit.app.internal.native.NativeAdapterValues.installRowDivider(obj.Figure, grid, 2 * k - 1, 2 * k);
        end
    end
end
