function varargout = labkit_DICPostprocess_app(varargin)
%LABKIT_DICPOSTPROCESS_APP Ncorr strain summary and overlay export app.

    if nargin > 0
        error('labkit_DICPostprocess_app:UnsupportedInput', ...
            'labkit_DICPostprocess_app does not accept input arguments.');
    end
    if nargout > 1
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

    workbenchOpts = struct('rightKind', 'dualPlot', ...
        'rightTitle', 'Strain Overlays', ...
        'topPlotTitle', 'EXX Overlay', ...
        'bottomPlotTitle', 'EYY Overlay', ...
        'showPlotControls', false);
    ui = labkit.ui.createWorkbench( ...
        'DIC Strain Postprocess', [90 70 1450 880], 390, workbenchOpts);
    fig = ui.fig;

    layFA = ui.filesAnalysisGrid;
    laySR = ui.summaryResultsGrid;
    layLog = ui.logGrid;
    layFA.RowHeight = {240, 6, 230, 6, 260, 6, 120};
    laySR.RowHeight = {210, 6, '1x'};

    filePanel = labkit.ui.createPanelGrid(layFA, 'Inputs', 1, [6 2], ...
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

    txtMat = uieditfield(fileGrid, 'text', 'Editable', 'off', 'Value', 'No MAT file loaded');
    txtMat.Layout.Row = 3;
    txtMat.Layout.Column = [1 2];
    txtReference = uieditfield(fileGrid, 'text', 'Editable', 'off', 'Value', 'No reference image loaded');
    txtReference.Layout.Row = 4;
    txtReference.Layout.Column = [1 2];
    txtMask = uieditfield(fileGrid, 'text', 'Editable', 'off', 'Value', 'No mask image loaded');
    txtMask.Layout.Row = 5;
    txtMask.Layout.Column = [1 2];

    btnGenerate = uibutton(fileGrid, 'Text', 'Generate overlays + summary', ...
        'ButtonPushedFcn', @onGenerate);
    btnGenerate.Layout.Row = 6;
    btnGenerate.Layout.Column = [1 2];

    optionPanel = labkit.ui.createPanelGrid(layFA, 'Overlay Options', 3, [6 2], ...
        struct('rowHeight', {{'fit', 'fit', 'fit', 'fit', 'fit', 'fit'}}));
    optionGrid = optionPanel.grid;

    [~, edAlpha] = labkit.ui.createLabeledEditField(optionGrid, 'Alpha:', 'numeric', ...
        'Value', 0.60, 'Limits', [0 1], 'ValueChangedFcn', @onOptionsChanged);
    [~, edMin] = labkit.ui.createLabeledEditField(optionGrid, 'Color min:', 'numeric', ...
        'Value', -0.15, 'ValueChangedFcn', @onOptionsChanged);
    [~, edMax] = labkit.ui.createLabeledEditField(optionGrid, 'Color max:', 'numeric', ...
        'Value', 0.15, 'ValueChangedFcn', @onOptionsChanged);
    [~, edOversample] = labkit.ui.createLabeledEditField(optionGrid, 'Oversample:', 'numeric', ...
        'Value', 6, 'Limits', [1 20], 'ValueChangedFcn', @onOptionsChanged);
    [~, edSigma] = labkit.ui.createLabeledEditField(optionGrid, 'Smooth sigma:', 'numeric', ...
        'Value', 0.8, 'Limits', [0 Inf], 'ValueChangedFcn', @onOptionsChanged);
    [~, edResolution] = labkit.ui.createLabeledEditField(optionGrid, 'Export DPI:', 'numeric', ...
        'Value', 1000, 'Limits', [72 2400]);

    imagePanel = labkit.ui.createPanelGrid(layFA, 'Optical Image Enhancement', 5, [7 2], ...
        struct('rowHeight', {{'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'}}));
    imageGrid = imagePanel.grid;

    [~, edBrightness] = labkit.ui.createLabeledEditField(imageGrid, 'Brightness:', 'numeric', ...
        'Value', 0, 'Limits', [-1 1], 'ValueChangedFcn', @onOptionsChanged);
    [~, edContrast] = labkit.ui.createLabeledEditField(imageGrid, 'Contrast:', 'numeric', ...
        'Value', 1, 'Limits', [0.05 5], 'ValueChangedFcn', @onOptionsChanged);
    [~, edGamma] = labkit.ui.createLabeledEditField(imageGrid, 'Gamma:', 'numeric', ...
        'Value', 1, 'Limits', [0.05 5], 'ValueChangedFcn', @onOptionsChanged);
    [~, edSaturation] = labkit.ui.createLabeledEditField(imageGrid, 'Saturation:', 'numeric', ...
        'Value', 1, 'Limits', [0 5], 'ValueChangedFcn', @onOptionsChanged);
    [~, edRedGain] = labkit.ui.createLabeledEditField(imageGrid, 'Red gain:', 'numeric', ...
        'Value', 1, 'Limits', [0 5], 'ValueChangedFcn', @onOptionsChanged);
    [~, edGreenGain] = labkit.ui.createLabeledEditField(imageGrid, 'Green gain:', 'numeric', ...
        'Value', 1, 'Limits', [0 5], 'ValueChangedFcn', @onOptionsChanged);
    [~, edBlueGain] = labkit.ui.createLabeledEditField(imageGrid, 'Blue gain:', 'numeric', ...
        'Value', 1, 'Limits', [0 5], 'ValueChangedFcn', @onOptionsChanged);

    exportPanel = labkit.ui.createPanelGrid(layFA, 'Exports', 7, [3 2], ...
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

    resultUi = labkit.ui.createResultTablePanel(laySR, 'ROI Strain Summary', 1, ...
        {'Metric', 'EXX', 'EYY'});
    resultTable = resultUi.table;

    txtSummary = uitextarea(laySR, 'Editable', 'off');
    txtSummary.Layout.Row = 3;
    txtSummary.Value = {'No DIC result loaded.'};

    labkit.ui.addRowResizeHandle(fig, layFA, 2, ...
        struct('minTopHeight', 150, 'minBottomHeight', 150));
    labkit.ui.addRowResizeHandle(fig, layFA, 4, ...
        struct('minTopHeight', 150, 'minBottomHeight', 90));
    labkit.ui.addRowResizeHandle(fig, layFA, 6, ...
        struct('minTopHeight', 120, 'minBottomHeight', 90));
    labkit.ui.addRowResizeHandle(fig, laySR, 2, ...
        struct('minTopHeight', 120, 'minBottomHeight', 90));

    logUi = labkit.ui.createLogPanel(layLog, 1, {'Ready.'});
    txtLog = logUi.textArea;

    labkit.ui.hardResetAxis(ui.topAxes, 'EXX Overlay', true);
    labkit.ui.hardResetAxis(ui.bottomAxes, 'EYY Overlay', true);

    if nargout == 1
        varargout{1} = fig;
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
        filepath = chooseImageFile('Select reference image');
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
        filepath = chooseImageFile('Select mask image');
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
            S.strain = loadNcorrStrain(char(S.matPath));
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

        tag = tagFromPath(char(S.matPath));
        opts = overlayOptionsFromControls();
        exxFile = fullfile(folder, sprintf('overlay_exx_%s.png', tag));
        eyyFile = fullfile(folder, sprintf('overlay_eyy_%s.png', tag));
        exportOverlayFigure(S.overlayExx, 'EXX', opts.colorRange, opts.exportResolution, exxFile);
        exportOverlayFigure(S.overlayEyy, 'EYY', opts.colorRange, opts.exportResolution, eyyFile);
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
        exportStrainColorbar(opts, pngOut);
        writetable(colorbarLevelsTable(opts), csvOut);
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
        overlayMask = imageMask(S.maskImage, imageHeightWidth(S.referenceImage));
        S.overlayExx = makeStrainOverlay( ...
            S.referenceImage, S.strain.exx, overlayMask, S.strain.roiMask, opts);
        S.overlayEyy = makeStrainOverlay( ...
            S.referenceImage, S.strain.eyy, overlayMask, S.strain.roiMask, opts);
        summaryMask = summaryMaskForStrain(S.strain, overlayMask);
        S.summaryTable = summarizeStrain(S.strain, summaryMask);
        showImage(ui.topAxes, S.overlayExx, 'EXX Overlay');
        showImage(ui.bottomAxes, S.overlayEyy, 'EYY Overlay');
        resultTable.Data = summaryTableData(S.summaryTable);
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
        lines{end+1} = sprintf('DIC MAT: %s', displayPath(S.matPath));
        lines{end+1} = sprintf('Reference image: %s', displayPath(S.referencePath));
        lines{end+1} = sprintf('Mask image: %s', displayPath(S.maskPath));
        lines{end+1} = sprintf('Overlays: %s', ternary(~isempty(S.overlayExx), 'available', 'not generated'));
        lines{end+1} = sprintf('Optical image: brightness %.3g, contrast %.3g, gamma %.3g, saturation %.3g', ...
            edBrightness.Value, edContrast.Value, edGamma.Value, edSaturation.Value);
        txtSummary.Value = lines;
    end

    function addLog(msg)
        labkit.ui.appendLog(txtLog, msg);
    end
end

function filepath = chooseImageFile(titleText)
    [f, p] = uigetfile( ...
        {'*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp', 'Image files'; '*.*', 'All files'}, ...
        titleText);
    if isequal(f, 0)
        filepath = "";
    else
        filepath = string(fullfile(p, f));
    end
end

function strain = loadNcorrStrain(matFile)
    data = load(matFile, 'data_dic_save');
    if ~isfield(data, 'data_dic_save') || ~isfield(data.data_dic_save, 'strains')
        error('MAT file must contain data_dic_save.strains.');
    end

    strains = data.data_dic_save.strains;
    required = {'plot_exx_ref_formatted', 'plot_eyy_ref_formatted'};
    for i = 1:numel(required)
        if ~isfield(strains, required{i})
            error('Missing data_dic_save.strains.%s.', required{i});
        end
    end

    strain = struct();
    strain.exx = strains.plot_exx_ref_formatted;
    strain.eyy = strains.plot_eyy_ref_formatted;
    strain.roiMask = [];
    if isfield(strains, 'roi_ref_formatted') && ...
            isfield(strains.roi_ref_formatted, 'mask')
        strain.roiMask = logical(strains.roi_ref_formatted.mask);
    end
end

function mask = imageMask(maskImage, targetSize)
    if ndims(maskImage) == 3
        maskImage = rgb2gray(maskImage);
    end
    mask = maskImage > 128;
    mask = imresize(mask, targetSize, 'nearest');
end

function targetSize = imageHeightWidth(imageData)
    targetSize = [size(imageData, 1), size(imageData, 2)];
end

function overlay = makeStrainOverlay(referenceImage, strainMap, mask, roiMask, opts)
    orig = enhanceReferenceImage(referenceImage, opts);
    [H, W, ~] = size(orig);
    mask = imresize(logical(mask), [H W], 'nearest');
    validMap = strainValidMask(strainMap, roiMask, mask);
    [strainRgb, validStrain] = strainToRgb(strainMap, validMap, [H W], opts);
    overlayMask = mask & validStrain;
    mask3 = repmat(overlayMask, [1 1 3]);
    overlay = orig;
    overlay(mask3) = (1 - opts.alpha) .* orig(mask3) + opts.alpha .* strainRgb(mask3);
end

function [rgb, validMask] = strainToRgb(strainMap, validMap, targetSize, opts)
    S = extendStrainMapToRoi(double(strainMap), validMap);
    if opts.sigmaSmooth > 0
        S = imgaussfilt(S, opts.sigmaSmooth);
    end
    Sbig = imresize(S, opts.oversample, 'lanczos3');
    Shr = imresize(Sbig, targetSize, 'lanczos3');
    validMask = imresize(logical(validMap), targetSize, 'nearest') & isfinite(Shr);
    smin = opts.colorRange(1);
    smax = opts.colorRange(2);
    Snorm = (Shr - smin) ./ (smax - smin);
    Snorm = max(min(Snorm, 1), 0);
    idx = ones(size(Snorm));
    idx(validMask) = round(Snorm(validMask) * (size(opts.colormap, 1) - 1)) + 1;
    rgb = ind2rgb(idx, opts.colormap);
end

function validMap = strainValidMask(strainMap, roiMask, displayMask)
    validMap = isfinite(strainMap);
    if ~isempty(roiMask)
        validMap = validMap & logical(roiMask);
    else
        validMap = validMap & imresize(logical(displayMask), size(strainMap), 'nearest');
    end
end

function Sfilled = extendStrainMapToRoi(S, validMap)
    validMap = logical(validMap) & isfinite(S);
    Sfilled = S;
    if ~any(validMap(:))
        Sfilled(:) = NaN;
        return;
    end

    [~, nearestIdx] = bwdist(validMap);
    invalid = ~validMap;
    Sfilled(invalid) = S(nearestIdx(invalid));
end

function img = enhanceReferenceImage(referenceImage, opts)
    img = ensureRgb(im2double(referenceImage));
    gains = reshape(opts.rgbGain, 1, 1, 3);
    img = img .* gains;
    img = clamp01(img);

    hsvImage = rgb2hsv(img);
    hsvImage(:, :, 2) = clamp01(hsvImage(:, :, 2) .* opts.saturation);
    img = hsv2rgb(hsvImage);

    img = (img - 0.5) .* opts.contrast + 0.5 + opts.brightness;
    img = clamp01(img);
    img = img .^ opts.gamma;
    img = clamp01(img);
end

function x = clamp01(x)
    x = min(max(x, 0), 1);
end

function out = ensureRgb(imageData)
    if ndims(imageData) == 2
        out = repmat(imageData, [1 1 3]);
    else
        out = imageData;
    end
end

function mask = summaryMaskForStrain(strain, overlayMask)
    if ~isempty(strain.roiMask)
        mask = logical(strain.roiMask);
    else
        mask = imresize(logical(overlayMask), size(strain.exx), 'nearest');
    end
end

function T = summarizeStrain(strain, mask)
    exx = strain.exx(mask);
    eyy = strain.eyy(mask);
    metric = ["Mean"; "Std"; "Median"; "Min"; "Max"];
    exxValues = nanSafeStats(exx);
    eyyValues = nanSafeStats(eyy);
    T = table(metric, exxValues, eyyValues, ...
        'VariableNames', {'Metric', 'EXX', 'EYY'});
end

function values = nanSafeStats(x)
    x = x(:);
    x = x(isfinite(x));
    if isempty(x)
        values = nan(5, 1);
        return;
    end
    values = [mean(x); std(x); median(x); min(x); max(x)];
end

function data = summaryTableData(T)
    if isempty(T) || height(T) == 0
        data = {};
        return;
    end
    data = [cellstr(T.Metric), num2cell(T.EXX), num2cell(T.EYY)];
end

function showImage(ax, imageData, titleText)
    cla(ax);
    image(ax, imageData);
    axis(ax, 'image');
    ax.XLim = [0.5, size(imageData, 2) + 0.5];
    ax.YLim = [0.5, size(imageData, 1) + 0.5];
    ax.YDir = 'reverse';
    ax.XTick = [];
    ax.YTick = [];
    title(ax, titleText);
end

function exportOverlayFigure(overlayImage, componentName, colorRange, resolution, outfile)
    fig = figure('Visible', 'off');
    cleanup = onCleanup(@() close(fig));
    imshow(overlayImage);
    title(sprintf('Strain %s', componentName));
    colormap(jet);
    clim(colorRange);
    cb = colorbar;
    cb.Label.String = sprintf('Strain %s', componentName);
    exportgraphics(fig, outfile, 'Resolution', resolution);
end

function exportStrainColorbar(opts, outfile)
    fig = figure('Visible', 'off', 'Position', [100 100 420 720]);
    cleanup = onCleanup(@() close(fig));
    ax = axes(fig, 'Position', [0.18 0.08 0.24 0.86]);
    levels = linspace(opts.colorRange(1), opts.colorRange(2), size(opts.colormap, 1));
    imagesc(ax, 1, levels, levels(:));
    set(ax, 'XTick', [], 'YDir', 'normal');
    ylabel(ax, 'Strain level');
    colormap(ax, opts.colormap);
    clim(ax, opts.colorRange);
    cb = colorbar(ax, 'Location', 'eastoutside');
    cb.Label.String = 'Strain level';
    exportgraphics(fig, outfile, 'Resolution', opts.exportResolution);
end

function T = colorbarLevelsTable(opts)
    n = size(opts.colormap, 1);
    strainLevel = linspace(opts.colorRange(1), opts.colorRange(2), n).';
    red = opts.colormap(:, 1);
    green = opts.colormap(:, 2);
    blue = opts.colormap(:, 3);
    T = table(strainLevel, red, green, blue, ...
        'VariableNames', {'StrainLevel', 'Red', 'Green', 'Blue'});
end

function tag = tagFromPath(filepath)
    tokens = regexp(filepath, '(\d+(?:\.\d+)?mm)', 'tokens');
    if isempty(tokens)
        tag = 'unknown_mm';
    else
        tag = tokens{end}{1};
    end
    tag = regexprep(tag, '[^A-Za-z0-9_.-]', '_');
end

function txt = displayPath(pathValue)
    if strlength(pathValue) == 0
        txt = 'none';
    else
        txt = char(pathValue);
    end
end

function txt = ternary(cond, trueText, falseText)
    if cond
        txt = trueText;
    else
        txt = falseText;
    end
end
