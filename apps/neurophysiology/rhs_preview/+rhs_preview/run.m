% Expected caller: labkit_RHSPreview_app. Input is a debug context prepared by
% labkit.ui.app.dispatchRequest. Output is the app figure. Side effects are
% GUI creation, RHS header/window reads, app-state updates, and debug trace
% attachment.
function fig = run(debugLog)
%RUN Build and run the RHS Preview app.

    S = rhs_preview.state.defaultState();
    callbacks = struct( ...
        "rhsChosen", @onRhsChosen, ...
        "rhsCleared", @onRhsCleared, ...
        "protocolChosen", @onProtocolChosen, ...
        "protocolCleared", @onProtocolCleared, ...
        "settingChanged", @onSettingChanged, ...
        "previewChannelEdited", @onPreviewChannelEdited, ...
        "protocolPairEdited", @onProtocolPairEdited, ...
        "refreshPreviewWindow", @onRefreshPreviewWindow, ...
        "zoomToRoi", @onZoomToRoi, ...
        "saveProtocol", @onSaveProtocol, ...
        "resetWorkflow", @onResetWorkflow);

    spec = rhs_preview.ui.buildSpec(callbacks);
    ui = labkit.ui.app.create(spec, "debug", debugLog);
    fig = ui.figure;
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
    end

    refreshAll();
    addLog("RHS Preview ready.");

    function onRhsChosen(~, event)
        paths = rhs_preview.ops.eventPaths(event);
        if isempty(paths)
            return;
        end
        S.rhsFile = paths(1);
        S.lastAction = "Selected RHS file";
        addLog("Selected RHS file: " + rhs_preview.view.displayFile(S.rhsFile));
        indexed = inspectSelectedFile();
        if indexed && rhs_preview.ops.hasReadableChannel(S)
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
        S.protocolPairRows = table();
        S.protocolPairsEdited = false;
        S.statusMessage = "No RHS file selected.";
        S.lastAction = "Cleared RHS file";
        refreshAll();
    end

    function onProtocolChosen(~, event)
        paths = rhs_preview.ops.eventPaths(event);
        if isempty(paths)
            return;
        end
        S.protocolFile = paths(1);
        S.protocol = rhs_preview.io.loadProtocol(S.protocolFile);
        rebuildPreviewChannelRows();
        rebuildProtocolPairRows(true);
        S.lastAction = "Selected protocol";
        addLog("Selected protocol: " + rhs_preview.view.displayFile(S.protocolFile));
        refreshAll();
    end

    function onProtocolCleared(~, ~)
        S.protocolFile = "";
        S.protocol = struct();
        rebuildPreviewChannelRows();
        rebuildProtocolPairRows(true);
        S.lastAction = "Cleared protocol";
        refreshAll();
    end

    function onSettingChanged(~, event)
        previousFamily = S.family;
        previousMaxChannels = S.maxPreviewChannels;
        changedId = rhs_preview.ops.eventId(event);
        S.family = string(labkit.ui.view.getValue(ui, "channelFamily"));
        if changedId == "windowStartPanner"
            S.windowStartSec = double(labkit.ui.view.getValue(ui, ...
                "windowStartPanner"));
        end
        S.maxPreviewChannels = max(1, floor(double(labkit.ui.view.getValue(ui, ...
            "maxPreviewChannels"))));
        if S.family ~= previousFamily || S.maxPreviewChannels ~= previousMaxChannels
            S = rhs_preview.ops.normalizeChannelSelection(S);
            rebuildPreviewChannelRows();
            rebuildProtocolPairRows(false);
            if S.autoWindow
                applyAdaptivePreviewWindow();
            end
        end
        S.lastAction = "Updated preview settings";
        if rhs_preview.ops.hasReadableChannel(S)
            readPreviewWindowFromState( ...
                rhs_preview.ops.settingActionLabel(changedId), false);
        end
        refreshAll();
    end

    function onPreviewChannelEdited(~, event)
        data = labkit.ui.view.getValue(ui, "previewChannelsTable");
        S.previewChannelRows = rhs_preview.ops.applyPreviewChannelsTableData( ...
            S.previewChannelRows, data);
        if ~S.protocolPairsEdited
            rebuildProtocolPairRows(false);
        end
        S.lastAction = "Updated preview channels";
        if isPreviewToggleEdit(event) && rhs_preview.ops.hasReadableChannel(S)
            if S.autoWindow
                applyAdaptivePreviewWindow();
            end
            readPreviewWindowFromState("Updated preview channel window", false);
        end
        refreshAll();
    end

    function onProtocolPairEdited(~, ~)
        data = labkit.ui.view.getValue(ui, "protocolPairsTable");
        S.protocolPairRows = rhs_preview.ops.applyProtocolPairsTableData(data);
        S.protocolPairsEdited = true;
        S.statusMessage = "Protocol pairs updated.";
        S.lastAction = "Updated protocol pairs";
        refreshAll();
    end

    function onRefreshPreviewWindow(~, ~)
        readPreviewWindowFromState("Refresh preview window");
        refreshAll();
    end

    function onZoomToRoi(~, ~)
        if ~rhs_preview.ops.hasValidRoi(S)
            S.statusMessage = "Drag a preview ROI before using Zoom to ROI.";
            S.lastAction = "Zoom to ROI skipped";
            refreshAll();
            return;
        end
        roiSec = sort(double(S.roiSec(:))).';
        durationSec = max(diff(roiSec), rhs_preview.ops.minPreviewDurationSec(S));
        if rhs_preview.ops.hasIndexedDuration(S)
            durationSec = min(durationSec, rhs_preview.ops.indexedDurationSec(S));
        end
        S.windowDurationSec = durationSec;
        S.windowStartSec = roiSec(1);
        S.windowStartSec = rhs_preview.ops.clampWindowStartSec(S.windowStartSec, S);
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
        ok = false;
        if strlength(S.rhsFile) == 0
            S.statusMessage = "Select an RHS file first.";
            return;
        end
        previousRoiSec = S.roiSec;

        opts = struct();
        opts.family = S.family;
        S.windowStartSec = rhs_preview.ops.clampWindowStartSec(S.windowStartSec, S);
        opts.timeRangeSec = [S.windowStartSec, ...
            S.windowStartSec + max(S.windowDurationSec, eps)];
        selectedChannels = selectedPreviewChannels();
        if isempty(selectedChannels)
            S.statusMessage = "Select at least one preview channel first.";
            return;
        else
            opts.channels = selectedChannels;
        end

        try
            [window, status] = labkit.rhs.readWindow(S.rhsFile, opts);
        catch ME
            S.preview = [];
            S.statusMessage = string(ME.message);
            S.lastAction = "Preview read failed";
            addLog("Preview read failed: " + S.statusMessage);
            return;
        end
        S.preview = window;
        if preserveRoi && ~isempty(window.timeSec)
            S.roiSec = rhs_preview.ops.clampRoi(previousRoiSec, window.timeSec);
        else
            S.roiSec = [NaN NaN];
        end
        if status.ok
            S.statusMessage = "Preview window read.";
            S.lastAction = string(actionLabel);
            if logRead
                addLog(sprintf("Read %d sample(s) from %s.", ...
                    numel(window.timeSec), char(window.family)));
            end
            ok = true;
        else
            S.statusMessage = status.message;
            S.lastAction = "Preview read failed";
            addLog("Preview read failed: " + status.message);
        end
    end

    function onPreviewAxesDown(source, ~)
        if isempty(S.preview) || isempty(S.preview.timeSec)
            return;
        end
        if ~rhs_preview.ops.isNormalClick(fig)
            return;
        end
        startX = rhs_preview.view.previewX(source);
        if ~isfinite(startX)
            return;
        end
        S.roiSec = rhs_preview.ops.clampRoi([startX startX], S.preview.timeSec);
        previewSession.captureDrag(@onPreviewAxesDrag, @onPreviewAxesUp);
        refreshPreview();

        function onPreviewAxesDrag(~, ~)
            currentX = rhs_preview.view.previewX(source);
            if ~isfinite(currentX)
                return;
            end
            S.roiSec = rhs_preview.ops.clampRoi([startX currentX], S.preview.timeSec);
            refreshPreview();
        end

        function onPreviewAxesUp(~, ~)
            S.lastAction = "Updated preview ROI";
            if all(isfinite(S.roiSec)) && diff(S.roiSec) > 0
                S.statusMessage = sprintf("ROI %.6g to %.6g s.", ...
                    S.roiSec(1), S.roiSec(2));
            end
            refreshAll();
        end
    end

    function onPreviewScrollWheel(~, event)
        if ~rhs_preview.ops.hasReadableChannel(S) || ...
                ~rhs_preview.ops.hasIndexedDuration(S)
            return;
        end
        scrollCount = rhs_preview.ops.scrollWheelCount(event);
        if scrollCount == 0
            return;
        end
        if ~shouldProcessPreviewScroll()
            return;
        end

        centerSec = rhs_preview.view.previewX(ui.controls.preview.primaryAxes);
        if ~isfinite(centerSec)
            centerSec = S.windowStartSec + S.windowDurationSec ./ 2;
        end
        oldStart = rhs_preview.ops.clampWindowStartSec(S.windowStartSec, S);
        oldDuration = max(S.windowDurationSec, rhs_preview.ops.minPreviewDurationSec(S));
        fileDuration = rhs_preview.ops.indexedDurationSec(S);
        factor = 1.25 .^ double(scrollCount);
        newDuration = min(rhs_preview.ops.maxInteractivePreviewDurationSec(S), ...
            max(rhs_preview.ops.minPreviewDurationSec(S), oldDuration .* factor));
        if ~isfinite(newDuration) || newDuration <= 0
            return;
        end

        anchor = (centerSec - oldStart) ./ oldDuration;
        anchor = min(1, max(0, anchor));
        S.windowDurationSec = min(fileDuration, newDuration);
        S.windowStartSec = centerSec - anchor .* S.windowDurationSec;
        S.windowStartSec = rhs_preview.ops.clampWindowStartSec(S.windowStartSec, S);
        S.autoWindow = false;
        if readPreviewWindowFromState("Zoom preview window", false)
            S.statusMessage = "Preview zoom updated.";
        end
        refreshAll();
    end

    function onSaveProtocol(~, ~)
        if isempty(S.previewChannelRows) || height(S.previewChannelRows) == 0
            S.statusMessage = "Select an RHS file before saving a protocol.";
            refreshAll();
            return;
        end
        outputPath = rhs_preview.io.promptProtocolOutput();
        if strlength(outputPath) == 0
            return;
        end
        rhs_preview.export.writeProtocolJson(S, outputPath);
        S.protocolFile = outputPath;
        S.protocol = rhs_preview.export.protocolJsonStruct(S);
        S.statusMessage = "Saved protocol JSON.";
        S.lastAction = "Saved protocol";
        addLog("Saved protocol JSON: " + rhs_preview.view.displayFile(outputPath));
        refreshAll();
    end

    function onResetWorkflow(~, ~)
        S = rhs_preview.state.defaultState();
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
            S = rhs_preview.ops.normalizeChannelSelection(S);
            rebuildPreviewChannelRows();
            rebuildProtocolPairRows(false);
            S.autoWindow = true;
            S.windowStartSec = 0;
            applyAdaptivePreviewWindow();
            addLog(sprintf("Indexed %s: %.3f s, %d amplifier channel(s).", ...
                char(rhs_preview.view.displayFile(S.rhsFile)), index.durationSec, ...
                numel(index.info.channelFamilies.amplifier)));
            ok = true;
        else
            S.statusMessage = status.message;
            addLog("RHS inspect failed: " + status.message);
        end
        S.lastAction = "Indexed RHS file";
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
        labkit.ui.view.setListItems(ui, "rhsFile", ...
            cellstr(rhs_preview.view.selectedList(S.rhsFile)));
        labkit.ui.view.setListItems(ui, "protocolFile", ...
            cellstr(rhs_preview.view.selectedList(S.protocolFile)));
        refreshChannelControls();
        refreshWindowControls();
        labkit.ui.view.setEnabled(ui, "refreshPreviewWindow", ...
            rhs_preview.ops.hasReadableChannel(S));
        labkit.ui.view.setEnabled(ui, "zoomToRoiWindow", ...
            rhs_preview.ops.hasReadableChannel(S) && ...
            rhs_preview.ops.hasValidRoi(S));
        labkit.ui.view.setEnabled(ui, "saveProtocol", ~isempty(S.previewChannelRows) && ...
            height(S.previewChannelRows) > 0);
        labkit.ui.view.setValue(ui, "statusField", char(S.statusMessage));
        labkit.ui.view.setValue(ui, "summaryTable", ...
            rhs_preview.view.summaryTableData(S));
        labkit.ui.view.setValue(ui, "previewChannelsTable", ...
            rhs_preview.view.previewChannelsTableData(S));
        labkit.ui.view.setValue(ui, "protocolPairsTable", ...
            rhs_preview.view.protocolPairsTableData(S));
        ui.controls.details.textArea.Value = rhs_preview.view.detailLines(S);
        refreshPreview();
    end

    function refreshChannelControls()
        selection = rhs_preview.view.channelSelection(S.info, S.family, ...
            "");
        S.family = selection.family;
        rhs_preview.view.setDropDown(ui.controls.channelFamily, selection.families, ...
            selection.family, selection.hasChannels);
    end

    function refreshPreview()
        rhs_preview.view.drawStackedPreview(ui.controls.preview.primaryAxes, S);
    end

    function rebuildPreviewChannelRows()
        S.previewChannelRows = rhs_preview.ops.channelRows(S.info, S.family, ...
            S.maxPreviewChannels, S.protocol);
    end

    function rebuildProtocolPairRows(forceFromProtocol)
        if nargin < 1
            forceFromProtocol = false;
        end
        if forceFromProtocol || ~S.protocolPairsEdited
            S.protocolPairRows = rhs_preview.ops.pairRows( ...
                S.previewChannelRows, S.protocol);
            S.protocolPairsEdited = false;
        end
    end

    function applyAdaptivePreviewWindow()
        durationSec = rhs_preview.ops.suggestedPreviewDurationSec( ...
            S.index, S.previewChannelRows, S.maxPreviewChannels);
        if ~isfinite(durationSec) || durationSec <= 0
            return;
        end
        S.windowDurationSec = durationSec;
        S.windowStartSec = rhs_preview.ops.clampWindowStartSec(S.windowStartSec, S);
    end

    function refreshWindowControls()
        if ~rhs_preview.ops.hasIndexedDuration(S)
            labkit.ui.view.setLimits(ui, "windowStartPanner", [0 1]);
            labkit.ui.view.setValue(ui, "windowStartPanner", 0);
            labkit.ui.view.setEnabled(ui, "windowStartPanner", false);
            labkit.ui.view.setValue(ui, "windowSummary", ...
                "Select RHS to estimate preview length.");
            return;
        end

        maxStartSec = rhs_preview.ops.maxPreviewStartSec(S);
        sliderMax = max(maxStartSec, eps);
        S.windowStartSec = rhs_preview.ops.clampWindowStartSec(S.windowStartSec, S);
        labkit.ui.view.setLimits(ui, "windowStartPanner", [0 sliderMax]);
        labkit.ui.view.setValue(ui, "windowStartPanner", S.windowStartSec);
        labkit.ui.view.setEnabled(ui, "windowStartPanner", maxStartSec > 0);
        labkit.ui.view.setValue(ui, "windowSummary", ...
            rhs_preview.ops.windowSummaryText(S));
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
end
