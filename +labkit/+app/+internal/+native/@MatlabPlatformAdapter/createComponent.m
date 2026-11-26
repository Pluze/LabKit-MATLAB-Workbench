function component = createComponent(obj, node, parent, inControls)
% Class-folder implementation of MatlabPlatformAdapter.createComponent.
    config = node.Configuration;
    switch node.Kind
        case "workbench"
            component = obj.installWorkbenchLayout(node, parent);
        case {"group", "section"}
            title = "";
            if isfield(config, "Title")
                title = config.Title;
            end
            border = "line";
            if node.Kind == "group"
                if strlength(title) == 0
                    border = "none";
                end
            elseif ~obj.sectionDrawsOwnTitle(node)
                title = "";
                border = "none";
            end
            if inControls && strlength(title) == 0 && ~isempty(node.ChildIds)
                component = obj.installContentGrid(node, parent);
                return
            end
            if (inControls || ~obj.isGrowableTabChild(node)) && strlength(title) > 0 && ~isempty(node.ChildIds)
                component = uigridlayout(parent, [2 1], Padding=[8 0 8 0], ...
                    RowHeight={24, '1x'}, RowSpacing=0);
                heading = uilabel(component, Text=title, FontWeight="bold", FontSize=16);
                if title == upper(title)
                    heading.FontSize = 11;
                    heading.FontColor = obj.Appearance.Muted;
                elseif node.Kind == "group"
                    heading.FontSize = 12;
                    heading.FontWeight = "normal";
                end
                heading.Tag = char(node.Id + ".heading");
                content = obj.installContentGrid(node, component);
                content.Padding = [0 8 0 6];
                return
            end
            component = uipanel(parent, Title=title, ...
                BorderType=border);
            obj.installContentGrid(node, component);
        case "tab"
            component = uipanel(parent, BorderType="none", BackgroundColor=obj.Appearance.Surface);
            if isstring(parent.UserData)
                component.Layout.Row = 1;
                component.Layout.Column = 1;
                component.Visible = labkit.app.internal.native.NativeAdapterValues.onOff(parent.UserData == node.Id);
            end
            obj.installContentGrid(node, component);
        case "button"
            component = uibutton(parent, Text=config.Label, ...
                Enable=labkit.app.internal.native.NativeAdapterValues.onOff(config.Enabled), ...
                Tooltip=char(config.Tooltip));
            labkit.app.internal.native.NativeAdapterValues.fitText(component, ...
                CharsPerStep=28, MaxShrinkSteps=2);
            if isprop(component, "WordWrap")
                component.WordWrap = "off";
            end
        case "field"
            component = obj.createField(parent, config, node.Id);
        case "rangeField"
            component = obj.createRangeField(node, parent);
        case "slider"
            component = obj.createPanner(node, parent);
        case "fileList"
            component = obj.createFilePanel(node, parent);
        case "dataTable"
            component = obj.createDataTable(node, parent);
        case "statusPanel"
            component = obj.createTextPanel(node, parent, config);
        case "plotArea"
            plotTitle = config.Title;
            owner = obj.owningNode(node.Id);
            if strlength(plotTitle) == 0 && ~isempty(owner) && ...
                    owner.Kind == "section" && ...
                    isfield(owner.Configuration, "Title")
                plotTitle = owner.Configuration.Title;
            end
            if strlength(plotTitle) > 0
                component = uipanel(parent, Title=char(plotTitle), BorderType="none");
            else
                component = uipanel(parent, BorderType="none");
            end
            obj.createAxes(node, component);
        case "workspace"
            if isempty(node.PageIds)
                component = uipanel(parent, BorderType="none");
                obj.installContentGrid(node, component);
            else
                component = obj.installPageNavigation(node, parent);
            end
        case "workspacePage"
            if isa(parent,"matlab.ui.container.TabGroup")
                component = uitab(parent, Title=config.Title);
            else
                component = uipanel(parent, BorderType="none", BackgroundColor=obj.Appearance.Surface);
                component.Layout.Row = 1;
                component.Layout.Column = 1;
                component.Visible = labkit.app.internal.native.NativeAdapterValues.onOff( ...
                    string(parent.UserData) == node.Id);
            end
            host = component;
            if config.Heading ~= "" || config.Subtitle ~= "" || config.Note ~= ""
                frame = uigridlayout(component, [3 1], Padding=[18 12 18 12], ...
                    RowHeight={28 * (config.Heading ~= "") + 18 * (config.Subtitle ~= ""), '1x', 22 * (config.Note ~= "")}, ...
                    RowSpacing=12, BackgroundColor=obj.Appearance.Surface);
                heading = uigridlayout(frame,[2 2],ColumnWidth={'1x','fit'},RowHeight={28,18 * (config.Subtitle ~= "")}, ...
                    RowSpacing=0,Padding=[0 0 0 0],BackgroundColor=obj.Appearance.Surface);
                uilabel(heading, Text=config.Heading, FontSize=20, FontWeight="bold", ...
                    FontColor=obj.Appearance.Text);
                context = uilabel(heading, Text="",FontSize=12,FontColor=obj.Appearance.Muted, ...
                    HorizontalAlignment="right",Tag=node.Id+".context");
                component.UserData = struct("HeadingContext",context);
                subtitle = uilabel(heading,Text=config.Subtitle,FontSize=12,FontColor=obj.Appearance.Muted);
                subtitle.Layout.Row = 2;
                subtitle.Layout.Column = [1 2];
                host = uigridlayout(frame,[1 1], Padding=[0 0 0 0], BackgroundColor=obj.Appearance.Surface);
                uilabel(frame, Text=config.Note, FontSize=11, FontColor=obj.Appearance.Muted);
            end
            content = obj.installContentGrid(node, host);
            if isa(parent,"matlab.ui.container.TabGroup")
                content.BackgroundColor = obj.Appearance.Background;
            else
                content.BackgroundColor = obj.Appearance.Surface;
            end
            if host ~= component
                content.Padding = [0 0 0 0];
                content.RowSpacing = 12;
            end
        otherwise
            error("labkit:app:runtime:InvariantFailure", ...
                "MATLAB adapter cannot create Layout kind %s.", node.Kind);
    end
end
