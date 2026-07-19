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
        Runtime
    end

    methods (Access = ?labkit.ui.RuntimeKernel)
        function obj = MatlabPlatformAdapter(plan)
            obj.Plan = validatePlan(plan);
            obj.Components = containers.Map("KeyType", "char", ...
                "ValueType", "any");
            obj.Axes = containers.Map("KeyType", "char", ...
                "ValueType", "any");
            obj.Layouts = containers.Map("KeyType", "char", ...
                "ValueType", "any");
            obj.Figure = uifigure(Visible="off", ...
                Name="LabKit application");
            obj.buildTree();
        end

        function attachRuntime(obj, runtime)
            if ~isa(runtime, "labkit.ui.RuntimeKernel")
                error("labkit:ui:runtime:InvariantFailure", ...
                    "MATLAB platform adapter requires its RuntimeKernel.");
            end
            obj.Runtime = runtime;
            obj.Figure.CloseRequestFcn = @(~, ~) runtime.close();
            obj.installCallbacks();
        end

        function reconcile(obj, previous, view)
            if ~isa(view, "labkit.ui.Presentation")
                error("labkit:ui:contract:InvalidValue", ...
                    "MATLAB platform adapter requires a Presentation value.");
            end
            try
                obj.applyView(view);
            catch cause
                if isa(previous, "labkit.ui.Presentation")
                    try
                        obj.applyView(previous);
                    catch rollbackCause
                        failure = MException( ...
                            "labkit:ui:runtime:InvariantFailure", ...
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
                        Position=[1 1 900 650]);
                    obj.installContentGrid(node, component);
                case {"group", "section", "tab"}
                    title = "";
                    if isfield(config, "Title")
                        title = config.Title;
                    end
                    component = uipanel(parent, Title=title);
                    obj.installContentGrid(node, component);
                case "action"
                    component = uibutton(parent, Text=config.Label, ...
                        Enable=onOff(config.Enabled));
                case "field"
                    component = obj.createField(parent, config, node.Id);
                case {"rangeField", "panner"}
                    [limits, value] = sliderInitialValue(config);
                    controlParent = labeledParent( ...
                        parent, config.Label, node.Id);
                    component = uislider(controlParent, Limits=limits, ...
                        Value=value, Enable=onOff(config.Enabled));
                case "filePanel"
                    component = obj.createFilePanel(node, parent);
                case "resultTable"
                    component = uitable(parent);
                case {"logPanel", "statusPanel"}
                    component = uitextarea(parent, Editable="off");
                case "previewArea"
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
                    error("labkit:ui:runtime:InvariantFailure", ...
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
            for k = 1:numel(operations)
                obj.apply(operations{k});
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
                case "files"
                    setIfProperty(component, "Items", operation.Value);
                case "selection"
                    obj.applySelection(component, operation.Value);
                case "table"
                    setIfProperty(component, "Data", operation.Value);
                case "plot"
                    obj.applyPlot(operation);
                case "workspacePage"
                    setIfProperty(component, "Enable", onOff(operation.Value.Enabled));
                    component.UserData = struct("Status", operation.Value.Status);
            end
        end

        function applySelection(~, component, selection)
            if ~isprop(component, "Items") || ~isprop(component, "Value")
                return;
            end
            items = string(component.Items);
            indices = selection.Indices;
            indices = indices(indices >= 1 & indices <= numel(items));
            component.Value = items(indices);
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

        function applyPlot(obj, operation)
            node = obj.node(operation.Target);
            renderer = obj.Plan.Renderers.(operation.Reference);
            axes = gobjects(1, numel(node.AxisIds));
            for k = 1:numel(node.AxisIds)
                axes(k) = obj.Axes(char(axisKey(node.Id, node.AxisIds(k))));
            end
            viewport = captureViewport(axes);
            renderer(axes, operation.Value);
            restoreViewport(axes, viewport);
        end

        function installContentGrid(obj, node, component)
            if isempty(node.ChildIds)
                return;
            end
            grid = uigridlayout(component, [numel(node.ChildIds) 1], ...
                Padding=[6 6 6 6], RowSpacing=5, ColumnSpacing=5);
            grid.RowHeight = repmat({'1x'}, 1, numel(node.ChildIds));
            obj.Layouts(char(node.Id)) = grid;
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
                Title=char(node.Id));
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
                    case "action"
                        component.ButtonPushedFcn = @(~, ~) ...
                            obj.Runtime.invokeAction(node.Id);
                    case {"field", "rangeField", "panner"}
                        if isprop(component, "ValueChangedFcn")
                            component.ValueChangedFcn = @(src, ~) ...
                                obj.Runtime.applyControlValue(node.Id, src.Value);
                        end
                    case "filePanel"
                        obj.installFilePanelCallbacks(node, component);
                end
            end
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
                error("labkit:ui:contract:UnknownReference", ...
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
        case {"choices", "limits", "files"}
            priority(k) = 1;
        case "value"
            priority(k) = 2;
        case "selection"
            priority(k) = 3;
        otherwise
            priority(k) = 4;
    end
end
[~, order] = sort(priority, "ascend");
operations = operations(order);
end

function plan = validatePlan(plan)
if ~isstruct(plan) || ~isscalar(plan) || ~isfield(plan, "Nodes") || ...
        ~isfield(plan, "Renderers")
    error("labkit:ui:contract:InvalidValue", ...
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
    result = labkit.ui.DialogResult("", Cancelled=true);
else
    result = labkit.ui.DialogResult(string(folder) + filesep + string(name));
end
end

function result = folderDialogPath(folder)
if isequal(folder, 0)
    result = labkit.ui.DialogResult("", Cancelled=true);
else
    result = labkit.ui.DialogResult(string(folder));
end
end
