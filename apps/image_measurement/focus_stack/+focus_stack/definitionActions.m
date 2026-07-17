% App-owned V2 actions for Focus Stack. Handlers own source registration,
% fusion, compact durable results, session caches, and exports without UI access.
function actions = definitionActions()
    actions = struct( ...
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

function state = onSourceFolderChosen(state, ~, services)
    [folder, cancelled] = services.dialogs.inputFolder( ...
        "Choose focus image folder", sourceFolder(state));
    if cancelled
        state = services.workflow.log(state, ...
            "Focus image folder selection cancelled.");
        return;
    end
    try
        paths = focus_stack.sourceFiles.findImages(folder);
    catch ME
        state = reportFailure(state, services, ...
            "Could not load focus image folder", ME);
        return;
    end
    state = registerPaths(state, paths, folder, services, sprintf( ...
        'Loaded %d focus image file(s) from folder.', numel(paths)));
end

function state = onOpenFilesChosen(state, event, services)
    paths = services.events.paths(event, "files");
    if isempty(paths)
        paths = services.events.paths(event, "addedFiles");
    end
    if isempty(paths)
        state = services.workflow.log(state, "Image selection cancelled.");
        return;
    end
    state = registerPaths(state, paths, fileparts(paths(1)), services, ...
        sprintf('Loaded %d focus image file(s).', numel(paths)));
end

function state = registerPaths(state, paths, folder, services, message)
    oldSources = state.project.inputs.sources;
    sources = services.project.reconcileSources( ...
        oldSources, paths, "focus-image", "image", true);
    try
        images = focus_stack.sourceFiles.readImages( ...
            labkit.ui.runtime.sourcePaths(sources));
    catch ME
        state = reportFailure(state, services, "Could not load focus stack", ME);
        return;
    end
    state.project.inputs.sources = sources;
    state.project.parameters.outputFolder = string( ...
        services.dialogs.defaultOutputFolder(string(folder), ...
        "focus_stack", state.project.parameters.outputFolder));
    state.session.cache.images = images;
    state = invalidateRun(state);
    state = services.workflow.log(state, message);
end

function state = onRemoveImages(state, event, services)
    sources = state.project.inputs.sources;
    indices = services.events.indices(event, "removedFiles", numel(sources));
    if isempty(indices)
        return;
    end
    sources(indices) = [];
    if numel(sources) < 2
        state = clearSources(state);
        state = services.workflow.log(state, ...
            "At least two focus image files are required; cleared the stack.");
        return;
    end
    paths = labkit.ui.runtime.sourcePaths(sources);
    state = registerPaths(state, paths, ...
        fileparts(paths(1)), services, sprintf( ...
        'Removed image file(s); %d remaining.', numel(sources)));
end

function state = onClearImages(state, ~, services)
    state = clearSources(state);
    state = services.workflow.log(state, ...
        "Cleared loaded focus images and results.");
end

function state = clearSources(state)
    state.project.inputs.sources = state.project.inputs.sources([]);
    state.session.cache.images = {};
    state = invalidateRun(state);
end

function state = onFusionPresetChanged(state, ~, services)
    preset = state.project.parameters.fusionPreset;
    settings = focus_stack.analysisRun.fusionPresetSettings(preset);
    state.project.parameters.focusWindow = settings.focusWindow;
    state.project.parameters.smoothRadius = settings.smoothRadius;
    state.project.parameters.uncertainBlend = settings.minConfidencePercent;
    state = invalidateRun(state);
    state = services.workflow.log(state, "Fusion preset set to " + preset + ".");
end

function state = onFusionOptionsChanged(state, ~, ~)
    state.project.parameters = normalizeParameters(state.project.parameters);
    state = invalidateRun(state);
end

function state = onRunFocusStack(state, ~, services)
    images = state.session.cache.images;
    if numel(images) < 2
        services.dialogs.alert( ...
            "Load at least two images before running focus stacking.", ...
            "Not enough images");
        return;
    end
    p = normalizeParameters(state.project.parameters);
    state.project.parameters = p;
    opts = fusionOptions(p);
    paths = labkit.ui.runtime.sourcePaths(state.project.inputs.sources);
    task = focus_stack.analysisRun.runTask( ...
        paths, images, opts, p.autoRegister);
    if state.session.cache.result.ok && ...
            state.project.results.lastRunFingerprint == task.fingerprint
        state = services.workflow.log(state, ...
            "Focus stack result is already up to date; skipped duplicate run.");
        return;
    end
    try
        [imagesForFusion, registrationLines] = prepareImages( ...
            images, p.autoRegister);
        result = focus_stack.analysisRun.computeFocusStack(imagesForFusion, opts);
    catch ME
        state = reportFailure(state, services, "Focus stacking failed", ME);
        return;
    end
    state.session.cache.alignedImages = imagesForFusion;
    state.session.cache.result = result;
    state.session.workflow.registrationLines = string(registrationLines(:));
    state.project.results.lastRun = compactResult(result);
    state.project.results.lastRunFingerprint = task.fingerprint;
    state.project.results.registrationLines = string(registrationLines(:));
    state.project.results.lastExport = [];
    state.project.results.resultManifestPath = "";
    state = services.workflow.log(state, sprintf( ...
        'Focus stack complete: %d images fused with %s.', ...
        result.inputCount, result.method));
    for line = string(registrationLines(:)).'
        state = services.workflow.log(state, line);
    end
end

function [images, lines] = prepareImages(images, autoRegister)
    lines = strings(0, 1);
    if autoRegister
        [images, rawLines] = focus_stack.analysisRun.alignImages(images);
        lines = string(rawLines(:));
    end
end

function state = onExportFused(state, ~, services)
    state = exportResult(state, services, "fused", ...
        "Export fused PNG", "focus_stack_fused.png");
end

function state = onExportFocusMap(state, ~, services)
    state = exportResult(state, services, "focus-map", ...
        "Export focus map PNG", "focus_stack_map.png");
end

function state = onExportSummary(state, ~, services)
    state = exportResult(state, services, "summary", ...
        "Export summary CSV", "focus_stack_summary.csv");
end

function state = exportResult(state, services, kind, titleText, defaultName)
    result = state.session.cache.result;
    if ~result.ok
        services.dialogs.alert( ...
            "Run focus stack before exporting results.", "No result");
        return;
    end
    defaultPath = fullfile(char(defaultOutputFolder(state, services)), defaultName);
    [filepath, cancelled] = services.dialogs.outputFile( ...
        {'*.png;*.csv', 'Export files'}, titleText, defaultPath);
    if cancelled
        state = services.workflow.log(state, titleText + " cancelled.");
        return;
    end
    try
        mediaType = writeOutput(kind, result, ...
            labkit.ui.runtime.sourcePaths( ...
            state.project.inputs.sources), filepath);
        [~, outputName, outputExtension] = fileparts(filepath);
        output = services.results.output(kind, kind, ...
            string(outputName) + string(outputExtension), mediaType);
        folder = string(fileparts(filepath));
        spec = struct( ...
            "Outputs", output, ...
            "Inputs", state.project.inputs.sources, ...
            "Parameters", state.project.parameters, ...
            "Summary", compactResult(result), ...
            "ManifestName", "focus_stack.labkit.json");
        [manifestPath, ~] = services.results.writeManifest(folder, spec);
    catch ME
        state = reportFailure(state, services, "Could not export result", ME);
        return;
    end
    state.project.results.lastExport = struct( ...
        "kind", string(kind), "outputPath", string(filepath), ...
        "manifestPath", string(manifestPath));
    state.project.results.resultManifestPath = string(manifestPath);
    state = services.workflow.log(state, ...
        "Exported " + kind + ": " + string(filepath));
end

function mediaType = writeOutput(kind, result, paths, filepath)
    switch kind
        case "fused"
            labkit.image.writeFile(result.fused, filepath);
            mediaType = "image/png";
        case "focus-map"
            imageData = focus_stack.userInterface.focusIndexRgb( ...
                result.focusIndex, result.inputCount);
            labkit.image.writeFile(imageData, filepath);
            mediaType = "image/png";
        otherwise
            writetable(focus_stack.resultFiles.buildSummaryTable( ...
                result, paths), filepath);
            mediaType = "text/csv";
    end
end

function state = invalidateRun(state)
    state.session.cache.alignedImages = {};
    state.session.cache.result = focus_stack.analysisRun.emptyResult();
    state.session.workflow.registrationLines = strings(0, 1);
    state.project.results.lastRun = focus_stack.analysisRun.emptyResult();
    state.project.results.lastRunFingerprint = "";
    state.project.results.registrationLines = strings(0, 1);
    state.project.results.lastExport = [];
    state.project.results.resultManifestPath = "";
end

function result = compactResult(result)
    for field = ["fused", "focusIndex", "confidence"]
        name = char(field);
        if isfield(result, name)
            result = rmfield(result, name);
        end
    end
end

function opts = fusionOptions(parameters)
    opts = struct( ...
        "focusWindow", parameters.focusWindow, ...
        "smoothRadius", parameters.smoothRadius, ...
        "minConfidence", parameters.uncertainBlend / 100);
end

function parameters = normalizeParameters(parameters)
    parameters.focusWindow = finiteScalar( ...
        parameters.focusWindow, 31, 3, 99, true);
    parameters.smoothRadius = finiteScalar( ...
        parameters.smoothRadius, 4, 0, 50, true);
    parameters.uncertainBlend = finiteScalar( ...
        parameters.uncertainBlend, 5, 0, 100, false);
    parameters.autoRegister = logical(parameters.autoRegister);
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

function folder = sourceFolder(state)
    paths = labkit.ui.runtime.sourcePaths(state.project.inputs.sources);
    folder = "";
    if ~isempty(paths)
        folder = string(fileparts(paths(1)));
    end
end

function folder = defaultOutputFolder(state, services)
    folder = string(state.project.parameters.outputFolder);
    if strlength(folder) == 0 || exist(char(folder), 'dir') ~= 7
        folder = services.dialogs.defaultFolder("output");
    end
end

function state = reportFailure(state, services, context, exception)
    services.diagnostics.report(context, exception);
    services.dialogs.alert(exception.message, context);
    state = services.workflow.log(state, context + ": " + exception.message);
end
