% Expected caller: labkit_NerveResponseAnalysis_app. Input is a debug
% context prepared by labkit.ui.app.dispatchRequest. Output is the app
% figure. Side effects are GUI creation, lazy RHS analysis, optional JSON
% export, and debug trace attachment.
function fig = run(debugLog)
%RUN Build and run the Nerve Response Analysis app.

    S = defaultState();
    callbacks = struct( ...
        "sessionChosen", @onSessionChosen, ...
        "sessionCleared", @onSessionCleared, ...
        "protocolChosen", @onProtocolChosen, ...
        "protocolCleared", @onProtocolCleared, ...
        "outputFolderChosen", @(~, ~) onOutputFolderChosen(), ...
        "outputFolderCleared", @(~, ~) onOutputFolderCleared(), ...
        "settingChanged", @onSettingChanged, ...
        "previewModeChanged", @onPreviewModeChanged, ...
        "runAnalysis", @onRunAnalysis, ...
        "exportAnalysis", @onExportAnalysis, ...
        "resetWorkflow", @onResetWorkflow);

    spec = nerve_response_analysis.ui.buildSpec(callbacks);
    ui = labkit.ui.app.create(spec, "debug", debugLog);
    fig = ui.figure;

    if debugLog.enabled
        debugLog.trace("Nerve Response Analysis debug trace enabled.");
        debugLog.instrumentFigure(fig);
    end

    refreshAll();
    addLog("Nerve Response Analysis ready.");

    function onSessionChosen(~, event)
        paths = eventPaths(event);
        if isempty(paths)
            return;
        end
        S.sessionFile = paths(1);
        S.outputFolder = string(labkit.ui.app.defaultOutputFolder( ...
            paths, "nerve_response_analysis", S.outputFolder));
        S.analysis = [];
        S.statusMessage = "Filter record selected.";
        S.lastAction = "Selected filter record";
        addLog("Selected filter record: " + displayPath(S.sessionFile));
        refreshAll();
    end

    function onSessionCleared(~, ~)
        S.sessionFile = "";
        S.analysis = [];
        S.statusMessage = "No filter record selected.";
        S.lastAction = "Cleared filter record";
        refreshAll();
    end

    function onProtocolChosen(~, event)
        paths = eventPaths(event);
        if isempty(paths)
            return;
        end
        S.protocolFile = paths(1);
        if ~isempty(S.analysis)
            S.analysis = [];
            S.statusMessage = "Protocol selected. Analyze session to refresh.";
        end
        S.lastAction = "Selected protocol";
        addLog("Selected protocol: " + displayPath(S.protocolFile));
        refreshAll();
    end

    function onProtocolCleared(~, ~)
        S.protocolFile = "";
        if ~isempty(S.analysis)
            S.analysis = [];
            S.statusMessage = "Protocol cleared. Analyze session to refresh.";
        end
        S.lastAction = "Cleared protocol";
        refreshAll();
    end

    function onOutputFolderChosen()
        [folder, cancelled] = labkit.ui.app.promptOutputFolder( ...
            "Select analysis output folder", S.outputFolder);
        if cancelled
            S.lastAction = "Output folder selection cancelled";
            refreshAll();
            return;
        end
        S.outputFolder = string(folder);
        S.lastAction = "Selected output folder";
        refreshAll();
    end

    function onOutputFolderCleared()
        S.outputFolder = "";
        S.lastAction = "Cleared output folder";
        refreshAll();
    end

    function onSettingChanged(~, ~)
        S.maxRecordings = finiteNonnegativeScalar( ...
            labkit.ui.view.getValue(ui, "maxRecordings"), S.maxRecordings);
        S.maxDurationSec = finiteNonnegativeScalar( ...
            labkit.ui.view.getValue(ui, "maxDurationSec"), S.maxDurationSec);
        if ~isempty(S.analysis)
            S.analysis = [];
            S.statusMessage = "Analysis options changed. Analyze session to refresh.";
        end
        S.lastAction = "Updated analysis options";
        refreshAll();
    end

    function onPreviewModeChanged(~, event)
        value = eventValue(event);
        if strlength(value) > 0
            S.previewMode = value;
        end
        refreshAll();
    end

    function onRunAnalysis(~, ~)
        if strlength(S.sessionFile) == 0
            S.statusMessage = "Select a filter record first.";
            refreshAll();
            return;
        end
        try
            session = jsondecode(fileread(char(S.sessionFile)));
            protocol = loadProtocol(S.protocolFile);
            opts = struct();
            if S.maxRecordings > 0
                opts.maxRecordings = S.maxRecordings;
            end
            if S.maxDurationSec > 0
                opts.maxDurationSec = S.maxDurationSec;
            end
            S.analysis = nerve_response_analysis.ops.analyzeSession( ...
                session, protocol, opts);
        catch ME
            debugLog.reportException('nerveResponseAnalysis', 'Analysis failed', ME);
            S.analysis = [];
            S.statusMessage = string(ME.message);
            S.lastAction = "Analysis failed";
            addLog("Analysis failed: " + S.statusMessage);
            refreshAll();
            return;
        end
        S.statusMessage = sprintf("Analyzed %d recording(s).", ...
            S.analysis.analyzedCount);
        S.lastAction = "Analyzed filter record";
        addLog(S.statusMessage);
        refreshAll();
    end

    function onExportAnalysis(~, ~)
        if isempty(S.analysis)
            S.statusMessage = "Run analysis before exporting.";
            refreshAll();
            return;
        end
        if strlength(S.outputFolder) == 0
            S.statusMessage = "Select an output folder first.";
            refreshAll();
            return;
        end
        outputPath = fullfile(char(S.outputFolder), ...
            "nerve_response_analysis.json");
        nerve_response_analysis.export.writeAnalysisJson(S.analysis, outputPath);
        S.statusMessage = "Exported nerve-response analysis.";
        S.lastAction = "Exported analysis";
        addLog("Exported analysis JSON: " + displayPath(outputPath));
        refreshAll();
    end

    function onResetWorkflow(~, ~)
        S = defaultState();
        labkit.ui.view.setValue(ui, "maxRecordings", S.maxRecordings);
        labkit.ui.view.setValue(ui, "maxDurationSec", S.maxDurationSec);
        addLog("Reset Nerve Response Analysis state.");
        refreshAll();
    end

    function refreshAll()
        labkit.ui.view.setValue(ui, "sessionFile", fileValue(S.sessionFile));
        labkit.ui.view.setValue(ui, "protocolFile", fileValue(S.protocolFile));
        labkit.ui.view.setValue(ui, "outputFolder", char(outputFolderText(S.outputFolder)));
        labkit.ui.view.setEnabled(ui, "runAnalysis", strlength(S.sessionFile) > 0);
        labkit.ui.view.setEnabled(ui, "exportAnalysis", ~isempty(S.analysis) && ...
            strlength(S.outputFolder) > 0);
        labkit.ui.view.setValue(ui, "statusField", char(S.statusMessage));
        ui.controls.summaryTable.table.Data = ...
            nerve_response_analysis.view.summaryTableData(S);
        ui.controls.details.textArea.Value = ...
            nerve_response_analysis.view.detailLines(S);
        refreshPreview();
    end

    function refreshPreview()
        nerve_response_analysis.view.drawAnalysisPreview( ...
            ui.controls.preview.primaryAxes, S);
    end

    function addLog(message)
        labkit.ui.view.appendLog(ui, "logPanel", message);
        debugLog.append(message);
    end
end

function S = defaultState()
    S = struct( ...
        "sessionFile", "", ...
        "protocolFile", "", ...
        "outputFolder", "", ...
        "maxRecordings", 0, ...
        "maxDurationSec", 0, ...
        "previewMode", "Counts", ...
        "analysis", [], ...
        "statusMessage", "No filter record selected.", ...
        "lastAction", "Ready");
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
    files = struct([]);
    if isstruct(event) && isfield(event, "addedFiles")
        files = event.addedFiles;
    elseif isobject(event) && isprop(event, "addedFiles")
        files = event.addedFiles;
    elseif isstruct(event) && isfield(event, "selectedFiles")
        files = event.selectedFiles;
    elseif isobject(event) && isprop(event, "selectedFiles")
        files = event.selectedFiles;
    end
    paths = labkit.ui.view.filePaths(files);
    if ~(isstring(paths) && iscolumn(paths))
        error('nerve_response_analysis:InvalidPathEvent', ...
            'filePanel event file paths must be a string column.');
    end
end

function value = finiteNonnegativeScalar(value, fallback)
    value = double(value);
    if isempty(value) || ~isscalar(value) || ~isfinite(value)
        value = fallback;
        return;
    end
    value = max(0, value);
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

function items = fileValue(pathValue)
    pathValue = string(pathValue);
    if strlength(pathValue) == 0
        items = strings(0, 1);
        return;
    end
    items = pathValue;
end

function text = outputFolderText(pathValue)
    pathValue = string(pathValue);
    if strlength(pathValue) == 0
        text = "No output folder selected";
        return;
    end
    text = pathValue;
end

function text = displayPath(pathValue)
    pathValue = string(pathValue);
    [~, base, ext] = fileparts(char(pathValue));
    text = string([base ext]);
    if strlength(text) == 0
        text = pathValue;
    end
end
