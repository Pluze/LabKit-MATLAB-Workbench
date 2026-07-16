% App-owned Runtime V2 actions for Gait Analysis. Handlers own pose loading,
% deterministic analysis, preview selection, and result export without UI
% reads, startup callbacks, or direct control mutation.
function actions = definitionActions()
    actions = struct( ...
        "openPoseFile", @onOpenPoseFile, ...
        "optionsChanged", @onOptionsChanged, ...
        "runAnalysis", @onRunAnalysis, ...
        "chooseOutputFolder", @onChooseOutputFolder, ...
        "exportResults", @onExportResults, ...
        "stepSelected", @onStepSelected, ...
        "previousStep", @onPreviousStep, ...
        "nextStep", @onNextStep);
end

function state = onOpenPoseFile(state, event, services)
    filepath = firstEventPath(event, services);
    if strlength(filepath) == 0
        state = services.workflow.log(state, "Pose file selection cancelled.");
        return;
    end
    try
        pose = gait_analysis.sourceFiles.readPoseFile(filepath);
    catch ME
        services.diagnostics.report("Pose load failed", ME);
        services.dialogs.alert(ME.message, "Could not load pose file");
        state = services.workflow.log(state, "Pose load failed: " + ME.message);
        return;
    end
    state.project.inputs.sources = services.project.sourceRecord( ...
        "pose", "poseCoordinates", filepath, true);
    state.project.parameters = gait_analysis.appState.optionsForPose( ...
        pose, state.project.parameters);
    state.project.results.analysis = gait_analysis.appState.emptyResult();
    state.project.results.lastExport = [];
    state.session.cache.filepath = filepath;
    state.session.cache.pose = pose;
    state.session.cache.lastRunFingerprint = "";
    state.session.selection.currentStepIndex = 1;
    state.session.workflow.outputFolder = string( ...
        services.dialogs.defaultOutputFolder(filepath, ...
        "gait_analysis", state.session.workflow.outputFolder));
    state = services.workflow.log(state, "Loaded pose file: " + filepath);
end

function state = onOptionsChanged(state, ~, ~)
    state.project.parameters = sanitizeOptions(state.project.parameters);
    state.project.results.analysis = gait_analysis.appState.emptyResult();
    state.project.results.analysis.message = ...
        "Analysis options changed; rerun analysis.";
    state.project.results.lastExport = [];
    state.session.cache.lastRunFingerprint = "";
end

function state = onRunAnalysis(state, ~, services)
    pose = state.session.cache.pose;
    if ~pose.ok
        services.dialogs.alert( ...
            "Open a current Video Marker MAT before running gait analysis.", ...
            "No pose data");
        return;
    end
    options = sanitizeOptions(state.project.parameters);
    task = gait_analysis.appState.runTask( ...
        state.session.cache.filepath, pose, options);
    if state.project.results.analysis.ok && ...
            state.session.cache.lastRunFingerprint == task.fingerprint
        state = services.workflow.log(state, ...
            "Gait analysis is already up to date; skipped duplicate run.");
        return;
    end
    try
        result = gait_analysis.analysisRun.computeGait(pose, options);
    catch ME
        services.diagnostics.report("Gait analysis failed", ME);
        services.dialogs.alert(ME.message, "Gait analysis failed");
        state = services.workflow.log(state, ...
            "Gait analysis failed: " + ME.message);
        return;
    end
    state.project.parameters = options;
    state.project.results.analysis = result;
    state.project.results.lastExport = [];
    state.session.cache.lastRunFingerprint = task.fingerprint;
    state.session.selection.currentStepIndex = 1;
    state = services.workflow.log(state, sprintf( ...
        "Gait analysis complete: %d valid step(s).", ...
        validStepCount(result.stepTable)));
end

function state = onChooseOutputFolder(state, ~, services)
    [folder, cancelled] = services.dialogs.outputFolder( ...
        "Choose gait analysis output folder", ...
        state.session.workflow.outputFolder);
    if cancelled
        state = services.workflow.log(state, ...
            "Output folder selection cancelled.");
        return;
    end
    state.session.workflow.outputFolder = string(folder);
    state = services.workflow.log(state, "Output folder: " + string(folder));
end

function state = onExportResults(state, ~, services)
    result = state.project.results.analysis;
    if ~result.ok
        services.dialogs.alert( ...
            "Run gait analysis before exporting CSV files.", "No result");
        return;
    end
    folder = state.session.workflow.outputFolder;
    if strlength(folder) == 0
        folder = string(services.dialogs.defaultOutputFolder( ...
            state.session.cache.filepath, "gait_analysis", ""));
        state.session.workflow.outputFolder = folder;
    end
    [~, stem] = fileparts(state.session.cache.filepath);
    if strlength(string(stem)) == 0
        stem = "gait_analysis";
    end
    try
        outputs = gait_analysis.resultFiles.writeOutputs(folder, stem, result);
    catch ME
        services.diagnostics.report("Gait export failed", ME);
        services.dialogs.alert(ME.message, "Could not export gait CSV files");
        return;
    end
    resultOutputs = [ ...
        outputFor(services, "frames", outputs.frameCsv); ...
        outputFor(services, "coordinates", outputs.coordinateCsv); ...
        outputFor(services, "steps", outputs.stepCsv); ...
        outputFor(services, "summary", outputs.summaryCsv)];
    spec = struct( ...
        "Outputs", resultOutputs, "Inputs", state.project.inputs.sources, ...
        "Parameters", state.project.parameters, ...
        "Summary", struct("validStepCount", ...
        validStepCount(result.stepTable)), ...
        "ManifestName", string(stem) + "_gait.labkit.json");
    [manifestPath, ~] = services.results.writeManifest(folder, spec);
    state.project.results.lastExport = struct( ...
        "outputs", outputs, "manifestPath", string(manifestPath));
    state = services.workflow.log(state, ...
        "Exported gait CSV set and manifest: " + string(manifestPath));
end

function state = onStepSelected(state, event, ~)
    if isempty(event.indices)
        return;
    end
    state.session.selection.currentStepIndex = selectedStep( ...
        state, event.indices(1));
end

function state = onPreviousStep(state, ~, ~)
    state.session.selection.currentStepIndex = selectedStep( ...
        state, state.session.selection.currentStepIndex - 1);
end

function state = onNextStep(state, ~, ~)
    state.session.selection.currentStepIndex = selectedStep( ...
        state, state.session.selection.currentStepIndex + 1);
end

function value = selectedStep(state, requested)
    count = height(state.project.results.analysis.stepTable);
    if count == 0
        value = 1;
    else
        value = min(max(1, round(double(requested))), count);
    end
end

function output = outputFor(services, id, filepath)
    [~, name, extension] = fileparts(filepath);
    output = services.results.output(id, "primary", ...
        string(name) + string(extension), "text/csv");
end

function options = sanitizeOptions(options)
    defaults = gait_analysis.appState.defaultOptions();
    numeric = ["frameRate", "pixelsPerUnit", "smoothWindow", ...
        "detectionProminence", "detectionMinHeightSigma", ...
        "minLiftOffIntervalSeconds", "minSwingFrames", ...
        "maxSwingFrames", "minStepLength", "maxHipTranslation"];
    for name = numeric
        value = double(options.(name));
        if isempty(value) || ~isscalar(value) || ~isfinite(value)
            options.(name) = defaults.(name);
        end
    end
    options.originAtFirstFrameFirstPoint = ...
        logical(options.originAtFirstFrameFirstPoint);
end

function count = validStepCount(value)
    count = 0;
    if ~isempty(value)
        count = sum(value.is_valid);
    end
end

function filepath = firstEventPath(event, services)
    paths = services.events.paths(event, "files");
    if isempty(paths)
        paths = services.events.paths(event, "addedFiles");
    end
    filepath = "";
    if ~isempty(paths)
        filepath = paths(1);
    end
end
