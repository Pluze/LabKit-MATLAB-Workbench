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
    if redundantTitle
        textArea = uitextarea(parent, Editable="off");
    else
        panel = uipanel(parent, Title=char(title), BorderType="none", Tag=node.Id + ".panel");
        grid = uigridlayout(panel, [1 1], Padding=[7 7 7 7]);
        textArea = uitextarea(grid, Editable="off");
        textArea.UserData = struct("Panel", panel);
    end
    if config.Lines <= 2
        policy = labkit.app.internal.native.NativeAdapterValues.layoutPolicy();
        textArea.FontSize = policy.SummaryFontSize;
        setappdata(textArea, "labkitAppTextFitMinFontSize", policy.SummaryFontSize);
    end
end
