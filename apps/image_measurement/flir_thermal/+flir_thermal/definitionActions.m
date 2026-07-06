% App-owned action registry for FLIR Thermal; expected caller is flir_thermal.definition.
function actions = definitionActions()
    S = [];
    ui = [];
    fig = [];
    debugLog = [];
    readingTool = [];
    actions = struct( ...
        'startup', @onStartup, ...
        'filesChosen', @dispatchAction, ...
        'removeFiles', @dispatchAction, ...
        'clearFiles', @dispatchAction, ...
        'selectionChanged', @dispatchAction, ...
        'previousImage', @dispatchAction, ...
        'nextImage', @dispatchAction, ...
        'autoRange', @dispatchAction, ...
        'groupRange', @dispatchAction, ...
        'perImageRange', @dispatchAction, ...
        'roundRange', @dispatchAction, ...
        'paletteChanged', @dispatchAction, ...
        'rangePresetChanged', @dispatchAction, ...
        'rangeChanged', @dispatchAction, ...
        'roiHotMode', @dispatchAction, ...
        'roiColdMode', @dispatchAction, ...
        'roiMeanMode', @dispatchAction, ...
        'chooseOutputFolder', @dispatchAction, ...
        'exportCurrent', @dispatchAction, ...
        'exportAll', @dispatchAction);
    function state = onStartup(state, ~, services)
        S = state;
        ui = services.ui;
        fig = services.figure;
        debugLog = services.debug;
        if debugLog.enabled
            debugLog.trace('FLIR thermal debug trace enabled.');
            debugLog.instrumentFigure(fig);
            flir_thermal.debug.writeAndLogSamplePack(debugLog, @addLog);
        end
        readingTool = flir_thermal.userInterface.temperatureReadingTool(fig, ...
            ui.controls.preview.axesById.thermalImage, ...
            struct('onPoint', @setManualTemperaturePoint, ...
            'onRoi', @setRoiTemperatureReading));
        resetPreviewAxes();
        refreshAll();
        state = S;
    end
    function state = dispatchAction(~, payload, ~)
        switch string(payload.id)
            case "filesChosen"
                onFilesChosen([], payload.event);
            case "removeFiles"
                onRemoveFiles([], payload.event);
            case "clearFiles"
                onClearFiles([], []);
            case "selectionChanged"
                onSelectionChanged([], payload.event);
            case "previousImage"
                onPreviousImage([], []);
            case "nextImage"
                onNextImage([], []);
            case "autoRange"
                onAutoRange([], []);
            case "groupRange"
                onGroupRange([], []);
            case "perImageRange"
                onPerImageRange([], []);
            case "roundRange"
                onRoundRange([], []);
            case "paletteChanged"
                onPaletteChanged([], []);
            case "rangePresetChanged"
                onRangePresetChanged([], []);
            case "rangeChanged"
                onRangeChanged([], []);
            case "roiHotMode"
                setRoiMode("hot");
            case "roiColdMode"
                setRoiMode("cold");
            case "roiMeanMode"
                setRoiMode("mean");
            case "chooseOutputFolder"
                onChooseOutputFolder([], []);
            case "exportCurrent"
                onExportCurrent([], []);
            case "exportAll"
                onExportAll([], []);
            otherwise
                error('flir_thermal:actions:UnknownAction', ...
                    'Unknown FLIR Thermal action "%s".', payload.id);
        end
        state = S;
    end
    function onFilesChosen(~, event)
        paths = labkit.ui.control.filePaths(event.files);
        if isempty(paths)
            addLog('FLIR file selection cancelled.');
            return;
        end
        try
            addLog(sprintf('Reading %d FLIR radiometric file(s).', numel(paths)));
            [S.items, report] = flir_thermal.sourceFiles.readImages(paths, ...
                struct('progressFcn', @onReadProgress));
        catch ME
            showException('Could not read FLIR images', ME);
            refreshAll();
            return;
        end
        if isempty(S.items)
            S.currentIndex = 0;
        else
            S.currentIndex = flir_thermal.appState.currentIndexForAddedFiles(event.addedFiles, S.items);
            syncRangeControlsFromCurrentItem();
            loadedPaths = string({S.items.path});
            S.outputFolder = string(labkit.ui.runtime.defaultOutputFolder( ...
                loadedPaths, "flir_thermal", S.outputFolder));
        end
        addLog(sprintf('Loaded %d/%d FLIR radiometric image(s).', ...
            report.loaded, report.requested));
        refreshAll();
        showImportReport(report);
    end
    function onReadProgress(event)
        switch event.stage
            case "beforeRead"
                addLog(sprintf('Reading %s (%d/%d).', ...
                    char(event.name), event.index, event.count));
            case "skipped"
                addLog(sprintf('Skipped non-compatible thermal file: %s', ...
                    char(event.name)));
        end
    end
    function onRemoveFiles(~, event)
        if isempty(S.items)
            return;
        end
        removeIdx = labkit.ui.control.fileIndices(event.removedFiles, numel(S.items));
        if isempty(removeIdx)
            refreshAll();
            return;
        end
        S.items(removeIdx) = [];
        S.currentIndex = min(S.currentIndex, numel(S.items));
        if isempty(S.items)
            S.currentIndex = 0;
        end
        addLog(sprintf('Removed FLIR file(s); %d remaining.', numel(S.items)));
        refreshAll();
    end
    function onClearFiles(~, ~)
        S.items = repmat(flir_thermal.appState.emptyItem(), 0, 1);
        S.currentIndex = 0;
        S.lastExport = [];
        addLog('Cleared loaded FLIR files.');
        refreshAll();
    end
    function onSelectionChanged(~, event)
        idx = labkit.ui.control.fileIndices(event.selectedFiles, numel(S.items));
        if isempty(idx)
            return;
        end
        S.currentIndex = idx(1);
        syncRangeControlsFromCurrentItem();
        refreshAll();
    end
    function onPreviousImage(~, ~)
        if isempty(S.items)
            return;
        end
        S.currentIndex = max(1, S.currentIndex - 1);
        syncRangeControlsFromCurrentItem();
        refreshAll();
    end
    function onNextImage(~, ~)
        if isempty(S.items)
            return;
        end
        S.currentIndex = min(numel(S.items), S.currentIndex + 1);
        syncRangeControlsFromCurrentItem();
        refreshAll();
    end
    function onAutoRange(~, ~)
        if ~hasCurrentItem()
            return;
        end
        range = autoRangeForItem(S.items(S.currentIndex));
        S.items(S.currentIndex).displayRange = range;
        S.items(S.currentIndex).rangeControlBounds = ...
            controlBoundsContaining(range, currentControlBounds());
        S.items(S.currentIndex).rangeAdjusted = true;
        syncRangeControlsFromCurrentItem();
        addLog(sprintf('Auto range set for %s.', char(S.items(S.currentIndex).name)));
        refreshAll();
    end
    function onGroupRange(~, ~)
        if isempty(S.items)
            return;
        end
        ranges = zeros(numel(S.items), 2);
        for k = 1:numel(S.items)
            ranges(k, :) = autoRangeForItem(S.items(k));
        end
        range = normalizeRange([min(ranges(:, 1)), max(ranges(:, 2))]);
        sharedBounds = range;
        for k = 1:numel(S.items)
            S.items(k).displayRange = range;
            S.items(k).rangeControlBounds = sharedBounds;
            S.items(k).rangeAdjusted = true;
        end
        syncRangeControlsFromCurrentItem();
        addLog(sprintf('Set all FLIR files to group range %.3g to %.3g C.', ...
            range(1), range(2)));
        refreshAll();
    end
    function onPerImageRange(~, ~)
        if isempty(S.items)
            return;
        end
        for k = 1:numel(S.items)
            range = autoRangeForItem(S.items(k));
            S.items(k).displayRange = range;
            S.items(k).rangeControlBounds = ...
                controlBoundsContaining(range, itemControlBounds(S.items(k)));
            S.items(k).rangeAdjusted = true;
        end
        syncRangeControlsFromCurrentItem();
        addLog(sprintf('Set each FLIR file to its own measured range (%d files).', ...
            numel(S.items)));
        refreshAll();
    end
    function onRoundRange(~, ~)
        if isempty(S.items)
            return;
        end
        roundedCount = 0;
        for k = 1:numel(S.items)
            if ~isRangeAdjusted(S.items(k))
                continue;
            end
            range = roundRangeOutward(S.items(k).displayRange);
            S.items(k).displayRange = range;
            S.items(k).rangeControlBounds = ...
                controlBoundsContaining(range, itemControlBounds(S.items(k)));
            roundedCount = roundedCount + 1;
        end
        syncRangeControlsFromCurrentItem();
        addLog(sprintf('Rounded %d already-set FLIR range(s) outward to integer C.', ...
            roundedCount));
        refreshAll();
    end
    function onPaletteChanged(~, ~)
        refreshPreview();
        refreshSummary();
    end
    function onRangePresetChanged(~, ~)
        if ~hasCurrentItem()
            return;
        end
        preset = string(labkit.ui.control.getValue(ui, 'rangePreset'));
        bounds = flir_thermal.userInterface.rangeControlBounds( ...
            S.items(S.currentIndex), preset, currentControlBounds());
        S.items(S.currentIndex).rangePreset = preset;
        S.items(S.currentIndex).rangeControlBounds = bounds;
        clampedRange = clampRangeToBounds(currentRange(), bounds);
        if ~isequaln(clampedRange, currentRange())
            S.items(S.currentIndex).displayRange = clampedRange;
            S.items(S.currentIndex).rangeAdjusted = true;
        end
        syncRangeControlsFromCurrentItem();
        refreshAll();
    end
    function onRangeChanged(~, ~)
        commitCurrentRangeFromControls();
        refreshAll();
    end
    function setRoiMode(mode)
        S.roiMode = string(mode);
        addLog(sprintf('ROI reading mode set to %s. Drag on the thermal image to set the ROI.', ...
            char(flir_thermal.userInterface.roiModeLabel(S.roiMode))));
        refreshExportControls();
        refreshDetails();
    end
    function onChooseOutputFolder(~, ~)
        [folder, cancelled] = labkit.ui.runtime.promptOutputFolder( ...
            'Select FLIR thermal export folder', S.outputFolder);
        if cancelled
            addLog('Export folder selection cancelled.');
            return;
        end
        S.outputFolder = string(folder);
        refreshExportControls();
        refreshDetails();
    end
    function onExportCurrent(~, ~)
        if isempty(S.items) || S.currentIndex < 1
            showError('No FLIR image selected', ...
                'Load and select a FLIR radiometric image before exporting.');
            return;
        end
        exportItems(S.items(S.currentIndex), 'current image');
    end
    function onExportAll(~, ~)
        if isempty(S.items)
            showError('No FLIR images loaded', ...
                'Load FLIR radiometric images before exporting.');
            return;
        end
        exportItems(S.items, 'loaded images');
    end
    function exportItems(items, label)
        try
            opts = exportOptions();
            payload = flir_thermal.resultFiles.writeOutputs(items, opts);
        catch ME
            showException('Could not export FLIR thermal images', ME);
            return;
        end
        S.lastExport = payload;
        saved = sum(string({payload.results.status}) == "saved");
        addLog(sprintf('Exported %d/%d %s. Manifest: %s', ...
            saved, numel(payload.results), label, char(payload.manifestPath)));
        refreshDetails();
    end
    function refreshAll()
        syncRangeControlsFromCurrentItem();
        refreshFileStatus();
        refreshPreview();
        refreshSummary();
        refreshExportControls();
        refreshDetails();
    end
    function refreshFileStatus()
        if isempty(S.items)
            labkit.ui.control.setValue(ui, 'thermalFiles', {});
        else
            labkit.ui.control.setValue(ui, 'thermalFiles', ...
                flir_thermal.userInterface.filePanelEntries(S.items));
            files = labkit.ui.control.getFiles(ui, 'thermalFiles');
            if ~isempty(files) && S.currentIndex >= 1 && S.currentIndex <= numel(files)
                labkit.ui.control.setFileSelection(ui, 'thermalFiles', files(S.currentIndex));
            end
        end
        if isempty(S.items)
            labkit.ui.control.setValue(ui, 'fileStatus', 'Files: 0');
            labkit.ui.control.setValue(ui, 'currentImage', 'No FLIR image loaded');
        else
            status = rangeStatus(S.items(S.currentIndex));
            labkit.ui.control.setValue(ui, 'fileStatus', ...
                sprintf('Files: %d | Current: %d/%d | %s', ...
                numel(S.items), S.currentIndex, numel(S.items), status));
            labkit.ui.control.setValue(ui, 'currentImage', ...
                sprintf('%s (%s)', char(S.items(S.currentIndex).name), status));
        end
    end
    function refreshPreview()
        item = currentItem();
        if isempty(item)
            resetPreviewAxes();
            return;
        end
        [values, units, label] = flir_thermal.userInterface.valueMatrix(item);
        range = currentRange();
        rgb = flir_thermal.userInterface.renderThermalImage(values, ...
            range, currentPalette(), ...
            string(labkit.ui.control.getValue(ui, 'colorMapping')), currentGamma());
        imageHandle = labkit.ui.plot.image(ui, 'preview', rgb, ...
            'axis', 'thermalImage', ...
            'title', char(label), ...
            'options', struct('hitTest', 'on', ...
            'pickableParts', 'visible'));
        ax = ui.controls.preview.axesById.thermalImage;
        readingTool.setBackground(imageHandle);
        readingTool.activate();
        flir_thermal.userInterface.drawTemperatureReadings(ax, item);
        flir_thermal.userInterface.drawTemperatureScale(ui, range, units, ...
            currentPalette(), string(labkit.ui.control.getValue(ui, 'colorMapping')), ...
            currentGamma());
    end
    function setManualTemperaturePoint(pointXY)
        if ~hasCurrentItem()
            return;
        end
        [S.items(S.currentIndex), reading] = ...
            flir_thermal.appState.withManualPoint(S.items(S.currentIndex), pointXY);
        if ~isfinite(reading.temperatureC)
            return;
        end
        S.items(S.currentIndex).manualPoint = reading;
        addLog(sprintf('Set manual point for %s: x=%.0f, y=%.0f, %.2f C.', ...
            char(S.items(S.currentIndex).name), reading.x, reading.y, ...
            reading.temperatureC));
        refreshPreview();
        refreshSummary();
        refreshDetails();
        syncRuntimeState();
    end
    function setRoiTemperatureReading(startXY, endXY)
        if ~hasCurrentItem()
            return;
        end
        [S.items(S.currentIndex), meanReading] = ...
            flir_thermal.appState.withRoiReading(S.items(S.currentIndex), ...
            S.roiMode, startXY, endXY);
        if ~isfinite(meanReading.temperatureC)
            return;
        end
        addLog(sprintf('Set %s ROI for %s.', ...
            char(flir_thermal.userInterface.roiModeLabel(S.roiMode)), ...
            char(S.items(S.currentIndex).name)));
        refreshPreview();
        refreshSummary();
        refreshDetails();
        syncRuntimeState();
    end
    function refreshSummary()
        item = currentItem();
        range = currentRange();
        labkit.ui.control.setValue(ui, 'summaryTable', ...
            flir_thermal.userInterface.summaryTableData(item, range, currentPalette()));
    end
    function refreshExportControls()
        hasItems = ~isempty(S.items);
        labkit.ui.control.setValue(ui, 'outputFolder', char(S.outputFolder));
        labkit.ui.control.setEnabled(ui, 'previousImage', hasItems && S.currentIndex > 1);
        labkit.ui.control.setEnabled(ui, 'nextImage', hasItems && S.currentIndex < numel(S.items));
        labkit.ui.control.setEnabled(ui, 'autoRange', hasItems && S.currentIndex >= 1);
        labkit.ui.control.setEnabled(ui, 'groupRange', hasItems);
        labkit.ui.control.setEnabled(ui, 'perImageRange', hasItems);
        labkit.ui.control.setEnabled(ui, 'roundRange', hasItems && anyRangeAdjusted());
        labkit.ui.control.setEnabled(ui, 'rangePreset', hasItems && S.currentIndex >= 1);
        labkit.ui.control.setEnabled(ui, 'temperatureMin', hasItems && S.currentIndex >= 1);
        labkit.ui.control.setEnabled(ui, 'temperatureMax', hasItems && S.currentIndex >= 1);
        labkit.ui.control.setEnabled(ui, 'roiHotMode', hasItems && S.currentIndex >= 1);
        labkit.ui.control.setEnabled(ui, 'roiColdMode', hasItems && S.currentIndex >= 1);
        labkit.ui.control.setEnabled(ui, 'roiMeanMode', hasItems && S.currentIndex >= 1);
        labkit.ui.control.setEnabled(ui, 'exportCurrent', hasItems && S.currentIndex >= 1);
        labkit.ui.control.setEnabled(ui, 'exportAll', hasItems);
    end
    function refreshDetails()
        labkit.ui.control.setValue(ui, 'details', ...
            flir_thermal.userInterface.detailLines(S.items, S.currentIndex, S.outputFolder));
    end
    function item = currentItem()
        item = [];
        if hasCurrentItem()
            item = S.items(S.currentIndex);
        end
    end
    function tf = hasCurrentItem()
        tf = ~isempty(S.items) && S.currentIndex >= 1 && S.currentIndex <= numel(S.items);
    end
    function range = currentRange()
        if hasCurrentItem()
            range = normalizeRange(S.items(S.currentIndex).displayRange);
            return;
        end
        range = [20 40];
    end
    function commitCurrentRangeFromControls()
        if ~hasCurrentItem()
            return;
        end
        range = normalizeRange([
            double(labkit.ui.control.getValue(ui, 'temperatureMin'))
            double(labkit.ui.control.getValue(ui, 'temperatureMax'))]);
        S.items(S.currentIndex).displayRange = range;
        S.items(S.currentIndex).rangeAdjusted = true;
    end
    function syncRangeControlsFromCurrentItem()
        range = currentRange();
        bounds = currentControlBounds();
        labkit.ui.control.setLimits(ui, 'temperatureMin', bounds);
        labkit.ui.control.setLimits(ui, 'temperatureMax', bounds);
        labkit.ui.control.setValue(ui, 'rangePreset', currentRangePreset());
        labkit.ui.control.setValue(ui, 'temperatureMin', round(range(1) * 100) / 100);
        labkit.ui.control.setValue(ui, 'temperatureMax', round(range(2) * 100) / 100);
    end
    function preset = currentRangePreset()
        labels = flir_thermal.userInterface.rangeControlLabels();
        preset = labels.defaultPreset;
        if hasCurrentItem() && isfield(S.items(S.currentIndex), 'rangePreset') && ...
                strlength(string(S.items(S.currentIndex).rangePreset)) > 0
            preset = string(S.items(S.currentIndex).rangePreset);
        end
    end
    function bounds = currentControlBounds()
        bounds = [-20 120];
        if hasCurrentItem() && isfield(S.items(S.currentIndex), 'rangeControlBounds')
            bounds = normalizeRange(S.items(S.currentIndex).rangeControlBounds);
        end
        bounds = controlBoundsContaining(currentRange(), bounds);
    end
    function bounds = itemControlBounds(item)
        bounds = [-20 120];
        if isfield(item, 'rangeControlBounds')
            bounds = normalizeRange(item.rangeControlBounds);
        end
        if isfield(item, 'displayRange')
            bounds = controlBoundsContaining(item.displayRange, bounds);
        end
    end
    function text = rangeStatus(item)
        if isRangeAdjusted(item)
            text = 'range set';
        else
            text = 'needs range';
        end
    end
    function tf = isRangeAdjusted(item)
        tf = isfield(item, 'rangeAdjusted') && logical(item.rangeAdjusted);
    end
    function tf = anyRangeAdjusted()
        tf = false;
        for item = reshape(S.items, 1, [])
            if isRangeAdjusted(item)
                tf = true;
                return;
            end
        end
    end
    function range = roundRangeOutward(range)
        range = normalizeRange(range);
        range = normalizeRange([floor(range(1)), ceil(range(2))]);
    end
    function range = autoRangeForItem(item)
        values = flir_thermal.userInterface.valueMatrix(item);
        values = values(isfinite(values));
        if isempty(values)
            range = currentRange();
            return;
        end
        range = normalizeRange([min(values), max(values)]);
    end
    function range = normalizeRange(range)
        range = double(range(:)).';
        if numel(range) ~= 2 || ~all(isfinite(range))
            range = [20 40];
        end
        range = sort(range);
        if range(2) <= range(1)
            range(2) = range(1) + 1;
        end
    end
    function resetPreviewAxes()
        labkit.ui.plot.reset(ui, 'preview', 'Clean thermal image', false, ...
            'thermalImage');
        labkit.ui.plot.reset(ui, 'preview', 'Scale', false, ...
            'temperatureScale');
    end
    function syncRuntimeState()
        if isempty(fig) || ~isvalid(fig) || ...
                ~isappdata(fig, 'labkitUiAppRuntime')
            return;
        end
        runtime = getappdata(fig, 'labkitUiAppRuntime');
        runtime.state = S;
        setappdata(fig, 'labkitUiAppRuntime', runtime);
    end
    function palette = currentPalette()
        palette = string(labkit.ui.control.getValue(ui, 'palette'));
    end
    function value = currentGamma()
        value = flir_thermal.userInterface.normalizeGammaValue( ...
            labkit.ui.control.getValue(ui, 'gammaValue'));
    end
    function range = clampRangeToBounds(range, bounds)
        range = normalizeRange(range);
        bounds = normalizeRange(bounds);
        range = min(bounds(2), max(bounds(1), range));
        if range(2) <= range(1)
            range = bounds;
        end
    end
    function bounds = controlBoundsContaining(range, bounds)
        range = normalizeRange(range);
        bounds = normalizeRange(bounds);
        bounds = [min(bounds(1), range(1)), max(bounds(2), range(2))];
        if bounds(2) <= bounds(1)
            bounds(2) = bounds(1) + 1;
        end
    end
    function opts = exportOptions()
        opts = struct();
        opts.outputFolder = S.outputFolder;
        opts.format = string(labkit.ui.control.getValue(ui, 'exportFormat'));
        opts.palette = currentPalette();
        opts.colorMapping = string(labkit.ui.control.getValue(ui, 'colorMapping'));
        opts.gammaValue = currentGamma();
        opts.range = [];
    end
    function addLog(message)
        labkit.ui.control.appendLog(ui, 'logPanel', message);
    end
    function showImportReport(report)
        if report.skipped == 0
            return;
        end
        if report.loaded == 0
            titleText = 'No compatible FLIR thermal data found';
        else
            titleText = 'Some files were skipped';
        end
        message = importReportMessage(report);
        labkit.ui.runtime.showAlert(fig, message, titleText);
        addLog([char(titleText) ': ' char(message)]);
    end
    function message = importReportMessage(report)
        if report.loaded == 0
            prefix = sprintf(['None of the %d selected file(s) contained ' ...
                'readable FLIR radiometric thermal data.'], report.requested);
        else
            prefix = sprintf(['Loaded %d compatible FLIR radiometric file(s) ' ...
                'and skipped %d file(s) without readable thermal data.'], ...
                report.loaded, report.skipped);
        end
        message = string(prefix);
        names = string({report.failures.name});
        if ~isempty(names)
            names = names(1:min(numel(names), 5));
            message = message + newline + "Skipped: " + strjoin(names, ", ");
            if report.skipped > numel(names)
                message = message + sprintf(" and %d more", report.skipped - numel(names));
            end
        end
    end
    function showError(titleText, message)
        labkit.ui.runtime.showAlert(fig, message, titleText);
        addLog([char(titleText) ': ' char(message)]);
    end
    function showException(titleText, ME)
        debugLog.reportException('flir_thermal', titleText, ME);
        labkit.ui.runtime.showAlert(fig, ME.message, titleText);
        addLog([char(titleText) ': ' ME.message]);
    end
end
