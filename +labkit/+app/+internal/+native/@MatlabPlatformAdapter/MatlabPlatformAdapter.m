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
        BusyLifecycle
        PriorPointer (1, 1) string = "arrow"
        ClosePrompt
        DialogFolders
        ReadonlyHeights
        Starting (1, 1) logical = false
        StartupStarted
        StartupPanel
        StartupLabel
        LogViewer
    end

    methods (Access = { ...
            ?labkit.app.internal.runtime.RuntimeKernel, ...
            ?labkit.app.internal.runtime.RuntimeContractBoundary})
        function obj = MatlabPlatformAdapter(plan, title)
            obj.Plan = labkit.app.internal.native.NativeAdapterValues.validatePlan(plan);
            if nargin < 2
                title = "LabKit application";
            end
            obj.Components = containers.Map("KeyType", "char", ...
                "ValueType", "any");
            obj.Axes = containers.Map("KeyType", "char", ...
                "ValueType", "any");
            obj.Layouts = containers.Map("KeyType", "char", ...
                "ValueType", "any");
            obj.DialogFolders = containers.Map("KeyType", "char", ...
                "ValueType", "char");
            obj.ReadonlyHeights = containers.Map("KeyType", "char", ...
                "ValueType", "double");
            policy = labkit.app.internal.native.NativeAdapterValues.layoutPolicy();
            obj.Figure = uifigure(Visible="off", ...
                Name=char(string(title)), ...
                Tag="labkitApp", ...
                Position=policy.InitialFigurePosition);
            obj.BusyLifecycle = ...
                labkit.app.internal.native.BusyLifecycle( ...
                    obj.Figure, title, ...
                    @(view, restoreValues) ...
                    obj.restoreBusyView(view, restoreValues), ...
                    @() obj.busyInputHandles());
            obj.Starting = true;
            obj.StartupStarted = tic;
            obj.PriorPointer = string(obj.Figure.Pointer);
            obj.Figure.Pointer = "watch";
            setappdata(obj.Figure, "labkitAppBusy", true);
            obj.buildTree();
            setappdata(obj.Figure, "labkitAppLayoutChanged", ...
                @() obj.refreshReadonlySurfaces());
            obj.createStartupSurface();
            obj.startupUpdate("Preparing runtime...");
        end

        function attachRuntime(obj, runtime)
            if ~isa(runtime, "labkit.app.internal.runtime.RuntimeKernel")
                error("labkit:app:runtime:InvariantFailure", ...
                    "MATLAB platform adapter requires its RuntimeKernel.");
            end
            obj.Runtime = runtime;
            obj.Figure.CloseRequestFcn = @(~, ~) obj.requestClose();
            obj.Figure.WindowKeyPressFcn = @(~, event) obj.onKeyPress(event);
            obj.installCallbacks();
            obj.installUtilityMenus();
            obj.InteractionDeclarations = obj.collectInteractionDeclarations();
            targets = obj.interactionTargetAxes();
            if ~isempty(targets)
                obj.InteractionController = labkit.app.internal.native.NativeAdapterValues.interactionController( ...
                    obj.Figure, targets, ...
                    @(id, signal, value) ...
                    obj.runUserInput(@() ...
                    runtime.applyInteraction(id, signal, value)));
            end
        end

        function reconcile(obj, previous, view)
            if ~isa(view, "labkit.app.view.Snapshot")
                error("labkit:app:contract:InvalidValue", ...
                    "MATLAB platform adapter requires a Presentation value.");
            end
            try
                obj.applyView(view, previous);
            catch cause
                if isa(previous, "labkit.app.view.Snapshot")
                    try
                        obj.applyView(previous, view);
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
            if ~isempty(obj.LogViewer) && isvalid(obj.LogViewer)
                obj.LogViewer.close();
                obj.LogViewer = [];
            end
            if ~isempty(obj.InteractionController)
                obj.InteractionController.delete();
                obj.InteractionController = [];
            end
            obj.BusyLifecycle.close();
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
                mode = labkit.app.internal.native.NativeAdapterValues.startupGuiMode();
                if mode == "hidden"
                    return
                end
                obj.Figure.Visible = "on";
                drawnow limitrate nocallbacks
                obj.refreshReadonlySurfaces();
                if mode == "minimized" && isprop(obj.Figure, "WindowState")
                    obj.Figure.WindowState = "minimized";
                end
            end
        end

        function setWindowTitle(obj, title)
            obj.BusyLifecycle.setWindowTitle(title);
        end

        function beginBusy(obj, message)
            if obj.Starting
                return
            end
            obj.BusyLifecycle.begin(message);
        end

        function updateBusy(obj, message)
            obj.BusyLifecycle.update(message);
        end

        function endBusy(obj, view)
            if obj.Starting
                return
            end
            obj.BusyLifecycle.finish(view);
        end

        function startupUpdate(obj, message)
            if ~obj.Starting || isempty(obj.Figure) || ~isvalid(obj.Figure)
                return
            end
            if ~isempty(obj.StartupLabel) && isvalid(obj.StartupLabel)
                obj.StartupLabel.Text = char(string(message));
            end
            if toc(obj.StartupStarted) >= 0.25 && ...
                    ~any(labkit.app.internal.native.NativeAdapterValues.startupGuiMode() == ["hidden", "minimized"])
                obj.StartupPanel.Visible = "on";
                obj.Figure.Visible = "on";
                drawnow limitrate nocallbacks
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
            if labkit.app.internal.native.NativeAdapterValues.startupGuiMode() == "minimized" && ...
                    isprop(obj.Figure, "WindowState")
                obj.Figure.Visible = "on";
                obj.Figure.WindowState = "minimized";
            end
        end

        function failStartup(obj, cause)
            obj.Starting = false;
            obj.BusyLifecycle.close();
            if isempty(obj.Figure) || ~isvalid(obj.Figure)
                return
            end
            message = "Startup failed: " + labkit.app.internal.native.NativeAdapterValues.deepestCauseMessage(cause);
            if ~isempty(obj.StartupLabel) && isvalid(obj.StartupLabel)
                obj.StartupLabel.Text = char(message);
            end
            if ~isempty(obj.StartupPanel) && isvalid(obj.StartupPanel)
                obj.StartupPanel.Visible = "on";
            end
            obj.Figure.Pointer = char(obj.PriorPointer);
            if isappdata(obj.Figure, "labkitAppBusy")
                rmappdata(obj.Figure, "labkitAppBusy");
            end
            setappdata(obj.Figure, "labkitAppStartupFailure", struct( ...
                "failed", true, ...
                "message", message, ...
                "identifier", string(cause.identifier)));
            obj.Figure.CloseRequestFcn = @(~, ~) obj.close();
            drawnow limitrate nocallbacks
        end

        function alert(obj, message, title, icon)
            if nargin < 4
                icon = "error";
            end
            if string(obj.Figure.Visible) == "off" && ...
                    labkit.app.internal.native.NativeAdapterValues.startupGuiMode() == ...
                    "hidden"
                setappdata(obj.Figure, "labkitAppLastAlert", struct( ...
                    "message", string(message), "title", string(title), ...
                    "icon", string(icon)));
                return;
            end
            uialert(obj.Figure, char(string(message)), char(string(title)), ...
                Icon=char(string(icon)));
        end

        function result = chooseOption(obj, prompt, choices, title, ...
                defaultChoice, cancelChoice)
            answer = uiconfirm(obj.Figure, char(string(prompt)), ...
                char(string(title)), ...
                Options=cellstr(string(choices)), ...
                DefaultOption=char(string(defaultChoice)), ...
                CancelOption=char(string(cancelChoice)));
            result = labkit.app.dialog.Choice(string(answer));
        end

        function result = chooseInputFile(~, filters, startPath)
            filters = labkit.app.internal.native.NativeAdapterValues.dialogFilters(filters);
            [name, folder] = uigetfile(filters, "Choose input file", ...
                labkit.app.internal.native.NativeAdapterValues.dialogStartFolder( ...
                "input", startPath));
            if ~isequal(name, 0)
                labkit.app.internal.native.NativeAdapterValues.rememberDialogFolder( ...
                    "input", folder);
            end
            result = labkit.app.internal.native.NativeAdapterValues.dialogPath(name, folder);
        end

        function result = chooseInputFolder(~, startPath)
            folder = uigetdir( ...
                labkit.app.internal.native.NativeAdapterValues.dialogStartFolder( ...
                "input", startPath), "Choose input folder");
            if ~isequal(folder, 0)
                labkit.app.internal.native.NativeAdapterValues.rememberDialogFolder( ...
                    "input", folder);
            end
            result = labkit.app.internal.native.NativeAdapterValues.folderDialogPath(folder);
        end

        function result = chooseOutputFile(~, filters, startPath)
            filters = labkit.app.internal.native.NativeAdapterValues.dialogFilters(filters);
            [name, folder] = uiputfile(filters, "Choose output file", ...
                labkit.app.internal.native.NativeAdapterValues.dialogStartFolder( ...
                "output", startPath));
            if ~isequal(name, 0)
                labkit.app.internal.native.NativeAdapterValues.rememberDialogFolder( ...
                    "output", folder);
            end
            result = labkit.app.internal.native.NativeAdapterValues.dialogPath(name, folder);
        end

        function result = chooseOutputFolder(~, startPath)
            folder = uigetdir( ...
                labkit.app.internal.native.NativeAdapterValues.dialogStartFolder( ...
                "output", startPath), "Choose output folder");
            if ~isequal(folder, 0)
                labkit.app.internal.native.NativeAdapterValues.rememberDialogFolder( ...
                    "output", folder);
            end
            result = labkit.app.internal.native.NativeAdapterValues.folderDialogPath(folder);
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

        buildTree(obj)

        parent = parentFor(obj, node)

        component = createComponent(obj, node, parent)

        component = createField(~, parent, config, id)

        spinner = createPanner(~, node, parent)

        first = createRangeField(~, node, parent)

        createAxes(obj, node, parent)

        table = createDataTable(obj, node, parent)

        applyView(obj, view, previous)

        apply(obj, operation)

        applyListSelection(~, component, selection)

        applyFilePaths(~, component, paths)

        applyFileItemStatuses(~, component, statuses)

        applyTableCellSelection(~, component, selection)

        applyTableData(~, component, model)

        applyText(obj, component, value)

        applyValue(obj, component, value)

        updateReadonlyHeight(obj, component, value)

        refreshReadonlySurfaces(obj)

        applyLimits(~, component, limits)

        applyEnabled(~, component, enabled)

        renderPlot(obj, operation)

        declarations = collectInteractionDeclarations(obj)

        targets = interactionTargetAxes(obj)

        installContentGrid(obj, node, component)

        placeInParent(obj, node, component)

        owner = owningNode(obj, id)

        installWorkbenchLayout(obj, node, component)

        heights = childRowHeights(obj, ids)

        height = preferredRowHeight(obj, node)

        tf = isGrowableTabChild(obj, node)

        tf = sectionDrawsOwnTitle(obj, node)

        tf = usesAdaptiveActionGrid(obj, node)

        [rows, columns] = actionGridSize(obj, node)

        selected = nodes(obj, ids)

        parent = contentParent(obj, id)

        list = createFilePanel(obj, node, parent)

        textArea = createTextPanel(obj, node, parent, config, isLog)

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

        installUtilityMenus(obj)

        function runUtility(obj, callback, title)
            if nargin < 3
                title = "LabKit Utility";
            end
            if obj.Starting || ~obj.BusyLifecycle.acceptInput()
                return
            end
            try
                callback();
            catch cause
                obj.alert( ...
                    labkit.app.internal.native.NativeAdapterValues.deepestCauseMessage( ...
                    cause), title);
            end
        end

        function runUserInput(obj, callback)
            if obj.Starting || ~obj.BusyLifecycle.acceptInput()
                return
            end
            callback();
        end

        restoreBusyView(obj, view, restoreValues)

        function openSessionLog(obj)
            if isempty(obj.LogViewer) || ~isvalid(obj.LogViewer) || ...
                    ~obj.LogViewer.isOpen()
                obj.LogViewer = ...
                    labkit.app.internal.diagnostics.SessionLogViewer(obj.Runtime);
            else
                obj.LogViewer.refresh();
            end
            obj.LogViewer.show();
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
                labkit.app.internal.native.enableAxesPopout(handles(k));
                menu = findall(handles(k).ContextMenu, ...
                    Type="uimenu", Tag="labkitAxesPopoutMenu");
                if ~isempty(menu)
                    menu(1).MenuSelectedFcn(menu(1), []);
                end
            end
        end

        function copyAllPlots(obj)
            handles = obj.allAxes();
            if isscalar(handles)
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
                    output = labkit.app.internal.native.NativeAdapterValues.plotFilepath(filepath, handles(k), k);
                end
                exportgraphics(handles(k), output, ContentType="image");
            end
        end

        function saveScreenshot(obj)
            filename = obj.Runtime.automaticArtifactFilename( ...
                "screenshot", ".png");
            try
                destination = obj.Runtime.automaticArtifactDestination( ...
                    "screenshots", "screenshot", ".png");
                exportapp(obj.Figure, destination);
            catch
                choice = obj.chooseOutputFile( ...
                    {"*.png", "PNG image (*.png)"; ...
                     "*.pdf", "PDF file (*.pdf)"}, filename);
                if choice.Cancelled
                    return;
                end
                destination = string(choice.Value);
                exportapp(obj.Figure, destination);
            end
            obj.alert("Screenshot written to:" + newline + destination, ...
                "Screenshot Saved", "info");
        end

        function copyScreenshot(obj)
            copygraphics(obj.Figure, ContentType="image");
        end

        function onKeyPress(obj, event)
            modifiers = strings(1, 0);
            if isprop(event, "Modifier")
                modifiers = string(event.Modifier);
            end
            if labkit.app.internal.native.NativeAdapterValues. ...
                    handlesCloseShortcut(event.Key, modifiers)
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
            if obj.BusyLifecycle.Active
                message = "LabKit is still working. Close anyway?";
            end
            obj.ClosePrompt = uipanel(obj.Figure, ...
                Title="Close LabKit app?", ...
                Tag="labkitAppClosePrompt", ...
                Position=labkit.app.internal.native.NativeAdapterValues.closePromptPosition(obj.Figure));
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
            drawnow nocallbacks
        end

        function clearClosePrompt(obj)
            if ~isempty(obj.ClosePrompt) && isvalid(obj.ClosePrompt)
                delete(obj.ClosePrompt);
            end
            obj.ClosePrompt = [];
        end

        installCallbacks(obj)

        function pannerChanged(obj, target, value)
            component = obj.component(target);
            value = min(component.Limits(2), ...
                max(component.Limits(1), double(value)));
            component.Value = value;
            linked = labkit.app.internal.native.NativeAdapterValues.linkedPannerSlider(component);
            if ~isempty(linked)
                linked.Value = value;
            end
            obj.Runtime.applyControlValue(target, value);
        end

        function handles = busyInputHandles(obj)
            % Return mutable leaf inputs without disabling visual containers.
            nodes = obj.Plan.Nodes;
            handles = cell(1, max(1, 6 * numel(nodes)));
            count = 0;
            for index = 1:numel(nodes)
                node = nodes(index);
                if ~isKey(obj.Components, char(node.Id))
                    continue
                end
                component = obj.Components(char(node.Id));
                switch node.Kind
                    case {"button", "field", "dataTable"}
                        count = count + 1;
                        handles{count} = component;
                    case "rangeField"
                        count = count + 1;
                        handles{count} = component;
                        linked = labkit.app.internal.native.NativeAdapterValues. ...
                            linkedRangeEnd(component);
                        if ~isempty(linked)
                            count = count + 1;
                            handles{count} = linked;
                        end
                    case "slider"
                        count = count + 1;
                        handles{count} = component;
                        linked = labkit.app.internal.native.NativeAdapterValues. ...
                            linkedPannerSlider(component);
                        if ~isempty(linked)
                            count = count + 1;
                            handles{count} = linked;
                        end
                    case "fileList"
                        inputs = filePanelInputs(component);
                        handles(count + (1:numel(inputs))) = inputs;
                        count = count + numel(inputs);
                    case "plotArea"
                        linked = labkit.app.internal.native.NativeAdapterValues. ...
                        linkedPlotMode(component);
                        if ~isempty(linked)
                            count = count + 1;
                            handles{count} = linked;
                        end
                end
            end
            handles = handles(1:count);
        end

        function rangeChanged(obj, target)
            component = obj.component(target);
            rangeEnd = labkit.app.internal.native.NativeAdapterValues.linkedRangeEnd(component);
            value = [component.Value, rangeEnd.Value];
            obj.Runtime.applyControlValue(target, value);
        end

        installTableCallbacks(obj, node, component)

        function dispatchTableEdit(obj, target, component, event)
            indices = event.Indices;
            rowId = labkit.app.internal.native.NativeAdapterValues.tableLabel(component.RowName, indices(1));
            columnId = labkit.app.internal.native.NativeAdapterValues.tableLabel(component.ColumnName, indices(2));
            edit = labkit.app.event.TableCellEdit( ...
                RowIndex=indices(1), ColumnIndex=indices(2), ...
                RowId=rowId, ColumnId=columnId, ...
                PreviousValue=event.PreviousData, ...
                NewValue=labkit.app.internal.native.NativeAdapterValues.editedValue(event), Data=component.Data);
            obj.Runtime.applyTableEdit(target, edit);
        end

        installFilePanelCallbacks(obj, node, list)

        function chooseFiles(obj, target)
            config = obj.node(target).Configuration;
            startPath = obj.dialogStartFolder(target, "");
            [names, folder] = uigetfile(labkit.app.internal.native.NativeAdapterValues.dialogFilters(config.Filters), ...
                char(config.ChooseLabel), ...
                startPath, MultiSelect=labkit.app.internal.native.NativeAdapterValues.multiSelectValue(config.SelectionMode));
            if isequal(names, 0)
                return;
            end
            obj.DialogFolders(char(target)) = char(folder);
            labkit.app.internal.native.NativeAdapterValues.rememberDialogFolder( ...
                "input", folder);
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
            startPath = obj.dialogStartFolder(target, "");
            folder = uigetdir(startPath, "Choose folder");
            if isequal(folder, 0)
                return
            end
            obj.DialogFolders(char(target)) = char(folder);
            labkit.app.internal.native.NativeAdapterValues.rememberDialogFolder( ...
                "input", folder);
            paths = labkit.app.internal.native.NativeAdapterValues.filesInFolder(folder, config.Filters, recursive);
            if recursive && ...
                    numel(paths) > 500
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
            obj.Runtime.removeFileSelection( ...
                target, labkit.app.internal.native.NativeAdapterValues.selectedIndices(list));
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
                folder = labkit.app.internal.native.NativeAdapterValues.dialogStartFolder( ...
                    "input", "");
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

function handles = filePanelInputs(list)
handles = cell(1, 6);
handles{1} = list;
count = 1;
if ~isprop(list, "UserData") || ~isstruct(list.UserData)
    return
end
names = ["Choose", "Folder", "RecursiveFolder", "Remove", "Clear"];
for name = names
    field = char(name);
    if isfield(list.UserData, field) && ~isempty(list.UserData.(field))
        count = count + 1;
        handles{count} = list.UserData.(field);
    end
end
handles = handles(1:count);
end
