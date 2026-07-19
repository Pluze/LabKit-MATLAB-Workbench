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
        InteractionBridge
        InteractionDeclarations (1, :) cell = {}
    end

    methods (Access = ?labkit.app.internal.RuntimeKernel)
        function obj = MatlabPlatformAdapter(plan)
            obj.Plan = validatePlan(plan);
            obj.Components = containers.Map("KeyType", "char", ...
                "ValueType", "any");
            obj.Axes = containers.Map("KeyType", "char", ...
                "ValueType", "any");
            obj.Layouts = containers.Map("KeyType", "char", ...
                "ValueType", "any");
            obj.Figure = uifigure(Visible="off", ...
                Name="LabKit application", Position=[100 100 1180 760]);
            obj.buildTree();
        end

        function attachRuntime(obj, runtime)
            if ~isa(runtime, "labkit.app.internal.RuntimeKernel")
                error("labkit:app:runtime:InvariantFailure", ...
                    "MATLAB platform adapter requires its RuntimeKernel.");
            end
            obj.Runtime = runtime;
            obj.Figure.CloseRequestFcn = @(~, ~) runtime.close();
            obj.installCallbacks();
            obj.InteractionDeclarations = obj.collectInteractionDeclarations();
            if ~isempty(obj.InteractionDeclarations)
                obj.InteractionBridge = ...
                    labkit.ui.runtime.appSdkInteractionBridge( ...
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
            if ~isempty(obj.InteractionBridge)
                obj.InteractionBridge.delete();
                obj.InteractionBridge = [];
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
                obj.Figure.Name = char(string(title));
                obj.Figure.Visible = "on";
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
        function buildTree(obj)
            nodes = obj.Plan.Nodes;
            for k = 1:numel(nodes)
                node = nodes(k);
                parent = obj.parentFor(node);
                component = obj.createComponent(node, parent);
                if ~isempty(component)
                    component.Tag = char(node.Id);
                end
                obj.Components(char(node.Id)) = component;
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
                    component = uipanel(parent, Title=title);
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
                case "field"
                    component = obj.createField(parent, config, node.Id);
                case {"rangeField", "slider"}
                    [limits, value] = sliderInitialValue(config);
                    controlParent = labeledParent( ...
                        parent, config.Label, node.Id);
                    component = uislider(controlParent, Limits=limits, ...
                        Value=value, Enable=onOff(config.Enabled));
                case "fileList"
                    component = obj.createFilePanel(node, parent);
                case "dataTable"
                    component = uitable(parent, ...
                        ColumnName=cellstr(config.Columns), ...
                        RowName=cellstr(config.RowNames), ...
                        ColumnEditable=config.ColumnEditable);
                case {"logPanel", "statusPanel"}
                    component = uitextarea(parent, Editable="off");
                case "plotArea"
                    component = uipanel(parent, BorderType="none");
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
                otherwise
                    component = uieditfield(parent, "text", ...
                        Value=string(value), Enable=onOff(config.Enabled));
            end
        end

        function createAxes(obj, node, parent)
            layout = uigridlayout(parent, [max(1, numel(node.AxisIds)) 1], ...
                Padding=[2 2 2 2], RowSpacing=2, ColumnSpacing=2);
            layout.RowHeight = repmat({'1x'}, 1, max(1, numel(node.AxisIds)));
            for k = 1:numel(node.AxisIds)
                axisId = node.AxisIds(k);
                key = axisKey(node.Id, axisId);
                ax = uiaxes(layout, Tag=char(key));
                ax.Layout.Row = k;
                obj.Axes(char(key)) = ax;
            end
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
            if ~isempty(obj.InteractionBridge)
                obj.InteractionBridge.reconcile( ...
                    obj.InteractionDeclarations, interactionOperations);
            end
        end

        function apply(obj, operation)
            component = obj.component(operation.Target);
            switch operation.Kind
                case "value"
                    setIfProperty(component, "Value", operation.Value);
                case "choices"
                    setIfProperty(component, "Items", operation.Value);
                case "limits"
                    setIfProperty(component, "Limits", operation.Value);
                case "enabled"
                    setIfProperty(component, "Enable", onOff(operation.Value));
                case "visible"
                    setIfProperty(component, "Visible", onOff(operation.Value));
                case "text"
                    obj.applyText(component, operation.Value);
                case "filePaths"
                    setIfProperty(component, "Items", operation.Value);
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
                    targets(end + 1) = struct( ...
                        "id", key, "axes", obj.Axes(char(key)));
                end
            end
        end

        function installContentGrid(obj, node, component)
            if isempty(node.ChildIds)
                return;
            end
            horizontal = node.Kind == "group" && ...
                isfield(node.Configuration, "Layout") && ...
                node.Configuration.Layout == "horizontal";
            if horizontal
                grid = uigridlayout(component, [1 numel(node.ChildIds)], ...
                    Padding=[6 6 6 6], RowSpacing=5, ColumnSpacing=5);
                grid.ColumnWidth = repmat({'1x'}, 1, numel(node.ChildIds));
            else
                grid = uigridlayout(component, [numel(node.ChildIds) 1], ...
                    Padding=[6 6 6 6], RowSpacing=5, ColumnSpacing=5);
                grid.RowHeight = obj.childRowHeights(node.ChildIds);
            end
            obj.Layouts(char(node.Id)) = grid;
        end

        function installWorkbenchLayout(obj, node, component)
            nodes = obj.nodes(node.ChildIds);
            hasWorkspace = any(string({nodes.Kind}) == "workspace");
            columns = 1 + hasWorkspace;
            grid = uigridlayout(component, [1 columns], ...
                Padding=[8 8 8 8], RowSpacing=0, ColumnSpacing=8);
            if hasWorkspace
                grid.ColumnWidth = {380, '1x'};
            else
                grid.ColumnWidth = {'1x'};
            end
            controls = nodes(string({nodes.Kind}) ~= "workspace");
            if ~isempty(controls) && ...
                    all(string({controls.Kind}) == "tab")
                controlParent = uitabgroup(grid);
                controlContainer = controlParent;
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
                workspace = uipanel(grid, BorderType="none");
                workspace.Layout.Row = 1;
                workspace.Layout.Column = 2;
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
            flexible = ["fileList", "dataTable", "logPanel", ...
                "plotArea", "section", "tab", "workspace"];
            for k = 1:numel(nodes)
                if any(nodes(k).Kind == flexible)
                    heights{k} = '1x';
                elseif nodes(k).Kind == "statusPanel"
                    heights{k} = 54;
                end
            end
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
            grid = uigridlayout(panel, [2 1], Padding=[5 5 5 5], ...
                RowHeight={'1x', 'fit'}, RowSpacing=4);
            list = uilistbox(grid, Items=strings(1, 0), ...
                Multiselect=config.SelectionMode == "multiple");
            list.Layout.Row = 1;
            buttons = uigridlayout(grid, [1 3], Padding=[0 0 0 0], ...
                ColumnWidth={'1x', '1x', '1x'}, ColumnSpacing=4);
            buttons.Layout.Row = 2;
            choose = uibutton(buttons, Text=config.ChooseLabel, Tag= ...
                char(node.Id + ".choose"));
            remove = uibutton(buttons, Text=config.RemoveLabel, Tag= ...
                char(node.Id + ".remove"));
            clear = uibutton(buttons, Text=config.ClearLabel, Tag= ...
                char(node.Id + ".clear"));
            list.UserData = struct("Panel", panel, "Choose", choose, ...
                "Remove", remove, "Clear", clear, "Target", node.Id);
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
                    case {"field", "rangeField", "slider"}
                        if isprop(component, "ValueChangedFcn")
                            component.ValueChangedFcn = @(src, ~) ...
                                obj.Runtime.applyControlValue(node.Id, src.Value);
                        end
                    case "fileList"
                        obj.installFilePanelCallbacks(node, component);
                    case "dataTable"
                        obj.installTableCallbacks(node, component);
                end
            end
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
            handles.Remove.ButtonPushedFcn = @(~, ~) obj.removeSelectedFiles(node.Id, list);
            handles.Clear.ButtonPushedFcn = @(~, ~) obj.Runtime.applyFileSelection( ...
                node.Id, strings(1, 0), zeros(1, 0));
        end

        function chooseFiles(obj, target)
            config = obj.node(target).Configuration;
            startPath = char(config.StartPath);
            if isempty(startPath) || ~isfolder(startPath)
                startPath = pwd;
            end
            [names, folder] = uigetfile(dialogFilters(config.Filters), ...
                char(config.ChooseLabel), ...
                startPath, MultiSelect=multiSelectValue(config.SelectionMode));
            if isequal(names, 0)
                return;
            end
            paths = string(folder) + filesep + string(names);
            existing = string(obj.component(target).Items);
            paths = unique([reshape(existing, 1, []), reshape(paths, 1, [])], ...
                "stable");
            obj.Runtime.applyFileSelection(target, paths, 1:numel(paths));
        end

        function removeSelectedFiles(obj, target, list)
            items = string(list.Items);
            keep = true(1, numel(items));
            keep(selectedIndices(list)) = false;
            obj.Runtime.applyFileSelection(target, items(keep), zeros(1, 0));
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
grid = uigridlayout(parent, [1 2], Padding=[0 0 0 0], ...
    ColumnSpacing=6, ColumnWidth={'fit', '1x'});
tag = "";
if strlength(string(id)) > 0
    tag = string(id) + ".label";
end
uilabel(grid, Text=char(string(label)), Tag=char(tag));
parent = grid;
end

function operations = orderedOperations(operations)
if isempty(operations)
    return;
end

priority = zeros(1, numel(operations));
for k = 1:numel(operations)
    switch operations{k}.Kind
        case {"choices", "limits", "filePaths"}
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
