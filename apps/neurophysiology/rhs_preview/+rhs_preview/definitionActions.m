% App-owned action table for RHS Preview. Expected caller is
% rhs_preview.definition. Output maps semantic action ids to handlers used by
% labkit.ui.app.run while preserving lazy RHS indexing and preview behavior.
function actions = definitionActions()
%DEFINITIONACTIONS Build the RHS Preview runtime action map.
    S = [];
    ui = [];
    fig = [];
    debugLog = [];
    previewRuntime = [];
    previewSession = [];
    callbacks = struct( ...
        "rhsChosen", @onRhsChosen, ...
        "rhsCleared", @onRhsCleared, ...
        "folderChosen", @onFolderChosen, ...
        "folderRemoved", @onFolderRemoved, ...
        "folderCleared", @onFolderCleared, ...
        "protocolChosen", @onProtocolChosen, ...
        "protocolCleared", @onProtocolCleared, ...
        "settingChanged", @onSettingChanged, ...
        "previewChannelEdited", @onPreviewChannelEdited, ...
        "fileFilterEdited", @onFileFilterEdited, ...
        "refreshPreviewWindow", @onRefreshPreviewWindow, ...
        "refreshFolderFiles", @onRefreshFolderFiles, ...
        "zoomToRoi", @onZoomToRoi, ...
        "saveProtocol", @onSaveProtocol, ...
        "saveFilterRecord", @onSaveFilterRecord, ...
        "resetWorkflow", @onResetWorkflow);
    eventActions = ["rhsChosen", "folderChosen", "folderRemoved", ...
        "protocolChosen", "settingChanged", "previewChannelEdited"];
    actionIds = string(fieldnames(callbacks));
    actions = struct("startup", @onStartup);
    for kAction = 1:numel(actionIds)
        actions.(char(actionIds(kAction))) = @dispatchAction;
    end
    function state = onStartup(state, ~, services)
        S = state;
        ui = services.ui;
        fig = services.figure;
        debugLog = services.debug;
        previewRuntime = labkit.ui.tool.createRuntime( ...
            ui.controls.preview.primaryAxes, ...
            struct("figure", fig, "defaultScrollFcn", @onPreviewScrollWheel));
        previewSession = previewRuntime.createSession(struct( ...
            "name", "rhsPreviewRoi", ...
            "onPointerDown", @onPreviewAxesDown, ...
            "installScrollWheel", false));
        previewSession.setBackground(ui.controls.preview.primaryAxes);
        previewSession.activate();
        if debugLog.enabled
            debugLog.trace("RHS Preview debug trace enabled.");
            debugLog.instrumentFigure(fig);
            rhs_preview.debug.writeAndLogSamplePack(debugLog, @addLog);
        end
        refreshAll();
        addLog("RHS Preview ready.");
        state = S;
    end
    function state = dispatchAction(~, payload, ~)
        id = string(payload.id);
        if ~isfield(callbacks, char(id))
            error('rhs_preview:actions:UnknownAction', ...
                'Unknown RHS Preview action "%s".', payload.id);
        end
        event = [];
        if any(id == eventActions)
            event = payload.event;
        end
        callbacks.(char(id))([], event);
        state = S;
    end
    function onRhsChosen(~, event)
        paths = labkit.ui.view.filePaths(event.addedFiles);
        if isempty(paths)
            return;
        end
        S.rhsFile = paths(1);
        S.lastAction = "Selected RHS file";
        addLog("Selected RHS file: " + rhs_preview.userInterface.displayFile(S.rhsFile));
        indexed = inspectSelectedFile();
        if indexed && rhs_preview.analysisRun.hasReadableChannel(S)
            readPreviewWindowFromState("Auto preview window");
        end
        refreshAll();
    end
    function onRhsCleared(~, ~)
        S.rhsFile = "";
        S.info = [];
        S.index = [];
        S.preview = [];
        S.roiSec = [NaN NaN];
        S.family = "amplifier";
        S.previewChannelRows = table();
        S.statusMessage = "No RHS file selected.";
        S.lastAction = "Cleared RHS file";
        refreshAll();
    end
    function onFolderChosen(~, event)
        paths = labkit.ui.view.filePaths(event.addedFiles);
        if isempty(paths)
            return;
        end
        S.rhsFolder = commonParentFolder(paths);
        refreshFilterRowsFromPaths(paths, "Discovered RHS files");
        refreshAll();
    end
    function onFolderRemoved(~, event)
        paths = labkit.ui.view.filePaths(event.removedFiles);
        if isempty(paths) || isempty(S.filterRows) || height(S.filterRows) == 0
            return;
        end
        keep = ~ismember(string(S.filterRows.filePath), string(paths));
        S.filterRows = S.filterRows(keep, :);
        S.filterRows.recordingId = "R" + compose("%03d", ...
            (1:height(S.filterRows)).');
        remainingPaths = filterTaskPaths(S.filterRows);
        if isempty(remainingPaths)
            S.rhsFolder = "";
            S.statusMessage = "No RHS folder selected.";
        else
            S.rhsFolder = commonParentFolder(remainingPaths);
            S.statusMessage = sprintf("Removed %d RHS filter task(s).", ...
                numel(paths));
        end
        S.lastAction = "Removed RHS filter files";
        refreshAll();
    end
    function onFolderCleared(~, ~)
        S.rhsFolder = "";
        S.filterRows = table();
        S.statusMessage = "No RHS folder selected.";
        S.lastAction = "Cleared RHS folder";
        refreshAll();
    end
    function onProtocolChosen(~, event)
        paths = labkit.ui.view.filePaths(event.addedFiles);
        if isempty(paths)
            return;
        end
        S.protocolFile = paths(1);
        S.protocol = rhs_preview.sourceFiles.loadProtocol(S.protocolFile);
        rebuildPreviewChannelRows();
        S.lastAction = "Selected protocol";
        addLog("Selected protocol: " + rhs_preview.userInterface.displayFile(S.protocolFile));
        refreshAll();
    end
    function onProtocolCleared(~, ~)
        S.protocolFile = "";
        S.protocol = struct();
        rebuildPreviewChannelRows();
        S.lastAction = "Cleared protocol";
        refreshAll();
    end
    function onSettingChanged(~, event)
        previousFamily = S.family;
        previousMaxChannels = S.maxPreviewChannels;
        changedId = eventId(event);
        S.family = string(labkit.ui.view.getValue(ui, "channelFamily"));
        if changedId == "windowStartPanner"
            S.windowStartSec = numericScalar(labkit.ui.view.getValue(ui, ...
                "windowStartPanner"), S.windowStartSec);
        end
        S.maxPreviewChannels = max(1, floor(numericScalar(labkit.ui.view.getValue(ui, ...
            "maxPreviewChannels"), S.maxPreviewChannels)));
        if S.family ~= previousFamily || S.maxPreviewChannels ~= previousMaxChannels
            S = rhs_preview.analysisRun.normalizeChannelSelection(S);
            rebuildPreviewChannelRows();
            if S.autoWindow
                applyAdaptivePreviewWindow();
            end
        end
        S.lastAction = "Updated preview settings";
        if rhs_preview.analysisRun.hasReadableChannel(S)
            readPreviewWindowFromState( ...
                settingActionLabel(changedId), false);
        end
        refreshAll();
    end
    function onPreviewChannelEdited(~, event)
        data = labkit.ui.view.getValue(ui, "previewChannelsTable");
        S.previewChannelRows = rhs_preview.analysisRun.applyPreviewChannelsTableData( ...
            S.previewChannelRows, data);
        S.lastAction = "Updated preview channels";
        if isPreviewToggleEdit(event) && rhs_preview.analysisRun.hasReadableChannel(S)
            if S.autoWindow
                applyAdaptivePreviewWindow();
            end
            readPreviewWindowFromState("Updated preview channel window", false);
        end
        refreshAll();
    end
    function onFileFilterEdited(~, ~)
        data = labkit.ui.view.getValue(ui, "fileFilterTable");
        S.filterRows = rhs_preview.analysisRun.applyFileFilterTableData( ...
            S.filterRows, data);
        S.statusMessage = "File filter updated.";
        S.lastAction = "Updated file filter";
        refreshAll();
    end
    function onRefreshPreviewWindow(~, ~)
        readPreviewWindowFromState("Refresh preview window");
        refreshAll();
    end
    function onRefreshFolderFiles(~, ~)
        if strlength(S.rhsFolder) == 0
            S.statusMessage = "Select an RHS folder first.";
            refreshAll();
            return;
        end
        refreshFolderFiles("Refreshed RHS file list");
        refreshAll();
    end
    function onZoomToRoi(~, ~)
        if ~rhs_preview.analysisRun.hasValidRoi(S)
            S.statusMessage = "Drag a preview ROI before using Zoom to ROI.";
            S.lastAction = "Zoom to ROI skipped";
            refreshAll();
            return;
        end
        roiSec = sort(double(S.roiSec(:))).';
        bounds = rhs_preview.analysisRun.previewWindowBounds(S);
        durationSec = max(diff(roiSec), bounds.minDurationSec);
        if bounds.hasIndexedDuration
            durationSec = min(durationSec, bounds.durationSec);
        end
        S.windowDurationSec = durationSec;
        S.windowStartSec = roiSec(1);
        S.windowStartSec = rhs_preview.analysisRun.clampWindowStartSec(S.windowStartSec, S);
        S.autoWindow = false;
        if readPreviewWindowFromState("Zoom to ROI window", true, true)
            S.statusMessage = sprintf("Window set to ROI %.6g to %.6g s.", ...
                roiSec(1), roiSec(2));
        end
        refreshAll();
    end
    function ok = readPreviewWindowFromState(actionLabel, logRead, preserveRoi)
        if nargin < 2
            logRead = true;
        end
        if nargin < 3
            preserveRoi = false;
        end
        [S, ok, logMessage] = rhs_preview.analysisRun.readPreviewWindow( ...
            S, selectedPreviewChannels(), actionLabel, preserveRoi);
        if strlength(logMessage) > 0 && (logRead || ~ok)
            addLog(logMessage);
        end
    end
    function onPreviewAxesDown(source, ~)
        if isempty(S.preview) || isempty(S.preview.timeSec)
            return;
        end
        if ~isNormalClick(fig)
            return;
        end
        startX = rhs_preview.userInterface.previewX(source);
        if ~isfinite(startX)
            return;
        end
        S.roiSec = rhs_preview.analysisRun.clampRoi([startX startX], S.preview.timeSec);
        previewSession.captureDrag(@onPreviewAxesDrag, @onPreviewAxesUp);
        refreshPreview();
        syncRuntimeState();
        function onPreviewAxesDrag(~, ~)
            currentX = rhs_preview.userInterface.previewX(source);
            if ~isfinite(currentX)
                return;
            end
            S.roiSec = rhs_preview.analysisRun.clampRoi([startX currentX], S.preview.timeSec);
            refreshPreview();
            syncRuntimeState();
        end
        function onPreviewAxesUp(~, ~)
            S.lastAction = "Updated preview ROI";
            if all(isfinite(S.roiSec)) && diff(S.roiSec) > 0
                S.statusMessage = sprintf("ROI %.6g to %.6g s.", ...
                    S.roiSec(1), S.roiSec(2));
            end
            refreshAll();
            syncRuntimeState();
        end
    end
    function onPreviewScrollWheel(~, event)
        bounds = rhs_preview.analysisRun.previewWindowBounds(S);
        if ~rhs_preview.analysisRun.hasReadableChannel(S) || ~bounds.hasIndexedDuration
            return;
        end
        scrollCount = scrollWheelCount(event);
        if scrollCount == 0
            return;
        end
        if ~shouldProcessPreviewScroll()
            return;
        end
        centerSec = rhs_preview.userInterface.previewX(ui.controls.preview.primaryAxes);
        if ~isfinite(centerSec)
            centerSec = S.windowStartSec + S.windowDurationSec ./ 2;
        end
        oldStart = rhs_preview.analysisRun.clampWindowStartSec(S.windowStartSec, S);
        oldDuration = max(S.windowDurationSec, bounds.minDurationSec);
        fileDuration = bounds.durationSec;
        factor = 1.25 .^ double(scrollCount);
        newDuration = min(rhs_preview.analysisRun.maxInteractivePreviewDurationSec(S), ...
            max(bounds.minDurationSec, oldDuration .* factor));
        if ~isfinite(newDuration) || newDuration <= 0
            return;
        end
        anchor = (centerSec - oldStart) ./ oldDuration;
        anchor = min(1, max(0, anchor));
        S.windowDurationSec = min(fileDuration, newDuration);
        S.windowStartSec = centerSec - anchor .* S.windowDurationSec;
        S.windowStartSec = rhs_preview.analysisRun.clampWindowStartSec(S.windowStartSec, S);
        S.autoWindow = false;
        if readPreviewWindowFromState("Zoom preview window", false)
            S.statusMessage = "Preview zoom updated.";
        end
        refreshAll();
        syncRuntimeState();
    end
    function onSaveProtocol(~, ~)
        if isempty(S.previewChannelRows) || height(S.previewChannelRows) == 0
            S.statusMessage = "Select an RHS file before saving a protocol.";
            refreshAll();
            return;
        end
        outputPath = rhs_preview.resultFiles.promptProtocolOutput( ...
            labkit.ui.app.defaultOutputFolder(defaultOutputSources(), "rhs_preview"));
        if strlength(outputPath) == 0
            return;
        end
        rhs_preview.resultFiles.writeProtocolJson(S, outputPath);
        S.protocolFile = outputPath;
        S.protocol = rhs_preview.resultFiles.protocolJsonStruct(S);
        S.statusMessage = "Saved protocol JSON.";
        S.lastAction = "Saved protocol";
        addLog("Saved protocol JSON: " + rhs_preview.userInterface.displayFile(outputPath));
        refreshAll();
    end
    function onSaveFilterRecord(~, ~)
        if isempty(S.filterRows) || height(S.filterRows) == 0
            S.statusMessage = "Select an RHS folder before saving a filter record.";
            refreshAll();
            return;
        end
        data = labkit.ui.view.getValue(ui, "fileFilterTable");
        S.filterRows = rhs_preview.analysisRun.applyFileFilterTableData(S.filterRows, data);
        outputPath = rhs_preview.resultFiles.promptFilterRecordOutput( ...
            labkit.ui.app.defaultOutputFolder(defaultOutputSources(), "rhs_preview"));
        if strlength(outputPath) == 0
            return;
        end
        rhs_preview.resultFiles.writeFilterRecordJson(S, outputPath);
        S.statusMessage = "Saved filter record JSON.";
        S.lastAction = "Saved filter record";
        addLog("Saved filter record JSON: " + rhs_preview.userInterface.displayFile(outputPath));
        refreshAll();
    end
    function onResetWorkflow(~, ~)
        S = rhs_preview.appLifecycle.createInitialState();
        labkit.ui.view.setValue(ui, "windowStartPanner", S.windowStartSec);
        labkit.ui.view.setValue(ui, "maxPreviewChannels", S.maxPreviewChannels);
        addLog("Reset RHS Preview state.");
        refreshAll();
    end
    function ok = inspectSelectedFile()
        ok = false;
        if strlength(S.rhsFile) == 0
            S.statusMessage = "No RHS file selected.";
            return;
        end
        [index, status] = labkit.rhs.indexFile(S.rhsFile);
        S.index = index;
        S.info = index.info;
        if status.ok
            S.statusMessage = "RHS header indexed.";
            if strlength(status.message) > 0
                S.statusMessage = status.message;
            end
            S = rhs_preview.analysisRun.normalizeChannelSelection(S);
            rebuildPreviewChannelRows();
            S.autoWindow = true;
            S.windowStartSec = 0;
            applyAdaptivePreviewWindow();
            addLog(sprintf("Indexed %s: %.3f s, %d amplifier channel(s).", ...
                char(rhs_preview.userInterface.displayFile(S.rhsFile)), index.durationSec, ...
                numel(index.info.channelFamilies.amplifier)));
            ok = true;
        else
            S.statusMessage = status.message;
            addLog("RHS inspect failed: " + status.message);
        end
        S.lastAction = "Indexed RHS file";
    end
    function refreshFolderFiles(actionLabel)
        try
            S.filterRows = rhs_preview.analysisRun.discoverFilterRows( ...
                S.rhsFolder, S.filterRows);
        catch ME
            debugLog.reportException('rhsPreview', 'Folder scan failed', ME);
            S.filterRows = table();
            S.statusMessage = string(ME.message);
            S.lastAction = "Folder scan failed";
            addLog("Folder scan failed: " + S.statusMessage);
            return;
        end
        S.statusMessage = sprintf("Discovered %d RHS file(s).", ...
            height(S.filterRows));
        S.lastAction = string(actionLabel);
        addLog(S.statusMessage);
    end
    function refreshFilterRowsFromPaths(paths, actionLabel)
        try
            S.filterRows = rhs_preview.analysisRun.discoverFilterRows(paths, ...
                S.filterRows);
        catch ME
            debugLog.reportException('rhsPreview', 'RHS task scan failed', ME);
            S.filterRows = table();
            S.statusMessage = string(ME.message);
            S.lastAction = "RHS task scan failed";
            addLog("RHS task scan failed: " + S.statusMessage);
            return;
        end
        S.statusMessage = sprintf("Discovered %d RHS file(s).", ...
            height(S.filterRows));
        S.lastAction = string(actionLabel);
        addLog(S.statusMessage);
    end
    function tf = isPreviewToggleEdit(event)
        tf = true;
        if (isstruct(event) && isfield(event, "indices")) || ...
                (isobject(event) && isprop(event, "indices"))
            indices = event.indices;
            tf = isempty(indices) || any(indices(:, 2) == 1);
        end
    end
    function refreshAll()
        labkit.ui.view.setValue(ui, "rhsFile", fileValue(S.rhsFile));
        labkit.ui.view.setValue(ui, "rhsFolder", filterTaskPaths(S.filterRows));
        labkit.ui.view.setValue(ui, "protocolFile", fileValue(S.protocolFile));
        refreshChannelControls();
        refreshWindowControls();
        labkit.ui.view.setEnabled(ui, "refreshPreviewWindow", ...
            rhs_preview.analysisRun.hasReadableChannel(S));
        labkit.ui.view.setEnabled(ui, "zoomToRoiWindow", ...
            rhs_preview.analysisRun.hasReadableChannel(S) && ...
            rhs_preview.analysisRun.hasValidRoi(S));
        labkit.ui.view.setEnabled(ui, "saveProtocol", ~isempty(S.previewChannelRows) && ...
            height(S.previewChannelRows) > 0);
        labkit.ui.view.setEnabled(ui, "refreshFolderFiles", ...
            strlength(S.rhsFolder) > 0);
        labkit.ui.view.setEnabled(ui, "saveFilterRecord", ...
            ~isempty(S.filterRows) && height(S.filterRows) > 0);
        labkit.ui.view.setValue(ui, "statusField", char(S.statusMessage));
        labkit.ui.view.setValue(ui, "summaryTable", ...
            rhs_preview.userInterface.summaryTableData(S));
        labkit.ui.view.setValue(ui, "previewChannelsTable", ...
            rhs_preview.userInterface.previewChannelsTableData(S));
        labkit.ui.view.setValue(ui, "fileFilterTable", ...
            rhs_preview.userInterface.fileFilterTableData(S));
        ui.controls.details.textArea.Value = rhs_preview.userInterface.detailLines(S);
        refreshPreview();
    end
    function refreshChannelControls()
        selection = rhs_preview.userInterface.channelSelection(S.info, S.family, ...
            "");
        S.family = selection.family;
        rhs_preview.userInterface.setDropDown(ui.controls.channelFamily, selection.families, ...
            selection.family, selection.hasChannels);
    end
    function refreshPreview()
        rhs_preview.userInterface.drawStackedPreview(ui.controls.preview.primaryAxes, S);
    end
    function rebuildPreviewChannelRows()
        S.previewChannelRows = rhs_preview.analysisRun.channelRows(S.info, S.family, ...
            S.maxPreviewChannels, S.protocol);
    end
    function applyAdaptivePreviewWindow()
        durationSec = rhs_preview.analysisRun.suggestedPreviewDurationSec( ...
            S.index, S.previewChannelRows, S.maxPreviewChannels);
        if ~isfinite(durationSec) || durationSec <= 0
            return;
        end
        S.windowDurationSec = durationSec;
        S.windowStartSec = rhs_preview.analysisRun.clampWindowStartSec(S.windowStartSec, S);
    end
    function refreshWindowControls()
        bounds = rhs_preview.analysisRun.previewWindowBounds(S);
        if ~bounds.hasIndexedDuration
            labkit.ui.view.setLimits(ui, "windowStartPanner", [0 1]);
            labkit.ui.view.setValue(ui, "windowStartPanner", 0);
            labkit.ui.view.setEnabled(ui, "windowStartPanner", false);
            labkit.ui.view.setValue(ui, "windowSummary", ...
                "Select RHS to estimate preview length.");
            return;
        end
        maxStartSec = bounds.maxStartSec;
        sliderMax = max(maxStartSec, eps);
        S.windowStartSec = rhs_preview.analysisRun.clampWindowStartSec(S.windowStartSec, S);
        labkit.ui.view.setLimits(ui, "windowStartPanner", [0 sliderMax]);
        labkit.ui.view.setValue(ui, "windowStartPanner", S.windowStartSec);
        labkit.ui.view.setEnabled(ui, "windowStartPanner", maxStartSec > 0);
        labkit.ui.view.setValue(ui, "windowSummary", ...
            rhs_preview.analysisRun.windowSummaryText(S));
    end
    function selected = selectedPreviewChannels()
        selected = strings(0, 1);
        if isempty(S.previewChannelRows) || height(S.previewChannelRows) == 0
            return;
        end
        mask = logical(S.previewChannelRows.preview);
        selected = S.previewChannelRows.channel(mask);
        if numel(selected) > S.maxPreviewChannels
            selected = selected(1:S.maxPreviewChannels);
            S.statusMessage = sprintf("Preview capped at %d channel(s).", ...
                S.maxPreviewChannels);
        end
    end
    function addLog(message)
        labkit.ui.view.appendLog(ui, "logPanel", message);
        debugLog.append(message);
    end
    function paths = defaultOutputSources()
        paths = strings(0, 1);
        candidates = [S.rhsFile, S.rhsFolder, S.protocolFile];
        for k = 1:numel(candidates)
            if strlength(candidates(k)) > 0
                paths(end + 1, 1) = candidates(k);
            end
        end
    end
    function tf = shouldProcessPreviewScroll()
        tf = true;
        minIntervalSec = 0.080;
        if isempty(S.lastScrollTic)
            S.lastScrollTic = tic;
            return;
        end
        if toc(S.lastScrollTic) < minIntervalSec
            tf = false;
            return;
        end
        S.lastScrollTic = tic;
    end
    function syncRuntimeState()
        if isempty(fig) || ~isvalid(fig) || ...
                ~isappdata(fig, 'labkitUiAppRuntime')
            return;
        end
        runtime = getappdata(fig, 'labkitUiAppRuntime');
        runtime.state = S;
        setappdata(fig, 'labkitUiAppRuntime', runtime);
    end
end
function value = numericScalar(value, fallback)
    value = double(value);
    if isempty(value) || ~isscalar(value) || ~isfinite(value)
        value = fallback;
    end
end
function id = eventId(event)
    id = "";
    if isstruct(event) && isfield(event, "id")
        id = string(event.id);
    elseif isobject(event) && isprop(event, "id")
        id = string(event.id);
    end
end
function label = settingActionLabel(changedId)
    if string(changedId) == "windowStartPanner"
        label = "Panned preview window";
    else
        label = "Updated preview window";
    end
end
function tf = isNormalClick(fig)
    tf = true;
    if isempty(fig) || ~isvalid(fig) || ~isprop(fig, 'SelectionType')
        return;
    end
    tf = strcmp(fig.SelectionType, 'normal');
end
function count = scrollWheelCount(event)
    count = 0;
    if isstruct(event) && isfield(event, "VerticalScrollCount")
        count = double(event.VerticalScrollCount);
    elseif isobject(event) && isprop(event, "VerticalScrollCount")
        count = double(event.VerticalScrollCount);
    end
end
function items = fileValue(pathValue)
    pathValue = string(pathValue);
    if strlength(pathValue) == 0
        items = strings(0, 1);
        return;
    end
    items = pathValue;
end
function paths = filterTaskPaths(rows)
    if istable(rows) && height(rows) > 0 && any(strcmp(rows.Properties.VariableNames, "filePath"))
        paths = string(rows.filePath);
        paths = paths(:);
    else
        paths = strings(0, 1);
    end
end
function folder = commonParentFolder(paths)
    paths = string(paths);
    paths = paths(strlength(paths) > 0);
    if isempty(paths)
        folder = "";
        return;
    end
    folders = strings(numel(paths), 1);
    for k = 1:numel(paths)
        folders(k) = string(fileparts(char(paths(k))));
    end
    folder = folders(1);
    parts = split(folder, filesep);
    for k = 2:numel(folders)
        peer = split(folders(k), filesep);
        n = min(numel(parts), numel(peer));
        keep = false(n, 1);
        for iPart = 1:n
            keep(iPart) = parts(iPart) == peer(iPart);
        end
        firstMismatch = find(~keep, 1, "first");
        if isempty(firstMismatch)
            parts = parts(1:n);
        elseif firstMismatch == 1
            parts = strings(0, 1);
        else
            parts = parts(1:firstMismatch - 1);
        end
    end
    parts = parts(strlength(parts) > 0);
    if isempty(parts)
        folder = fileparts(char(paths(1)));
    elseif startsWith(folders(1), filesep)
        folder = string(filesep) + strjoin(parts, filesep);
    else
        folder = strjoin(parts, filesep);
    end
end
