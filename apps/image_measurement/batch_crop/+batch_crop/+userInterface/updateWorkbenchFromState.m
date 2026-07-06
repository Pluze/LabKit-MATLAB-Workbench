% App-owned renderer for Batch Image Crop. Expected caller is
% labkit.ui.runtime.run after actions update state. Inputs are app state and UI
% registry. Side effects are limited to UI controls, preview axes, scale-bar
% tool state, tables, and status text.
function updateWorkbenchFromState(state, ui, services)
    renderList(state, ui);
    renderControls(state, ui, services);
    renderPreview(state, ui);
    renderSummary(state, ui, services);
end

function renderList(state, ui)
    if isempty(state.items)
        labkit.ui.control.setListItems(ui, 'images', {});
        ui.controls.imageSource.valueHandle.Value = 'No images loaded';
        ui.controls.imageStatus.valueHandle.Value = 'Images: 0';
        return;
    end

    labkit.ui.control.setValue(ui, 'images', batch_crop.userInterface.filePanelEntries( ...
        state.items, string(ui.controls.scaleMode.valueHandle.Value)));
    currentIndex = currentIndexOrOne(state);
    files = labkit.ui.control.getFiles(ui, 'images');
    labkit.ui.control.setFileSelection(ui, 'images', files(currentIndex));
    ui.controls.imageSource.valueHandle.Value = ...
        char(state.items(currentIndex).path);
    if strcmpi(string(ui.controls.scaleMode.valueHandle.Value), "Physical")
        scaleSummary = batch_crop.appState.scaleCalibrationSummary(state.items);
        ui.controls.imageStatus.valueHandle.Value = sprintf( ...
            'Images: %d | centers: %d | scales: %d', ...
            numel(state.items), ...
            batch_crop.appState.countConfirmedCenters(state.items), ...
            scaleSummary.calibratedCount);
    else
        ui.controls.imageStatus.valueHandle.Value = sprintf( ...
            'Images: %d | confirmed centers: %d', numel(state.items), ...
            batch_crop.appState.countConfirmedCenters(state.items));
    end
end

function renderControls(state, ui, services)
    hasImage = hasCurrentImage(state);
    enabled = batch_crop.userInterface.ternary(hasImage, 'on', 'off');
    physicalMode = strcmpi(string(ui.controls.scaleMode.valueHandle.Value), ...
        "Physical");
    ui.controls.images.clearButton.Enable = enabled;
    ui.controls.duplicateImage.button.Enable = enabled;
    ui.controls.previousImage.button.Enable = batch_crop.userInterface.ternary( ...
        hasImage && state.currentIndex > 1, 'on', 'off');
    ui.controls.nextImage.button.Enable = batch_crop.userInterface.ternary( ...
        hasImage && state.currentIndex < numel(state.items), 'on', 'off');
    labkit.ui.control.setEnabled(ui, "cropWidth", hasImage && ~physicalMode);
    labkit.ui.control.setEnabled(ui, "cropHeight", hasImage && ~physicalMode);
    labkit.ui.control.setEnabled(ui, "rotation", hasImage);
    labkit.ui.control.setEnabled(ui, "paddingPercent", hasImage);
    labkit.ui.control.setEnabled(ui, "centerX", hasImage);
    labkit.ui.control.setEnabled(ui, "centerY", hasImage);
    ui.controls.useImageCenter.button.Enable = enabled;
    ui.controls.useImageXCenter.button.Enable = enabled;
    ui.controls.useImageYCenter.button.Enable = enabled;
    ui.controls.scaleUnit.valueHandle.Enable = ...
        batch_crop.userInterface.ternary(physicalMode, 'on', 'off');
    labkit.ui.control.setEnabled(ui, "physicalWidth", hasImage && physicalMode);
    labkit.ui.control.setEnabled(ui, "physicalHeight", hasImage && physicalMode);
    labkit.ui.control.setEnabled(ui, "targetPixelsPerUnit", ...
        hasImage && physicalMode);
    labkit.ui.control.setEnabled(ui, "maxUpsamplePercent", ...
        hasImage && physicalMode);

    if hasImage
        item = state.items(state.currentIndex);
        cropLimit = batch_crop.cropGeometry.cropSizeUpperLimit(item.image);
        labkit.ui.control.setLimits(ui, "cropWidth", [1, cropLimit]);
        labkit.ui.control.setLimits(ui, "cropHeight", [1, cropLimit]);
        if ~state.cropDefaultsInitialized
            labkit.ui.control.setValue(ui, "cropWidth", ...
                max(1, round(size(item.image, 2) * 0.7)));
            labkit.ui.control.setValue(ui, "cropHeight", ...
                max(1, round(size(item.image, 1) * 0.7)));
        end
        geometry = currentGeometry(state, ui);
        centerLimits = batch_crop.userInterface.centerCoordinateLimits(geometry);
        labkit.ui.control.setLimits(ui, "centerX", centerLimits.x);
        labkit.ui.control.setLimits(ui, "centerY", centerLimits.y);
        labkit.ui.control.setValue(ui, "rotation", item.angleDeg);
        labkit.ui.control.setValue(ui, "paddingPercent", ...
            batch_crop.appState.itemPaddingPercent(item, ...
            ui.controls.paddingPercent.valueHandle.Value));
        if ~isempty(item.centerXY) && all(isfinite(item.centerXY))
            labkit.ui.control.setValue(ui, "centerX", item.centerXY(1));
            labkit.ui.control.setValue(ui, "centerY", item.centerXY(2));
        end
    else
        labkit.ui.control.setLimits(ui, "cropWidth", [1, 100000]);
        labkit.ui.control.setLimits(ui, "cropHeight", [1, 100000]);
        labkit.ui.control.setValue(ui, "rotation", 0);
        labkit.ui.control.setValue(ui, "paddingPercent", 0);
        labkit.ui.control.setLimits(ui, "centerX", [1, 100000]);
        labkit.ui.control.setLimits(ui, "centerY", [1, 100000]);
        labkit.ui.control.setValue(ui, "centerX", 1);
        labkit.ui.control.setValue(ui, "centerY", 1);
    end

    ui.controls.outputFolder.valueHandle.Value = char(state.outputFolder);
    refreshScaleControls(state, ui, services, []);
    ui.controls.exportCrops.button.Enable = enabled;
end

function renderPreview(state, ui)
    if ~hasCurrentImage(state) || ~hasTools(state)
        resetPreviewAxes(ui);
        if hasTools(state)
            state.tools.cropSession.setBackground([]);
            state.tools.cropSession.setGraphics([]);
            state.tools.scaleTool.setBackground([]);
            state.tools.scaleTool.setImageSize([]);
        end
        return;
    end
    geometry = currentGeometry(state, ui);
    placement = batch_crop.userInterface.previewPlacement(geometry);
    item = state.items(state.currentIndex);
    tools = struct('scaleTool', state.tools.scaleTool, ...
        'cropSession', state.tools.cropSession);
    batch_crop.userInterface.drawPreview(ui, state.tools.previewAxes, geometry, ...
        placement, item, currentCropSize(state, ui), tools, ...
        state.previewView);
end

function renderSummary(state, ui, services)
    cropSize = currentCropSize(state, ui);
    ui.controls.resultTable.table.Data = batch_crop.userInterface.summaryTableData( ...
        state, state.currentIndex, cropSize(1), cropSize(2), ...
        currentPaddingPercent(state, ui), ui.controls.format.valueHandle.Value);
    ui.controls.details.textArea.Value = batch_crop.userInterface.detailLines( ...
        state, state.currentIndex, cropSize(1), cropSize(2), ...
        currentPaddingPercent(state, ui));
    refreshScaleControls(state, ui, services, ui.controls.scaleStatus.valueHandle);
end

function refreshScaleControls(state, ui, ~, statusControl)
    if ~hasTools(state)
        return;
    end
    batch_crop.userInterface.refreshScaleControls(state.tools.scaleTool, ...
        statusControl, state.items, state.currentIndex, ...
        string(ui.controls.scaleMode.valueHandle.Value), ...
        [ui.controls.physicalWidth.valueHandle.Value, ...
        ui.controls.physicalHeight.valueHandle.Value], ...
        string(ui.controls.scaleUnit.valueHandle.Value));
end

function resetPreviewAxes(ui)
    labkit.ui.plot.reset(ui, 'preview', ...
        'Padded rotation preview + fixed crop', true, 'crop');
end

function geometry = currentGeometry(state, ui)
    item = state.items(state.currentIndex);
    [geometry, ~] = batch_crop.appState.currentGeometry(state.canvasCache, ...
        state.currentIndex, item, currentPaddingPercent(state, ui));
end

function cropSize = currentCropSize(state, ui)
    if strcmpi(string(ui.controls.scaleMode.valueHandle.Value), "Physical") && ...
            hasCurrentImage(state)
        cal = batch_crop.appState.itemScaleCalibration(state.items, ...
            state.currentIndex);
        if batch_crop.appState.isScaleCalibrationSet(cal)
            pixelsPerUnit = batch_crop.cropGeometry.pixelsPerUnitForUnit(cal, ...
                string(ui.controls.scaleUnit.valueHandle.Value));
            cropSize = max(1, round([ ...
                double(ui.controls.physicalWidth.valueHandle.Value), ...
                double(ui.controls.physicalHeight.valueHandle.Value)] * ...
                pixelsPerUnit));
            return;
        end
    end
    cropSize = max(1, round([ ...
        double(ui.controls.cropWidth.valueHandle.Value), ...
        double(ui.controls.cropHeight.valueHandle.Value)]));
end

function percent = currentPaddingPercent(state, ui)
    if hasCurrentImage(state)
        percent = batch_crop.appState.itemPaddingPercent( ...
            state.items(state.currentIndex), ...
            ui.controls.paddingPercent.valueHandle.Value);
        return;
    end
    percent = min(max(double(ui.controls.paddingPercent.valueHandle.Value), ...
        0), 200);
end

function idx = currentIndexOrOne(state)
    idx = state.currentIndex;
    if isempty(idx) || idx < 1 || idx > numel(state.items)
        idx = 1;
    end
end

function tf = hasCurrentImage(state)
    tf = ~isempty(state.items) && state.currentIndex >= 1 && ...
        state.currentIndex <= numel(state.items) && ...
        ~isempty(state.items(state.currentIndex).image);
end

function tf = hasTools(state)
    tf = isfield(state, 'tools') && isstruct(state.tools) && ...
        isfield(state.tools, 'scaleTool') && ~isempty(state.tools.scaleTool);
end
