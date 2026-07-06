% App-owned action table for Nerve Response Analysis. Expected caller is
% nerve_response_analysis.definition. Output maps semantic action ids to
% handlers used by labkit.ui.runtime.run. Handlers own workflow transitions,
% analysis, and export side effects.
function actions = definitionActions()
    actions = struct( ...
        "startup", @onStartup, ...
        "sessionChosen", @onSessionChosen, ...
        "sessionCleared", @onSessionCleared, ...
        "protocolChosen", @onProtocolChosen, ...
        "protocolCleared", @onProtocolCleared, ...
        "outputFolderChosen", @onOutputFolderChosen, ...
        "outputFolderCleared", @onOutputFolderCleared, ...
        "settingChanged", @onSettingChanged, ...
        "previewModeChanged", @onPreviewModeChanged, ...
        "runAnalysis", @onRunAnalysis, ...
        "exportAnalysis", @onExportAnalysis, ...
        "resetWorkflow", @onResetWorkflow);
end

function state = onStartup(state, ~, services)
    debugLog = services.debug;
    if isDebugEnabled(debugLog)
        debugLog.trace("Nerve Response Analysis debug trace enabled.");
        debugLog.instrumentFigure(services.figure);
        state = setupDebugSamples(state, services);
    end
    addLog(services, "Nerve Response Analysis ready.");
end

function state = onSessionChosen(state, payload, services)
    paths = eventPaths(payload.event);
    if isempty(paths)
        return;
    end
    state.sessionFile = paths(1);
    state.outputFolder = string(labkit.ui.runtime.defaultOutputFolder( ...
        paths, "nerve_response_analysis", state.outputFolder));
    state.analysis = [];
    state.statusMessage = "Filter record selected.";
    state.lastAction = "Selected filter record";
    addLog(services, "Selected filter record: " + displayPath(state.sessionFile));
end

function state = onSessionCleared(state, ~, ~)
    state.sessionFile = "";
    state.analysis = [];
    state.statusMessage = "No filter record selected.";
    state.lastAction = "Cleared filter record";
end

function state = onProtocolChosen(state, payload, services)
    paths = eventPaths(payload.event);
    if isempty(paths)
        return;
    end
    state.protocolFile = paths(1);
    if ~isempty(state.analysis)
        state.analysis = [];
        state.statusMessage = "Protocol selected. Analyze session to refresh.";
    end
    state.lastAction = "Selected protocol";
    addLog(services, "Selected protocol: " + displayPath(state.protocolFile));
end

function state = onProtocolCleared(state, ~, ~)
    state.protocolFile = "";
    if ~isempty(state.analysis)
        state.analysis = [];
        state.statusMessage = "Protocol cleared. Analyze session to refresh.";
    end
    state.lastAction = "Cleared protocol";
end

function state = onOutputFolderChosen(state, ~, services)
    [folder, cancelled] = labkit.ui.runtime.promptOutputFolder( ...
        "Select analysis output folder", state.outputFolder);
    if cancelled
        state.lastAction = "Output folder selection cancelled";
        return;
    end
    state.outputFolder = string(folder);
    state.lastAction = "Selected output folder";
    addLog(services, "Selected output folder: " + displayPath(state.outputFolder));
end

function state = onOutputFolderCleared(state, ~, ~)
    state.outputFolder = "";
    state.lastAction = "Cleared output folder";
end

function state = onSettingChanged(state, ~, services)
    state.maxRecordings = finiteNonnegativeScalar( ...
        labkit.ui.control.getValue(services.ui, "maxRecordings"), ...
        state.maxRecordings);
    state.maxDurationSec = finiteNonnegativeScalar( ...
        labkit.ui.control.getValue(services.ui, "maxDurationSec"), ...
        state.maxDurationSec);
    if ~isempty(state.analysis)
        state.analysis = [];
        state.statusMessage = ...
            "Analysis options changed. Analyze session to refresh.";
    end
    state.lastAction = "Updated analysis options";
end

function state = onPreviewModeChanged(state, payload, ~)
    value = eventValue(payload.event);
    if strlength(value) > 0
        state.previewMode = value;
    end
end

function state = onRunAnalysis(state, ~, services)
    if strlength(state.sessionFile) == 0
        state.statusMessage = "Select a filter record first.";
        return;
    end
    try
        session = jsondecode(fileread(char(state.sessionFile)));
        protocol = loadProtocol(state.protocolFile);
        opts = struct();
        if state.maxRecordings > 0
            opts.maxRecordings = state.maxRecordings;
        end
        if state.maxDurationSec > 0
            opts.maxDurationSec = state.maxDurationSec;
        end
        state.analysis = nerve_response_analysis.analysisRun.analyzeSession( ...
            session, protocol, opts);
    catch ME
        services.debug.reportException('nerveResponseAnalysis', ...
            'Analysis failed', ME);
        state.analysis = [];
        state.statusMessage = string(ME.message);
        state.lastAction = "Analysis failed";
        addLog(services, "Analysis failed: " + state.statusMessage);
        return;
    end
    state.statusMessage = sprintf("Analyzed %d recording(s).", ...
        state.analysis.analyzedCount);
    state.lastAction = "Analyzed filter record";
    addLog(services, state.statusMessage);
end

function state = onExportAnalysis(state, ~, services)
    if isempty(state.analysis)
        state.statusMessage = "Run analysis before exporting.";
        return;
    end
    if strlength(state.outputFolder) == 0
        state.statusMessage = "Select an output folder first.";
        return;
    end
    outputPath = fullfile(char(state.outputFolder), ...
        "nerve_response_analysis.json");
    nerve_response_analysis.resultFiles.writeAnalysisJson(state.analysis, outputPath);
    state.statusMessage = "Exported nerve-response analysis.";
    state.lastAction = "Exported analysis";
    addLog(services, "Exported analysis JSON: " + displayPath(outputPath));
end

function state = onResetWorkflow(~, ~, services)
    state = nerve_response_analysis.appLifecycle.createInitialState();
    addLog(services, "Reset Nerve Response Analysis state.");
end

function state = setupDebugSamples(state, services)
    debugLog = services.debug;
    try
        pack = nerve_response_analysis.debug.writeSamplePack(debugLog);
        addLog(services, "Debug sample files: " + string(pack.sampleFolder));
        addLog(services, "Debug output folder: " + string(pack.outputFolder));
    catch ME
        debugLog.reportException('nerveResponseAnalysis', ...
            'Debug sample setup failed', ME);
        addLog(services, "Debug sample setup failed: " + string(ME.message));
    end
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
    paths = labkit.ui.control.filePaths(files);
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

function text = displayPath(pathValue)
    pathValue = string(pathValue);
    [~, base, ext] = fileparts(char(pathValue));
    text = string([base ext]);
    if strlength(text) == 0
        text = pathValue;
    end
end

function addLog(services, message)
    labkit.ui.control.appendLog(services.ui, "logPanel", message);
    if isDebugEnabled(services.debug)
        services.debug.append(message);
    end
end

function tf = isDebugEnabled(debugLog)
    tf = isstruct(debugLog) && isfield(debugLog, 'enabled') && ...
        logical(debugLog.enabled);
end
