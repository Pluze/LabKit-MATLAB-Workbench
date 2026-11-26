function textArea = createTextPanel(obj, node, parent, config)
% Class-folder implementation of MatlabPlatformAdapter.createTextPanel.
    title = string(config.Title);
    if config.Presentation == "note"
        textArea = uilabel(parent,Text="",WordWrap="on",FontSize=11, ...
            FontColor=obj.Appearance.Muted,VerticalAlignment="center");
        return
    end
    if config.Presentation == "label"
        grid = uigridlayout(parent,[2 1],RowHeight={'1x',16}, ...
            Padding=[8 3 8 3],RowSpacing=0,BackgroundColor=obj.Appearance.Background);
        textArea = uilabel(grid,Text="",FontSize=16,FontWeight="bold",WordWrap="on", ...
            FontColor=obj.Appearance.Text);
        uilabel(grid,Text=title,FontSize=10,FontColor=obj.Appearance.Muted);
        textArea.UserData = struct("LayoutContainer",grid);
        return
    end
    owner = obj.owningNode(node.Id);
    redundantTitle = ~isempty(owner) && owner.Kind == "section" && ...
        obj.sectionDrawsOwnTitle(owner) && ...
        isfield(owner.Configuration, "Title") && ...
        string(owner.Configuration.Title) == title;
    policy = labkit.app.internal.native.NativeAdapterValues.layoutPolicy();
    if title == "Status" && ~isempty(owner) && owner.Kind == "section" && ...
            ~obj.sectionDrawsOwnTitle(owner)
        title = string(owner.Configuration.Title);
    end
    showHeading = ~redundantTitle && title ~= "" && title ~= "Status";
    grid = uigridlayout(parent, [1 1], Padding=policy.ReadonlyInset, ...
        RowSpacing=4, ColumnSpacing=0, Tag=node.Id + ".panel");
    headingHeight = 0;
    if showHeading
        grid.RowHeight = {18, '1x'};
        uilabel(grid, Text=title, FontWeight="bold", FontSize=policy.ReadonlyFontSize);
        headingHeight = 18 + grid.RowSpacing;
    end
    textArea = uitextarea(grid, Editable="off", WordWrap="on", ...
        FontSize=policy.ReadonlyFontSize);
    textArea.UserData = struct("LayoutContainer", grid, "NodeId", node.Id, ...
        "Readonly", true, "HeadingHeight", headingHeight, ...
        "MaximumLines", max(6, config.Lines));
end
