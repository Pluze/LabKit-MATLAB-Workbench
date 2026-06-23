% Expected caller: labkit_FocusStack_app. Input is the debug context prepared
% by the public launcher. Output is the app figure. Side effects are GUI
% creation, user-driven image loading, focus-stack export, and debug trace attachment.
function fig = run(debugLog)
%RUN Build and run the Focus Stack app body.

    S = struct();
    S.folder = "";
    S.paths = strings(0, 1);
    S.images = {};
    S.alignedImages = {};
    S.registrationLines = {};
    S.result = focus_stack.state.emptyResult();

    fusionPresets = {'Balanced', 'Crisp details', 'Smooth transitions', 'Noisy images'};
    workflowNotes = { ...
        '1. Load a folder or select one or more image files from the same microscope field of view.', ...
        '2. Use file selection when a folder contains bad frames that should be excluded.', ...
        '3. Start with Balanced. Use Crisp for fine texture, Smooth for visible seams, Noisy for grainy images.', ...
        '4. Detail scale controls feature size; Blend radius controls seam softness; Uncertain blend softens low-texture areas.'};
    callbacks = struct( ...
        'openImageFolder', @onOpenFolder, ...
        'sourceImagesChosen', @onOpenFilesChosen, ...
        'clearImages', @onClearImages, ...
        'fusionPresetChanged', @onFusionPresetChanged, ...
        'runFocusStack', @onRunFocusStack, ...
        'exportFused', @onExportFused, ...
        'exportFocusMap', @onExportFocusMap, ...
        'exportSummary', @onExportSummary);
    spec = focus_stack.ui.buildSpec(fusionPresets, workflowNotes, callbacks);
    ui = labkit.ui.app.create(spec, 'debug', debugLog);
    fig = ui.figure;
    if debugLog.enabled
        debugLog.trace('Focus stack debug trace enabled.');
        debugLog.instrumentFigure(fig);
    end

    resetPreviewAxes();
    refreshSummary();

    function onOpenFolder(~, ~)
        folder = uigetdir(labkit.ui.app.defaultDialogFolder("input"), ...
            'Select focus image folder');
        if isequal(folder, 0)
            addLog('Image folder selection cancelled.');
            return;
        end
        loadImageFolder(string(folder));
    end

    function onOpenFilesChosen(~, event)
        loadImagePaths(event.paths, string(fileparts(event.paths(1))), ...
            sprintf('Selected image files from %s', char(fileparts(event.paths(1)))), ...
            sprintf('Loaded %d selected image file(s).', numel(event.paths)));
    end

    function onClearImages(~, ~)
        S.folder = "";
        S.paths = strings(0, 1);
        S.images = {};
        S.alignedImages = {};
        S.registrationLines = {};
        S.result = focus_stack.state.emptyResult();
        addLog('Cleared loaded focus images and results.');
        refreshSourcePanel();
        refreshPreview();
        refreshSummary();
    end

    function loadImageFolder(folder)
        try
            paths = focus_stack.io.findImages(folder);
        catch ME
            showError('Could not load focus stack', ME.message);
            return;
        end
        loadImagePaths(paths, folder, char(folder), ...
            sprintf('Loaded %d image(s) from folder.', numel(paths)));
    end

    function loadImagePaths(paths, sourceFolder, sourceDescription, logMessage)
        try
            images = focus_stack.io.readImages(paths);
        catch ME
            showError('Could not load focus stack', ME.message);
            return;
        end

        S.paths = string(paths(:));
        S.images = images;
        S.alignedImages = {};
        S.registrationLines = {};
        S.result = focus_stack.state.emptyResult();
        S.folder = string(sourceFolder);

        labkit.ui.view.setValue(ui, 'sourceLocation', char(string(sourceDescription)));
        addLog(logMessage);
        refreshSourcePanel();
        refreshPreview();
        refreshSummary();
    end

    function onRunFocusStack(~, ~)
        if numel(S.images) < 2
            showError('Not enough images', 'Load at least two images before running focus stacking.');
            return;
        end

        opts = currentFusionOptions();
        registerStack = labkit.ui.view.getValue(ui, 'autoRegister');
        try
            payload = runFocusStackComputation(opts, registerStack);
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
        opts.focusWindow = round(labkit.ui.view.getValue(ui, 'focusWindow'));
        opts.smoothRadius = round(labkit.ui.view.getValue(ui, 'smoothRadius'));
        opts.minConfidence = labkit.ui.view.getValue(ui, 'uncertainBlend') / 100;
    end

    function onFusionPresetChanged(~, ~)
        settings = focus_stack.state.fusionPresetSettings( ...
            labkit.ui.view.getValue(ui, 'fusionPreset'));
        labkit.ui.view.setValue(ui, 'focusWindow', settings.focusWindow);
        labkit.ui.view.setValue(ui, 'smoothRadius', settings.smoothRadius);
        labkit.ui.view.setValue(ui, 'uncertainBlend', settings.minConfidencePercent);
        addLog(sprintf('Fusion preset set to %s.', ...
            labkit.ui.view.getValue(ui, 'fusionPreset')));
    end

    function payload = runFocusStackComputation(opts, registerStack)
        imagesForFusion = S.images;
        registrationLines = {};
        if registerStack
            [imagesForFusion, registrationLines] = focus_stack.ops.alignImages(S.images);
        end

        payload = struct();
        payload.imagesForFusion = imagesForFusion;
        payload.registrationLines = registrationLines;
        payload.result = focus_stack.ops.computeFocusStack(imagesForFusion, opts);
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
            imwrite(focus_stack.view.focusIndexRgb(S.result.focusIndex, S.result.inputCount), filepath);
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
            T = focus_stack.export.buildSummaryTable(S.result, S.paths);
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
            folder = labkit.ui.app.defaultDialogFolder("output");
        end
    end

    function refreshSourcePanel()
        if isempty(S.images)
            labkit.ui.view.setValue(ui, 'sourceImages', {});
            labkit.ui.view.setValue(ui, 'sourceLocation', 'No images loaded');
            return;
        end

        labkit.ui.view.setValue(ui, 'sourceImages', cellstr(S.paths));
    end

    function refreshPreview()
        if S.result.ok
            labkit.ui.view.drawImage(ui, 'preview', S.result.fused, ...
                'axis', 'fused', 'title', 'Fused all-in-focus image');
            labkit.ui.view.drawImage(ui, 'preview', ...
                focus_stack.view.focusIndexRgb(S.result.focusIndex, S.result.inputCount), ...
                'axis', 'focusMap', 'title', 'Focus-depth index map');
        elseif ~isempty(S.images)
            labkit.ui.view.drawImage(ui, 'preview', ...
                focus_stack.view.previewImage(S.images{1}), ...
                'axis', 'fused', 'title', 'First source image');
            labkit.ui.view.resetAxes(ui, 'preview', 'Focus-depth index map', true, 'focusMap');
        else
            resetPreviewAxes();
        end
        updateControls();
    end

    function refreshSummary()
        if S.result.ok
            ui.controls.resultTable.table.Data = focus_stack.view.resultTableData(S.result);
            labkit.ui.view.setValue(ui, 'details', ...
                focus_stack.view.details(S.result, S.paths, S.registrationLines));
        elseif numel(S.images) >= 2
            ui.controls.resultTable.table.Data = focus_stack.view.initialResultTable();
            labkit.ui.view.setValue(ui, 'details', { ...
                sprintf('Loaded images: %d', numel(S.images)), ...
                'Run focus stack to compute the fused image and focus-depth map.'});
        elseif ~isempty(S.images)
            ui.controls.resultTable.table.Data = focus_stack.view.initialResultTable();
            labkit.ui.view.setValue(ui, 'details', { ...
                sprintf('Loaded images: %d', numel(S.images)), ...
                'Load at least two images before running focus stack.'});
        else
            ui.controls.resultTable.table.Data = focus_stack.view.initialResultTable();
            labkit.ui.view.setValue(ui, 'details', ...
                {'Load a focus image folder or select image files to begin.'});
        end
        updateControls();
    end

    function updateControls()
        hasImages = ~isempty(S.images);
        hasStack = numel(S.images) >= 2;
        hasResult = S.result.ok;
        ui.controls.sourceImages.clearButton.Enable = onOff(hasImages);
        ui.controls.sourceImages.listbox.Enable = onOff(hasImages);
        labkit.ui.view.setEnabled(ui, 'runFocusStack', hasStack);
        labkit.ui.view.setEnabled(ui, 'exportFused', hasResult);
        labkit.ui.view.setEnabled(ui, 'exportFocusMap', hasResult);
        labkit.ui.view.setEnabled(ui, 'exportSummary', hasResult);
    end

    function resetPreviewAxes()
        labkit.ui.view.resetAxes(ui, 'preview', 'Fused all-in-focus image', true, 'fused');
        labkit.ui.view.resetAxes(ui, 'preview', 'Focus-depth index map', true, 'focusMap');
    end

    function addLog(message)
        labkit.ui.view.appendLog(ui, 'logPanel', message);
        debugLog.append(message);
    end

    function showError(titleText, message)
        addLog(sprintf('%s: %s', titleText, message));
        uialert(fig, message, titleText);
    end
end

function text = onOff(value)
    if islogical(value) && isscalar(value)
        if value
            text = 'on';
        else
            text = 'off';
        end
    else
        text = char(string(value));
    end
end
