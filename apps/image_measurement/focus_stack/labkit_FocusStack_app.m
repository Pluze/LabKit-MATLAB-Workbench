function varargout = labkit_FocusStack_app(varargin)
%LABKIT_FOCUSSTACK_APP Fuse a focus image stack into one all-in-focus image.

    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'labkit_FocusStack_app', varargin, nargout);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_FocusStack_app:TooManyOutputs', ...
                'labkit_FocusStack_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_FocusStack_app:TooManyOutputs', ...
            'labkit_FocusStack_app returns at most the app figure handle.');
    end

    S = struct();
    S.folder = "";
    S.paths = strings(0, 1);
    S.images = {};
    S.alignedImages = {};
    S.registrationLines = {};
    S.result = emptyFocusStackResult();

    workbenchOpts = struct('rightKind', 'dualPlot', ...
        'rightTitle', 'Focus Stack Preview', ...
        'topPlotTitle', 'Fused all-in-focus image', ...
        'bottomPlotTitle', 'Focus-depth index map', ...
        'showPlotControls', false);
    workbenchOpts.tabs = [ ...
        labkit.ui.app.tab('filesAnalysis', 'Files + Analysis', [4 1], ...
            {250, 235, 185, 170}, ...
            struct('resizeRows', [1 2 3], ...
            'resizeOptions', struct('minTopHeight', 130, 'minBottomHeight', 90))), ...
        labkit.ui.app.tab('summaryResults', 'Summary + Results', [2 1], ...
            {220, '1x'}, ...
            struct('resizeRows', 1)), ...
        labkit.ui.app.tab('log', 'Log', [1 1], {'1x'})];

    ui = labkit.ui.app.createShell(struct( ...
        'title', 'Microscope Focus Stack Fusion', ...
        'position', [80 60 1440 860], ...
        'leftWidth', 390, ...
        'options', workbenchOpts));
    fig = ui.fig;
    layFA = ui.filesAnalysisGrid;
    laySR = ui.summaryResultsGrid;
    layLog = ui.logGrid;

    filePanel = labkit.ui.view.section(layFA, 'Images', 1, [4 2], ...
        struct('rowHeight', {{'fit', 'fit', 105, 'fit'}}, ...
        'columnWidth', {{'1x', '1x'}}));
    fileGrid = filePanel.grid;

    btnOpenFolder = uibutton(fileGrid, 'Text', 'Open image folder', ...
        'ButtonPushedFcn', @onOpenFolder);
    btnOpenFolder.Layout.Row = 1;
    btnOpenFolder.Layout.Column = 1;

    btnOpenFiles = uibutton(fileGrid, 'Text', 'Open image files', ...
        'ButtonPushedFcn', @onOpenFiles);
    btnOpenFiles.Layout.Row = 1;
    btnOpenFiles.Layout.Column = 2;

    txtFolder = labkit.ui.view.form(fileGrid, 'readonly', ...
        'Value', 'No images loaded');
    txtFolder.Layout.Row = 2;
    txtFolder.Layout.Column = [1 2];

    lbImages = uilistbox(fileGrid, 'Items', {'No images loaded'});
    lbImages.Layout.Row = 3;
    lbImages.Layout.Column = [1 2];

    txtStackStatus = labkit.ui.view.form(fileGrid, 'readonly', ...
        'Value', 'Images: 0');
    txtStackStatus.Layout.Row = 4;
    txtStackStatus.Layout.Column = [1 2];

    analysisPanel = labkit.ui.view.section(layFA, 'Fusion Options', 2, [6 2], ...
        struct('rowHeight', {{'fit', 'fit', 'fit', 'fit', 'fit', 'fit'}}, ...
        'columnWidth', {{155, '1x'}}));
    analysisGrid = analysisPanel.grid;

    [lblFusionPreset, ddFusionPreset] = labkit.ui.view.form(analysisGrid, 'dropdown', ...
        'Preset:', ...
        'Items', {'Balanced', 'Crisp details', 'Smooth transitions', 'Noisy images'}, ...
        'Value', 'Balanced', ...
        'ValueChangedFcn', @onFusionPresetChanged);
    lblFusionPreset.Layout.Row = 1;
    lblFusionPreset.Layout.Column = 1;
    ddFusionPreset.Layout.Row = 1;
    ddFusionPreset.Layout.Column = 2;

    chkRegister = uicheckbox(analysisGrid, ...
        'Text', 'Auto-register stack to middle image', ...
        'Value', false);
    chkRegister.Layout.Row = 2;
    chkRegister.Layout.Column = [1 2];

    [lblFocusWindow, edtFocusWindow] = labkit.ui.view.form(analysisGrid, 'spinner', ...
        'Detail scale (px):', 'Value', 31, 'Limits', [3 99], 'Step', 2);
    lblFocusWindow.Layout.Row = 3;
    lblFocusWindow.Layout.Column = 1;
    edtFocusWindow.Layout.Row = 3;
    edtFocusWindow.Layout.Column = 2;

    [lblSmoothRadius, edtSmoothRadius] = labkit.ui.view.form(analysisGrid, 'spinner', ...
        'Blend radius (px):', 'Value', 4, 'Limits', [0 50], 'Step', 1);
    lblSmoothRadius.Layout.Row = 4;
    lblSmoothRadius.Layout.Column = 1;
    edtSmoothRadius.Layout.Row = 4;
    edtSmoothRadius.Layout.Column = 2;

    [lblUncertainBlend, edtUncertainBlend] = labkit.ui.view.form(analysisGrid, 'spinner', ...
        'Uncertain blend (%):', 'Value', 5, 'Limits', [0 100], 'Step', 1);
    lblUncertainBlend.Layout.Row = 5;
    lblUncertainBlend.Layout.Column = 1;
    edtUncertainBlend.Layout.Row = 5;
    edtUncertainBlend.Layout.Column = 2;

    btnRun = uibutton(analysisGrid, 'Text', 'Run focus stack', ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @onRunFocusStack);
    btnRun.Layout.Row = 6;
    btnRun.Layout.Column = [1 2];

    exportPanel = labkit.ui.view.section(layFA, 'Export', 3, [3 1], ...
        struct('rowHeight', {{'fit', 'fit', 'fit'}}));
    exportGrid = exportPanel.grid;

    btnExportFused = uibutton(exportGrid, 'Text', 'Export fused PNG', ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @onExportFused);
    btnExportFused.Layout.Row = 1;
    btnExportMap = uibutton(exportGrid, 'Text', 'Export focus map PNG', ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @onExportFocusMap);
    btnExportMap.Layout.Row = 2;
    btnExportSummary = uibutton(exportGrid, 'Text', 'Export summary CSV', ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @onExportSummary);
    btnExportSummary.Layout.Row = 3;

    labkit.ui.view.panel(layFA, 'text', 'Workflow Notes', 4, { ...
        '1. Load a folder or select one or more image files from the same microscope field of view.', ...
        '2. Use file selection when a folder contains bad frames that should be excluded.', ...
        '3. Start with Balanced. Use Crisp for fine texture, Smooth for visible seams, Noisy for grainy images.', ...
        '4. Detail scale controls feature size; Blend radius controls seam softness; Uncertain blend softens low-texture areas.'});

    resultTable = uitable(laySR, ...
        'ColumnName', {'Metric', 'Value'}, ...
        'Data', initialResultTable());
    resultTable.Layout.Row = 1;

    txtDetails = uitextarea(laySR, 'Editable', 'off');
    labkit.ui.view.place(txtDetails, laySR, 2);
    txtDetails.Value = {'Load a focus image folder or select image files to begin.'};

    logUi = labkit.ui.view.panel(layLog, 'log', 1, {'Ready.'});
    txtLog = logUi.textArea;
    if debugLog.enabled
        debugLog.attachTextLog(txtLog);
        debugLog.trace('Focus stack debug trace enabled.');
        debugLog.instrumentFigure(fig);
    end

    resetPreviewAxes();
    refreshSummary();

    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end

    function onOpenFolder(~, ~)
        folder = uigetdir(pwd, 'Select focus image folder');
        if isequal(folder, 0)
            addLog('Image folder selection cancelled.');
            return;
        end
        loadImageFolder(string(folder));
    end

    function onOpenFiles(~, ~)
        [files, folder] = uigetfile(focusImageDialogFilter(), ...
            'Select focus image files', pwd, 'MultiSelect', 'on');
        if isequal(files, 0)
            addLog('Image file selection cancelled.');
            return;
        end

        try
            paths = selectedFocusImagePaths(files, folder);
        catch ME
            showError('Could not select focus images', ME.message);
            return;
        end
        loadImagePaths(paths, string(folder), ...
            sprintf('Selected image files from %s', char(folder)), ...
            sprintf('Loaded %d selected image file(s).', numel(paths)));
    end

    function loadImageFolder(folder)
        try
            paths = findFocusStackImages(folder);
        catch ME
            showError('Could not load focus stack', ME.message);
            return;
        end
        loadImagePaths(paths, folder, char(folder), ...
            sprintf('Loaded %d image(s) from folder.', numel(paths)));
    end

    function loadImagePaths(paths, sourceFolder, sourceDescription, logMessage)
        try
            images = readFocusStackImages(paths);
        catch ME
            showError('Could not load focus stack', ME.message);
            return;
        end

        sourceDescription = string(sourceDescription);
        S.paths = paths;
        S.images = images;
        S.alignedImages = {};
        S.registrationLines = {};
        S.result = emptyFocusStackResult();
        S.folder = string(sourceFolder);

        txtFolder.Value = char(sourceDescription);
        lbImages.Items = displayImageNames(paths);
        if ~isempty(lbImages.Items)
            lbImages.Value = lbImages.Items{1};
        end
        addLog(logMessage);
        refreshPreview();
        refreshSummary();
    end

    function onRunFocusStack(~, ~)
        if numel(S.images) < 2
            showError('Not enough images', 'Load at least two images before running focus stacking.');
            return;
        end

        opts = currentFusionOptions();
        registerStack = chkRegister.Value;
        busyOpts = struct();
        busyOpts.title = 'Focus stacking';
        busyOpts.message = 'Fusing selected microscope images...';
        busyOpts.controls = focusStackBusyControls();
        try
            payload = labkit.ui.app.runBusy(fig, ...
                @() runFocusStackComputation(opts, registerStack), busyOpts);
        catch ME
            showError('Focus stacking failed', ME.message);
            return;
        end

        S.alignedImages = payload.imagesForFusion;
        S.registrationLines = payload.registrationLines;
        S.result = payload.result;
        addLog(sprintf('Focus stack complete: %d images fused with %s.', ...
            S.result.inputCount, S.result.method));
        for k = 1:numel(S.registrationLines)
            addLog(S.registrationLines{k});
        end
        refreshPreview();
        refreshSummary();
    end

    function opts = currentFusionOptions()
        opts = struct();
        opts.focusWindow = round(edtFocusWindow.Value);
        opts.smoothRadius = round(edtSmoothRadius.Value);
        opts.minConfidence = edtUncertainBlend.Value / 100;
    end

    function onFusionPresetChanged(~, ~)
        settings = focusFusionPresetSettings(ddFusionPreset.Value);
        edtFocusWindow.Value = settings.focusWindow;
        edtSmoothRadius.Value = settings.smoothRadius;
        edtUncertainBlend.Value = settings.minConfidencePercent;
        addLog(sprintf('Fusion preset set to %s.', ddFusionPreset.Value));
    end

    function payload = runFocusStackComputation(opts, registerStack)
        imagesForFusion = S.images;
        registrationLines = {};
        if registerStack
            [imagesForFusion, registrationLines] = alignFocusStackImages(S.images);
        end

        payload = struct();
        payload.imagesForFusion = imagesForFusion;
        payload.registrationLines = registrationLines;
        payload.result = computeFocusStack(imagesForFusion, opts);
    end

    function controls = focusStackBusyControls()
        controls = {btnOpenFolder, btnOpenFiles, lbImages, ddFusionPreset, chkRegister, ...
            edtFocusWindow, edtSmoothRadius, edtUncertainBlend, btnRun, ...
            btnExportFused, btnExportMap, btnExportSummary};
    end

    function onExportFused(~, ~)
        if ~S.result.ok
            showError('No fused image', 'Run focus stack before exporting the fused PNG.');
            return;
        end
        filepath = chooseSavePath('Export fused PNG', 'focus_stack_fused.png');
        if filepath == ""
            addLog('Export fused PNG cancelled.');
            return;
        end
        try
            imwrite(S.result.fused, filepath);
        catch ME
            showError('Could not export fused PNG', ME.message);
            return;
        end
        addLog(sprintf('Exported fused PNG: %s', filepath));
    end

    function onExportFocusMap(~, ~)
        if ~S.result.ok
            showError('No focus map', 'Run focus stack before exporting the focus map PNG.');
            return;
        end
        filepath = chooseSavePath('Export focus map PNG', 'focus_stack_map.png');
        if filepath == ""
            addLog('Export focus map PNG cancelled.');
            return;
        end
        try
            imwrite(focusIndexRgb(S.result.focusIndex, S.result.inputCount), filepath);
        catch ME
            showError('Could not export focus map PNG', ME.message);
            return;
        end
        addLog(sprintf('Exported focus map PNG: %s', filepath));
    end

    function onExportSummary(~, ~)
        if ~S.result.ok
            showError('No summary', 'Run focus stack before exporting the summary CSV.');
            return;
        end
        filepath = chooseSavePath('Export summary CSV', 'focus_stack_summary.csv');
        if filepath == ""
            addLog('Export summary CSV cancelled.');
            return;
        end
        try
            T = buildFocusStackSummaryTable(S.result, S.paths);
            writetable(T, filepath);
        catch ME
            showError('Could not export summary CSV', ME.message);
            return;
        end
        addLog(sprintf('Exported summary CSV: %s', filepath));
    end

    function filepath = chooseSavePath(titleText, defaultName)
        defaultPath = fullfile(defaultSaveFolder(), defaultName);
        [fn, fp] = uiputfile({'*.png;*.csv', 'Export files'}, titleText, defaultPath);
        if isequal(fn, 0)
            filepath = "";
        else
            filepath = string(fullfile(fp, fn));
        end
    end

    function folder = defaultSaveFolder()
        folder = char(S.folder);
        if isempty(folder) || exist(folder, 'dir') ~= 7
            folder = pwd;
        end
    end

    function refreshPreview()
        if S.result.ok
            labkit.ui.view.draw(ui.topAxes, 'image', S.result.fused, ...
                'Fused all-in-focus image');
            labkit.ui.view.draw(ui.bottomAxes, 'image', ...
                focusIndexRgb(S.result.focusIndex, S.result.inputCount), ...
                'Focus-depth index map');
        elseif ~isempty(S.images)
            labkit.ui.view.draw(ui.topAxes, 'image', previewImage(S.images{1}), ...
                'First source image');
            labkit.ui.view.draw(ui.bottomAxes, 'reset', 'Focus-depth index map', true);
        else
            resetPreviewAxes();
        end
        updateControls();
    end

    function refreshSummary()
        txtStackStatus.Value = sprintf('Images: %d', numel(S.images));
        if S.result.ok
            resultTable.Data = focusStackResultTableData(S.result);
            txtDetails.Value = focusStackDetails(S.result, S.paths, S.registrationLines);
        elseif numel(S.images) >= 2
            resultTable.Data = initialResultTable();
            txtDetails.Value = { ...
                sprintf('Loaded images: %d', numel(S.images)), ...
                'Run focus stack to compute the fused image and focus-depth map.'};
        elseif ~isempty(S.images)
            resultTable.Data = initialResultTable();
            txtDetails.Value = { ...
                sprintf('Loaded images: %d', numel(S.images)), ...
                'Load at least two images before running focus stack.'};
        else
            resultTable.Data = initialResultTable();
            txtDetails.Value = {'Load a focus image folder or select image files to begin.'};
        end
        updateControls();
    end

    function updateControls()
        hasStack = numel(S.images) >= 2;
        hasResult = S.result.ok;
        btnRun.Enable = ternary(hasStack, 'on', 'off');
        btnExportFused.Enable = ternary(hasResult, 'on', 'off');
        btnExportMap.Enable = ternary(hasResult, 'on', 'off');
        btnExportSummary.Enable = ternary(hasResult, 'on', 'off');
    end

    function resetPreviewAxes()
        labkit.ui.view.draw(ui.topAxes, 'reset', 'Fused all-in-focus image', true);
        labkit.ui.view.draw(ui.bottomAxes, 'reset', 'Focus-depth index map', true);
    end

    function addLog(message)
        labkit.ui.view.update(txtLog, 'appendLog', message);
        debugLog.append(message);
    end

    function showError(titleText, message)
        addLog(sprintf('%s: %s', titleText, message));
        uialert(fig, message, titleText);
    end
end

function filter = focusImageDialogFilter()
    filter = {'*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp', ...
        'Image files (*.png, *.jpg, *.jpeg, *.tif, *.tiff, *.bmp)'};
end

function images = readFocusStackImages(paths)
    paths = string(paths(:));
    if isempty(paths)
        error('labkit_FocusStack_app:NoImagesSelected', ...
            'Select at least one image file.');
    end
    assertSupportedFocusImagePaths(paths);

    images = cell(numel(paths), 1);
    for k = 1:numel(paths)
        if exist(paths(k), 'file') ~= 2
            error('labkit_FocusStack_app:ImageFileNotFound', ...
                'Image file does not exist: %s', char(paths(k)));
        end
        images{k} = imread(paths(k));
    end
end

function data = initialResultTable()
    data = { ...
        'Input images', '-'; ...
        'Image size', '-'; ...
        'Detail scale', '-'; ...
        'Blend radius', '-'; ...
        'Uncertain blend', '-'; ...
        'Mean confidence', '-'; ...
        'Dominant source', '-'};
end

function data = focusStackResultTableData(result)
    [dominantCoverage, dominantIndex] = max(result.focusCoverage);
    data = { ...
        'Input images', sprintf('%d', result.inputCount); ...
        'Image size', sprintf('%d x %d px', result.imageWidth, result.imageHeight); ...
        'Detail scale', sprintf('%d px', result.focusWindow); ...
        'Blend radius', sprintf('%d px', result.smoothRadius); ...
        'Uncertain blend', sprintf('%.1f%%', 100 * result.minConfidence); ...
        'Mean confidence', sprintf('%.4f', result.meanConfidence); ...
        'Dominant source', sprintf('%d (%.1f%%)', dominantIndex, 100 * dominantCoverage)};
end

function lines = focusStackDetails(result, paths, registrationLines)
    lines = { ...
        sprintf('Method: %s', result.method), ...
        sprintf('Fused size: %d x %d px, channels: %d', ...
        result.imageWidth, result.imageHeight, result.channelCount), ...
        sprintf('Images resized to first image: %d', result.resizedCount), ...
        sprintf('Detail scale: %d px; blend radius: %d px; uncertain blend: %.1f%%', ...
        result.focusWindow, result.smoothRadius, 100 * result.minConfidence), ...
        'Selected pixel coverage by source:'};
    names = displayImageNamesForDetails(paths, result.inputCount);
    for k = 1:result.inputCount
        lines{end+1} = sprintf('  %d. %s: %.2f%%', ...
            k, names{k}, 100 * result.focusCoverage(k)); %#ok<AGROW>
    end
    if ~isempty(registrationLines)
        lines{end+1} = 'Registration:'; %#ok<AGROW>
        lines = [lines, registrationLines(:).']; %#ok<AGROW>
    end
end

function names = displayImageNamesForDetails(paths, count)
    paths = string(paths(:));
    names = cell(count, 1);
    for k = 1:count
        if k <= numel(paths)
            names{k} = displayNameFromPath(paths(k));
        else
            names{k} = sprintf('slice_%03d', k);
        end
    end
end

function names = displayImageNames(paths)
    paths = string(paths(:));
    names = cell(numel(paths), 1);
    for k = 1:numel(paths)
        names{k} = displayNameFromPath(paths(k));
    end
end

function rgb = focusIndexRgb(focusIndex, imageCount)
    imageCount = max(1, double(imageCount));
    cmap = parula(max(imageCount, 2));
    idx = double(focusIndex);
    idx(~isfinite(idx) | idx < 1) = 1;
    idx(idx > imageCount) = imageCount;
    rgb = zeros(size(idx, 1), size(idx, 2), 3);
    for k = 1:imageCount
        mask = idx == k;
        for c = 1:3
            channel = rgb(:, :, c);
            channel(mask) = cmap(k, c);
            rgb(:, :, c) = channel;
        end
    end
end

function img = previewImage(img)
    img = im2double(img);
    if ndims(img) == 3 && size(img, 3) > 3
        img = img(:, :, 1:3);
    end
end

function value = ternary(condition, trueValue, falseValue)
    if condition
        value = trueValue;
    else
        value = falseValue;
    end
end
