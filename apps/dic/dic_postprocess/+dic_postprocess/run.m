% Expected caller: labkit_DICPostprocess_app. Input is the debug context
% prepared by the public launcher. Output is the app figure. Side effects are
% GUI creation, user-driven DIC file loading, overlay export, and debug trace attachment.
function fig = run(debugLog)
%RUN Build and run the DIC Postprocess app body.

    S = struct();
    S.matPath = "";
    S.referencePath = "";
    S.maskPath = "";
    S.strain = struct();
    S.referenceImage = [];
    S.maskImage = [];
    S.overlayExx = [];
    S.overlayEyy = [];
    S.summaryTable = table();

    callbacks = struct( ...
        "matChosen", @onMatChosen, ...
        "matCleared", @(~, ~) onMatCleared(), ...
        "referenceChosen", @onReferenceChosen, ...
        "referenceCleared", @(~, ~) onReferenceCleared(), ...
        "maskChosen", @onMaskChosen, ...
        "maskCleared", @(~, ~) onMaskCleared(), ...
        "generate", @onGenerate, ...
        "optionsChanged", @onOptionsChanged, ...
        "saveOverlays", @onSaveOverlays, ...
        "exportSummary", @onExportSummary);
    spec = dic_postprocess.ui.buildSpec(callbacks);
    ui = labkit.ui.app.create(spec, "debug", debugLog);
    fig = ui.figure;

    edAlpha = ui.controls.alpha.valueHandle;
    edMin = ui.controls.colorMin.valueHandle;
    edMax = ui.controls.colorMax.valueHandle;
    edOversample = ui.controls.oversample.valueHandle;
    edSigma = ui.controls.smoothSigma.valueHandle;
    edEdgeTrim = ui.controls.edgeTrim.valueHandle;
    edBrightness = ui.controls.brightness.valueHandle;
    edContrast = ui.controls.contrast.valueHandle;
    edGamma = ui.controls.gamma.valueHandle;
    edSaturation = ui.controls.saturation.valueHandle;
    edRedGain = ui.controls.redGain.valueHandle;
    edGreenGain = ui.controls.greenGain.valueHandle;
    edBlueGain = ui.controls.blueGain.valueHandle;
    resultTable = ui.controls.resultTable.table;
    txtSummary = ui.controls.summaryText.textArea;
    ui.topAxes = ui.controls.overlayAxes.axesById.exx;
    ui.bottomAxes = ui.controls.overlayAxes.axesById.eyy;
    if debugLog.enabled
        debugLog.trace('DIC postprocess debug trace enabled.');
    end

    labkit.ui.view.resetAxes(ui, 'overlayAxes', 'EXX Overlay', true, 'exx');
    labkit.ui.view.resetAxes(ui, 'overlayAxes', 'EYY Overlay', true, 'eyy');

    function onMatChosen(~, event)
        paths = labkit.ui.view.filePaths(event.addedFiles);
        if isempty(paths)
            addLog('DIC MAT selection cancelled.');
            return;
        end
        S.matPath = paths(1);
        addLog(sprintf('Selected DIC MAT: %s', S.matPath));
        refreshSummaryText();
    end

    function onMatCleared()
        S.matPath = "";
        S.strain = struct();
        clearOutputs();
        addLog('Cleared DIC MAT task.');
        refreshSummaryText();
    end

    function onReferenceChosen(~, event)
        paths = labkit.ui.view.filePaths(event.addedFiles);
        if isempty(paths)
            addLog('Reference image selection cancelled.');
            return;
        end
        filepath = paths(1);
        S.referencePath = filepath;
        S.referenceImage = imread(filepath);
        addLog(sprintf('Loaded reference image: %s', filepath));
        refreshSummaryText();
    end

    function onReferenceCleared()
        S.referencePath = "";
        S.referenceImage = [];
        clearOutputs();
        addLog('Cleared reference image file.');
        refreshSummaryText();
    end

    function onMaskChosen(~, event)
        paths = labkit.ui.view.filePaths(event.addedFiles);
        if isempty(paths)
            addLog('Mask image selection cancelled.');
            return;
        end
        filepath = paths(1);
        S.maskPath = filepath;
        S.maskImage = imread(filepath);
        addLog(sprintf('Loaded mask image: %s', filepath));
        refreshSummaryText();
    end

    function onMaskCleared()
        S.maskPath = "";
        S.maskImage = [];
        clearOutputs();
        addLog('Cleared mask image file.');
        refreshSummaryText();
    end

    function onGenerate(~, ~)
        if strlength(S.matPath) == 0 || isempty(S.referenceImage) || isempty(S.maskImage)
            uialert(fig, 'Load the DIC MAT file, reference image, and mask image first.', ...
                'Missing inputs');
            return;
        end
        if edMax.Value <= edMin.Value
            uialert(fig, 'Color max must be greater than color min.', 'Invalid color range');
            return;
        end

        try
            S.strain = dic_postprocess.io.loadNcorrStrain(char(S.matPath));
            renderOverlays(true);
            addLog('Generated EXX/EYY overlays and ROI summary.');
        catch ME
            debugLog.reportException('dicPostprocess', 'Generate failed', ME);
            uialert(fig, ME.message, 'DIC postprocess error');
            addLog(sprintf('Generate failed: %s', ME.message));
        end
    end

    function onSaveOverlays(~, ~)
        if isempty(S.overlayExx) || isempty(S.overlayEyy)
            uialert(fig, 'Generate overlays before saving.', 'Save overlays');
            return;
        end

        [folder, cancelled] = labkit.ui.app.promptOutputFolder( ...
            'Select folder for overlay PNGs', "");
        if cancelled
            addLog('Save overlay PNGs cancelled.');
            return;
        end

        tag = dic_postprocess.view.tagFromPath(char(S.matPath));
        exxFile = fullfile(folder, sprintf('overlay_exx_%s.png', tag));
        eyyFile = fullfile(folder, sprintf('overlay_eyy_%s.png', tag));
        dic_postprocess.export.exportOverlayImage(S.overlayExx, exxFile);
        dic_postprocess.export.exportOverlayImage(S.overlayEyy, eyyFile);
        addLog(sprintf('Saved clean overlay PNGs: %s and %s', exxFile, eyyFile));
    end

    function onExportSummary(~, ~)
        if isempty(S.summaryTable) || height(S.summaryTable) == 0
            uialert(fig, 'Generate a summary before exporting.', 'Export summary');
            return;
        end

        [folder, name] = fileparts(char(S.matPath));
        folder = labkit.ui.app.defaultDialogFolder("output", folder);
        defaultName = fullfile(folder, [name '_strain_summary.csv']);
        [out, cancelled] = labkit.ui.app.promptOutputFile( ...
            '*.csv', 'Save strain summary CSV', defaultName);
        if cancelled
            addLog('Export summary cancelled.');
            return;
        end

        writetable(S.summaryTable, out);
        addLog(sprintf('Exported summary CSV: %s', char(out)));
    end

    function onOptionsChanged(~, ~)
        if isfield(S.strain, 'exx') && ~isempty(S.referenceImage) && ~isempty(S.maskImage)
            try
                renderOverlays(false);
            catch ME
                debugLog.reportException('dicPostprocess', 'Option update skipped', ME);
                addLog(sprintf('Option update skipped: %s', ME.message));
            end
        end
    end

    function renderOverlays(showAlerts)
        if edMax.Value <= edMin.Value
            if showAlerts
                uialert(fig, 'Color max must be greater than color min.', 'Invalid color range');
            end
            return;
        end

        opts = overlayOptionsFromControls();
        overlayMask = dic_postprocess.ops.imageMask(S.maskImage, ...
            dic_postprocess.ops.imageHeightWidth(S.referenceImage));
        S.overlayExx = dic_postprocess.ops.makeStrainOverlay( ...
            S.referenceImage, S.strain.exx, overlayMask, S.strain.roiMask, opts);
        S.overlayEyy = dic_postprocess.ops.makeStrainOverlay( ...
            S.referenceImage, S.strain.eyy, overlayMask, S.strain.roiMask, opts);
        summaryMask = dic_postprocess.ops.summaryMaskForStrain(S.strain);
        S.summaryTable = dic_postprocess.ops.summarizeStrain(S.strain, summaryMask);
        dic_postprocess.ui.showImage(ui, S.overlayExx, 'EXX Overlay', 'exx');
        dic_postprocess.ui.showImage(ui, S.overlayEyy, 'EYY Overlay', 'eyy');
        resultTable.Data = dic_postprocess.view.summaryTableData(S.summaryTable);
        refreshSummaryText();
    end

    function opts = overlayOptionsFromControls()
        opts = struct();
        opts.alpha = edAlpha.Value;
        opts.colorRange = [edMin.Value edMax.Value];
        opts.oversample = max(1, round(edOversample.Value));
        opts.sigmaSmooth = edSigma.Value;
        opts.edgeTrim = max(0, round(edEdgeTrim.Value));
        opts.colormap = jet(256);
        opts.brightness = edBrightness.Value;
        opts.contrast = edContrast.Value;
        opts.gamma = edGamma.Value;
        opts.saturation = edSaturation.Value;
        opts.rgbGain = [edRedGain.Value edGreenGain.Value edBlueGain.Value];
    end

    function refreshSummaryText()
        labkit.ui.view.setValue(ui, "matFile", fileValue(S.matPath));
        labkit.ui.view.setValue(ui, "referenceFile", fileValue(S.referencePath));
        labkit.ui.view.setValue(ui, "maskFile", fileValue(S.maskPath));
        lines = {};
        lines{end+1} = sprintf('DIC MAT: %s', dic_postprocess.view.displayPath(S.matPath));
        lines{end+1} = sprintf('Reference image: %s', dic_postprocess.view.displayPath(S.referencePath));
        lines{end+1} = sprintf('Mask image: %s', dic_postprocess.view.displayPath(S.maskPath));
        lines{end+1} = sprintf('Overlays: %s', ...
            dic_postprocess.view.ternary(~isempty(S.overlayExx), ...
            'available', 'not generated'));
        lines{end+1} = sprintf('Optical image: brightness %.3g, contrast %.3g, gamma %.3g, saturation %.3g', ...
            edBrightness.Value, edContrast.Value, edGamma.Value, edSaturation.Value);
        txtSummary.Value = lines;
    end

    function clearOutputs()
        S.overlayExx = [];
        S.overlayEyy = [];
        S.summaryTable = table();
        resultTable.Data = {};
        labkit.ui.view.resetAxes(ui, 'overlayAxes', 'EXX Overlay', true, 'exx');
        labkit.ui.view.resetAxes(ui, 'overlayAxes', 'EYY Overlay', true, 'eyy');
    end

    function addLog(msg)
        labkit.ui.view.appendLog(ui, 'appLog', msg);
        debugLog.append(msg);
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
