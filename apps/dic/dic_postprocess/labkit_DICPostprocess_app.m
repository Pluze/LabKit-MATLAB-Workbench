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

    workbenchOpts = struct( ...
        'rightTitle', 'Strain Overlays', ...
        'rightGridSize', [2 1], ...
        'rightRowHeight', {{'1x', '1x'}}, ...
        'rightRowSpacing', 10);
    workbenchOpts.tabs = [ ...
        labkit.ui.app.tab('filesAnalysis', 'Files + Analysis', [4 1], ...
            {240, 230, 260, 120}, ...
            struct('resizeRows', [1 2 3], ...
            'resizeOptions', struct('minTopHeight', 120, 'minBottomHeight', 90))), ...
        labkit.ui.app.tab('summaryResults', 'Summary + Results', [2 1], ...
            {210, '1x'}, ...
            struct('resizeRows', 1, ...
            'resizeOptions', struct('minTopHeight', 120, 'minBottomHeight', 90))), ...
        labkit.ui.app.tab('log', 'Log', [1 1], {'1x'})];
    ui = labkit.ui.app.createShell(struct( ...
        'title', 'DIC Strain Postprocess', ...
        'position', [90 70 1450 880], ...
        'leftWidth', 390, ...
        'options', workbenchOpts));
    ui = dic_postprocess.ui.createRightAxesPair(ui, ...
        'EXX Overlay', 'EYY Overlay', false);
    fig = ui.fig;

    layFA = ui.filesAnalysisGrid;
    laySR = ui.summaryResultsGrid;
    layLog = ui.logGrid;

    filePanel = labkit.ui.view.section(layFA, 'Inputs', 1, [6 2], ...
        struct('rowHeight', {{'fit', 'fit', 'fit', 'fit', 'fit', 'fit'}}, ...
        'columnWidth', {{'1x', '1x'}}));
    fileGrid = filePanel.grid;

    btnMat = uibutton(fileGrid, 'Text', 'Open DIC MAT', 'ButtonPushedFcn', @onOpenMat);
    btnMat.Layout.Row = 1;
    btnMat.Layout.Column = 1;
    btnReference = uibutton(fileGrid, 'Text', 'Open reference image', 'ButtonPushedFcn', @onOpenReference);
    btnReference.Layout.Row = 1;
    btnReference.Layout.Column = 2;
    btnMask = uibutton(fileGrid, 'Text', 'Open mask image', 'ButtonPushedFcn', @onOpenMask);
    btnMask.Layout.Row = 2;
    btnMask.Layout.Column = [1 2];

    txtMat = labkit.ui.view.form(fileGrid, 'readonly', 'Value', 'No MAT file loaded');
    txtMat.Layout.Row = 3;
    txtMat.Layout.Column = [1 2];
    txtReference = labkit.ui.view.form(fileGrid, 'readonly', 'Value', 'No reference image loaded');
    txtReference.Layout.Row = 4;
    txtReference.Layout.Column = [1 2];
    txtMask = labkit.ui.view.form(fileGrid, 'readonly', 'Value', 'No mask image loaded');
    txtMask.Layout.Row = 5;
    txtMask.Layout.Column = [1 2];

    btnGenerate = uibutton(fileGrid, 'Text', 'Generate overlays + summary', ...
        'ButtonPushedFcn', @onGenerate);
    btnGenerate.Layout.Row = 6;
    btnGenerate.Layout.Column = [1 2];

    optionPanel = labkit.ui.view.section(layFA, 'Overlay Options', 2, [6 2], ...
        struct('rowHeight', {{'fit', 'fit', 'fit', 'fit', 'fit', 'fit'}}));
    optionGrid = optionPanel.grid;

    [~, edAlpha] = labkit.ui.view.form(optionGrid, 'spinner', 'Alpha:', ...
        'Value', 0.60, 'Limits', [0 1], 'Step', 0.05, 'ValueChangedFcn', @onOptionsChanged);
    [~, edMin] = labkit.ui.view.form(optionGrid, 'spinner', 'Color min:', ...
        'Value', -0.15, 'Step', 0.01, 'ValueChangedFcn', @onOptionsChanged);
    [~, edMax] = labkit.ui.view.form(optionGrid, 'spinner', 'Color max:', ...
        'Value', 0.15, 'Step', 0.01, 'ValueChangedFcn', @onOptionsChanged);
    [~, edOversample] = labkit.ui.view.form(optionGrid, 'spinner', 'Oversample:', ...
        'Value', 6, 'Limits', [1 20], 'Step', 1, 'ValueChangedFcn', @onOptionsChanged);
    [~, edSigma] = labkit.ui.view.form(optionGrid, 'spinner', 'Smooth sigma:', ...
        'Value', 0.8, 'Limits', [0 Inf], 'Step', 0.1, 'ValueChangedFcn', @onOptionsChanged);
    [~, edResolution] = labkit.ui.view.form(optionGrid, 'spinner', 'Export DPI:', ...
        'Value', 1000, 'Limits', [72 2400], 'Step', 50);

    imagePanel = labkit.ui.view.section(layFA, 'Optical Image Enhancement', 3, [7 2], ...
        struct('rowHeight', {{'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'}}));
    imageGrid = imagePanel.grid;

    [~, edBrightness] = labkit.ui.view.form(imageGrid, 'spinner', 'Brightness:', ...
        'Value', 0, 'Limits', [-1 1], 'Step', 0.05, 'ValueChangedFcn', @onOptionsChanged);
    [~, edContrast] = labkit.ui.view.form(imageGrid, 'spinner', 'Contrast:', ...
        'Value', 1, 'Limits', [0.05 5], 'Step', 0.05, 'ValueChangedFcn', @onOptionsChanged);
    [~, edGamma] = labkit.ui.view.form(imageGrid, 'spinner', 'Gamma:', ...
        'Value', 1, 'Limits', [0.05 5], 'Step', 0.05, 'ValueChangedFcn', @onOptionsChanged);
    [~, edSaturation] = labkit.ui.view.form(imageGrid, 'spinner', 'Saturation:', ...
        'Value', 1, 'Limits', [0 5], 'Step', 0.05, 'ValueChangedFcn', @onOptionsChanged);
    [~, edRedGain] = labkit.ui.view.form(imageGrid, 'spinner', 'Red gain:', ...
        'Value', 1, 'Limits', [0 5], 'Step', 0.05, 'ValueChangedFcn', @onOptionsChanged);
    [~, edGreenGain] = labkit.ui.view.form(imageGrid, 'spinner', 'Green gain:', ...
        'Value', 1, 'Limits', [0 5], 'Step', 0.05, 'ValueChangedFcn', @onOptionsChanged);
    [~, edBlueGain] = labkit.ui.view.form(imageGrid, 'spinner', 'Blue gain:', ...
        'Value', 1, 'Limits', [0 5], 'Step', 0.05, 'ValueChangedFcn', @onOptionsChanged);

    exportPanel = labkit.ui.view.section(layFA, 'Exports', 4, [3 2], ...
        struct('rowHeight', {{'fit', 'fit', 'fit'}}, 'columnWidth', {{'1x', '1x'}}));
    exportGrid = exportPanel.grid;
    btnSaveOverlays = uibutton(exportGrid, 'Text', 'Save overlay PNGs', ...
        'ButtonPushedFcn', @onSaveOverlays);
    btnSaveOverlays.Layout.Row = 1;
    btnSaveOverlays.Layout.Column = [1 2];
    btnExportSummary = uibutton(exportGrid, 'Text', 'Export summary CSV', ...
        'ButtonPushedFcn', @onExportSummary);
    btnExportSummary.Layout.Row = 2;
    btnExportSummary.Layout.Column = [1 2];
    btnExportColorbar = uibutton(exportGrid, 'Text', 'Export strain colorbar + levels', ...
        'ButtonPushedFcn', @onExportColorbar);
    btnExportColorbar.Layout.Row = 3;
    btnExportColorbar.Layout.Column = [1 2];

    resultUi = labkit.ui.view.panel(laySR, 'table', 'ROI Strain Summary', 1, ...
        {'Metric', 'EXX', 'EYY'});
    resultTable = resultUi.table;

    txtSummary = uitextarea(laySR, 'Editable', 'off');
    labkit.ui.view.place(txtSummary, laySR, 2);
    txtSummary.Value = {'No DIC result loaded.'};

    logUi = labkit.ui.view.panel(layLog, 'log', 1, {'Ready.'});
    txtLog = logUi.textArea;
    if debugLog.enabled
        debugLog.attachTextLog(txtLog);
        debugLog.trace('DIC postprocess debug trace enabled.');
        debugLog.instrumentFigure(fig);
    end

    labkit.ui.view.draw(ui.topAxes, 'reset', 'EXX Overlay', true);
    labkit.ui.view.draw(ui.bottomAxes, 'reset', 'EYY Overlay', true);

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
        dic_postprocess.ui.showImage(ui.topAxes, S.overlayExx, 'EXX Overlay');
        dic_postprocess.ui.showImage(ui.bottomAxes, S.overlayEyy, 'EYY Overlay');
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
        labkit.ui.view.update(txtLog, 'appendLog', msg);
        debugLog.append(msg);
    end
end
