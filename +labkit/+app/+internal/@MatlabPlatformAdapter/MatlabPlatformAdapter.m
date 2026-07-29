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
        LogViewer
        TraceCaptureMenu
    end

    methods (Access = { ...
            ?labkit.app.internal.RuntimeKernel, ...
            ?labkit.app.internal.RuntimeContractBoundary})
        function obj = MatlabPlatformAdapter(plan, title)
            obj.Plan = labkit.app.internal.NativeAdapterValues.validatePlan(plan);
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
            policy = labkit.app.internal.NativeAdapterValues.layoutPolicy();
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
            targets = obj.interactionTargetAxes();
            if ~isempty(targets)
                obj.InteractionController = labkit.app.internal.NativeAdapterValues.interactionController( ...
                    obj.Figure, targets, ...
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
            if ~isempty(obj.LogViewer) && isvalid(obj.LogViewer)
                obj.LogViewer.close();
                obj.LogViewer = [];
            end
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
                mode = labkit.app.internal.NativeAdapterValues.startupGuiMode();
                if mode == "hidden"
                    return
                end
                obj.Figure.Visible = "on";
                if mode == "minimized" && isprop(obj.Figure, "WindowState")
                    obj.Figure.WindowState = "minimized";
                end
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
            drawnow limitrate nocallbacks
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
            drawnow limitrate nocallbacks
        end

        function startupUpdate(obj, message)
            if ~obj.Starting || isempty(obj.Figure) || ~isvalid(obj.Figure)
                return
            end
            if ~isempty(obj.StartupLabel) && isvalid(obj.StartupLabel)
                obj.StartupLabel.Text = char(string(message));
            end
            if toc(obj.StartupStarted) >= 0.25 && ...
                    ~any(labkit.app.internal.NativeAdapterValues.startupGuiMode() == ["hidden", "minimized"])
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
            if labkit.app.internal.NativeAdapterValues.startupGuiMode() == "minimized" && ...
                    isprop(obj.Figure, "WindowState")
                obj.Figure.Visible = "on";
                obj.Figure.WindowState = "minimized";
            end
        end

        function failStartup(obj, cause)
            obj.Starting = false;
            obj.Busy = false;
            if isempty(obj.Figure) || ~isvalid(obj.Figure)
                return
            end
            message = "Startup failed: " + labkit.app.internal.NativeAdapterValues.deepestCauseMessage(cause);
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

        function alert(obj, message, title)
            uialert(obj.Figure, char(string(message)), char(string(title)));
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
            filters = labkit.app.internal.NativeAdapterValues.dialogFilters(filters);
            [name, folder] = uigetfile(filters, "Choose input file", ...
                labkit.app.internal.NativeAdapterValues.safeStartPath(startPath));
            result = labkit.app.internal.NativeAdapterValues.dialogPath(name, folder);
        end

        function result = chooseInputFolder(~, startPath)
            folder = uigetdir(labkit.app.internal.NativeAdapterValues.safeStartPath(startPath), "Choose input folder");
            result = labkit.app.internal.NativeAdapterValues.folderDialogPath(folder);
        end

        function result = chooseOutputFile(~, filters, startPath)
            filters = labkit.app.internal.NativeAdapterValues.dialogFilters(filters);
            [name, folder] = uiputfile(filters, "Choose output file", ...
                labkit.app.internal.NativeAdapterValues.safeStartPath(startPath));
            result = labkit.app.internal.NativeAdapterValues.dialogPath(name, folder);
        end

        function result = chooseOutputFolder(~, startPath)
            folder = uigetdir(labkit.app.internal.NativeAdapterValues.safeStartPath(startPath), "Choose output folder");
            result = labkit.app.internal.NativeAdapterValues.folderDialogPath(folder);
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

        applyView(obj, view)

        apply(obj, operation)

        applyListSelection(~, component, selection)

        applyFilePaths(~, component, paths)

        applyFileItemStatuses(~, component, statuses)

        applyTableCellSelection(~, component, selection)

        applyTableData(~, component, model)

        applyText(~, component, value)

        applyValue(~, component, value)

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

        function runUtility(obj, callback)
            try
                callback();
            catch cause
                obj.alert(cause.message, "LabKit Utility");
            end
        end

        function openSessionLog(obj)
            if isempty(obj.LogViewer) || ~isvalid(obj.LogViewer) || ...
                    ~obj.LogViewer.isOpen()
                obj.LogViewer = ...
                    labkit.app.internal.SessionLogViewer(obj.Runtime);
            else
                obj.LogViewer.refresh();
            end
            obj.LogViewer.show();
        end

        function toggleTraceCapture(obj)
            enabled = true;
            if ~isempty(obj.TraceCaptureMenu) && ...
                    isvalid(obj.TraceCaptureMenu)
                enabled = string(obj.TraceCaptureMenu.Checked) ~= "on";
            end
            obj.Runtime.setTraceCapture(enabled);
            if ~isempty(obj.TraceCaptureMenu) && ...
                    isvalid(obj.TraceCaptureMenu)
                if enabled
                    obj.TraceCaptureMenu.Checked = "on";
                else
                    obj.TraceCaptureMenu.Checked = "off";
                end
            end
            if ~isempty(obj.LogViewer) && isvalid(obj.LogViewer)
                obj.LogViewer.refresh();
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
                    output = labkit.app.internal.NativeAdapterValues.plotFilepath(filepath, handles(k), k);
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

        function copyScreenshot(obj)
            copygraphics(obj.Figure, ContentType="image");
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
                Position=labkit.app.internal.NativeAdapterValues.closePromptPosition(obj.Figure));
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
            linked = labkit.app.internal.NativeAdapterValues.linkedPannerSlider(component);
            if ~isempty(linked)
                linked.Value = value;
            end
            obj.Runtime.applyControlValue(target, value);
        end

        function rangeChanged(obj, target)
            component = obj.component(target);
            rangeEnd = labkit.app.internal.NativeAdapterValues.linkedRangeEnd(component);
            value = [component.Value, rangeEnd.Value];
            obj.Runtime.applyControlValue(target, value);
        end

        installTableCallbacks(obj, node, component)

        function dispatchTableEdit(obj, target, component, event)
            indices = event.Indices;
            rowId = labkit.app.internal.NativeAdapterValues.tableLabel(component.RowName, indices(1));
            columnId = labkit.app.internal.NativeAdapterValues.tableLabel(component.ColumnName, indices(2));
            edit = labkit.app.event.TableCellEdit( ...
                RowIndex=indices(1), ColumnIndex=indices(2), ...
                RowId=rowId, ColumnId=columnId, ...
                PreviousValue=event.PreviousData, ...
                NewValue=labkit.app.internal.NativeAdapterValues.editedValue(event), Data=component.Data);
            obj.Runtime.applyTableEdit(target, edit);
        end

        installFilePanelCallbacks(obj, node, list)

        function chooseFiles(obj, target)
            config = obj.node(target).Configuration;
            startPath = obj.dialogStartFolder(target, config.StartPath);
            [names, folder] = uigetfile(labkit.app.internal.NativeAdapterValues.dialogFilters(config.Filters), ...
                char(config.ChooseLabel), ...
                startPath, MultiSelect=labkit.app.internal.NativeAdapterValues.multiSelectValue(config.SelectionMode));
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
            paths = labkit.app.internal.NativeAdapterValues.filesInFolder(folder, config.Filters, recursive);
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
            obj.Runtime.removeFileSelection( ...
                target, labkit.app.internal.NativeAdapterValues.selectedIndices(list));
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
                folder = labkit.app.internal.NativeAdapterValues.userDialogFolder();
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
