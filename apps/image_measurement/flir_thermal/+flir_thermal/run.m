% Expected caller: labkit_FLIRThermal_app. Input is the debug context
% prepared by the public launcher. Output is the app figure. Side effects are
% GUI creation, user-driven FLIR image loading, thermal export, and debug trace
% attachment.
function fig = run(debugLog)

    S = struct();
    S.items = repmat(flir_thermal.state.emptyItem(), 0, 1);
    S.currentIndex = 0;
    S.outputFolder = string(labkit.ui.app.defaultDialogFolder("output"));
    S.lastExport = [];
    S.roiHandle = [];
    S.roiListeners = [];

    callbacks = struct( ...
        'filesChosen', @onFilesChosen, ...
        'removeFiles', @onRemoveFiles, ...
        'clearFiles', @onClearFiles, ...
        'selectionChanged', @onSelectionChanged, ...
        'previousImage', @onPreviousImage, ...
        'nextImage', @onNextImage, ...
        'autoRange', @onAutoRange, ...
        'groupRange', @onGroupRange, ...
        'perImageRange', @onPerImageRange, ...
        'roundRange', @onRoundRange, ...
        'paletteChanged', @onPaletteChanged, ...
        'rangePresetChanged', @onRangePresetChanged, ...
        'rangeChanged', @onRangeChanged, ...
        'drawRoi', @onDrawRoi, ...
        'clearRoi', @onClearRoi, ...
        'exportRoiCsv', @onExportRoiCsv, ...
        'chooseOutputFolder', @onChooseOutputFolder, ...
        'exportCurrent', @onExportCurrent, ...
        'exportAll', @onExportAll);
    spec = flir_thermal.ui.buildSpec(char(S.outputFolder), callbacks);
    ui = labkit.ui.app.create(spec, 'debug', debugLog);
    fig = ui.figure;
    if debugLog.enabled
        debugLog.trace('FLIR thermal debug trace enabled.');
        debugLog.instrumentFigure(fig);
    end

    resetPreviewAxes();
    refreshAll();

    function onFilesChosen(~, event)
        paths = labkit.ui.view.filePaths(event.files);
        if isempty(paths)
            addLog('FLIR file selection cancelled.');
            return;
        end
        try
            addLog(sprintf('Reading %d FLIR radiometric file(s).', numel(paths)));
            [S.items, report] = flir_thermal.io.readImages(paths, ...
                struct('progressFcn', @onReadProgress));
        catch ME
            showException('Could not read FLIR images', ME);
            refreshAll();
            return;
        end
        if isempty(S.items)
            S.currentIndex = 0;
            clearRoiOverlay();
        else
            S.currentIndex = 1;
            syncRangeControlsFromCurrentItem();
            loadedPaths = string({S.items.path});
            S.outputFolder = string(labkit.ui.app.defaultOutputFolder( ...
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
        removeIdx = labkit.ui.view.fileIndices(event.removedFiles, numel(S.items));
        if isempty(removeIdx)
            refreshAll();
            return;
        end
        S.items(removeIdx) = [];
        S.currentIndex = min(S.currentIndex, numel(S.items));
        if isempty(S.items)
            S.currentIndex = 0;
            clearRoiOverlay();
        end
        addLog(sprintf('Removed FLIR file(s); %d remaining.', numel(S.items)));
        refreshAll();
    end

    function onClearFiles(~, ~)
        S.items = repmat(flir_thermal.state.emptyItem(), 0, 1);
        S.currentIndex = 0;
        S.lastExport = [];
        clearRoiOverlay();
        addLog('Cleared loaded FLIR files.');
        refreshAll();
    end

    function onSelectionChanged(~, event)
        idx = labkit.ui.view.fileIndices(event.selectedFiles, numel(S.items));
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
        for k = 1:numel(S.items)
            S.items(k).displayRange = range;
            S.items(k).rangeControlBounds = ...
                controlBoundsContaining(range, itemControlBounds(S.items(k)));
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
        if ~hasCurrentItem()
            return;
        end
        current = currentRange();
        range = normalizeRange([floor(current(1)), ceil(current(2))]);
        S.items(S.currentIndex).displayRange = range;
        S.items(S.currentIndex).rangeControlBounds = ...
            controlBoundsContaining(range, currentControlBounds());
        S.items(S.currentIndex).rangeAdjusted = true;
        syncRangeControlsFromCurrentItem();
        addLog(sprintf('Rounded range for %s to %.0f to %.0f C.', ...
            char(S.items(S.currentIndex).name), range(1), range(2)));
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
        preset = string(labkit.ui.view.getValue(ui, 'rangePreset'));
        bounds = flir_thermal.view.rangeControlBounds( ...
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

    function onDrawRoi(~, ~)
        if ~hasCurrentItem()
            return;
        end
        if exist('drawrectangle', 'file') ~= 2
            showError('ROI tool unavailable', ...
                'The MATLAB drawrectangle ROI tool is not available in this installation.');
            return;
        end
        clearRoiOverlay();
        ax = ui.controls.preview.axesById.thermalImage;
        position = defaultRoiPosition(S.items(S.currentIndex));
        try
            S.roiHandle = drawrectangle(ax, 'Position', position, ...
                'Color', [1 1 1], 'FaceAlpha', 0.05);
            S.roiListeners = [ ...
                addlistener(S.roiHandle, 'MovingROI', @onRoiMoved), ...
                addlistener(S.roiHandle, 'ROIMoved', @onRoiMoved)];
            storeCurrentRoi();
            addLog(sprintf('ROI set for %s.', char(S.items(S.currentIndex).name)));
            refreshExportControls();
            refreshDetails();
        catch ME
            clearRoiOverlay();
            showException('Could not start ROI selection', ME);
        end
    end

    function onClearRoi(~, ~)
        if ~hasCurrentItem()
            return;
        end
        S.items(S.currentIndex).roiRect = [];
        clearRoiOverlay();
        addLog(sprintf('Cleared ROI for %s.', char(S.items(S.currentIndex).name)));
        refreshPreview();
        refreshExportControls();
        refreshDetails();
    end

    function onExportRoiCsv(~, ~)
        if ~hasCurrentItem()
            showError('No FLIR image selected', ...
                'Load and select a FLIR radiometric image before exporting ROI CSV.');
            return;
        end
        storeCurrentRoi();
        if isempty(S.items(S.currentIndex).roiRect)
            showError('No ROI selected', ...
                'Draw an ROI on the current thermal image before exporting ROI CSV.');
            return;
        end
        try
            opts = exportOptions(S.items(S.currentIndex));
            result = flir_thermal.export.writeRoiCsv(S.items(S.currentIndex), opts);
        catch ME
            showException('Could not export ROI CSV', ME);
            return;
        end
        addLog(sprintf('Exported ROI CSV: %s', char(result.roiCsvPath)));
        refreshDetails();
    end

    function onChooseOutputFolder(~, ~)
        [folder, cancelled] = labkit.ui.app.promptOutputFolder( ...
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
            opts = exportOptions(items);
            payload = flir_thermal.export.writeOutputs(items, opts);
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
            labkit.ui.view.setValue(ui, 'thermalFiles', {});
        else
            labkit.ui.view.setValue(ui, 'thermalFiles', ...
                flir_thermal.view.filePanelEntries(S.items));
            files = labkit.ui.view.getFiles(ui, 'thermalFiles');
            if ~isempty(files) && S.currentIndex >= 1 && S.currentIndex <= numel(files)
                labkit.ui.view.setFileSelection(ui, 'thermalFiles', files(S.currentIndex));
            end
        end
        if isempty(S.items)
            labkit.ui.view.setValue(ui, 'fileStatus', 'Files: 0');
            labkit.ui.view.setValue(ui, 'currentImage', 'No FLIR image loaded');
        else
            status = rangeStatus(S.items(S.currentIndex));
            labkit.ui.view.setValue(ui, 'fileStatus', ...
                sprintf('Files: %d | Current: %d/%d | %s', ...
                numel(S.items), S.currentIndex, numel(S.items), status));
            labkit.ui.view.setValue(ui, 'currentImage', ...
                sprintf('%s (%s)', char(S.items(S.currentIndex).name), status));
        end
    end

    function refreshPreview()
        item = currentItem();
        if isempty(item)
            resetPreviewAxes();
            return;
        end
        [values, units, label] = previewValues(item);
        range = currentRange();
        rgb = labkit.thermal.renderImage(values, ...
            struct('Limits', range, 'Palette', currentPalette()));
        labkit.ui.view.drawImage(ui, 'preview', rgb, ...
            'axis', 'thermalImage', ...
            'Title', char(label));
        restoreRoiOverlay();
        drawTemperatureScale(range, units);
    end

    function [values, units, label] = previewValues(item)
        [values, units, label] = flir_thermal.view.valueMatrix(item);
    end

    function refreshSummary()
        item = currentItem();
        range = currentRange();
        labkit.ui.view.setValue(ui, 'summaryTable', ...
            flir_thermal.view.summaryTableData(item, range, currentPalette()));
    end

    function refreshExportControls()
        hasItems = ~isempty(S.items);
        labkit.ui.view.setValue(ui, 'outputFolder', char(S.outputFolder));
        labkit.ui.view.setEnabled(ui, 'previousImage', hasItems && S.currentIndex > 1);
        labkit.ui.view.setEnabled(ui, 'nextImage', hasItems && S.currentIndex < numel(S.items));
        labkit.ui.view.setEnabled(ui, 'autoRange', hasItems && S.currentIndex >= 1);
        labkit.ui.view.setEnabled(ui, 'groupRange', hasItems);
        labkit.ui.view.setEnabled(ui, 'perImageRange', hasItems);
        labkit.ui.view.setEnabled(ui, 'roundRange', hasItems && S.currentIndex >= 1);
        labkit.ui.view.setEnabled(ui, 'rangePreset', hasItems && S.currentIndex >= 1);
        labkit.ui.view.setEnabled(ui, 'temperatureMin', hasItems && S.currentIndex >= 1);
        labkit.ui.view.setEnabled(ui, 'temperatureMax', hasItems && S.currentIndex >= 1);
        hasRoi = hasItems && S.currentIndex >= 1 && hasCurrentRoi();
        labkit.ui.view.setEnabled(ui, 'drawRoi', hasItems && S.currentIndex >= 1);
        labkit.ui.view.setEnabled(ui, 'clearRoi', hasRoi);
        labkit.ui.view.setEnabled(ui, 'exportRoiCsv', hasRoi);
        labkit.ui.view.setEnabled(ui, 'exportCurrent', hasItems && S.currentIndex >= 1);
        labkit.ui.view.setEnabled(ui, 'exportAll', hasItems);
    end

    function refreshDetails()
        labkit.ui.view.setValue(ui, 'details', ...
            flir_thermal.view.detailLines(S.items, S.currentIndex, S.outputFolder));
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
            double(labkit.ui.view.getValue(ui, 'temperatureMin'))
            double(labkit.ui.view.getValue(ui, 'temperatureMax'))]);
        S.items(S.currentIndex).displayRange = range;
        S.items(S.currentIndex).rangeAdjusted = true;
    end

    function syncRangeControlsFromCurrentItem()
        range = currentRange();
        bounds = currentControlBounds();
        labkit.ui.view.setLimits(ui, 'temperatureMin', bounds);
        labkit.ui.view.setLimits(ui, 'temperatureMax', bounds);
        labkit.ui.view.setValue(ui, 'rangePreset', currentRangePreset());
        labkit.ui.view.setValue(ui, 'temperatureMin', round(range(1) * 100) / 100);
        labkit.ui.view.setValue(ui, 'temperatureMax', round(range(2) * 100) / 100);
    end

    function preset = currentRangePreset()
        preset = "-20 to 120 C";
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
        if isfield(item, 'rangeAdjusted') && logical(item.rangeAdjusted)
            text = 'range set';
        else
            text = 'needs range';
        end
    end

    function range = autoRangeForItem(item)
        values = flir_thermal.view.valueMatrix(item);
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
        clearRoiOverlay();
        labkit.ui.view.resetAxes(ui, 'preview', 'Clean thermal image', false, ...
            'thermalImage');
        labkit.ui.view.resetAxes(ui, 'preview', 'Scale', false, ...
            'temperatureScale');
    end

    function drawTemperatureScale(range, units)
        values = linspace(range(1), range(2), 256).';
        imageData = labkit.thermal.renderImage(repmat(values, 1, 12), ...
            struct('Limits', range, 'Palette', currentPalette()));
        ax = ui.controls.preview.axesById.temperatureScale;
        cla(ax);
        image(ax, 'CData', imageData, 'XData', [0 1], 'YData', range);
        title(ax, '');
        ax.DataAspectRatioMode = 'auto';
        ax.PlotBoxAspectRatioMode = 'auto';
        ax.XLim = [0 1];
        ax.YLim = [range(1) range(2)];
        ax.YDir = 'normal';
        ax.XTick = [];
        ax.YTick = [range(1), mean(range), range(2)];
        ax.YTickLabel = cellstr(string(compose('%.1f', ax.YTick)));
        if units == "C"
            ylabel(ax, 'deg C');
        else
            ylabel(ax, char(units));
        end
    end

    function palette = currentPalette()
        palette = string(labkit.ui.view.getValue(ui, 'palette'));
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

    function opts = exportOptions(items)
        opts = struct();
        opts.outputFolder = S.outputFolder;
        opts.format = string(labkit.ui.view.getValue(ui, 'exportFormat'));
        opts.palette = currentPalette();
        opts.range = [];
    end

    function onRoiMoved(~, ~)
        storeCurrentRoi();
        refreshExportControls();
        refreshDetails();
    end

    function storeCurrentRoi()
        if ~hasCurrentItem() || isempty(S.roiHandle) || ~isvalid(S.roiHandle)
            return;
        end
        S.items(S.currentIndex).roiRect = double(S.roiHandle.Position);
    end

    function restoreRoiOverlay()
        clearRoiOverlay();
        if ~hasCurrentItem() || isempty(S.items(S.currentIndex).roiRect)
            return;
        end
        if exist('drawrectangle', 'file') ~= 2
            return;
        end
        try
            ax = ui.controls.preview.axesById.thermalImage;
            S.roiHandle = drawrectangle(ax, ...
                'Position', clampRoiRect(S.items(S.currentIndex).roiRect, ...
                S.items(S.currentIndex)), ...
                'Color', [1 1 1], 'FaceAlpha', 0.05);
            S.roiListeners = [ ...
                addlistener(S.roiHandle, 'MovingROI', @onRoiMoved), ...
                addlistener(S.roiHandle, 'ROIMoved', @onRoiMoved)];
        catch
            clearRoiOverlay();
        end
    end

    function clearRoiOverlay()
        if ~isempty(S.roiListeners)
            delete(S.roiListeners(isvalid(S.roiListeners)));
        end
        S.roiListeners = [];
        if ~isempty(S.roiHandle) && isvalid(S.roiHandle)
            delete(S.roiHandle);
        end
        S.roiHandle = [];
    end

    function tf = hasCurrentRoi()
        tf = hasCurrentItem() && isfield(S.items(S.currentIndex), 'roiRect') && ...
            ~isempty(S.items(S.currentIndex).roiRect);
    end

    function rect = defaultRoiPosition(item)
        [values] = flir_thermal.view.valueMatrix(item);
        h = size(values, 1);
        w = size(values, 2);
        rectW = max(1, round(w / 3));
        rectH = max(1, round(h / 3));
        rect = [ ...
            max(1, round((w - rectW) / 2) + 1), ...
            max(1, round((h - rectH) / 2) + 1), ...
            rectW, rectH];
    end

    function rect = clampRoiRect(rect, item)
        [values] = flir_thermal.view.valueMatrix(item);
        h = size(values, 1);
        w = size(values, 2);
        rect = double(rect(:)).';
        if numel(rect) ~= 4 || ~all(isfinite(rect)) || any(rect(3:4) <= 0)
            rect = defaultRoiPosition(item);
            return;
        end
        rect(1) = min(max(1, rect(1)), w);
        rect(2) = min(max(1, rect(2)), h);
        rect(3) = min(max(1, rect(3)), w - rect(1) + 1);
        rect(4) = min(max(1, rect(4)), h - rect(2) + 1);
    end

    function addLog(message)
        labkit.ui.view.appendLog(ui, 'logPanel', message);
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
        labkit.ui.app.showAlert(fig, message, titleText);
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
        labkit.ui.app.showAlert(fig, message, titleText);
        addLog([char(titleText) ': ' char(message)]);
    end

    function showException(titleText, ME)
        debugLog.reportException('flir_thermal', titleText, ME);
        labkit.ui.app.showAlert(fig, ME.message, titleText);
        addLog([char(titleText) ': ' ME.message]);
    end
end
