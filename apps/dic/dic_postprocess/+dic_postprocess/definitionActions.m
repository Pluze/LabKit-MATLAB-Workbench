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
    filepath = firstEventPath(event);
    if strlength(filepath) == 0
        state = addLog(state, services, "DIC MAT selection cancelled.");
        return;
    end
    state.project.inputs.matPath = filepath;
    state.project.inputs.strain = struct();
    state.project.inputs.sources = setSource( ...
        state.project.inputs.sources, "dicMat", "strain", filepath);
    state = clearPreparedOutputs(state);
    state = addLog(state, services, "Selected DIC MAT: " + filepath);
end

function state = onReferenceChosen(state, event, services)
    filepath = firstEventPath(event);
    if strlength(filepath) == 0
        state = addLog(state, services, ...
            "Reference image selection cancelled.");
        return;
    end
    state.project.inputs.referencePath = filepath;
    state.project.inputs.referenceImage = imread(filepath);
    state.project.inputs.sources = setSource( ...
        state.project.inputs.sources, "referenceImage", "reference", filepath);
    state = clearPreparedOutputs(state);
    state = addLog(state, services, "Loaded reference image: " + filepath);
end

function state = onMaskChosen(state, event, services)
    filepath = firstEventPath(event);
    if strlength(filepath) == 0
        state = addLog(state, services, "Mask image selection cancelled.");
        return;
    end
    state.project.inputs.maskPath = filepath;
    state.project.inputs.maskImage = imread(filepath);
    state.project.inputs.sources = setSource( ...
        state.project.inputs.sources, "maskImage", "mask", filepath);
    state = clearPreparedOutputs(state);
    state = addLog(state, services, "Loaded mask image: " + filepath);
end

function state = onGenerate(state, ~, services)
    inputs = state.project.inputs;
    if strlength(inputs.matPath) == 0 || isempty(inputs.referenceImage) || ...
            isempty(inputs.maskImage)
        labkit.ui.runtime.showAlert(services.figure, ...
            'Load the DIC MAT file, reference image, and mask image first.', ...
            'Missing inputs');
        return;
    end
    if ~validColorRange(state.project.parameters)
        labkit.ui.runtime.showAlert(services.figure, ...
            'Color max must be greater than color min.', 'Invalid color range');
        return;
    end
    try
        state.project.inputs.strain = ...
            dic_postprocess.sourceFiles.loadNcorrStrain(char(inputs.matPath));
        state = prepareOutputs(state);
        state = addLog(state, services, ...
            "Generated EXX/EYY overlays and ROI summary.");
    catch ME
        reportException(services, 'Generate failed', ME);
        labkit.ui.runtime.showAlert(services.figure, ME.message, ...
            'DIC postprocess error');
        state = addLog(state, services, "Generate failed: " + ME.message);
    end
end

function state = onOptionsChanged(state, ~, services)
    if ~hasPreparedInputs(state.project.inputs)
        return;
    end
    if ~validColorRange(state.project.parameters)
        state = addLog(state, services, ...
            "Option update skipped: Color max must exceed color min.");
        return;
    end
    try
        state = prepareOutputs(state);
    catch ME
        reportException(services, 'Option update skipped', ME);
        state = addLog(state, services, ...
            "Option update skipped: " + ME.message);
    end
end

function state = onSaveOverlays(state, ~, services)
    if isempty(state.session.cache.overlayExx) || ...
            isempty(state.session.cache.overlayEyy)
        labkit.ui.runtime.showAlert(services.figure, ...
            'Generate overlays before saving.', 'Save overlays');
        return;
    end
    [folder, cancelled] = promptOverlayFolder(services);
    if cancelled
        state = addLog(state, services, "Save overlay PNGs cancelled.");
        return;
    end
    tag = string(dic_postprocess.userInterface.tagFromPath( ...
        char(state.project.inputs.matPath)));
    exxName = "overlay_exx_" + tag + ".png";
    eyyName = "overlay_eyy_" + tag + ".png";
    exxFile = fullfile(folder, exxName);
    eyyFile = fullfile(folder, eyyName);
    dic_postprocess.resultFiles.exportOverlayImage( ...
        state.session.cache.overlayExx, exxFile);
    dic_postprocess.resultFiles.exportOverlayImage( ...
        state.session.cache.overlayEyy, eyyFile);
    outputs = [resultOutput("exxOverlay", "primary", exxName, "image/png"); ...
        resultOutput("eyyOverlay", "primary", eyyName, "image/png")];
    spec = resultSpec(state, outputs);
    spec.ManifestName = "dic_overlays_" + tag + ".labkit.json";
    [manifestPath, ~] = services.results.writeManifest(folder, spec);
    state.project.results.overlayManifestPath = string(manifestPath);
    state = addLog(state, services, ...
        "Saved clean overlay PNGs: " + exxFile + " and " + eyyFile);
end

function state = onExportSummary(state, ~, services)
    summary = state.project.results.summaryTable;
    if isempty(summary) || height(summary) == 0
        labkit.ui.runtime.showAlert(services.figure, ...
            'Generate a summary before exporting.', 'Export summary');
        return;
    end
    [out, cancelled] = promptSummaryFile(state.project.inputs.matPath, services);
    if cancelled
        state = addLog(state, services, "Export summary cancelled.");
        return;
    end
    writetable(summary, out);
    [folder, base, extension] = fileparts(out);
    outputName = string(base) + string(extension);
    spec = resultSpec(state, resultOutput( ...
        "strainSummary", "primary", outputName, "text/csv"));
    spec.ManifestName = string(base) + ".labkit.json";
    [manifestPath, ~] = services.results.writeManifest(folder, spec);
    state.project.results.summaryManifestPath = string(manifestPath);
    state = addLog(state, services, "Exported summary CSV: " + string(out));
end

function state = prepareOutputs(state)
    [summary, overlayExx, overlayEyy] = ...
        dic_postprocess.analysisRun.prepareOutputs( ...
        state.project.inputs, state.project.parameters);
    state.project.results.summaryTable = summary;
    state.session.cache.overlayExx = overlayExx;
    state.session.cache.overlayEyy = overlayEyy;
end

function state = clearPreparedOutputs(state)
    state.project.results.summaryTable = table();
    state.session.cache.overlayExx = [];
    state.session.cache.overlayEyy = [];
end

function tf = hasPreparedInputs(inputs)
    tf = isfield(inputs.strain, 'exx') && ...
        ~isempty(inputs.referenceImage) && ~isempty(inputs.maskImage);
end

function tf = validColorRange(parameters)
    tf = parameters.colorMax > parameters.colorMin;
end

function filepath = firstEventPath(event)
    filepath = "";
    if ~isfield(event, 'meta') || ~isfield(event.meta, 'original') || ...
            ~isfield(event.meta.original, 'addedFiles')
        return;
    end
    files = event.meta.original.addedFiles;
    if isstruct(files) && ~isempty(files) && isfield(files, 'path')
        filepath = string(files(1).path);
    elseif ~isempty(files)
        values = string(files(:));
        filepath = values(1);
    end
end

function sources = setSource(sources, id, role, filepath)
    source = sourceRecord(id, role, filepath);
    if isempty(sources)
        sources = source;
        return;
    end
    match = find(string({sources.id}) == id, 1, 'first');
    if isempty(match)
        sources(end + 1) = source;
    else
        sources(match) = source;
    end
end

function source = sourceRecord(id, role, filepath)
    [~, name, extension] = fileparts(filepath);
    reference = struct( ...
        "schemaVersion", 1, "relativePath", "", ...
        "originalPath", string(filepath), ...
        "fileName", string(name) + string(extension));
    source = struct("id", string(id), "required", true, ...
        "role", string(role), "reference", reference);
end

function [folder, cancelled] = promptOverlayFolder(services)
    promptArgs = {};
    if isstruct(services.request) && ...
            isfield(services.request, 'outputFolderChooser') && ...
            isa(services.request.outputFolderChooser, 'function_handle')
        promptArgs = {'Chooser', services.request.outputFolderChooser};
    end
    [folder, cancelled] = labkit.ui.runtime.promptOutputFolder( ...
        'Select folder for overlay PNGs', "", promptArgs{:});
end

function [out, cancelled] = promptSummaryFile(matPath, services)
    [folder, name] = fileparts(char(matPath));
    folder = labkit.ui.runtime.defaultDialogFolder("output", folder);
    defaultName = fullfile(folder, [name '_strain_summary.csv']);
    promptArgs = {};
    if isstruct(services.request) && ...
            isfield(services.request, 'outputFileChooser') && ...
            isa(services.request.outputFileChooser, 'function_handle')
        promptArgs = {'Chooser', services.request.outputFileChooser};
    end
    [out, cancelled] = labkit.ui.runtime.promptOutputFile( ...
        '*.csv', 'Save strain summary CSV', defaultName, promptArgs{:});
end

function output = resultOutput(id, role, pathValue, mediaType)
    output = struct("Id", string(id), "Role", string(role), ...
        "Path", string(pathValue), "MediaType", string(mediaType), ...
        "Status", "success", "Message", "");
end

function spec = resultSpec(state, outputs)
    spec = struct();
    spec.Outputs = outputs;
    spec.Inputs = state.project.inputs.sources;
    spec.Parameters = state.project.parameters;
    spec.Summary = struct("metricCount", ...
        height(state.project.results.summaryTable));
end

function state = addLog(state, services, message)
    message = string(message);
    state.session.workflow.logLines(end + 1, 1) = message;
    if isDebugEnabled(services.debug)
        services.debug.append(char(message));
    end
end

function reportException(services, context, exception)
    if isstruct(services.debug) && isfield(services.debug, 'reportException')
        services.debug.reportException('dicPostprocess', context, exception);
    end
end

function tf = isDebugEnabled(debugLog)
    tf = isstruct(debugLog) && isfield(debugLog, 'enabled') && ...
        logical(debugLog.enabled);
end
