% App-owned action registry for DIC Postprocess. Expected caller is
% dic_postprocess.definition. Output maps semantic action ids to handlers
% used by labkit.ui.app.run. Handlers own workflow transitions, overlay
% generation, and export side effects.
function actions = definitionActions()
    actions = struct( ...
        "startup", @onStartup, ...
        "matChosen", @onMatChosen, ...
        "matCleared", @onMatCleared, ...
        "referenceChosen", @onReferenceChosen, ...
        "referenceCleared", @onReferenceCleared, ...
        "maskChosen", @onMaskChosen, ...
        "maskCleared", @onMaskCleared, ...
        "generate", @onGenerate, ...
        "optionsChanged", @onOptionsChanged, ...
        "saveOverlays", @onSaveOverlays, ...
        "exportSummary", @onExportSummary);
end

function state = onStartup(state, ~, services)
    debugLog = services.debug;
    if ~isDebugEnabled(debugLog)
        return;
    end
    debugLog.trace('DIC postprocess debug trace enabled.');
    try
        pack = dic_postprocess.debug.writeSamplePack(debugLog);
        addLog(services, sprintf('Debug sample files: %s', char(pack.sampleFolder)));
        addLog(services, sprintf('Debug output folder: %s', char(pack.outputFolder)));
    catch ME
        debugLog.reportException('dicPostprocess', ...
            'Debug sample setup failed', ME);
        addLog(services, sprintf('Debug sample setup failed: %s', ME.message));
    end
end

function state = onMatChosen(state, payload, services)
    paths = labkit.ui.view.filePaths(payload.event.addedFiles);
    if isempty(paths)
        addLog(services, 'DIC MAT selection cancelled.');
        return;
    end
    state.matPath = paths(1);
    addLog(services, sprintf('Selected DIC MAT: %s', state.matPath));
end

function state = onMatCleared(state, ~, services)
    state.matPath = "";
    state.strain = struct();
    state = clearOutputs(state);
    addLog(services, 'Cleared DIC MAT task.');
end

function state = onReferenceChosen(state, payload, services)
    paths = labkit.ui.view.filePaths(payload.event.addedFiles);
    if isempty(paths)
        addLog(services, 'Reference image selection cancelled.');
        return;
    end
    filepath = paths(1);
    state.referencePath = filepath;
    state.referenceImage = imread(filepath);
    addLog(services, sprintf('Loaded reference image: %s', filepath));
end

function state = onReferenceCleared(state, ~, services)
    state.referencePath = "";
    state.referenceImage = [];
    state = clearOutputs(state);
    addLog(services, 'Cleared reference image file.');
end

function state = onMaskChosen(state, payload, services)
    paths = labkit.ui.view.filePaths(payload.event.addedFiles);
    if isempty(paths)
        addLog(services, 'Mask image selection cancelled.');
        return;
    end
    filepath = paths(1);
    state.maskPath = filepath;
    state.maskImage = imread(filepath);
    addLog(services, sprintf('Loaded mask image: %s', filepath));
end

function state = onMaskCleared(state, ~, services)
    state.maskPath = "";
    state.maskImage = [];
    state = clearOutputs(state);
    addLog(services, 'Cleared mask image file.');
end

function state = onGenerate(state, ~, services)
    if strlength(state.matPath) == 0 || isempty(state.referenceImage) || ...
            isempty(state.maskImage)
        labkit.ui.app.showAlert(services.figure, ...
            'Load the DIC MAT file, reference image, and mask image first.', ...
            'Missing inputs');
        return;
    end
    opts = overlayOptionsFromControls(services.ui);
    if opts.colorRange(2) <= opts.colorRange(1)
        labkit.ui.app.showAlert(services.figure, ...
            'Color max must be greater than color min.', 'Invalid color range');
        return;
    end

    try
        state.strain = dic_postprocess.sourceFiles.loadNcorrStrain(char(state.matPath));
        state = renderOverlays(state, opts);
        addLog(services, 'Generated EXX/EYY overlays and ROI summary.');
    catch ME
        services.debug.reportException('dicPostprocess', 'Generate failed', ME);
        labkit.ui.app.showAlert(services.figure, ME.message, ...
            'DIC postprocess error');
        addLog(services, sprintf('Generate failed: %s', ME.message));
    end
end

function state = onOptionsChanged(state, ~, services)
    if isfield(state.strain, 'exx') && ~isempty(state.referenceImage) && ...
            ~isempty(state.maskImage)
        try
            state = renderOverlays(state, overlayOptionsFromControls(services.ui));
        catch ME
            services.debug.reportException('dicPostprocess', ...
                'Option update skipped', ME);
            addLog(services, sprintf('Option update skipped: %s', ME.message));
        end
    end
end

function state = onSaveOverlays(state, ~, services)
    if isempty(state.overlayExx) || isempty(state.overlayEyy)
        labkit.ui.app.showAlert(services.figure, ...
            'Generate overlays before saving.', 'Save overlays');
        return;
    end

    [folder, cancelled] = labkit.ui.app.promptOutputFolder( ...
        'Select folder for overlay PNGs', "");
    if cancelled
        addLog(services, 'Save overlay PNGs cancelled.');
        return;
    end

    tag = dic_postprocess.userInterface.tagFromPath(char(state.matPath));
    exxFile = fullfile(folder, sprintf('overlay_exx_%s.png', tag));
    eyyFile = fullfile(folder, sprintf('overlay_eyy_%s.png', tag));
    dic_postprocess.resultFiles.exportOverlayImage(state.overlayExx, exxFile);
    dic_postprocess.resultFiles.exportOverlayImage(state.overlayEyy, eyyFile);
    addLog(services, sprintf('Saved clean overlay PNGs: %s and %s', ...
        exxFile, eyyFile));
end

function state = onExportSummary(state, ~, services)
    if isempty(state.summaryTable) || height(state.summaryTable) == 0
        labkit.ui.app.showAlert(services.figure, ...
            'Generate a summary before exporting.', 'Export summary');
        return;
    end

    [folder, name] = fileparts(char(state.matPath));
    folder = labkit.ui.app.defaultDialogFolder("output", folder);
    defaultName = fullfile(folder, [name '_strain_summary.csv']);
    [out, cancelled] = labkit.ui.app.promptOutputFile( ...
        '*.csv', 'Save strain summary CSV', defaultName);
    if cancelled
        addLog(services, 'Export summary cancelled.');
        return;
    end

    writetable(state.summaryTable, out);
    addLog(services, sprintf('Exported summary CSV: %s', char(out)));
end

function state = renderOverlays(state, opts)
    overlayMask = dic_postprocess.analysisRun.imageMask(state.maskImage, ...
        dic_postprocess.analysisRun.imageHeightWidth(state.referenceImage));
    state.overlayExx = dic_postprocess.analysisRun.makeStrainOverlay( ...
        state.referenceImage, state.strain.exx, overlayMask, ...
        state.strain.roiMask, opts);
    state.overlayEyy = dic_postprocess.analysisRun.makeStrainOverlay( ...
        state.referenceImage, state.strain.eyy, overlayMask, ...
        state.strain.roiMask, opts);
    summaryMask = dic_postprocess.analysisRun.summaryMaskForStrain(state.strain);
    state.summaryTable = dic_postprocess.analysisRun.summarizeStrain( ...
        state.strain, summaryMask);
end

function opts = overlayOptionsFromControls(ui)
    opts = struct();
    opts.alpha = ui.controls.alpha.valueHandle.Value;
    opts.colorRange = [ui.controls.colorMin.valueHandle.Value ...
        ui.controls.colorMax.valueHandle.Value];
    opts.oversample = max(1, round(ui.controls.oversample.valueHandle.Value));
    opts.sigmaSmooth = ui.controls.smoothSigma.valueHandle.Value;
    opts.edgeTrim = max(0, round(ui.controls.edgeTrim.valueHandle.Value));
    opts.colormap = jet(256);
    opts.brightness = ui.controls.brightness.valueHandle.Value;
    opts.contrast = ui.controls.contrast.valueHandle.Value;
    opts.gamma = ui.controls.gamma.valueHandle.Value;
    opts.saturation = ui.controls.saturation.valueHandle.Value;
    opts.rgbGain = [ui.controls.redGain.valueHandle.Value ...
        ui.controls.greenGain.valueHandle.Value ...
        ui.controls.blueGain.valueHandle.Value];
end

function state = clearOutputs(state)
    state.overlayExx = [];
    state.overlayEyy = [];
    state.summaryTable = table();
end

function addLog(services, msg)
    labkit.ui.view.appendLog(services.ui, 'appLog', msg);
    if isDebugEnabled(services.debug)
        services.debug.append(msg);
    end
end

function tf = isDebugEnabled(debugLog)
    tf = isstruct(debugLog) && isfield(debugLog, 'enabled') && ...
        logical(debugLog.enabled);
end
