% App-owned action registry for Focus Stack. Expected caller is
% focus_stack.definition. Output maps semantic action ids to handlers used by
% labkit.ui.runtime.run. Handlers own image loading, fusion, exports, and debug
% sample setup.
function actions = definitionActions()
    actions = struct( ...
        "startup", @onStartup, ...
        "sourceImagesChosen", @onOpenFilesChosen, ...
        "sourceFolderChosen", @onSourceFolderChosen, ...
        "removeImages", @onRemoveImages, ...
        "clearImages", @onClearImages, ...
        "fusionPresetChanged", @onFusionPresetChanged, ...
        "fusionOptionsChanged", @onFusionOptionsChanged, ...
        "runFocusStack", @onRunFocusStack, ...
        "exportFused", @onExportFused, ...
        "exportFocusMap", @onExportFocusMap, ...
        "exportSummary", @onExportSummary);
end

function state = onStartup(state, ~, services)
    debugLog = services.debug;
    if ~isDebugEnabled(debugLog)
        return;
    end
    debugLog.trace('Focus stack debug trace enabled.');
    debugLog.instrumentFigure(services.figure);
    try
        pack = focus_stack.debug.writeSamplePack(debugLog);
        addLog(services, sprintf('Debug sample files: %s', char(pack.sampleFolder)));
        addLog(services, sprintf('Debug output folder: %s', char(pack.outputFolder)));
    catch ME
        debugLog.reportException('focusStack', 'Debug sample setup failed', ME);
        addLog(services, sprintf('Debug sample setup failed: %s', ME.message));
    end
end

function state = onSourceFolderChosen(state, ~, services)
    startFolder = labkit.ui.runtime.defaultDialogFolder("input", state.folder);
    folder = uigetdir(startFolder, 'Choose focus image folder');
    if isequal(folder, 0)
        addLog(services, 'Focus image folder selection cancelled.');
        return;
    end
    try
        paths = focus_stack.sourceFiles.findImages(folder);
    catch ME
        showException(services, 'Could not load focus image folder', ME);
        return;
    end
    state = loadImagePaths(state, paths, string(labkit.ui.runtime.defaultOutputFolder( ...
        string(folder), "focus_stack", state.folder)), ...
        sprintf('Selected image folder %s', char(string(folder))), ...
        sprintf('Loaded %d focus image file(s) from folder.', numel(paths)), ...
        services);
end

function state = onOpenFilesChosen(state, payload, services)
    paths = labkit.ui.control.filePaths(payload.event.files);
    if isempty(paths)
        paths = labkit.ui.control.filePaths(payload.event.addedFiles);
    end
    if isempty(paths)
        addLog(services, 'Image selection cancelled.');
        return;
    end
    state = loadImagePaths(state, paths, string(labkit.ui.runtime.defaultOutputFolder( ...
        paths, "focus_stack", state.folder)), ...
        sprintf('Selected image files from %s', char(fileparts(paths(1)))), ...
        sprintf('Loaded %d focus image file(s).', numel(paths)), services);
end

function state = onClearImages(state, ~, services)
    state = focus_stack.appLifecycle.createInitialState();
    addLog(services, 'Cleared loaded focus images and results.');
end

function state = onRemoveImages(state, payload, services)
    removeIdx = labkit.ui.control.fileIndices(payload.event.removedFiles, ...
        numel(state.paths));
    if isempty(removeIdx)
        return;
    end
    paths = state.paths;
    paths(removeIdx) = [];
    if numel(paths) < 2
        state = onClearImages(state, [], services);
        addLog(services, 'At least two focus image files are required.');
        return;
    end
    state = loadImagePaths(state, paths, string(labkit.ui.runtime.defaultOutputFolder( ...
        paths, "focus_stack", state.folder)), ...
        sprintf('Selected image files from %s', char(fileparts(paths(1)))), ...
        sprintf('Removed image file(s); %d remaining.', numel(paths)), services);
end

function state = loadImagePaths(state, paths, sourceFolder, sourceDescription, ...
        logMessage, services)
    try
        images = focus_stack.sourceFiles.readImages(paths);
    catch ME
        showException(services, 'Could not load focus stack', ME);
        return;
    end

    state.paths = string(paths(:));
    state.images = images;
    state.alignedImages = {};
    state.registrationLines = {};
    state.result = focus_stack.appState.emptyResult();
    state.lastRunFingerprint = "";
    state.folder = string(sourceFolder);
    state.sourceLocation = string(sourceDescription);
    addLog(services, logMessage);
end

function state = onRunFocusStack(state, ~, services)
    if numel(state.images) < 2
        showError(services, 'Not enough images', ...
            'Load at least two images before running focus stacking.');
        return;
    end

    opts = currentFusionOptions(services.ui);
    registerStack = labkit.ui.control.getValue(services.ui, 'autoRegister');
    task = focus_stack.appState.runTask(state.paths, state.images, opts, ...
        registerStack);
    if state.result.ok && state.lastRunFingerprint == task.fingerprint
        addLog(services, ...
            'Focus stack result is already up to date; skipped duplicate run.');
        return;
    end
    try
        payload = runFocusStackComputation(state, opts, registerStack);
    catch ME
        showException(services, 'Focus stacking failed', ME);
        return;
    end

    state.alignedImages = payload.imagesForFusion;
    state.registrationLines = payload.registrationLines;
    state.result = payload.result;
    state.lastRunFingerprint = task.fingerprint;
    addLog(services, sprintf('Focus stack complete: %d images fused with %s.', ...
        state.result.inputCount, state.result.method));
    for k = 1:numel(state.registrationLines)
        addLog(services, state.registrationLines{k});
    end
end

function state = onFusionPresetChanged(state, ~, services)
    ui = services.ui;
    settings = focus_stack.appState.fusionPresetSettings( ...
        labkit.ui.control.getValue(ui, 'fusionPreset'));
    labkit.ui.control.setValue(ui, 'focusWindow', settings.focusWindow);
    labkit.ui.control.setValue(ui, 'smoothRadius', settings.smoothRadius);
    labkit.ui.control.setValue(ui, 'uncertainBlend', ...
        settings.minConfidencePercent);
    state = markResultDirty(state);
    addLog(services, sprintf('Fusion preset set to %s.', ...
        labkit.ui.control.getValue(ui, 'fusionPreset')));
end

function state = onFusionOptionsChanged(state, ~, ~)
    state = markResultDirty(state);
end

function payload = runFocusStackComputation(state, opts, registerStack)
    imagesForFusion = state.images;
    registrationLines = {};
    if registerStack
        [imagesForFusion, registrationLines] = ...
            focus_stack.analysisRun.alignImages(state.images);
    end

    payload = struct();
    payload.imagesForFusion = imagesForFusion;
    payload.registrationLines = registrationLines;
    payload.result = focus_stack.analysisRun.computeFocusStack(imagesForFusion, opts);
end

function state = onExportFused(state, ~, services)
    if ~state.result.ok
        showError(services, 'No fused image', ...
            'Run focus stack before exporting the fused PNG.');
        return;
    end
    filepath = chooseSavePath(state, 'Export fused PNG', ...
        'focus_stack_fused.png');
    if filepath == ""
        addLog(services, 'Export fused PNG cancelled.');
        return;
    end
    try
        labkit.image.writeFile(state.result.fused, filepath);
    catch ME
        showException(services, 'Could not export fused PNG', ME);
        return;
    end
    addLog(services, sprintf('Exported fused PNG: %s', filepath));
end

function state = onExportFocusMap(state, ~, services)
    if ~state.result.ok
        showError(services, 'No focus map', ...
            'Run focus stack before exporting the focus map PNG.');
        return;
    end
    filepath = chooseSavePath(state, 'Export focus map PNG', ...
        'focus_stack_map.png');
    if filepath == ""
        addLog(services, 'Export focus map PNG cancelled.');
        return;
    end
    try
        labkit.image.writeFile(focus_stack.userInterface.focusIndexRgb( ...
            state.result.focusIndex, state.result.inputCount), filepath);
    catch ME
        showException(services, 'Could not export focus map PNG', ME);
        return;
    end
    addLog(services, sprintf('Exported focus map PNG: %s', filepath));
end

function state = onExportSummary(state, ~, services)
    if ~state.result.ok
        showError(services, 'No summary', ...
            'Run focus stack before exporting the summary CSV.');
        return;
    end
    filepath = chooseSavePath(state, 'Export summary CSV', ...
        'focus_stack_summary.csv');
    if filepath == ""
        addLog(services, 'Export summary CSV cancelled.');
        return;
    end
    try
        T = focus_stack.resultFiles.buildSummaryTable(state.result, state.paths);
        writetable(T, filepath);
    catch ME
        showException(services, 'Could not export summary CSV', ME);
        return;
    end
    addLog(services, sprintf('Exported summary CSV: %s', filepath));
end

function opts = currentFusionOptions(ui)
    opts = struct();
    opts.focusWindow = finiteScalar(labkit.ui.control.getValue(ui, ...
        'focusWindow'), 7, 3, inf, true);
    opts.smoothRadius = finiteScalar(labkit.ui.control.getValue(ui, ...
        'smoothRadius'), 1, 0, inf, true);
    opts.minConfidence = finiteScalar(labkit.ui.control.getValue(ui, ...
        'uncertainBlend'), 25, 0, 100, false) / 100;
end

function filepath = chooseSavePath(state, titleText, defaultName)
    defaultPath = fullfile(defaultSaveFolder(state), defaultName);
    [filepath, cancelled] = labkit.ui.runtime.promptOutputFile( ...
        {'*.png;*.csv', 'Export files'}, titleText, defaultPath);
    if cancelled
        filepath = "";
    end
end

function folder = defaultSaveFolder(state)
    folder = char(state.folder);
    if isempty(folder) || exist(folder, 'dir') ~= 7
        folder = labkit.ui.runtime.defaultDialogFolder("output");
    end
end

function state = markResultDirty(state)
    if state.result.ok
        state.result = focus_stack.appState.emptyResult();
        state.alignedImages = {};
        state.registrationLines = {};
    end
    state.lastRunFingerprint = "";
end

function showError(services, titleText, message)
    addLog(services, sprintf('%s: %s', titleText, message));
    labkit.ui.runtime.showAlert(services.figure, message, titleText);
end

function showException(services, titleText, exception)
    if isDebugEnabled(services.debug)
        services.debug.reportException('focusStack', titleText, exception);
    end
    showError(services, titleText, exception.message);
end

function addLog(services, message)
    labkit.ui.control.appendLog(services.ui, 'logPanel', message);
    if isDebugEnabled(services.debug)
        services.debug.append(message);
    end
end

function value = finiteScalar(value, fallback, minValue, maxValue, roundValue)
    value = double(value);
    if isempty(value) || ~isscalar(value) || ~isfinite(value)
        value = fallback;
    end
    value = min(max(value, minValue), maxValue);
    if roundValue
        value = round(value);
    end
end

function tf = isDebugEnabled(debugLog)
    tf = isstruct(debugLog) && isfield(debugLog, 'enabled') && ...
        logical(debugLog.enabled);
end
