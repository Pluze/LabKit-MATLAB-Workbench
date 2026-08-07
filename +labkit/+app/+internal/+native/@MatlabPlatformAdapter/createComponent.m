function component = createComponent(obj, node, parent)
% Class-folder implementation of MatlabPlatformAdapter.createComponent.
    config = node.Configuration;
    switch node.Kind
        case "workbench"
            component = uipanel(parent, BorderType="none", ...
                Units="normalized", Position=[0 0 1 1]);
            obj.installWorkbenchLayout(node, component);
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
            component = uipanel(parent, Title=title, ...
                BorderType=border);
            obj.installContentGrid(node, component);
        case "tab"
            if isa(parent, "matlab.ui.container.TabGroup")
                component = uitab(parent, Title=config.Title);
            else
                component = uipanel(parent, Title=config.Title);
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
            component = obj.createTextPanel(node, parent, config, false);
        case "plotArea"
            plotTitle = config.Title;
            owner = obj.owningNode(node.Id);
            if strlength(plotTitle) == 0 && ~isempty(owner) && ...
                    owner.Kind == "section" && ...
                    isfield(owner.Configuration, "Title")
                plotTitle = owner.Configuration.Title;
            end
            if strlength(plotTitle) > 0
                component = uipanel(parent, Title=char(plotTitle));
            else
                component = uipanel(parent, BorderType="none");
            end
            obj.createAxes(node, component);
        case "workspace"
            if isempty(node.PageIds)
                component = uipanel(parent, BorderType="none");
                obj.installContentGrid(node, component);
            else
                component = uitabgroup(parent);
            end
        case "workspacePage"
            component = uitab(parent, Title=config.Title);
            obj.installContentGrid(node, component);
        otherwise
            error("labkit:app:runtime:InvariantFailure", ...
                "MATLAB adapter cannot create Layout kind %s.", node.Kind);
    end
end
