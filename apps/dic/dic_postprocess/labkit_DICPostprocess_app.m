function varargout = labkit_DICPostprocess_app(varargin)
%LABKIT_DICPOSTPROCESS_APP Ncorr strain summary and overlay export app.

    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'labkit_DICPostprocess_app', varargin, nargout);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_DICPostprocess_app:TooManyOutputs', ...
                'labkit_DICPostprocess_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_DICPostprocess_app:TooManyOutputs', ...
            'labkit_DICPostprocess_app returns at most the app figure handle.');
    end

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
        "openMat", @onOpenMat, ...
        "openReference", @onOpenReference, ...
        "openMask", @onOpenMask, ...
        "generate", @onGenerate, ...
        "optionsChanged", @onOptionsChanged, ...
        "saveOverlays", @onSaveOverlays, ...
        "exportSummary", @onExportSummary, ...
        "exportColorbar", @onExportColorbar);
    spec = dic_postprocess.ui.buildSpec(callbacks);
    ui = labkit.ui.app.create(spec, "debug", debugLog);
    fig = ui.figure;

    txtMat = ui.controls.matPath.valueHandle;
    txtReference = ui.controls.referencePath.valueHandle;
    txtMask = ui.controls.maskPath.valueHandle;
    edAlpha = ui.controls.alpha.valueHandle;
    edMin = ui.controls.colorMin.valueHandle;
    edMax = ui.controls.colorMax.valueHandle;
    edOversample = ui.controls.oversample.valueHandle;
    edSigma = ui.controls.smoothSigma.valueHandle;
    edResolution = ui.controls.exportDpi.valueHandle;
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

    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end

    function onOpenMat(~, ~)
        [f, p] = uigetfile({'*.mat', 'MAT files (*.mat)'}, 'Select Ncorr DIC MAT file');
        if isequal(f, 0)
            addLog('DIC MAT selection cancelled.');
            return;
        end
        S.matPath = string(fullfile(p, f));
        txtMat.Value = char(S.matPath);
        addLog(sprintf('Selected DIC MAT: %s', S.matPath));
        refreshSummaryText();
    end

    function onOpenReference(~, ~)
        filepath = dic_postprocess.io.chooseImageFile('Select reference image');
        if filepath == ""
            addLog('Reference image selection cancelled.');
            return;
        end
        S.referencePath = filepath;
        S.referenceImage = imread(filepath);
        txtReference.Value = char(filepath);
        addLog(sprintf('Loaded reference image: %s', filepath));
        refreshSummaryText();
    end

    function onOpenMask(~, ~)
        filepath = dic_postprocess.io.chooseImageFile('Select mask image');
        if filepath == ""
            addLog('Mask image selection cancelled.');
            return;
        end
        S.maskPath = filepath;
        S.maskImage = imread(filepath);
        txtMask.Value = char(filepath);
        addLog(sprintf('Loaded mask image: %s', filepath));
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
            uialert(fig, ME.message, 'DIC postprocess error');
            addLog(sprintf('Generate failed: %s', ME.message));
        end
    end

    function onSaveOverlays(~, ~)
        if isempty(S.overlayExx) || isempty(S.overlayEyy)
            uialert(fig, 'Generate overlays before saving.', 'Save overlays');
            return;
        end

        folder = uigetdir(pwd, 'Select folder for overlay PNGs');
        if isequal(folder, 0)
            addLog('Save overlay PNGs cancelled.');
            return;
        end

        tag = dic_postprocess.view.tagFromPath(char(S.matPath));
        opts = overlayOptionsFromControls();
        exxFile = fullfile(folder, sprintf('overlay_exx_%s.png', tag));
        eyyFile = fullfile(folder, sprintf('overlay_eyy_%s.png', tag));
        dic_postprocess.export.exportOverlayFigure(S.overlayExx, 'EXX', ...
            opts.colorRange, opts.exportResolution, exxFile);
        dic_postprocess.export.exportOverlayFigure(S.overlayEyy, 'EYY', ...
            opts.colorRange, opts.exportResolution, eyyFile);
        addLog(sprintf('Saved overlay PNGs: %s and %s', exxFile, eyyFile));
    end

    function onExportSummary(~, ~)
        if isempty(S.summaryTable) || height(S.summaryTable) == 0
            uialert(fig, 'Generate a summary before exporting.', 'Export summary');
            return;
        end

        [folder, name] = fileparts(char(S.matPath));
        defaultName = fullfile(folder, [name '_strain_summary.csv']);
        [f, p] = uiputfile('*.csv', 'Save strain summary CSV', defaultName);
        if isequal(f, 0)
            addLog('Export summary cancelled.');
            return;
        end

        out = fullfile(p, f);
        writetable(S.summaryTable, out);
        addLog(sprintf('Exported summary CSV: %s', out));
    end

    function onExportColorbar(~, ~)
        if edMax.Value <= edMin.Value
            uialert(fig, 'Color max must be greater than color min.', 'Invalid color range');
            return;
        end

        [folder, name] = fileparts(char(S.matPath));
        if isempty(folder)
            folder = pwd;
        end
        if isempty(name)
            name = 'dic_strain';
        end
        defaultName = fullfile(folder, [name '_strain_colorbar.png']);
        [f, p] = uiputfile({'*.png', 'PNG image'}, 'Save strain colorbar', defaultName);
        if isequal(f, 0)
            addLog('Export strain colorbar cancelled.');
            return;
        end

        opts = overlayOptionsFromControls();
        pngOut = fullfile(p, f);
        [~, baseName] = fileparts(f);
        csvOut = fullfile(p, [baseName '_levels.csv']);
        dic_postprocess.export.exportStrainColorbar(opts, pngOut);
        writetable(dic_postprocess.view.colorbarLevelsTable(opts), csvOut);
        addLog(sprintf('Exported strain colorbar: %s and %s', pngOut, csvOut));
    end

    function onOptionsChanged(~, ~)
        if isfield(S.strain, 'exx') && ~isempty(S.referenceImage) && ~isempty(S.maskImage)
            try
                renderOverlays(false);
            catch ME
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
        summaryMask = dic_postprocess.ops.summaryMaskForStrain(S.strain, overlayMask);
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
        opts.colormap = jet(256);
        opts.exportResolution = round(edResolution.Value);
        opts.brightness = edBrightness.Value;
        opts.contrast = edContrast.Value;
        opts.gamma = edGamma.Value;
        opts.saturation = edSaturation.Value;
        opts.rgbGain = [edRedGain.Value edGreenGain.Value edBlueGain.Value];
    end

    function refreshSummaryText()
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

    function addLog(msg)
        labkit.ui.view.appendLog(ui, 'appLog', msg);
        debugLog.append(msg);
    end
end
