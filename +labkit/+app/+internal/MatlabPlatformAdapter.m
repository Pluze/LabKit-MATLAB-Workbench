classdef (Hidden, Sealed) MatlabPlatformAdapter < handle
    % Private semantic-plan adapter for native MATLAB UI components.
    %
    % This is deliberately not a registry API.  It owns native handles behind
    % semantic IDs and only consumes the compiled Application plan plus a
    % complete Presentation.  RuntimeKernel is its production-only caller.
    % Native callbacks call typed RuntimeKernel entry points only.  Native
    % handles stay inside this adapter and never become an App API.

    properties (Access = private)
        Plan (1, 1) struct
        Figure
        Components
        Axes
        Layouts
        WorkbenchControls
        WorkbenchWorkspace
        Runtime
        InteractionController
        InteractionDeclarations (1, :) cell = {}
        BaseWindowTitle (1, 1) string = "LabKit application"
        Busy (1, 1) logical = false
        PriorPointer (1, 1) string = "arrow"
        ClosePrompt
        DialogFolders
        Starting (1, 1) logical = false
        StartupStarted
        StartupPanel
        StartupLabel
    end

    methods (Access = ?labkit.app.internal.RuntimeKernel)
        function obj = MatlabPlatformAdapter(plan, title)
            obj.Plan = validatePlan(plan);
            if nargin < 2
                title = "LabKit application";
            end
            obj.BaseWindowTitle = string(title);
            obj.Components = containers.Map("KeyType", "char", ...
                "ValueType", "any");
            obj.Axes = containers.Map("KeyType", "char", ...
                "ValueType", "any");
            obj.Layouts = containers.Map("KeyType", "char", ...
                "ValueType", "any");
            obj.DialogFolders = containers.Map("KeyType", "char", ...
                "ValueType", "char");
            policy = nativeLayoutPolicy();
            obj.Figure = uifigure(Visible="off", ...
                Name=char(obj.BaseWindowTitle), ...
                Position=policy.InitialFigurePosition);
            obj.Starting = true;
            obj.StartupStarted = tic;
            obj.PriorPointer = string(obj.Figure.Pointer);
            obj.Figure.Pointer = "watch";
            setappdata(obj.Figure, "labkitAppBusy", true);
            obj.buildTree();
            obj.createStartupSurface();
            obj.startupUpdate("Preparing runtime...");
        end

        function attachRuntime(obj, runtime)
            if ~isa(runtime, "labkit.app.internal.RuntimeKernel")
                error("labkit:app:runtime:InvariantFailure", ...
                    "MATLAB platform adapter requires its RuntimeKernel.");
            end
            obj.Runtime = runtime;
            obj.Figure.CloseRequestFcn = @(~, ~) obj.requestClose();
            obj.Figure.WindowKeyPressFcn = @(~, event) obj.onKeyPress(event);
            obj.installCallbacks();
            obj.installUtilityMenus();
            obj.InteractionDeclarations = obj.collectInteractionDeclarations();
            if ~isempty(obj.InteractionDeclarations)
                obj.InteractionController = InteractionController( ...
                    obj.Figure, obj.interactionTargetAxes(), ...
                    @(id, signal, value) ...
                    runtime.applyInteraction(id, signal, value));
            end
        end

        function reconcile(obj, previous, view)
            if ~isa(view, "labkit.app.view.Snapshot")
                error("labkit:app:contract:InvalidValue", ...
                    "MATLAB platform adapter requires a Presentation value.");
            end
            try
                obj.applyView(view);
            catch cause
                if isa(previous, "labkit.app.view.Snapshot")
                    try
                        obj.applyView(previous);
                    catch rollbackCause
                        failure = MException( ...
                            "labkit:app:runtime:InvariantFailure", ...
                            "MATLAB presentation commit and rollback both failed.");
                        failure = addCause(failure, cause);
                        failure = addCause(failure, rollbackCause);
                        throw(failure);
                    end
                end
                rethrow(cause);
            end
        end

        function close(obj)
            if ~isempty(obj.InteractionController)
                obj.InteractionController.delete();
                obj.InteractionController = [];
            end
            if ~isempty(obj.Figure) && isvalid(obj.Figure)
                delete(obj.Figure);
            end
        end

        function value = figureForRuntime(obj)
            value = obj.Figure;
        end

        function show(obj, title)
            if ~isempty(obj.Figure) && isvalid(obj.Figure)
                obj.setWindowTitle(title);
                obj.Figure.Visible = "on";
            end
        end

        function setWindowTitle(obj, title)
            obj.BaseWindowTitle = string(title);
            if ~obj.Busy && ~isempty(obj.Figure) && isvalid(obj.Figure)
                obj.Figure.Name = char(obj.BaseWindowTitle);
            end
        end

        function beginBusy(obj, message)
            if obj.Starting || obj.Busy || ...
                    isempty(obj.Figure) || ~isvalid(obj.Figure)
                return
            end
            message = strip(string(message));
            if strlength(message) == 0
                message = "Working";
            end
            obj.Busy = true;
            obj.PriorPointer = string(obj.Figure.Pointer);
            obj.Figure.Pointer = "watch";
            obj.Figure.Name = char(obj.BaseWindowTitle + ...
                " [Working: " + message + "]");
            setappdata(obj.Figure, "labkitAppBusy", true);
            drawnow limitrate
        end

        function endBusy(obj)
            if obj.Starting
                return
            end
            if ~obj.Busy
                return
            end
            obj.Busy = false;
            if isempty(obj.Figure) || ~isvalid(obj.Figure)
                return
            end
            obj.Figure.Pointer = char(obj.PriorPointer);
            obj.Figure.Name = char(obj.BaseWindowTitle);
            if isappdata(obj.Figure, "labkitAppBusy")
                rmappdata(obj.Figure, "labkitAppBusy");
            end
            drawnow limitrate
        end

        function startupUpdate(obj, message)
            if ~obj.Starting || isempty(obj.Figure) || ~isvalid(obj.Figure)
                return
            end
            if ~isempty(obj.StartupLabel) && isvalid(obj.StartupLabel)
                obj.StartupLabel.Text = char(string(message));
            end
            if toc(obj.StartupStarted) >= 0.25 && ...
                    ~any(startupGuiMode() == ["hidden", "minimized"])
                obj.StartupPanel.Visible = "on";
                obj.Figure.Visible = "on";
                drawnow limitrate
            end
        end

        function finishStartup(obj)
            if ~obj.Starting
                return
            end
            obj.Starting = false;
            if isempty(obj.Figure) || ~isvalid(obj.Figure)
                return
            end
            if ~isempty(obj.StartupPanel) && isvalid(obj.StartupPanel)
                delete(obj.StartupPanel);
            end
            obj.StartupPanel = [];
            obj.StartupLabel = [];
            obj.Figure.Pointer = char(obj.PriorPointer);
            if isappdata(obj.Figure, "labkitAppBusy")
                rmappdata(obj.Figure, "labkitAppBusy");
            end
            if startupGuiMode() == "minimized" && ...
                    isprop(obj.Figure, "WindowState")
                obj.Figure.Visible = "on";
                obj.Figure.WindowState = "minimized";
            end
        end

        function alert(obj, message, title)
            uialert(obj.Figure, char(string(message)), char(string(title)));
        end

        function result = chooseInputFile(~, filters, startPath)
            [name, folder] = uigetfile(filters, "Choose input file", ...
                safeStartPath(startPath));
            result = dialogPath(name, folder);
        end

        function result = chooseInputFolder(~, startPath)
            folder = uigetdir(safeStartPath(startPath), "Choose input folder");
            result = folderDialogPath(folder);
        end

        function result = chooseOutputFile(~, filters, startPath)
            [name, folder] = uiputfile(filters, "Choose output file", ...
                safeStartPath(startPath));
            result = dialogPath(name, folder);
        end

        function result = chooseOutputFolder(~, startPath)
            folder = uigetdir(safeStartPath(startPath), "Choose output folder");
            result = folderDialogPath(folder);
        end
    end

    methods (Access = private)
        function createStartupSurface(obj)
            figurePosition = obj.Figure.Position;
            width = max(220, figurePosition(3) - 32);
            obj.StartupPanel = uipanel(obj.Figure, ...
                BorderType="line", Visible="off", ...
                Tag="labkitAppStartupStatus", ...
                Position=[16 12 width 34]);
            grid = uigridlayout(obj.StartupPanel, [1 1], ...
                Padding=[8 2 8 2]);
            obj.StartupLabel = uilabel(grid, ...
                Text="Building controls...", ...
                Tag="labkitAppStartupStatusLabel");
        end

        function buildTree(obj)
            nodes = obj.Plan.Nodes;
            for k = 1:numel(nodes)
                node = nodes(k);
                parent = obj.parentFor(node);
                component = obj.createComponent(node, parent);
                if ~isempty(component)
                    component.Tag = char(node.Id);
                end
                obj.placeInParent(node, component);
                obj.Components(char(node.Id)) = component;
            end
            workspaceIndex = find(string({nodes.Kind}) == "workspace", 1);
            if ~isempty(workspaceIndex)
                workspace = nodes(workspaceIndex);
                if strlength(workspace.InitialPage) > 0
                    group = obj.component(workspace.Id);
                    page = obj.component(workspace.InitialPage);
                    group.SelectedTab = page;
                end
            end
        end

        function parent = parentFor(obj, node)
            if node.Kind == "workbench"
                parent = obj.Figure;
                return;
            end
            parent = obj.Figure;
            nodes = obj.Plan.Nodes;
            for k = 1:numel(nodes)
                if any(nodes(k).ChildIds == node.Id)
                    if nodes(k).Kind == "workbench"
                        if node.Kind == "workspace"
                            parent = obj.WorkbenchWorkspace;
                        else
                            parent = obj.WorkbenchControls;
                        end
                        return;
                    end
                    parent = obj.contentParent(nodes(k).Id);
                    return;
                end
            end
        end

        function component = createComponent(obj, node, parent)
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
                        border = "none";
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
                        Enable=onOff(config.Enabled));
                    applyTextFit(component, ...
                        CharsPerStep=18, MaxShrinkSteps=3);
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
                case {"logPanel", "statusPanel"}
                    component = obj.createTextPanel( ...
                        node, parent, config, node.Kind == "logPanel");
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

        function component = createField(~, parent, config, id)
            value = neutralValue(config.Value, config.Kind, config.Choices);
            if config.Kind == "logical"
                component = uicheckbox(parent, Text=config.Label, ...
                    Value=logical(value), Enable=onOff(config.Enabled));
                return;
            end
            parent = labeledParent(parent, config.Label, id);
            layoutContainer = parent;
            switch config.Kind
                case "numeric"
                    component = uieditfield(parent, "numeric", ...
                        Value=value, Enable=onOff(config.Enabled));
                case "choice"
                    choices = config.Choices;
                    if isempty(choices)
                        choices = "";
                    end
                    component = uidropdown(parent, Items=choices, ...
                        Value=value, Enable=onOff(config.Enabled));
                case "readonly"
                    component = uitextarea(parent, Editable="off", ...
                        Value=char(string(value)), ...
                        Enable=onOff(config.Enabled));
                otherwise
                    component = uieditfield(parent, "text", ...
                        Value=string(value), Enable=onOff(config.Enabled));
            end
            component.UserData = struct( ...
                "LayoutContainer", layoutContainer);
        end

        function spinner = createPanner(~, node, parent)
            config = node.Configuration;
            [limits, value] = sliderInitialValue(config);
            outer = labeledParent(parent, config.Label, node.Id);
            grid = uigridlayout(outer, [1 2], ...
                Padding=[0 0 0 0], ColumnSpacing=6, ...
                ColumnWidth={76, '1x'}, ...
                Tag=char(node.Id + ".panner"));
            grid.Layout.Row = 1;
            grid.Layout.Column = 2;
            step = config.Step;
            if isempty(step)
                step = max(eps, diff(limits) * 0.002);
            end
            spinner = uispinner(grid, Limits=limits, Value=value, ...
                Step=step, Enable=onOff(config.Enabled));
            spinner.Layout.Row = 1;
            spinner.Layout.Column = 1;
            if strlength(config.ValueDisplayFormat) > 0
                spinner.ValueDisplayFormat = ...
                    char(config.ValueDisplayFormat);
            end
            slider = uislider(grid, Limits=limits, Value=value, ...
                Enable=onOff(config.Enabled), ...
                Tag=char(node.Id + ".slider"));
            slider.Layout.Row = 1;
            slider.Layout.Column = 2;
            if ~config.ShowTicks
                slider.MajorTicks = [];
                slider.MinorTicks = [];
            end
            spinner.UserData = struct( ...
                "LayoutContainer", outer, "Slider", slider);
        end

        function first = createRangeField(~, node, parent)
            config = node.Configuration;
            [limits, value] = rangeSliderInitialValue(config);
            outer = labeledParent(parent, config.Label, node.Id);
            grid = uigridlayout(outer, [1 2], ...
                Padding=[0 0 0 0], ColumnSpacing=6, ...
                ColumnWidth={'1x', '1x'}, ...
                Tag=char(node.Id + ".range"));
            grid.Layout.Row = 1;
            grid.Layout.Column = 2;
            first = uieditfield(grid, "numeric", Limits=limits, ...
                Value=value(1), Enable=onOff(config.Enabled));
            first.Layout.Row = 1;
            first.Layout.Column = 1;
            second = uieditfield(grid, "numeric", Limits=limits, ...
                Value=value(2), Enable=onOff(config.Enabled), ...
                Tag=char(node.Id + ".end"));
            second.Layout.Row = 1;
            second.Layout.Column = 2;
            first.UserData = struct( ...
                "LayoutContainer", outer, "EndField", second);
        end

        function createAxes(obj, node, parent)
            config = node.Configuration;
            hasModes = ~isempty(config.ViewModes);
            root = uigridlayout(parent, [1 + double(hasModes) 1], ...
                Padding=[2 2 2 2], RowSpacing=4, ColumnSpacing=2);
            root.RowHeight = {'1x'};
            axesRow = 1;
            mode = [];
            if hasModes
                root.RowHeight = {'fit', '1x'};
                mode = uidropdown(root, Items=config.ViewModes, ...
                    Value=config.ViewModes(1), ...
                    Tag=char(node.Id + ".viewMode"));
                mode.Layout.Row = 1;
                mode.Layout.Column = 1;
                axesRow = 2;
            end
            axisCount = numel(node.AxisIds);
            switch config.Layout
                case "pair"
                    layout = uigridlayout(root, [1 axisCount]);
                    layout.RowHeight = {'1x'};
                    layout.ColumnWidth = repeatedOrConfigured( ...
                        config.ColumnWidths, axisCount);
                case "stack"
                    layout = uigridlayout(root, [axisCount 1]);
                    layout.RowHeight = repeatedOrConfigured( ...
                        config.RowHeights, axisCount);
                    layout.ColumnWidth = {'1x'};
                otherwise
                    layout = uigridlayout(root, [1 1]);
                    layout.RowHeight = {'1x'};
                    layout.ColumnWidth = {'1x'};
            end
            layout.Layout.Row = axesRow;
            layout.Layout.Column = 1;
            layout.Padding = [0 0 0 0];
            layout.RowSpacing = 2;
            layout.ColumnSpacing = 2;
            for k = 1:numel(node.AxisIds)
                axisId = node.AxisIds(k);
                key = axisKey(node.Id, axisId);
                ax = uiaxes(layout, Tag=char(key));
                if config.Layout == "stack"
                    ax.Layout.Row = k;
                    ax.Layout.Column = 1;
                elseif config.Layout == "pair"
                    ax.Layout.Row = 1;
                    ax.Layout.Column = k;
                else
                    ax.Layout.Row = 1;
                    ax.Layout.Column = 1;
                end
                title(ax, axisText(config.AxisTitles, node.AxisIds, k));
                xlabel(ax, axisText(config.XLabels, strings(1, axisCount), k));
                ylabel(ax, axisText(config.YLabels, strings(1, axisCount), k));
                if config.ScrollZoomAxes(k) ~= "xy"
                    setappdata(ax, "labkitPreviewScrollZoomAxes", ...
                        config.ScrollZoomAxes(k));
                end
                obj.Axes(char(key)) = ax;
            end
            parent.UserData = struct("ValueControl", mode);
        end

        function table = createDataTable(obj, node, parent)
            config = node.Configuration;
            title = config.Title;
            owner = obj.owningNode(node.Id);
            if strlength(title) == 0 && ~isempty(owner) && ...
                    owner.Kind == "section" && ...
                    isfield(owner.Configuration, "Title")
                title = owner.Configuration.Title;
            end
            panel = uipanel(parent, Title=char(title));
            grid = uigridlayout(panel, [1 1], Padding=[8 8 8 8]);
            table = uitable(grid, ...
                ColumnName=cellstr(config.Columns), ...
                RowName=cellstr(config.RowNames), ...
                ColumnEditable=config.ColumnEditable);
            table.UserData = struct("LayoutContainer", panel);
            panel.Tag = char(node.Id + ".panel");
        end

        function applyView(obj, view)
            operations = orderedOperations(view.operationsForCompiler());
            interactionOperations = operations(cellfun(@(operation) ...
                isInteractionKind(operation.Kind), operations));
            operations = operations(~cellfun(@(operation) ...
                isInteractionKind(operation.Kind), operations));
            for k = 1:numel(operations)
                obj.apply(operations{k});
            end
            if ~isempty(obj.InteractionController)
                obj.InteractionController.reconcile( ...
                    obj.InteractionDeclarations, interactionOperations);
            end
        end

        function apply(obj, operation)
            component = obj.component(operation.Target);
            switch operation.Kind
                case "value"
                    obj.applyValue(component, operation.Value);
                case "choices"
                    applyChoices(component, operation.Value);
                case "limits"
                    obj.applyLimits(component, operation.Value);
                case "enabled"
                    obj.applyEnabled(component, operation.Value);
                case "visible"
                    setIfProperty(layoutHandle(component), ...
                        "Visible", onOff(operation.Value));
                case "text"
                    obj.applyText(component, operation.Value);
                case "filePaths"
                    obj.applyFilePaths(component, operation.Value);
                case "listSelection"
                    obj.applyListSelection(component, operation.Value);
                case "tableCellSelection"
                    obj.applyTableCellSelection(component, operation.Value);
                case "tableData"
                    obj.applyTableData(component, operation.Value);
                case "renderPlot"
                    obj.renderPlot(operation);
                case "workspacePage"
                    setIfProperty(component, "Enable", onOff(operation.Value.Enabled));
                    component.UserData = struct("Status", operation.Value.Status);
            end
        end

        function applyListSelection(~, component, selection)
            if ~isprop(component, "Items") || ~isprop(component, "Value")
                return;
            end
            items = string(component.Items);
            indices = selection.Indices;
            indices = indices(indices >= 1 & indices <= numel(items));
            component.Value = items(indices);
        end

        function applyFilePaths(~, component, paths)
            data = component.UserData;
            data.Paths = reshape(string(paths), 1, []);
            component.UserData = data;
            labels = formatFileLabels(paths);
            if isempty(labels) && ~data.Compact
                labels = data.EmptyText;
            end
            setIfProperty(component, "Items", labels);
            if ~isstruct(component.UserData) || ...
                    ~isfield(component.UserData, "Status") || ...
                    isempty(component.UserData.Status) || ...
                    ~isvalid(component.UserData.Status)
                return
            end
            text = component.UserData.EmptyText;
            if ~isempty(paths)
                if component.UserData.Compact
                    text = string(paths(1));
                elseif numel(paths) == 1
                    text = "1 file";
                else
                    text = string(numel(paths)) + " files";
                end
            end
            if component.UserData.Compact
                component.UserData.Status.Value = char(string(text));
            else
                component.UserData.Status.Value = cellstr(string(text));
            end
        end

        function applyTableCellSelection(~, component, selection)
            if isprop(component, "Selection")
                component.Selection = selection.CellIndices;
            end
        end

        function applyTableData(~, component, model)
            component.Data = nativeTableData(model.Data);
            if ~isempty(model.Columns)
                component.ColumnName = cellstr(model.Columns);
            end
            if ~isempty(model.RowNames)
                component.RowName = cellstr(model.RowNames);
            end
            component.ColumnEditable = model.ColumnEditable;
        end

        function applyText(~, component, value)
            if isprop(component, "Text")
                component.Text = value;
            elseif isprop(component, "Value")
                component.Value = value;
            elseif isprop(component, "Title")
                component.Title = value;
            end
            applyTextFit(component);
            if isappdata(component, "labkitAppLogFollowLatest") && ...
                    getappdata(component, "labkitAppLogFollowLatest")
                try
                    scroll(component, "bottom");
                catch
                end
            end
        end

        function applyValue(~, component, value)
            mode = linkedPlotMode(component);
            if ~isempty(mode)
                mode.Value = value;
                return
            end
            rangeEnd = linkedRangeEnd(component);
            if ~isempty(rangeEnd)
                component.Value = value(1);
                rangeEnd.Value = value(2);
                return
            end
            setIfProperty(component, "Value", value);
            linked = linkedPannerSlider(component);
            if ~isempty(linked)
                linked.Value = min(linked.Limits(2), ...
                    max(linked.Limits(1), double(value)));
            end
        end

        function applyLimits(~, component, limits)
            rangeEnd = linkedRangeEnd(component);
            if ~isempty(rangeEnd)
                component.Limits = limits;
                rangeEnd.Limits = limits;
                return
            end
            linked = linkedPannerSlider(component);
            if isempty(linked)
                setIfProperty(component, "Limits", limits);
                return
            end
            value = min(limits(2), ...
                max(limits(1), double(component.Value)));
            component.Limits = limits;
            component.Value = value;
            linked.Limits = limits;
            linked.Value = value;
        end

        function applyEnabled(~, component, enabled)
            value = onOff(enabled);
            setIfProperty(component, "Enable", value);
            mode = linkedPlotMode(component);
            if ~isempty(mode)
                mode.Enable = value;
            end
            linked = linkedPannerSlider(component);
            if ~isempty(linked)
                linked.Enable = value;
            end
            rangeEnd = linkedRangeEnd(component);
            if ~isempty(rangeEnd)
                rangeEnd.Enable = value;
            end
        end

        function renderPlot(obj, operation)
            node = obj.node(operation.Target);
            renderer = node.Renderer;
            axesById = struct();
            axes = gobjects(1, numel(node.AxisIds));
            for k = 1:numel(node.AxisIds)
                axes(k) = obj.Axes(char(axisKey(node.Id, node.AxisIds(k))));
                axesById.(char(node.AxisIds(k))) = axes(k);
            end
            viewport = captureViewport(axes);
            renderer(axesById, operation.Value);
            for k = 1:numel(axes)
                labkit.app.plot.enablePopout(axes(k));
            end
            restoreViewport(axes, viewport);
        end

        function declarations = collectInteractionDeclarations(obj)
            declarations = {};
            for k = 1:numel(obj.Plan.Nodes)
                config = obj.Plan.Nodes(k).Configuration;
                if isfield(config, "Interactions")
                    declarations = [declarations config.Interactions];
                end
            end
        end

        function targets = interactionTargetAxes(obj)
            targets = struct("id", {}, "axes", {});
            for k = 1:numel(obj.Plan.Nodes)
                node = obj.Plan.Nodes(k);
                if node.Kind ~= "plotArea"
                    continue;
                end
                for axisId = node.AxisIds
                    key = axisKey(node.Id, axisId);
                    targetId = key;
                    if numel(node.AxisIds) == 1
                        targetId = node.Id;
                    end
                    targets(end + 1) = struct( ...
                        "id", targetId, "axes", obj.Axes(char(key)));
                end
            end
        end

        function installContentGrid(obj, node, component)
            if isempty(node.ChildIds)
                return;
            end
            policy = nativeLayoutPolicy();
            padding = policy.ContentPadding;
            if node.Kind == "group"
                padding = [0 0 0 0];
            end
            horizontal = node.Kind == "group" && ...
                isfield(node.Configuration, "Layout") && ...
                node.Configuration.Layout == "horizontal";
            actionGrid = obj.usesAdaptiveActionGrid(node);
            if actionGrid
                [rows, columns] = obj.actionGridSize(node);
                grid = uigridlayout(component, [rows columns], ...
                    Padding=padding, ...
                    RowSpacing=policy.ContentSpacing, ...
                    ColumnSpacing=policy.ContentSpacing);
                grid.RowHeight = repmat({'fit'}, 1, rows);
                grid.ColumnWidth = repmat({'1x'}, 1, columns);
            elseif horizontal
                grid = uigridlayout(component, [1 numel(node.ChildIds)], ...
                    Padding=padding, ...
                    RowSpacing=policy.ContentSpacing, ...
                    ColumnSpacing=policy.ContentSpacing);
                grid.ColumnWidth = repmat({'1x'}, 1, numel(node.ChildIds));
            else
                rowCount = numel(node.ChildIds);
                if node.Kind == "tab"
                    rowCount = 2 * rowCount;
                end
                grid = uigridlayout(component, [rowCount 1], ...
                    Padding=padding, ...
                    RowSpacing=policy.ContentSpacing, ...
                    ColumnSpacing=policy.ContentSpacing);
                heights = obj.childRowHeights(node.ChildIds);
                if numel(node.ChildIds) == 1 && ...
                        obj.isGrowableTabChild(obj.node(node.ChildIds(1)))
                    heights{1} = "1x";
                end
                if node.Kind == "tab"
                    expanded = cell(1, 2 * numel(heights));
                    expanded(1:2:end) = heights;
                    expanded(2:2:end) = {policy.SplitterThickness};
                    heights = expanded;
                end
                grid.RowHeight = heights;
                if node.Kind == "tab" && isprop(grid, "Scrollable")
                    grid.Scrollable = "on";
                end
            end
            grid.Tag = char(node.Id + ".layout");
            obj.Layouts(char(node.Id)) = grid;
            if node.Kind == "tab"
                for k = 1:numel(node.ChildIds)
                    installRowResize(obj.Figure, grid, 2 * k - 1, 2 * k);
                end
            end
        end

        function placeInParent(obj, node, component)
            if node.Kind == "workbench" || isempty(component)
                return
            end
            parentNode = obj.owningNode(node.Id);
            if isempty(parentNode) || parentNode.Kind == "workbench"
                return
            end
            index = find(parentNode.ChildIds == node.Id, 1);
            if isempty(index)
                return
            end
            handle = layoutHandle(component);
            if isempty(handle) || ~isprop(handle, "Layout")
                return
            end
            horizontal = parentNode.Kind == "group" && ...
                isfield(parentNode.Configuration, "Layout") && ...
                parentNode.Configuration.Layout == "horizontal";
            if obj.usesAdaptiveActionGrid(parentNode)
                [~, columns] = obj.actionGridSize(parentNode);
                row = ceil(index / columns);
                column = mod(index - 1, columns) + 1;
                if columns > 1 && index == numel(parentNode.ChildIds) && ...
                        mod(numel(parentNode.ChildIds), columns) == 1
                    column = [1 columns];
                end
                handle.Layout.Row = row;
                handle.Layout.Column = column;
            elseif horizontal
                handle.Layout.Row = 1;
                handle.Layout.Column = index;
            else
                row = index;
                if parentNode.Kind == "tab"
                    row = 2 * index - 1;
                end
                handle.Layout.Row = row;
                handle.Layout.Column = 1;
            end
        end

        function owner = owningNode(obj, id)
            owner = [];
            for k = 1:numel(obj.Plan.Nodes)
                if any(obj.Plan.Nodes(k).ChildIds == id)
                    owner = obj.Plan.Nodes(k);
                    return
                end
            end
        end

        function installWorkbenchLayout(obj, node, component)
            policy = nativeLayoutPolicy();
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
                installColumnResize(obj.Figure, grid, 1, 2);
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

        function heights = childRowHeights(obj, ids)
            nodes = obj.nodes(ids);
            heights = repmat({'fit'}, 1, numel(nodes));
            for k = 1:numel(nodes)
                heights{k} = obj.preferredRowHeight(nodes(k));
            end
        end

        function height = preferredRowHeight(obj, node)
            policy = nativeLayoutPolicy();
            switch node.Kind
                case {"tab", "workspace", "workspacePage", "plotArea"}
                    height = "1x";
                case "fileList"
                    if node.Configuration.SelectionMode == "single" && ...
                            node.Configuration.MaxFiles == 1
                        height = policy.CompactFileHeight;
                    elseif ~node.Configuration.ShowStatus
                        height = policy.FileListNoStatusHeight;
                    else
                        height = policy.FileListHeight;
                    end
                case "dataTable"
                    height = policy.TableHeight;
                case "logPanel"
                    height = policy.LogHeight;
                case "statusPanel"
                    if node.Id == "applicationUsage"
                        height = policy.UsageHeight;
                    else
                        height = policy.StatusHeight;
                    end
                case "button"
                    height = estimatedControlHeight( ...
                        node.Configuration.Label, 22, 2, ...
                        policy.ButtonHeight);
                case "slider"
                    height = policy.SliderHeight;
                case "field"
                    if node.Configuration.Kind == "readonly"
                        text = [string(node.Configuration.Label), ...
                            string(node.Configuration.Value)];
                        height = estimatedControlHeight( ...
                            text, 34, 3, policy.FieldHeight);
                    elseif node.Configuration.Kind == "logical"
                        height = estimatedControlHeight( ...
                            node.Configuration.Label, 42, 2, ...
                            policy.FieldHeight);
                    else
                        height = estimatedControlHeight( ...
                            node.Configuration.Label, 30, 2, ...
                            policy.FieldHeight);
                    end
                case {"rangeField", "panner"}
                    height = policy.FieldHeight;
                case {"section", "group"}
                    children = obj.nodes(node.ChildIds);
                    childHeights = zeros(1, numel(children));
                    for k = 1:numel(children)
                        candidate = obj.preferredRowHeight(children(k));
                        if ischar(candidate) || isstring(candidate)
                            candidate = policy.FileListHeight;
                        end
                        childHeights(k) = candidate;
                    end
                    horizontal = node.Kind == "group" && ...
                        isfield(node.Configuration, "Layout") && ...
                        node.Configuration.Layout == "horizontal";
                    if node.Kind == "section" && ...
                            ~obj.sectionDrawsOwnTitle(node) && ...
                            numel(children) == 1
                        height = childHeights(1) + ...
                            policy.UntitledSectionChromeHeight;
                    elseif obj.usesAdaptiveActionGrid(node)
                        [rows, ~] = obj.actionGridSize(node);
                        height = rows * policy.ButtonHeight + ...
                            max(0, rows - 1) * policy.ContentSpacing + ...
                            policy.GroupChromeHeight;
                    elseif horizontal
                        height = max(childHeights, [], "omitnan") + ...
                            policy.GroupChromeHeight;
                    else
                        height = sum(childHeights) + ...
                            max(0, numel(children) - 1) * ...
                            policy.ContentSpacing + ...
                            policy.SectionChromeHeight;
                    end
                otherwise
                    height = "fit";
            end
        end

        function tf = isGrowableTabChild(obj, node)
            if node.Kind == "section" && numel(node.ChildIds) == 1
                tf = obj.isGrowableTabChild(obj.node(node.ChildIds(1)));
                return
            end
            if node.Kind == "fileList"
                tf = node.Configuration.SelectionMode == "multiple" || ...
                    node.Configuration.MaxFiles > 1;
                return
            end
            tf = any(node.Kind == [ ...
                "plotArea", "dataTable", "logPanel", "statusPanel"]);
        end

        function tf = sectionDrawsOwnTitle(obj, node)
            tf = true;
            if node.Kind ~= "section" || numel(node.ChildIds) ~= 1
                return
            end
            child = obj.node(node.ChildIds(1));
            tf = ~any(child.Kind == [ ...
                "plotArea", "dataTable", "logPanel", ...
                "statusPanel", "fileList"]);
        end

        function tf = usesAdaptiveActionGrid(obj, node)
            tf = false;
            if node.Kind ~= "group" || ...
                    ~isfield(node.Configuration, "Layout") || ...
                    node.Configuration.Layout ~= "auto" || ...
                    isempty(node.ChildIds)
                return
            end
            children = obj.nodes(node.ChildIds);
            tf = all(string({children.Kind}) == "button");
        end

        function [rows, columns] = actionGridSize(obj, node)
            children = obj.nodes(node.ChildIds);
            columns = min(2, numel(children));
            labels = strings(1, numel(children));
            for k = 1:numel(children)
                labels(k) = children(k).Configuration.Label;
            end
            if any(strlength(labels) > 28)
                columns = 1;
            end
            rows = max(1, ceil(numel(children) / columns));
        end

        function selected = nodes(obj, ids)
            selected = repmat(obj.Plan.Nodes(1), 0, 1);
            for id = string(ids)
                index = find(string({obj.Plan.Nodes.Id}) == id, 1);
                if isempty(index)
                    error("labkit:app:runtime:InvariantFailure", ...
                        "Compiled Layout child is missing: %s.", id);
                end
                selected(end + 1, 1) = obj.Plan.Nodes(index);
            end
        end

        function parent = contentParent(obj, id)
            key = char(id);
            if isKey(obj.Layouts, key)
                parent = obj.Layouts(key);
            else
                parent = obj.component(id);
            end
        end

        function list = createFilePanel(obj, node, parent)
            config = node.Configuration;
            panel = uipanel(parent, BorderType="line", ...
                Title=char(config.Label));
            if config.SelectionMode == "single" && config.MaxFiles == 1
                grid = uigridlayout(panel, [1 2], Padding=[7 6 7 6], ...
                    ColumnWidth={140, '1x'}, ColumnSpacing=7);
                grid.Tag = char(node.Id + ".layout");
                choose = uibutton(grid, Text=config.ChooseLabel, ...
                    Tag=char(node.Id + ".choose"));
                applyTextFit(choose, CharsPerStep=18, MaxShrinkSteps=3);
                status = uieditfield(grid, Editable="off", ...
                    Value=char(config.EmptyText), ...
                    Tag=char(node.Id + ".status"));
                list = uilistbox(panel, Items=strings(1, 0), ...
                    Visible="off", Position=[0 0 1 1]);
                list.UserData = struct("Panel", panel, ...
                    "Choose", choose, "Folder", [], ...
                    "RecursiveFolder", [], "Remove", [], "Clear", [], ...
                    "Status", status, "EmptyText", config.EmptyText, ...
                    "Target", node.Id, "Compact", true, ...
                    "Paths", strings(1, 0));
                return
            end
            statusHeight = 0;
            if config.ShowStatus
                statusHeight = 64;
            end
            grid = uigridlayout(panel, [4 1], Padding=[5 5 5 5], ...
                RowHeight={'fit', 'fit', '1x', statusHeight}, ...
                RowSpacing=4);
            grid.Tag = char(node.Id + ".layout");
            list = uilistbox(grid, Items=strings(1, 0), ...
                Multiselect=config.SelectionMode == "multiple");
            list.Layout.Row = 3;
            addButtons = uigridlayout(grid, [1 3], ...
                Padding=[0 0 0 0], ...
                ColumnWidth={'1x', '1x', '1x'}, ColumnSpacing=4);
            addButtons.Layout.Row = 1;
            choose = uibutton(addButtons, Text=config.ChooseLabel, Tag= ...
                char(node.Id + ".choose"));
            folder = uibutton(addButtons, Text=config.FolderLabel, Tag= ...
                char(node.Id + ".folder"));
            recursive = uibutton(addButtons, ...
                Text=config.RecursiveFolderLabel, Tag= ...
                char(node.Id + ".recursiveFolder"));
            selectionButtons = uigridlayout(grid, [1 2], ...
                Padding=[0 0 0 0], ...
                ColumnWidth={'2x', '1x'}, ColumnSpacing=4);
            selectionButtons.Layout.Row = 2;
            remove = uibutton(selectionButtons, ...
                Text=config.RemoveLabel, Tag= ...
                char(node.Id + ".remove"));
            clear = uibutton(selectionButtons, ...
                Text=config.ClearLabel, Tag= ...
                char(node.Id + ".clear"));
            buttons = [choose, folder, recursive, remove, clear];
            for k = 1:numel(buttons)
                applyTextFit(buttons(k), ...
                    CharsPerStep=18, MaxShrinkSteps=3);
            end
            status = [];
            if config.ShowStatus
                status = uitextarea(grid, Editable="off", ...
                    Value=char(config.EmptyText), ...
                    Tag=char(node.Id + ".status"));
                status.Layout.Row = 4;
            end
            list.UserData = struct("Panel", panel, "Choose", choose, ...
                "Folder", folder, "RecursiveFolder", recursive, ...
                "Remove", remove, "Clear", clear, "Status", status, ...
                "EmptyText", config.EmptyText, "Target", node.Id, ...
                "Compact", false, "Paths", strings(1, 0));
        end

        function textArea = createTextPanel(obj, node, parent, config, isLog)
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
                applyTextFit(follow, ...
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
            end
            textArea.UserData = struct("Panel", panel);
            panel.Tag = char(node.Id + ".panel");
        end

        function toggleLogFollowLatest(~, textArea, button)
            following = ~logical(getappdata( ...
                textArea, "labkitAppLogFollowLatest"));
            setappdata(textArea, "labkitAppLogFollowLatest", following);
            menuItem = getappdata(textArea, "labkitAppLogFollowMenu");
            if following
                label = "Pause auto-scroll";
                checked = "on";
                try
                    scroll(textArea, "bottom");
                catch
                end
            else
                label = "Follow latest";
                checked = "off";
            end
            button.Text = label;
            menuItem.Text = label;
            menuItem.Checked = checked;
        end

        function installUtilityMenus(obj)
            plotMenu = uimenu(obj.Figure, Text="Plot", ...
                Tag="labkitAppUtilityPlotMenu");
            uimenu(plotMenu, Text="Pop out all plots", ...
                Tag="labkitAppUtilityPopout", ...
                MenuSelectedFcn=@(~, ~) obj.runUtility( ...
                @() obj.popoutAllPlots()));
            uimenu(plotMenu, Text="Copy all plots", ...
                Tag="labkitAppUtilityCopyPlot", ...
                MenuSelectedFcn=@(~, ~) obj.runUtility( ...
                @() obj.copyAllPlots()));
            uimenu(plotMenu, Text="Save all plots", ...
                Tag="labkitAppUtilitySavePlot", ...
                MenuSelectedFcn=@(~, ~) obj.runUtility( ...
                @() obj.saveAllPlots()));
            uimenu(obj.Figure, Text="Screenshot", ...
                Tag="labkitAppUtilityScreenshot", ...
                MenuSelectedFcn=@(~, ~) obj.runUtility( ...
                @() obj.saveScreenshot()));
            if obj.hasProjectDocument()
                uimenu(obj.Figure, Text="Save State", ...
                    Tag="labkitAppUtilitySaveState", ...
                    MenuSelectedFcn=@(~, ~) obj.runUtility( ...
                    @() obj.saveState()));
                uimenu(obj.Figure, Text="Load State", ...
                    Tag="labkitAppUtilityLoadState", ...
                    MenuSelectedFcn=@(~, ~) obj.runUtility( ...
                    @() obj.loadState()));
            end
        end

        function runUtility(obj, callback)
            try
                callback();
            catch cause
                obj.alert(cause.message, "LabKit Utility");
            end
        end

        function handles = allAxes(obj)
            values = obj.Axes.values;
            if isempty(values)
                handles = gobjects(0, 1);
            else
                handles = vertcat(values{:});
                handles = handles(isvalid(handles));
            end
        end

        function popoutAllPlots(obj)
            handles = obj.allAxes();
            for k = 1:numel(handles)
                labkit.app.plot.enablePopout(handles(k));
                menu = findall(handles(k).ContextMenu, ...
                    Type="uimenu", Tag="labkitAxesPopoutMenu");
                if ~isempty(menu)
                    menu(1).MenuSelectedFcn(menu(1), []);
                end
            end
        end

        function copyAllPlots(obj)
            handles = obj.allAxes();
            if numel(handles) == 1
                copygraphics(handles(1), ContentType="image");
            elseif ~isempty(handles)
                copygraphics(obj.Figure, ContentType="image");
            end
        end

        function saveAllPlots(obj)
            handles = obj.allAxes();
            if isempty(handles)
                return
            end
            choice = obj.chooseOutputFile( ...
                {"*.png", "PNG image (*.png)"; ...
                 "*.pdf", "PDF file (*.pdf)"}, "plots.png");
            if choice.Cancelled
                return
            end
            filepath = string(choice.Value);
            for k = 1:numel(handles)
                output = filepath;
                if numel(handles) > 1
                    output = plotFilepath(filepath, handles(k), k);
                end
                exportgraphics(handles(k), output, ContentType="image");
            end
        end

        function saveScreenshot(obj)
            choice = obj.chooseOutputFile( ...
                {"*.png", "PNG image (*.png)"; ...
                 "*.pdf", "PDF file (*.pdf)"}, "app.png");
            if ~choice.Cancelled
                exportapp(obj.Figure, choice.Value);
            end
        end

        function tf = hasProjectDocument(obj)
            tf = true;
            try
                obj.Runtime.documentMetadata();
            catch
                tf = false;
            end
        end

        function saveState(obj)
            metadata = obj.Runtime.documentMetadata();
            startPath = string(metadata.path);
            if strlength(startPath) == 0
                startPath = "project.mat";
            end
            choice = obj.chooseOutputFile( ...
                {"*.mat", "LabKit project (*.mat)"}, startPath);
            if ~choice.Cancelled
                obj.Runtime.saveProject(obj.Runtime.State, choice.Value);
            end
        end

        function loadState(obj)
            choice = obj.chooseInputFile( ...
                {"*.mat", "LabKit project (*.mat)"}, "");
            if ~choice.Cancelled
                obj.Runtime.restoreProject(choice.Value);
            end
        end

        function onKeyPress(obj, event)
            modifiers = strings(1, 0);
            if isprop(event, "Modifier")
                modifiers = string(event.Modifier);
            end
            if strcmpi(string(event.Key), "w") && ...
                    any(ismember(lower(modifiers), ["control", "command"]))
                obj.requestClose();
            end
        end

        function requestClose(obj)
            if isempty(obj.Figure) || ~isvalid(obj.Figure)
                return
            end
            if ~isempty(obj.ClosePrompt) && isvalid(obj.ClosePrompt)
                obj.Runtime.close();
                return
            end
            message = "Close this LabKit app?";
            if obj.Busy
                message = "LabKit is still working. Close anyway?";
            elseif obj.hasProjectDocument()
                metadata = obj.Runtime.documentMetadata();
                if metadata.dirty
                    message = "This project has unsaved changes. Close anyway?";
                end
            end
            obj.ClosePrompt = uipanel(obj.Figure, ...
                Title="Close LabKit app?", ...
                Tag="labkitAppClosePrompt", ...
                Position=closePromptPosition(obj.Figure));
            grid = uigridlayout(obj.ClosePrompt, [2 3], ...
                RowHeight={'1x', 34}, ColumnWidth={'1x', 86, 86}, ...
                Padding=[10 8 10 8], RowSpacing=6, ColumnSpacing=8);
            label = uilabel(grid, Text=char(message + ...
                " Close again to confirm."), ...
                WordWrap="on", FontWeight="bold");
            label.Layout.Row = 1;
            label.Layout.Column = [1 3];
            closeButton = uibutton(grid, Text="Close", ...
                ButtonPushedFcn=@(~, ~) obj.Runtime.close());
            closeButton.Layout.Row = 2;
            closeButton.Layout.Column = 2;
            cancelButton = uibutton(grid, Text="Cancel", ...
                ButtonPushedFcn=@(~, ~) obj.clearClosePrompt());
            cancelButton.Layout.Row = 2;
            cancelButton.Layout.Column = 3;
            drawnow
        end

        function clearClosePrompt(obj)
            if ~isempty(obj.ClosePrompt) && isvalid(obj.ClosePrompt)
                delete(obj.ClosePrompt);
            end
            obj.ClosePrompt = [];
        end

        function installCallbacks(obj)
            nodes = obj.Plan.Nodes;
            for k = 1:numel(nodes)
                node = nodes(k);
                if ~isKey(obj.Components, char(node.Id))
                    continue;
                end
                component = obj.Components(char(node.Id));
                switch node.Kind
                    case "button"
                        component.ButtonPushedFcn = @(~, ~) ...
                            obj.Runtime.invokeAction(node.Id);
                    case "field"
                        if isprop(component, "ValueChangedFcn")
                            component.ValueChangedFcn = @(src, ~) ...
                                obj.Runtime.applyControlValue(node.Id, src.Value);
                        end
                    case "rangeField"
                        component.ValueChangedFcn = @(~, ~) ...
                            obj.rangeChanged(node.Id);
                        rangeEnd = linkedRangeEnd(component);
                        rangeEnd.ValueChangedFcn = @(~, ~) ...
                            obj.rangeChanged(node.Id);
                    case "slider"
                        component.ValueChangedFcn = @(src, ~) ...
                            obj.pannerChanged(node.Id, src.Value);
                        linked = linkedPannerSlider(component);
                        linked.ValueChangedFcn = @(src, ~) ...
                            obj.pannerChanged(node.Id, src.Value);
                        if isprop(linked, "ValueChangingFcn")
                            linked.ValueChangingFcn = @(src, event) ...
                                obj.pannerChanged(node.Id, ...
                                changingValue(event, src.Value));
                        end
                    case "fileList"
                        obj.installFilePanelCallbacks(node, component);
                    case "dataTable"
                        obj.installTableCallbacks(node, component);
                    case "plotArea"
                        mode = linkedPlotMode(component);
                        if ~isempty(mode)
                            mode.ValueChangedFcn = @(src, ~) ...
                                obj.Runtime.applyControlValue( ...
                                node.Id, string(src.Value));
                        end
                    case "workspace"
                        if ~isempty(node.PageIds)
                            component.SelectionChangedFcn = @(src, ~) ...
                                obj.Runtime.applyControlValue( ...
                                node.Id, string(src.SelectedTab.Tag));
                        end
                end
            end
        end

        function pannerChanged(obj, target, value)
            component = obj.component(target);
            value = min(component.Limits(2), ...
                max(component.Limits(1), double(value)));
            component.Value = value;
            linked = linkedPannerSlider(component);
            if ~isempty(linked)
                linked.Value = value;
            end
            obj.Runtime.applyControlValue(target, value);
        end

        function rangeChanged(obj, target)
            component = obj.component(target);
            rangeEnd = linkedRangeEnd(component);
            value = [component.Value, rangeEnd.Value];
            obj.Runtime.applyControlValue(target, value);
        end

        function installTableCallbacks(obj, node, component)
            roles = string(cellfun(@(value) value.Signal, node.Signals, ...
                "UniformOutput", false));
            if any(roles == "cellEdited")
                component.CellEditCallback = @(src, event) ...
                    obj.dispatchTableEdit(node.Id, src, event);
            end
            if any(roles == "cellSelectionChanged")
                if isprop(component, "SelectionChangedFcn")
                    component.SelectionChangedFcn = @(~, event) ...
                        obj.Runtime.applyTableSelection( ...
                            node.Id, tableSelectionCells(event));
                else
                    component.CellSelectionCallback = @(~, event) ...
                        obj.Runtime.applyTableSelection( ...
                            node.Id, tableSelectionCells(event));
                end
            end
        end

        function dispatchTableEdit(obj, target, component, event)
            indices = event.Indices;
            rowId = tableLabel(component.RowName, indices(1));
            columnId = tableLabel(component.ColumnName, indices(2));
            edit = labkit.app.event.TableCellEdit( ...
                RowIndex=indices(1), ColumnIndex=indices(2), ...
                RowId=rowId, ColumnId=columnId, ...
                PreviousValue=event.PreviousData, ...
                NewValue=editedValue(event), Data=component.Data);
            obj.Runtime.applyTableEdit(target, edit);
        end

        function installFilePanelCallbacks(obj, node, list)
            handles = list.UserData;
            list.ValueChangedFcn = @(src, ~) obj.Runtime.applyFilePanelSelection( ...
                node.Id, selectedIndices(src));
            handles.Choose.ButtonPushedFcn = @(~, ~) obj.chooseFiles(node.Id);
            if ~isempty(handles.Folder)
                handles.Folder.ButtonPushedFcn = @(~, ~) ...
                    obj.chooseFolderFiles(node.Id, false);
            end
            if ~isempty(handles.RecursiveFolder)
                handles.RecursiveFolder.ButtonPushedFcn = @(~, ~) ...
                    obj.chooseFolderFiles(node.Id, true);
            end
            if ~isempty(handles.Remove)
                handles.Remove.ButtonPushedFcn = @(~, ~) ...
                    obj.removeSelectedFiles(node.Id, list);
            end
            if ~isempty(handles.Clear)
                handles.Clear.ButtonPushedFcn = @(~, ~) ...
                    obj.Runtime.applyFileSelection( ...
                    node.Id, strings(1, 0), zeros(1, 0));
            end
        end

        function chooseFiles(obj, target)
            config = obj.node(target).Configuration;
            startPath = obj.dialogStartFolder(target, config.StartPath);
            [names, folder] = uigetfile(dialogFilters(config.Filters), ...
                char(config.ChooseLabel), ...
                startPath, MultiSelect=multiSelectValue(config.SelectionMode));
            if isequal(names, 0)
                return;
            end
            obj.DialogFolders(char(target)) = char(folder);
            paths = string(folder) + filesep + string(names);
            if config.SelectionMode == "single"
                paths = paths(1);
            else
                existing = obj.component(target).UserData.Paths;
                paths = unique([reshape(existing, 1, []), ...
                    reshape(paths, 1, [])], "stable");
            end
            obj.Runtime.applyFileSelection(target, paths, 1:numel(paths));
        end

        function chooseFolderFiles(obj, target, recursive)
            config = obj.node(target).Configuration;
            startPath = obj.dialogStartFolder(target, config.StartPath);
            folder = uigetdir(startPath, "Choose folder");
            if isequal(folder, 0)
                return
            end
            obj.DialogFolders(char(target)) = char(folder);
            paths = filesInFolder(folder, config.Filters, recursive);
            if recursive && ...
                    numel(paths) > config.FolderWarningThreshold
                message = sprintf([ ...
                    "Recursive scan found %d matching file(s) under:\n%s\n\n" ...
                    "Loading a very large folder may take a while. Continue?"], ...
                    numel(paths), folder);
                answer = uiconfirm(obj.Figure, message, ...
                    "Large folder scan", ...
                    Options={"Continue", "Cancel"}, ...
                    DefaultOption="Cancel", CancelOption="Cancel");
                if string(answer) ~= "Continue"
                    return
                end
            end
            existing = obj.component(target).UserData.Paths;
            paths = unique([reshape(existing, 1, []), ...
                reshape(paths, 1, [])], "stable");
            if isfinite(config.MaxFiles)
                paths = paths(1:min(numel(paths), config.MaxFiles));
            end
            obj.Runtime.applyFileSelection(target, paths, 1:numel(paths));
        end

        function removeSelectedFiles(obj, target, list)
            paths = list.UserData.Paths;
            keep = true(1, numel(paths));
            keep(selectedIndices(list)) = false;
            obj.Runtime.applyFileSelection(target, paths(keep), zeros(1, 0));
        end

        function folder = dialogStartFolder(obj, target, configured)
            key = char(target);
            if isKey(obj.DialogFolders, key) && ...
                    isfolder(obj.DialogFolders(key))
                folder = obj.DialogFolders(key);
                return
            end
            folder = char(string(configured));
            if isempty(folder) || ~isfolder(folder)
                folder = userDialogFolder();
            end
        end

        function component = component(obj, id)
            key = char(id);
            if ~isKey(obj.Components, key)
                error("labkit:app:contract:UnknownReference", ...
                    "MATLAB adapter target is undeclared: %s.", id);
            end
            component = obj.Components(key);
        end

        function node = node(obj, id)
            index = find(string({obj.Plan.Nodes.Id}) == string(id), 1);
            node = obj.Plan.Nodes(index);
        end
    end
end

function parent = labeledParent(parent, label, id)
policy = nativeLayoutPolicy();
grid = uigridlayout(parent, [1 2], Padding=[0 0 0 0], ...
    ColumnSpacing=8, ColumnWidth={policy.FormLabelWidth, '1x'});
tag = "";
if strlength(string(id)) > 0
    tag = string(id) + ".label";
    grid.Tag = char(string(id) + ".layout");
end
labelHandle = uilabel(grid, Text=char(string(label)), Tag=char(tag), ...
    HorizontalAlignment="right");
applyTextFit(labelHandle);
parent = grid;
end

function operations = orderedOperations(operations)
if isempty(operations)
    return;
end

priority = zeros(1, numel(operations));
for k = 1:numel(operations)
    switch operations{k}.Kind
        case {"choices", "limits", "filePaths", "tableData"}
            priority(k) = 1;
        case "value"
            priority(k) = 2;
        case {"listSelection", "tableCellSelection"}
            priority(k) = 3;
        otherwise
            priority(k) = 4;
    end
end
[~, order] = sort(priority, "ascend");
operations = operations(order);
end

function tf = isInteractionKind(kind)
tf = any(string(kind) == [ ...
    "anchorPath", "pairedAnchors", "pointSlots", "rectangle", ...
    "regionSelection", "interval", "scaleReference"]);
end

function plan = validatePlan(plan)
if ~isstruct(plan) || ~isscalar(plan) || ~isfield(plan, "Nodes")
    error("labkit:app:contract:InvalidValue", ...
        "MATLAB platform adapter requires a compiled Application plan.");
end
end

function value = onOff(value)
if value
    value = "on";
else
    value = "off";
end
end

function setIfProperty(component, name, value)
if isprop(component, name)
    component.(name) = value;
end
end

function handle = layoutHandle(component)
handle = component;
if ~isprop(component, "UserData") || ~isstruct(component.UserData)
    return
end
if isfield(component.UserData, "LayoutContainer")
    candidate = component.UserData.LayoutContainer;
elseif isfield(component.UserData, "Panel")
    candidate = component.UserData.Panel;
else
    return
end
if ~isempty(candidate) && isvalid(candidate)
    handle = candidate;
end
end

function slider = linkedPannerSlider(component)
slider = [];
if ~isprop(component, "UserData") || ~isstruct(component.UserData) || ...
        ~isfield(component.UserData, "Slider")
    return
end
candidate = component.UserData.Slider;
if ~isempty(candidate) && isvalid(candidate)
    slider = candidate;
end
end

function field = linkedRangeEnd(component)
field = [];
if ~isprop(component, "UserData") || ~isstruct(component.UserData) || ...
        ~isfield(component.UserData, "EndField")
    return
end
candidate = component.UserData.EndField;
if ~isempty(candidate) && isvalid(candidate)
    field = candidate;
end
end

function mode = linkedPlotMode(component)
mode = [];
if isempty(component) || ~isvalid(component) || ...
        ~isstruct(component.UserData) || ...
        ~isfield(component.UserData, "ValueControl")
    return
end
candidate = component.UserData.ValueControl;
if ~isempty(candidate) && isvalid(candidate)
    mode = candidate;
end
end

function sizes = repeatedOrConfigured(configured, count)
sizes = repmat({'1x'}, 1, count);
if ~isempty(configured)
    sizes = configured;
end
end

function value = axisText(configured, fallback, index)
value = "";
if ~isempty(configured)
    value = configured(index);
elseif ~isempty(fallback)
    value = fallback(index);
end
value = char(value);
end

function value = changingValue(event, fallback)
value = fallback;
if isstruct(event) && isfield(event, "Value")
    value = event.Value;
elseif isobject(event) && isprop(event, "Value")
    value = event.Value;
end
end

function applyChoices(component, choices)
if ~isprop(component, "Items")
    return;
end
incoming = reshape(string(choices), 1, []);
if isprop(component, "Value") && ~isempty(incoming)
    current = string(component.Value);
    if isscalar(current) && ~any(incoming == current)
        component.Items = unique([current, incoming], "stable");
        component.Value = incoming(1);
    end
end
component.Items = choices;
end

function [limits, value] = sliderInitialValue(config)
limits = config.Limits;
if isempty(limits)
    limits = [0 1];
end
value = config.Value;
if isempty(value)
    value = limits(1);
end
end

function [limits, value] = rangeSliderInitialValue(config)
limits = config.Limits;
if isempty(limits)
    limits = [0 1];
end
value = config.Value;
if isempty(value)
    value = limits;
end
end

function value = neutralValue(value, kind, choices)
if ~isempty(value)
    return;
end
switch kind
    case "numeric"
        value = 0;
    case "choice"
        if isempty(choices)
            value = "";
        else
            value = choices(1);
        end
    case "logical"
        value = false;
    otherwise
        value = "";
end
end

function key = axisKey(target, axisId)
key = string(target) + "." + string(axisId);
end

function viewport = captureViewport(axes)
viewport = repmat(struct("XLim", [], "YLim", [], ...
    "XLimMode", "", "YLimMode", ""), 1, numel(axes));
for k = 1:numel(axes)
    viewport(k) = struct("XLim", axes(k).XLim, "YLim", axes(k).YLim, ...
        "XLimMode", axes(k).XLimMode, "YLimMode", axes(k).YLimMode);
end
end

function restoreViewport(axes, viewport)
for k = 1:numel(axes)
    if viewport(k).XLimMode == "manual"
        axes(k).XLim = viewport(k).XLim;
        axes(k).XLimMode = "manual";
    end
    if viewport(k).YLimMode == "manual"
        axes(k).YLim = viewport(k).YLim;
        axes(k).YLimMode = "manual";
    end
end
end

function indices = selectedIndices(list)
if isstruct(list.UserData) && isfield(list.UserData, "Paths") && ...
        isempty(list.UserData.Paths)
    indices = zeros(1, 0);
    return
end
items = string(list.Items);
values = string(list.Value);
indices = find(ismember(items, values));
indices = reshape(indices, 1, []);
end

function cells = tableSelectionCells(event)
if isstruct(event)
    if isfield(event, "Selection")
        cells = event.Selection;
    elseif isfield(event, "Indices")
        cells = event.Indices;
    else
        cells = zeros(0, 2);
    end
elseif isprop(event, "Selection")
    cells = event.Selection;
elseif isprop(event, "Indices")
    cells = event.Indices;
else
    cells = zeros(0, 2);
end
if isempty(cells)
    cells = zeros(0, 2);
elseif ~isnumeric(cells)
    rows = [cells.Row];
    columns = [cells.Column];
    cells = [rows(:), columns(:)];
end
cells = double(cells);
end

function value = editedValue(event)
if isstruct(event)
    if isfield(event, "NewData")
        value = event.NewData;
    else
        value = event.EditData;
    end
elseif isprop(event, "NewData")
    value = event.NewData;
else
    value = event.EditData;
end
end

function value = tableLabel(labels, index)
value = "";
if index < 1 || index > numel(labels)
    return;
end
candidate = string(labels(index));
if isscalar(candidate)
    value = candidate;
end
end

function value = nativeTableData(value)
if ~iscell(value)
    return;
end
for k = 1:numel(value)
    item = value{k};
    if isempty(item)
        value{k} = '';
    elseif ischar(item)
        continue;
    elseif (isnumeric(item) || islogical(item)) && isscalar(item)
        continue;
    elseif isscalar(item)
        text = string(item);
        if ismissing(text)
            value{k} = '';
        else
            value{k} = char(text);
        end
    else
        error("labkit:app:contract:InvalidValue", ...
            "Table cells must contain scalar display values.");
    end
end
end

function value = multiSelectValue(selectionMode)
if selectionMode == "multiple"
    value = "on";
else
    value = "off";
end
end

function value = dialogFilters(filters)
filters = string(filters(:));
if isempty(filters)
    value = "*.*";
elseif mod(numel(filters), 2) == 0
    value = reshape(cellstr(filters), 2, []).';
else
    value = cellstr(filters);
end
end

function paths = filesInFolder(folder, filters, recursive)
filters = string(filters(:));
if mod(numel(filters), 2) == 0
    filters = filters(1:2:end);
end
patterns = strings(0, 1);
for filter = filters.'
    patterns = [patterns; split(filter, ";")];
end
patterns = unique(strtrim(patterns(strlength(strtrim(patterns)) > 0)), ...
    "stable");
parts = cell(numel(patterns), 1);
for k = 1:numel(patterns)
    if recursive
        entries = dir(fullfile(folder, "**", patterns(k)));
    else
        entries = dir(fullfile(folder, patterns(k)));
    end
    entries = entries(~[entries.isdir]);
    values = strings(numel(entries), 1);
    for index = 1:numel(entries)
        values(index) = string(fullfile( ...
            entries(index).folder, entries(index).name));
    end
    parts{k} = values;
end
if isempty(parts)
    paths = strings(0, 1);
else
    paths = sort(unique(vertcat(parts{:}), "stable"));
end
end

function path = safeStartPath(value)
path = char(string(value));
if isempty(path) || ~isfolder(path)
    path = pwd;
end
end

function result = dialogPath(name, folder)
if isequal(name, 0)
    result = labkit.app.dialog.Choice("", Cancelled=true);
else
    result = labkit.app.dialog.Choice(string(folder) + filesep + string(name));
end
end

function result = folderDialogPath(folder)
if isequal(folder, 0)
    result = labkit.app.dialog.Choice("", Cancelled=true);
else
    result = labkit.app.dialog.Choice(string(folder));
end
end

function position = closePromptPosition(fig)
width = 430;
height = 118;
figurePosition = fig.Position;
promptWidth = min(width, max(160, figurePosition(3) - 24));
x = max(12, (figurePosition(3) - promptWidth) / 2);
y = max(12, figurePosition(4) - height - 44);
position = [x y promptWidth height];
end

function labels = formatFileLabels(paths)
paths = string(paths(:));
names = strings(size(paths));
parents = strings(size(paths));
for k = 1:numel(paths)
    [folder, base, extension] = fileparts(char(paths(k)));
    names(k) = string(base) + string(extension);
    [~, parents(k)] = fileparts(folder);
end
width = max(2, strlength(string(max(1, numel(paths)))));
labels = strings(size(paths));
for k = 1:numel(paths)
    suffix = "";
    if nnz(names == names(k)) > 1 && strlength(parents(k)) > 0
        suffix = " (" + parents(k) + ")";
    end
    labels(k) = compose("%0" + width + "d %s%s", ...
        k, names(k), suffix);
end
labels = reshape(labels, 1, []);
end

function height = estimatedControlHeight(text, charsPerLine, maxLines, minimum)
text = string(text);
if isempty(text)
    height = minimum;
    return
end
lines = splitlines(text(:));
lineCount = max(1, ceil(double(max(strlength(lines))) / charsPerLine));
lineCount = min(maxLines, lineCount);
height = max(minimum, 20 * lineCount + 6);
end

function folder = userDialogFolder()
folder = string(getenv("USERPROFILE"));
if strlength(folder) == 0 || ~isfolder(folder)
    folder = string(getenv("HOME"));
end
if strlength(folder) == 0 || ~isfolder(folder)
    folder = string(tempdir);
end
folder = char(folder);
end

function mode = startupGuiMode()
mode = lower(strip(string(getenv("LABKIT_GUI_TEST_MODE"))));
if strlength(mode) == 0
    mode = "visible";
end
end

function filepath = plotFilepath(basePath, axesHandle, index)
[folder, name, extension] = fileparts(basePath);
label = join(string(axesHandle.Title.String), " ");
label = string(matlab.lang.makeValidName(char(label)));
if strlength(label) == 0
    label = "plot" + string(index);
end
filepath = string(fullfile(folder, sprintf( ...
    "%s_%02d_%s%s", name, index, label, extension)));
end
