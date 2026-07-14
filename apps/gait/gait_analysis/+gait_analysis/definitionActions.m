% App-owned action registry for Gait Analysis. Expected caller is
% gait_analysis.definition. Handlers own pose loading, option snapshots,
% analysis runs, and CSV exports.
function actions = definitionActions()
    actions = struct( ...
        "startup", @onStartup, ...
        "openPoseFile", @onOpenPoseFile, ...
        "optionsChanged", @onOptionsChanged, ...
        "runAnalysis", @onRunAnalysis, ...
        "chooseOutputFolder", @onChooseOutputFolder, ...
        "exportResults", @onExportResults, ...
        "previewModeChanged", @onPreviewModeChanged);
end

function state = onStartup(state, ~, services)
    debugLog = services.debug;
    if debugLog.enabled
        debugLog.trace('Gait analysis debug trace enabled.');
        debugLog.instrumentFigure(services.figure);
        try
            pack = gait_analysis.debugArtifacts.writeSamplePack(debugLog);
            addLog(services, sprintf('Debug sample file: %s', char(pack.representativeFiles)));
        catch ME
            debugLog.reportException('gaitAnalysis', 'Debug sample setup failed', ME);
            addLog(services, sprintf('Debug sample setup failed: %s', ME.message));
        end
    end
end

function state = onOpenPoseFile(state, payload, services)
    paths = labkit.ui.control.filePaths(payload.event.files);
    if isempty(paths)
        paths = labkit.ui.control.filePaths(payload.event.addedFiles);
    end
    if isempty(paths)
        addLog(services, 'Pose file selection cancelled.');
        return;
    end
    filepath = string(paths(1));
    try
        pose = gait_analysis.sourceFiles.readPoseFile(filepath);
    catch ME
        showException(services, 'Could not load pose file', ME);
        return;
    end
    state.sourcePath = filepath;
    state.pose = pose;
    state.sourceSummary = sourceSummary(pose);
    state.outputFolder = string(labkit.ui.runtime.defaultOutputFolder( ...
        filepath, "gait_analysis", state.outputFolder));
    state.result = gait_analysis.appState.emptyResult();
    state.lastRunFingerprint = "";
    addLog(services, sprintf('Loaded pose file: %s', filepath));
end

function state = onOptionsChanged(state, ~, services)
    state.options = collectOptions(services.ui, state.options);
    if state.result.ok
        state.result.message = "Analysis options changed; rerun analysis.";
    end
    state.lastRunFingerprint = "";
end

function state = onRunAnalysis(state, ~, services)
    if ~state.pose.ok
        showError(services, 'No pose data', ...
            'Load a pose coordinate file before running gait analysis.');
        return;
    end
    opts = collectOptions(services.ui, state.options);
    task = gait_analysis.appState.runTask(state.sourcePath, state.pose, opts);
    if state.result.ok && state.lastRunFingerprint == task.fingerprint
        addLog(services, 'Gait analysis is already up to date; skipped duplicate run.');
        return;
    end
    try
        result = gait_analysis.analysisRun.computeGait(state.pose, opts);
    catch ME
        showException(services, 'Gait analysis failed', ME);
        return;
    end
    state.options = opts;
    state.result = result;
    state.lastRunFingerprint = task.fingerprint;
    addLog(services, sprintf('Gait analysis complete: %d valid step(s).', ...
        validStepCount(result.stepTable)));
end

function state = onChooseOutputFolder(state, ~, services)
    startFolder = labkit.ui.runtime.defaultDialogFolder("output", state.outputFolder);
    folder = uigetdir(startFolder, 'Choose gait analysis output folder');
    if isequal(folder, 0)
        addLog(services, 'Output folder selection cancelled.');
        return;
    end
    state.outputFolder = string(folder);
    addLog(services, sprintf('Output folder: %s', folder));
end

function state = onExportResults(state, ~, services)
    if ~state.result.ok
        showError(services, 'No result', ...
            'Run gait analysis before exporting CSV files.');
        return;
    end
    if strlength(state.outputFolder) == 0
        state.outputFolder = string(labkit.ui.runtime.defaultOutputFolder( ...
            state.sourcePath, "gait_analysis", state.outputFolder));
    end
    [~, stem] = fileparts(state.sourcePath);
    if strlength(string(stem)) == 0
        stem = "gait_analysis";
    end
    try
        outputs = gait_analysis.resultFiles.writeOutputs( ...
            state.outputFolder, stem, state.result);
    catch ME
        showException(services, 'Could not export gait CSV files', ME);
        return;
    end
    addLog(services, sprintf('Exported frame CSV: %s', outputs.frameCsv));
    addLog(services, sprintf('Exported coordinate CSV: %s', outputs.coordinateCsv));
    addLog(services, sprintf('Exported step CSV: %s', outputs.stepCsv));
    addLog(services, sprintf('Exported summary CSV: %s', outputs.summaryCsv));
end

function state = onPreviewModeChanged(state, payload, ~)
    if isfield(payload, "event") && isfield(payload.event, "value")
        state.previewMode = string(payload.event.value);
    end
end

function opts = collectOptions(ui, previous)
    opts = previous;
    opts.iliacPoint = string(labkit.ui.control.getValue(ui, 'iliacPoint'));
    opts.hipPoint = string(labkit.ui.control.getValue(ui, 'hipPoint'));
    opts.kneePoint = string(labkit.ui.control.getValue(ui, 'kneePoint'));
    opts.anklePoint = string(labkit.ui.control.getValue(ui, 'anklePoint'));
    opts.footPoint = string(labkit.ui.control.getValue(ui, 'footPoint'));
    opts.frameRate = finiteScalar(labkit.ui.control.getValue(ui, 'frameRate'), ...
        previous.frameRate);
    opts.pixelsPerUnit = finiteScalar(labkit.ui.control.getValue(ui, 'pixelsPerUnit'), ...
        previous.pixelsPerUnit);
    opts.unitName = string(labkit.ui.control.getValue(ui, 'unitName'));
    opts.originAtFirstFrameFirstPoint = logicalScalar( ...
        labkit.ui.control.getValue(ui, 'originAtFirstFrameFirstPoint'), ...
        previous.originAtFirstFrameFirstPoint);
    opts.smoothWindow = finiteScalar(labkit.ui.control.getValue(ui, 'smoothWindow'), ...
        previous.smoothWindow);
    opts.minStepFrames = finiteScalar(labkit.ui.control.getValue(ui, 'minStepFrames'), ...
        previous.minStepFrames);
    opts.maxStepFrames = finiteScalar(labkit.ui.control.getValue(ui, 'maxStepFrames'), ...
        previous.maxStepFrames);
    opts.minStride = finiteScalar(labkit.ui.control.getValue(ui, 'minStride'), ...
        previous.minStride);
    opts.maxBodyDrift = finiteScalar(labkit.ui.control.getValue(ui, 'maxBodyDrift'), ...
        previous.maxBodyDrift);
end

function value = logicalScalar(value, fallback)
    if isempty(value)
        value = fallback;
    elseif islogical(value) || isnumeric(value)
        value = logical(value(1));
    else
        text = lower(string(value));
        value = text == "true" || text == "1" || text == "on";
    end
end

function value = finiteScalar(value, fallback)
    value = double(value);
    if ~isscalar(value) || ~isfinite(value)
        value = fallback;
    end
end

function text = sourceSummary(pose)
    text = sprintf('%d frames | %d points | %s | unit %s', ...
        size(pose.coords, 1), numel(pose.pointNames), ...
        char(pose.sourceFormat), char(pose.unitName));
end

function count = validStepCount(stepTable)
    if isempty(stepTable)
        count = 0;
    else
        count = sum(stepTable.is_valid);
    end
end

function addLog(services, message)
    if isfield(services, 'ui')
        labkit.ui.control.appendLog(services.ui, 'appLog', message);
    end
end

function showError(services, titleText, message)
    labkit.ui.runtime.showAlert(services.figure, message, titleText);
    addLog(services, sprintf('%s: %s', titleText, message));
end

function showException(services, titleText, ME)
    services.debug.reportException('gaitAnalysis', titleText, ME);
    labkit.ui.runtime.showAlert(services.figure, ME.message, titleText);
    addLog(services, sprintf('%s: %s', titleText, ME.message));
end
