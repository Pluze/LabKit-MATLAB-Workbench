function textArea = createTextPanel(obj, node, parent, config, isLog)
% Class-folder implementation of MatlabPlatformAdapter.createTextPanel.
    title = string(config.Title);
    owner = obj.owningNode(node.Id);
    redundantTitle = ~isempty(owner) && owner.Kind == "section" && ...
        obj.sectionDrawsOwnTitle(owner) && ...
        isfield(owner.Configuration, "Title") && ...
        string(owner.Configuration.Title) == title;
    if redundantTitle
        panel = uipanel(parent, BorderType="none");
    else
        panel = uipanel(parent, Title=char(title));
    end
    if isLog
        grid = uigridlayout(panel, [2 1], ...
            Padding=[7 7 7 7], RowHeight={30, '1x'}, ...
            RowSpacing=4);
        follow = uibutton(grid, Text="Pause auto-scroll");
        labkit.app.internal.native.NativeAdapterValues.fitText(follow, ...
            CharsPerStep=18, MaxShrinkSteps=2);
        follow.Tag = char(node.Id + ".follow");
        follow.Layout.Row = 1;
        textArea = uitextarea(grid, Editable="off");
        textArea.Value = {'Ready.'};
        textArea.Layout.Row = 2;
        setappdata(textArea, "labkitAppLogFollowLatest", true);
        follow.ButtonPushedFcn = @(~, ~) ...
            obj.toggleLogFollowLatest(textArea, follow);
        menu = uicontextmenu(obj.Figure);
        menuItem = uimenu(menu, Text="Pause auto-scroll", ...
            Checked="on");
        menuItem.MenuSelectedFcn = @(~, ~) ...
            obj.toggleLogFollowLatest(textArea, follow);
        textArea.ContextMenu = menu;
        setappdata(textArea, "labkitAppLogFollowButton", follow);
        setappdata(textArea, "labkitAppLogFollowMenu", menuItem);
    else
        grid = uigridlayout(panel, [1 1], Padding=[7 7 7 7]);
        textArea = uitextarea(grid, Editable="off");
        if isfield(config, "Lines") && config.Lines <= 2
            policy = labkit.app.internal.native.NativeAdapterValues.layoutPolicy();
            textArea.FontSize = policy.SummaryFontSize;
            setappdata(textArea, ...
                "labkitAppTextFitMinFontSize", policy.SummaryFontSize);
        end
    end
    textArea.UserData = struct("Panel", panel);
    panel.Tag = char(node.Id + ".panel");
end
