% Expected caller: labkit_RHSScreen_app. Input is a debug context prepared
% by labkit.ui.app.dispatchRequest. Output is the app figure. Side effects
% are GUI creation, RHS header screening, optional JSON export, and debug
% trace attachment.
function fig = run(debugLog)
%RUN Build and run the RHS Screen app.

    S = defaultState();
    callbacks = struct( ...
        "folderChosen", @onFolderChosen, ...
        "folderCleared", @onFolderCleared, ...
        "protocolChosen", @onProtocolChosen, ...
        "protocolCleared", @onProtocolCleared, ...
        "outputFolderChosen", @onOutputFolderChosen, ...
        "outputFolderCleared", @onOutputFolderCleared, ...
        "settingChanged", @onSettingChanged, ...
        "recordingEdited", @onRecordingEdited, ...
        "previewModeChanged", @onPreviewModeChanged, ...
        "scanFolder", @onScanFolder, ...
        "exportSession", @onExportSession, ...
        "resetWorkflow", @onResetWorkflow);

    spec = rhs_screen.ui.buildSpec(callbacks);
    ui = labkit.ui.app.create(spec, "debug", debugLog);
    fig = ui.figure;

    if debugLog.enabled
        debugLog.trace("RHS Screen debug trace enabled.");
        debugLog.instrumentFigure(fig);
    end

    refreshAll();
    addLog("RHS Screen ready.");

    function onFolderChosen(~, event)
        paths = eventPaths(event);
        if isempty(paths)
            return;
        end
        S.rootFolder = paths(1);
        S.lastAction = "Selected RHS folder";
        S.statusMessage = "RHS folder selected.";
        addLog("Selected RHS folder: " + displayPath(S.rootFolder));
        scanSelectedFolder("Auto-scanned RHS folder");
        refreshAll();
    end

    function onFolderCleared(~, ~)
        S.rootFolder = "";
        S.session = [];
        S.report = emptyReport();
        S.statusMessage = "No RHS folder selected.";
        S.lastAction = "Cleared RHS folder";
        refreshAll();
    end

    function onProtocolChosen(~, event)
        paths = eventPaths(event);
        if isempty(paths)
            return;
        end
        S.protocolFile = paths(1);
        S.lastAction = "Selected protocol";
        addLog("Selected protocol: " + displayPath(S.protocolFile));
        if strlength(S.rootFolder) > 0
            scanSelectedFolder("Refreshed scan with protocol");
        end
        refreshAll();
    end

    function onProtocolCleared(~, ~)
        S.protocolFile = "";
        S.lastAction = "Cleared protocol";
        if strlength(S.rootFolder) > 0
            scanSelectedFolder("Refreshed scan without protocol");
        end
        refreshAll();
    end

    function onOutputFolderChosen(~, event)
        paths = eventPaths(event);
        if ~isempty(paths)
            S.outputFolder = paths(1);
            S.lastAction = "Selected output folder";
            refreshAll();
        end
    end

    function onOutputFolderCleared(~, ~)
        S.outputFolder = "";
        S.lastAction = "Cleared output folder";
        refreshAll();
    end

    function onSettingChanged(~, ~)
        S.minDurationSec = max(0, double(labkit.ui.view.getValue(ui, ...
            "minDurationSec")));
        S.requireExactBlocks = logical(labkit.ui.view.getValue(ui, ...
            "requireExactBlocks"));
        S.lastAction = "Updated QC options";
        if strlength(S.rootFolder) > 0
            scanSelectedFolder("Refreshed scan after QC option change");
        end
        refreshAll();
    end

    function onPreviewModeChanged(~, event)
        value = eventValue(event);
        if strlength(value) > 0
            S.previewMode = value;
        end
        refreshAll();
    end

    function onRecordingEdited(~, ~)
        if isempty(S.session)
            return;
        end
        data = labkit.ui.view.getValue(ui, "recordingsTable");
        [S.session, S.report] = rhs_screen.ops.applyRecordingsTableData( ...
            S.session, data);
        S.statusMessage = sprintf("Kept %d of %d RHS file(s).", ...
            S.report.keptCount, S.report.fileCount);
        S.lastAction = "Updated recording curation";
        refreshAll();
    end

    function onScanFolder(~, ~)
        if strlength(S.rootFolder) == 0
            S.statusMessage = "Select an RHS folder first.";
            refreshAll();
            return;
        end

        scanSelectedFolder("Screened RHS folder");
        refreshAll();
    end

    function onExportSession(~, ~)
        if isempty(S.session)
            S.statusMessage = "Scan a folder before exporting.";
            refreshAll();
            return;
        end
        if strlength(S.outputFolder) == 0
            S.statusMessage = "Select an output folder first.";
            refreshAll();
            return;
        end

        outputPath = fullfile(char(S.outputFolder), ...
            "rhs_screen_session.json");
        rhs_screen.export.writeSessionJson(S.session, outputPath);
        S.statusMessage = "Exported RHS screening session.";
        S.lastAction = "Exported session";
        addLog("Exported session JSON: " + displayPath(outputPath));
        refreshAll();
    end

    function onResetWorkflow(~, ~)
        S = defaultState();
        labkit.ui.view.setValue(ui, "minDurationSec", S.minDurationSec);
        labkit.ui.view.setValue(ui, "requireExactBlocks", S.requireExactBlocks);
        addLog("Reset RHS Screen state.");
        refreshAll();
    end

    function refreshAll()
        labkit.ui.view.setListItems(ui, "rhsFolder", cellstr(selectedList(S.rootFolder)));
        labkit.ui.view.setListItems(ui, "protocolFile", cellstr(selectedList(S.protocolFile)));
        labkit.ui.view.setListItems(ui, "outputFolder", cellstr(selectedList(S.outputFolder)));
        labkit.ui.view.setEnabled(ui, "scanFolder", strlength(S.rootFolder) > 0);
        labkit.ui.view.setEnabled(ui, "exportSession", ~isempty(S.session) && ...
            strlength(S.outputFolder) > 0);
        labkit.ui.view.setValue(ui, "statusField", char(S.statusMessage));
        labkit.ui.view.setValue(ui, "summaryTable", ...
            rhs_screen.view.summaryTableData(S));
        labkit.ui.view.setValue(ui, "recordingsTable", ...
            rhs_screen.view.recordingsTableData(S));
        ui.controls.details.textArea.Value = rhs_screen.view.detailLines(S);
        refreshPreview();
    end

    function refreshPreview()
        rhs_screen.view.drawQcPreview(ui.controls.preview.primaryAxes, S);
    end

    function addLog(message)
        labkit.ui.view.appendLog(ui, "logPanel", message);
        debugLog.append(message);
    end

    function ok = scanSelectedFolder(actionLabel)
        ok = false;
        if strlength(S.rootFolder) == 0
            S.statusMessage = "Select an RHS folder first.";
            return;
        end
        opts = struct( ...
            "minDurationSec", S.minDurationSec, ...
            "requireExactBlocks", S.requireExactBlocks, ...
            "protocol", loadProtocol(S.protocolFile));
        try
            [S.session, S.report] = rhs_screen.ops.screenFolder(S.rootFolder, opts);
        catch ME
            S.session = [];
            S.report = emptyReport();
            S.statusMessage = string(ME.message);
            S.lastAction = "Screen failed";
            addLog("RHS screen failed: " + S.statusMessage);
            return;
        end
        S.statusMessage = sprintf("Screened %d RHS file(s); kept %d.", ...
            S.report.fileCount, S.report.keptCount);
        S.lastAction = string(actionLabel);
        addLog(S.statusMessage);
        ok = true;
    end
end

function S = defaultState()
    S = struct( ...
        "rootFolder", "", ...
        "protocolFile", "", ...
        "outputFolder", "", ...
        "minDurationSec", 0, ...
        "requireExactBlocks", true, ...
        "previewMode", "QC", ...
        "session", [], ...
        "report", emptyReport(), ...
        "statusMessage", "No RHS folder selected.", ...
        "lastAction", "Ready");
end

function report = emptyReport()
    report = struct( ...
        "fileCount", 0, ...
        "acceptedCount", 0, ...
        "keptCount", 0, ...
        "needsReviewCount", 0, ...
        "failedCount", 0, ...
        "groupCount", 0);
end

function protocol = loadProtocol(protocolFile)
    protocol = struct();
    protocolFile = string(protocolFile);
    if strlength(protocolFile) == 0 || exist(char(protocolFile), "file") ~= 2
        return;
    end
    try
        protocol = jsondecode(fileread(char(protocolFile)));
    catch
        protocol = struct();
    end
end

function paths = eventPaths(event)
    paths = strings(0, 1);
    if isstruct(event) && isfield(event, "paths")
        paths = string(event.paths(:));
    elseif isobject(event) && isprop(event, "paths")
        paths = string(event.paths(:));
    end
end

function value = eventValue(event)
    value = "";
    if isstruct(event) && isfield(event, "value")
        value = string(event.value);
    elseif isobject(event) && isprop(event, "value")
        value = string(event.value);
    end
    if numel(value) > 1
        value = value(1);
    end
end

function items = selectedList(pathValue)
    pathValue = string(pathValue);
    if strlength(pathValue) == 0
        items = strings(0, 1);
    else
        items = displayPath(pathValue);
    end
end

function text = displayPath(pathValue)
    pathValue = string(pathValue);
    [~, base, ext] = fileparts(char(pathValue));
    text = string([base ext]);
    if strlength(text) == 0
        text = pathValue;
    end
end
