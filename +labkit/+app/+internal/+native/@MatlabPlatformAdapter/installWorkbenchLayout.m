function root = installWorkbenchLayout(obj, node, parent)
% Build the native product header, data sidebar and scientific workspace.
    style = obj.Appearance;
    policy = labkit.app.internal.native.NativeAdapterValues.layoutPolicy();
    nodes = obj.nodes(node.ChildIds);
    kinds = string({nodes.Kind});
    hasWorkspace = any(kinds == "workspace");
    headerHeight = policy.HeaderTopInset + policy.HeaderContentHeight + policy.HeaderBottomGap;
    sideColor = style.Surface;
    if hasWorkspace
        sideColor = style.Background;
    end
    root = uigridlayout(parent,[3 1+2*hasWorkspace], RowHeight={headerHeight,'1x',22}, ...
        Padding=[0 0 0 0], RowSpacing=0, ColumnSpacing=0, BackgroundColor=style.Surface, ...
        Tag="labkitAppWorkbenchGrid");
    if hasWorkspace
        root.ColumnWidth = {policy.ControlPaneWidth,policy.SplitterThickness,'1x'};
        brand = uigridlayout(root,[2 4],ColumnWidth={28,68,'fit','1x'}, ...
            RowHeight={policy.HeaderContentHeight,1},RowSpacing=policy.HeaderBottomGap-1, ...
            Padding=[14 0 14 policy.HeaderTopInset],ColumnSpacing=8,BackgroundColor=sideColor);
        brand.Layout.Row = 1;
        brand.Layout.Column = 1;
        widths = {'fit','1x'};
        if node.Configuration.HeaderAction ~= ""
            widths{end+1} = 'fit';
        end
        obj.Header = uigridlayout(root,[1 numel(widths)],ColumnWidth=widths, ...
            Padding=[18 policy.HeaderBottomGap 15 policy.HeaderTopInset],ColumnSpacing=8, ...
            BackgroundColor=style.Surface);
        obj.Header.Layout.Row = 1;
        obj.Header.Layout.Column = 3;
    else
        widths = {28,68,'fit','fit','1x'};
        if node.Configuration.HeaderAction ~= ""
            widths{end+1} = 'fit';
        end
        obj.Header = uigridlayout(root,[1 numel(widths)],ColumnWidth=widths, ...
            Padding=[15 policy.HeaderBottomGap 15 policy.HeaderTopInset],ColumnSpacing=8, ...
            BackgroundColor=style.Surface);
        obj.Header.Layout.Row = 1;
        obj.Header.Layout.Column = 1;
        brand = obj.Header;
    end
    labkit.app.internal.native.installBrandMark(brand);
    obj.BrandButton = uibutton(brand, Text="LabKit  ▾", FontSize=14, FontWeight="bold", ...
        BackgroundColor=sideColor, FontColor=style.Text, Tooltip="Open LabKit tools", ...
        Tag="labkitAppToolsButton");
    uilabel(brand, Text=obj.Family, FontSize=12, FontColor=style.Muted);
    uilabel(obj.Header, Text=obj.DisplayName, FontSize=15, FontWeight="bold", FontColor=style.Text);

    if hasWorkspace
        rule = uilabel(brand,Text="",BackgroundColor=style.Line);
        rule.Layout.Row = 2;
        rule.Layout.Column = [1 4];
    end
    controls = nodes(kinds ~= "workspace" & string({nodes.Id}) ~= node.Configuration.HeaderAction);
    side = uigridlayout(root,[2 1], RowHeight={18,'1x'}, Padding=[14 14 14 12], ...
        RowSpacing=7, BackgroundColor=sideColor);
    side.Layout.Row = 2;
    side.Layout.Column = 1;
    if numel(controls) > 1 && all(string({controls.Kind}) == "tab")
        obj.WorkbenchControls = obj.installPageNavigation(node,side,controls);
    else
        uilabel(side, Text="DATA WORKSPACE", FontSize=11, FontWeight="bold", FontColor=style.Muted);
        obj.WorkbenchControls = uigridlayout(side,[max(1,numel(controls)) 1], ...
            Padding=[0 0 0 0], RowSpacing=7, Scrollable="on", BackgroundColor=sideColor);
        if ~isempty(controls)
            obj.WorkbenchControls.RowHeight = obj.childRowHeights(string({controls.Id}));
        end
    end
    if hasWorkspace
        labkit.app.internal.native.NativeAdapterValues.installColumnDivider(obj.Figure, root, 1, 2);
        divider = findobj(root.Children, "Tag", "labkitAppColumnResize");
        divider.Layout.Row = [1 3];
        divider.BackgroundColor = style.Line;
        obj.WorkbenchWorkspace = uigridlayout(root,[1 1], Padding=[0 0 0 0], ...
            BackgroundColor=style.Background, Tag="labkitAppWorkspacePanel");
        obj.WorkbenchWorkspace.Layout.Row = 2;
        obj.WorkbenchWorkspace.Layout.Column = 3;
    else
        obj.WorkbenchWorkspace = root;
    end
    footer = uigridlayout(root,[1 1], Padding=[18 2 18 2], BackgroundColor=sideColor);
    footer.Layout.Row = 3;
    footer.Layout.Column = 1;
    uilabel(footer, Text=obj.Figure.Name, FontSize=11, FontColor=style.Muted);
end
