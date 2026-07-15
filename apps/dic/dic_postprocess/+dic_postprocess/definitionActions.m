% App-owned V2 action registry for DIC Postprocess. Handlers receive canonical
% state/events/services and own source loading, overlay generation, and export
% side effects without reading or mutating UI controls.
function actions = definitionActions()
    actions = struct( ...
        "matChosen", @onMatChosen, ...
        "referenceChosen", @onReferenceChosen, ...
        "maskChosen", @onMaskChosen, ...
        "generate", @onGenerate, ...
        "optionsChanged", @onOptionsChanged, ...
        "saveOverlays", @onSaveOverlays, ...
        "exportSummary", @onExportSummary);
end

function state = onMatChosen(state, event, services)
    filepath = firstEventPath(event, services);
    if strlength(filepath) == 0
        state = services.workflow.log(state, "DIC MAT selection cancelled.");
        return;
    end
    state.project.inputs.sources = services.project.upsertSource( ...
        state.project.inputs.sources, "dicMat", "strain", filepath, true);
    state.session.cache.strain = struct();
    state = clearPreparedOutputs(state);
    state = services.workflow.log(state, "Selected DIC MAT: " + filepath);
end

function state = onReferenceChosen(state, event, services)
    filepath = firstEventPath(event, services);
    if strlength(filepath) == 0
        state = services.workflow.log(state, ...
            "Reference image selection cancelled.");
        return;
    end
    state.session.cache.referenceImage = imread(filepath);
    state.project.inputs.sources = services.project.upsertSource( ...
        state.project.inputs.sources, "referenceImage", "reference", ...
        filepath, true);
    state = clearPreparedOutputs(state);
    state = services.workflow.log(state, "Loaded reference image: " + filepath);
end

function state = onMaskChosen(state, event, services)
    filepath = firstEventPath(event, services);
    if strlength(filepath) == 0
        state = services.workflow.log(state, "Mask image selection cancelled.");
        return;
    end
    state.session.cache.maskImage = imread(filepath);
    state.project.inputs.sources = services.project.upsertSource( ...
        state.project.inputs.sources, "maskImage", "mask", filepath, true);
    state = clearPreparedOutputs(state);
    state = services.workflow.log(state, "Loaded mask image: " + filepath);
end

function state = onGenerate(state, ~, services)
    matPath = sourcePath(state, "dicMat");
    cache = state.session.cache;
    if strlength(matPath) == 0 || isempty(cache.referenceImage) || ...
            isempty(cache.maskImage)
        services.dialogs.alert( ...
            'Load the DIC MAT file, reference image, and mask image first.', ...
            'Missing inputs');
        return;
    end
    if ~validColorRange(state.project.parameters)
        services.dialogs.alert( ...
            'Color max must be greater than color min.', 'Invalid color range');
        return;
    end
    try
        state.session.cache.strain = ...
            dic_postprocess.sourceFiles.loadNcorrStrain(matPath);
        state = prepareOutputs(state);
        state = services.workflow.log(state, ...
            "Generated EXX/EYY overlays and ROI summary.");
    catch ME
        services.diagnostics.report('Generate failed', ME);
        services.dialogs.alert(ME.message, ...
            'DIC postprocess error');
        state = services.workflow.log(state, "Generate failed: " + ME.message);
    end
end

function state = onOptionsChanged(state, ~, services)
    if ~hasPreparedInputs(state.session.cache)
        return;
    end
    if ~validColorRange(state.project.parameters)
        state = services.workflow.log(state, ...
            "Option update skipped: Color max must exceed color min.");
        return;
    end
    try
        state = prepareOutputs(state);
    catch ME
        services.diagnostics.report('Option update skipped', ME);
        state = services.workflow.log(state, ...
            "Option update skipped: " + ME.message);
    end
end

function state = onSaveOverlays(state, ~, services)
    if isempty(state.session.cache.overlayExx) || ...
            isempty(state.session.cache.overlayEyy)
        services.dialogs.alert( ...
            'Generate overlays before saving.', 'Save overlays');
        return;
    end
    [folder, cancelled] = services.dialogs.outputFolder( ...
        'Select folder for overlay PNGs', "");
    if cancelled
        state = services.workflow.log(state, "Save overlay PNGs cancelled.");
        return;
    end
    tag = string(dic_postprocess.userInterface.tagFromPath( ...
        char(sourcePath(state, "dicMat"))));
    exxName = "overlay_exx_" + tag + ".png";
    eyyName = "overlay_eyy_" + tag + ".png";
    exxFile = fullfile(folder, exxName);
    eyyFile = fullfile(folder, eyyName);
    dic_postprocess.resultFiles.exportOverlayImage( ...
        state.session.cache.overlayExx, exxFile);
    dic_postprocess.resultFiles.exportOverlayImage( ...
        state.session.cache.overlayEyy, eyyFile);
    outputs = [services.results.output( ...
        "exxOverlay", "primary", exxName, "image/png"); ...
        services.results.output( ...
        "eyyOverlay", "primary", eyyName, "image/png")];
    spec = resultSpec(state, outputs);
    spec.ManifestName = "dic_overlays_" + tag + ".labkit.json";
    [manifestPath, ~] = services.results.writeManifest(folder, spec);
    state.project.results.overlayManifestPath = string(manifestPath);
    state = services.workflow.log(state, ...
        "Saved clean overlay PNGs: " + exxFile + " and " + eyyFile);
end

function state = onExportSummary(state, ~, services)
    summary = state.project.results.summaryTable;
    if isempty(summary) || height(summary) == 0
        services.dialogs.alert( ...
            'Generate a summary before exporting.', 'Export summary');
        return;
    end
    [folder, name] = fileparts(char(sourcePath(state, "dicMat")));
    folder = services.dialogs.defaultFolder("output", folder);
    defaultName = fullfile(folder, [name '_strain_summary.csv']);
    [out, cancelled] = services.dialogs.outputFile( ...
        '*.csv', 'Save strain summary CSV', defaultName);
    if cancelled
        state = services.workflow.log(state, "Export summary cancelled.");
        return;
    end
    writetable(summary, out);
    [folder, base, extension] = fileparts(out);
    outputName = string(base) + string(extension);
    spec = resultSpec(state, services.results.output( ...
        "strainSummary", "primary", outputName, "text/csv"));
    spec.ManifestName = string(base) + ".labkit.json";
    [manifestPath, ~] = services.results.writeManifest(folder, spec);
    state.project.results.summaryManifestPath = string(manifestPath);
    state = services.workflow.log(state, "Exported summary CSV: " + string(out));
end

function state = prepareOutputs(state)
    [summary, overlayExx, overlayEyy] = ...
        dic_postprocess.analysisRun.prepareOutputs( ...
        state.session.cache, state.project.parameters);
    state.project.results.summaryTable = summary;
    state.session.cache.overlayExx = overlayExx;
    state.session.cache.overlayEyy = overlayEyy;
end

function state = clearPreparedOutputs(state)
    state.project.results.summaryTable = table();
    state.session.cache.overlayExx = [];
    state.session.cache.overlayEyy = [];
end

function filepath = sourcePath(state, id)
    filepath = dic_postprocess.sourceFiles.pathForId( ...
        state.project.inputs.sources, id);
end

function tf = hasPreparedInputs(inputs)
    tf = isfield(inputs.strain, 'exx') && ...
        ~isempty(inputs.referenceImage) && ~isempty(inputs.maskImage);
end

function tf = validColorRange(parameters)
    tf = parameters.colorMax > parameters.colorMin;
end

function filepath = firstEventPath(event, services)
    paths = services.events.paths(event, "addedFiles");
    filepath = "";
    if ~isempty(paths)
        filepath = paths(1);
    end
end

function spec = resultSpec(state, outputs)
    spec = struct();
    spec.Outputs = outputs;
    spec.Inputs = state.project.inputs.sources;
    spec.Parameters = state.project.parameters;
    spec.Summary = struct("metricCount", ...
        height(state.project.results.summaryTable));
end
