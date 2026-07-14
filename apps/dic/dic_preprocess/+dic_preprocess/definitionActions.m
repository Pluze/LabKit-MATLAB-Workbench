% App-owned action registry for DIC preprocess. Expected caller is
% dic_preprocess.definition. Output maps semantic action ids to handlers used
% by labkit.ui.runtime.run. The handlers preserve the existing ROI-edit workflow
% while moving package-root lifecycle orchestration into the runtime.
function actions = definitionActions()
%DEFINITIONACTIONS Build the DIC preprocess runtime action map.

    S = [];
    ui = [];
    controls = [];
    txtSummary = [];
    txtDetails = [];
    ddPreview = [];
    ddBoundaryStyle = [];
    btnApplyCrop = [];
    btnCancelCrop = [];
    debugLog = [];
    imageRuntime = [];
    movingImageRuntime = [];
    pointMatcher = [];
    fig = [];

    actions = struct( ...
        'startup', @onStartup, ...
        'referenceChosen', eventAction(@(~, event) onImageChosen('reference', event)), ...
        'referenceCleared', noEventAction(@() onImageCleared('reference')), ...
        'movingChosen', eventAction(@(~, event) onImageChosen('moving', event)), ...
        'movingCleared', noEventAction(@() onImageCleared('moving')), ...
        'previewChanged', noEventAction(@onPreviewChanged), ...
        'startPointMatching', eventAction(@onStartPointMatching), ...
        'applyPointAlignment', eventAction(@onApplyPointAlignment), ...
        'cancelPointMatching', eventAction(@onCancelPointMatching), ...
        'undoPointPair', eventAction(@onUndoPointPair), ...
        'autoAlign', eventAction(@onAutoAlign), ...
        'startCropRoi', eventAction(@onStartCropRoi), ...
        'applyCropRoi', eventAction(@onApplyCropRoi), ...
        'cancelCropRoi', eventAction(@onCancelCropRoi), ...
        'undoEdit', eventAction(@onUndoEdit), ...
        'saveCurrentImages', eventAction(@onSaveCurrentImages), ...
        'resetToOriginals', eventAction(@onResetToOriginals), ...
        'startMaskEdit', eventAction(@onStartMaskEdit), ...
        'boundaryStyleChanged', eventAction(@onBoundaryStyleChanged), ...
        'previewMaskRoi', eventAction(@onPreviewMaskRoi), ...
        'addBoundaryToMask', eventAction(@onAddBoundaryToMask), ...
        'subtractBoundaryFromMask', eventAction(@onSubtractBoundaryFromMask), ...
        'undoMaskAnchor', eventAction(@onUndoMaskAnchor), ...
        'undoMaskEdit', eventAction(@onUndoMaskEdit), ...
        'clearMaskBoundary', eventAction(@onClearMaskBoundary), ...
        'clearMaskCanvas', eventAction(@onClearMaskCanvas), ...
        'saveMask', eventAction(@onSaveMask));

    function state = onStartup(state, ~, services)
        S = state;
        ui = services.ui;
        fig = services.figure;
        debugLog = services.debug;
        ui.topAxes = ui.controls.previewAxes.axesById.reference;
        ui.bottomAxes = ui.controls.previewAxes.axesById.current;
        movingImageRuntime = labkit.ui.interaction.runtime(ui.bottomAxes, ...
            struct('figure', fig, 'defaultScrollFcn', @(~, event) ...
            dic_preprocess.userInterface.zoomPreviewAtPointer( ...
            ui.bottomAxes, event)));
        imageRuntime = labkit.ui.interaction.runtime(ui.topAxes, ...
            struct('figure', fig, 'defaultScrollFcn', @(~, event) ...
            dic_preprocess.userInterface.zoomPreviewAtPointer( ...
            ui.topAxes, event)));
        pointMatcher = dic_preprocess.userInterface.rigidPointMatcher( ...
            imageRuntime, movingImageRuntime, ui.topAxes, ui.bottomAxes, ...
            struct('onChanged', @onPointMatchingChanged, ...
            'onTrace', debugLog.trace));
        ui.imageRuntime = imageRuntime;
        controls = dic_preprocess.userInterface.mapControlHandles(ui);
        txtSummary = ui.controls.summaryText.textArea;
        txtDetails = ui.controls.detailsText.textArea;
        ddPreview = controls.ddPreview;
        ddBoundaryStyle = controls.ddBoundaryStyle;
        btnApplyCrop = controls.btnApplyCrop;
        btnCancelCrop = controls.btnCancelCrop;
        if debugLog.enabled
            debugLog.trace('DIC preprocess debug trace enabled.');
            setupDebugSamples();
        end
        refreshPreview();
        state = S;
    end

    function handler = eventAction(callback)
        handler = @(state, payload, services) runEventAction( ...
            state, payload, services, callback);
    end

    function state = runEventAction(state, payload, ~, callback)
        S = state;
        callback([], payload.event);
        state = S;
    end

    function handler = noEventAction(callback)
        handler = @(state, payload, services) runNoEventAction( ...
            state, payload, services, callback);
    end

    function state = runNoEventAction(state, ~, ~, callback)
        S = state;
        callback();
        state = S;
    end

    function onImageChosen(role, event)
        stopPointMatching();
        paths = labkit.ui.control.filePaths(event.addedFiles);
        if isempty(paths)
            addLog(sprintf('%s image selection cancelled.', titleCase(role)));
            return;
        end
        filepath = paths(1);
        S = dic_preprocess.appState.setLoadedImage( ...
            S, role, filepath, imread(filepath));
        resetWorkflowStateForNewInput();
        addLog(sprintf('Loaded %s image: %s', role, filepath));
        chooseDefaultPreviewAfterLoad();
        refreshPreview();
    end

    function onImageCleared(role)
        stopPointMatching();
        S.([role 'Path']) = "";
        S.([role 'Image']) = [];
        S.(['current' titleCase(role) 'Image']) = [];
        resetWorkflowStateForNewInput();
        addLog(sprintf('Cleared %s image file.', role));
        refreshPreview();
    end

    function onPreviewChanged()
        stopPointMatching();
        refreshPreview();
    end

    function onStartPointMatching(~, ~)
        if dic_preprocess.userInterface.alertIfMissingImagePair(fig, S, ...
                'Load both reference and moving images before alignment.', ...
                'Missing images')
            return;
        end

        stopPointMatching();
        S = dic_preprocess.userInterface.clearCropRoiState(S, controls);
        S = dic_preprocess.userInterface.clearMaskRoiState(S, controls);
        ddPreview.Value = 'Current pair';
        request = dic_preprocess.userInterface.previewRequest(S, ddPreview.Value);
        dic_preprocess.userInterface.drawPreview(ui, request);

        pointMatcher.start(S.currentReferenceImage, S.currentMovingImage, ...
            findPreviewImage(ui.topAxes), findPreviewImage(ui.bottomAxes));
        updatePointMatchingControls();
        txtDetails.Value = {['Point matching active. Select a feature in the ' ...
            'reference image, then its match in the moving image. Drag points ' ...
            'to refine them; at least two pairs are required.']};
        addLog('Started point matching in the main reference and moving previews.');
    end

    function onApplyPointAlignment(~, ~)
        if ~pointMatcher.hasCompleteAlignment()
            labkit.ui.runtime.showAlert(fig, ...
                'Rigid registration requires at least two complete point pairs.', ...
                'Not enough points');
            return;
        end

        [referencePoints, movingPoints] = pointMatcher.points();
        pushHistory('manual alignment');
        [alignedImage, tform] = dic_preprocess.analysisRun.alignMovingToReference( ...
            S.currentReferenceImage, S.currentMovingImage, ...
            referencePoints, movingPoints);
        pairCount = size(referencePoints, 1);
        stopPointMatching();
        S.currentMovingImage = alignedImage;
        S.alignedImage = alignedImage;
        clearDerivedStateAndMaskEditor();
        ddPreview.Value = 'False-color overlay';
        addLog(sprintf('Aligned image using %d point pair(s).', pairCount));
        txtDetails.Value = dic_preprocess.userInterface.transformSummary( ...
            tform, size(S.currentReferenceImage), size(S.currentMovingImage));
        refreshPreview();
    end

    function onCancelPointMatching(~, ~)
        if ~pointMatcher.isActive()
            return;
        end
        stopPointMatching();
        addLog('Cancelled point matching.');
        txtDetails.Value = {'Point matching cancelled.'};
        refreshPreview();
    end

    function onUndoPointPair(~, ~)
        pointMatcher.undoLast();
    end

    function onAutoAlign(~, ~)
        if dic_preprocess.userInterface.alertIfMissingImagePair(fig, S, ...
                'Load both reference and moving images before automatic alignment.', ...
                'Missing images')
            return;
        end

        stopPointMatching();
        try
            [alignedImage, tform, method] = dic_preprocess.analysisRun.autoAlignMovingToReference( ...
                S.currentReferenceImage, S.currentMovingImage);
        catch err
            labkit.ui.runtime.showAlert(fig, sprintf('Automatic alignment failed:\n%s', err.message), 'Auto align failed');
            addLog(sprintf('Automatic alignment failed: %s', err.message));
            return;
        end

        pushHistory('automatic alignment');
        S.currentMovingImage = alignedImage;
        S.alignedImage = alignedImage;
        clearDerivedStateAndMaskEditor();
        ddPreview.Value = 'False-color overlay';
        addLog(sprintf('Automatically aligned current pair using %s.', method));
        txtDetails.Value = dic_preprocess.userInterface.transformSummary( ...
            tform, size(S.currentReferenceImage), size(S.currentMovingImage));
        refreshPreview();
    end

    function onStartCropRoi(~, ~)
        if dic_preprocess.userInterface.alertIfMissingImagePair(fig, S, ...
                'Load both reference and moving images before cropping.', ...
                'Missing images')
            return;
        end

        stopPointMatching();
        S = dic_preprocess.userInterface.clearCropRoiState(S, controls);
        S = dic_preprocess.userInterface.clearMaskRoiState(S, controls);

        S.cropReference = [];
        S.cropMoving = [];
        rect = dic_preprocess.analysisRun.defaultSquareRect(size(S.currentReferenceImage));
        S.cropRect = rect;
        cropUi = dic_preprocess.userInterface.startCropRoi(ui, imageRuntime, ...
            S.currentReferenceImage, S.currentMovingImage, rect, @onCropRoiMoved);
        S.cropRoiTop = cropUi.top;
        S.cropRoiBottom = cropUi.bottom;
        S.cropRoiListeners = cropUi.listeners;
        btnApplyCrop.Enable = 'on';
        btnCancelCrop.Enable = 'on';
        txtDetails.Value = dic_preprocess.userInterface.cropSelectionSummary(rect);
        addLog('Started crop ROI on the current pair preview.');
        refreshSummary();
    end

    function onApplyCropRoi(~, ~)
        if isempty(S.cropRoiTop) || ~S.cropRoiTop.isValid()
            labkit.ui.runtime.showAlert(fig, 'Start a crop ROI before applying the crop.', 'No active ROI');
            return;
        end

        rect = dic_preprocess.analysisRun.squareRectInsideImage( ...
            S.cropRoiTop.getPosition(), size(S.currentReferenceImage));
        pushHistory('crop');
        S.cropRect = rect;
        S.currentReferenceImage = dic_preprocess.analysisRun.cropImage( ...
            S.currentReferenceImage, rect);
        S.currentMovingImage = dic_preprocess.analysisRun.cropImage( ...
            S.currentMovingImage, rect);
        S.cropReference = S.currentReferenceImage;
        S.cropMoving = S.currentMovingImage;
        clearDerivedStateAndMaskEditor();
        S = dic_preprocess.userInterface.clearCropRoiState(S, controls);
        ddPreview.Value = 'Current pair';
        dic_preprocess.userInterface.drawPreview(ui, ...
            dic_preprocess.userInterface.previewRequest(S, 'Current pair'));
        addLog(sprintf('Cropped current pair with [%g %g %g %g].', ...
            rect(1), rect(2), rect(3), rect(4)));
        txtDetails.Value = dic_preprocess.userInterface.cropSummary(rect);
        refreshSummary();
    end

    function onCancelCropRoi(~, ~)
        S = dic_preprocess.userInterface.clearCropRoiState(S, controls);
        addLog('Crop ROI cancelled.');
        refreshPreview();
    end

    function onCropRoiMoved(pos)
        rect = dic_preprocess.analysisRun.squareRectInsideImage(pos, size(S.currentReferenceImage));
        S.cropRect = rect;
        if ~isempty(S.cropRoiBottom) && isvalid(S.cropRoiBottom)
            S.cropRoiBottom.Position = rect;
        end
        txtDetails.Value = dic_preprocess.userInterface.cropSelectionSummary(rect);
    end

    function onUndoEdit(~, ~)
        if isempty(S.history)
            labkit.ui.runtime.showAlert(fig, 'No align or crop operation is available to undo.', 'Undo');
            return;
        end

        stopPointMatching();
        snapshot = S.history(end);
        S.history(end) = [];
        S = dic_preprocess.userInterface.clearCropRoiState(S, controls);
        S = dic_preprocess.userInterface.clearMaskRoiState(S, controls);
        S = dic_preprocess.appState.restoreEditSnapshot(S, snapshot);
        ddPreview.Value = 'Current pair';
        addLog(sprintf('Undid %s.', snapshot.description));
        txtDetails.Value = {sprintf('Restored state before %s.', snapshot.description)};
        refreshPreview();
        dic_preprocess.userInterface.updateUndoButton(controls, S);
    end

    function onResetToOriginals(~, ~)
        if isempty(S.referenceImage) || isempty(S.movingImage)
            labkit.ui.runtime.showAlert(fig, 'Load both images before resetting the working pair.', 'Reset');
            return;
        end
        stopPointMatching();
        pushHistory('reset to originals');
        S = dic_preprocess.userInterface.clearCropRoiState(S, controls);
        S = dic_preprocess.userInterface.clearMaskRoiState(S, controls);
        S = dic_preprocess.appState.resetToOriginals(S);
        ddPreview.Value = 'Current pair';
        addLog('Reset current working pair to the original loaded images.');
        txtDetails.Value = {'Current working pair reset to originals.'};
        refreshPreview();
    end

    function onSaveCurrentImages(~, ~)
        if dic_preprocess.userInterface.alertIfMissingImagePair(fig, S, ...
                'Load both images before saving the current pair.', ...
                'Save current images')
            return;
        end

        [outputs, cancelled] = dic_preprocess.sourceFiles.saveCurrentImages( ...
            S.currentReferenceImage, S.currentMovingImage, ...
            S.referencePath, S.movingPath, ...
            labkit.ui.runtime.defaultDialogFolder("output"));
        if cancelled
            addLog('Save current images cancelled.');
            return;
        end

        addLog(sprintf('Saved current images: %s and %s', ...
            outputs.referencePath, outputs.movingPath));
    end

    function onStartMaskEdit(~, ~)
        if isempty(S.currentReferenceImage)
            labkit.ui.runtime.showAlert(fig, 'Load a reference image before drawing an ROI mask.', 'Missing image');
            return;
        end

        stopPointMatching();
        S = dic_preprocess.userInterface.clearCropRoiState(S, controls);
        S = dic_preprocess.userInterface.clearMaskRoiState(S, controls);
        S.maskImage = [];
        S.maskPoints = [];
        S.maskHistory = S.maskHistory([]);
        S.maskBoundaryStyle = string(ddBoundaryStyle.Value);
        S.maskEditor = dic_preprocess.userInterface.startMaskEdit(ui, imageRuntime, ...
            S.currentReferenceImage, S.maskPoints, ...
            S.maskBoundaryStyle, @onMaskEditorChanged);
        S = dic_preprocess.userInterface.setMaskEditControls(S, controls, true);
        addLog('Started mask ROI canvas. Add/insert, move, or delete anchors; add/subtract boundaries on the mask canvas.');
        txtDetails.Value = {'ROI edit started. Double-click the reference preview to add anchors, drag points to move them, double-click points to delete them.'};
        dic_preprocess.userInterface.updateMaskEditControls(controls, S);
    end

    function onMaskEditorChanged(points, ~)
        S.maskPoints = points;
        updateMaskDraft();
    end

    function onBoundaryStyleChanged(~, ~)
        S.maskBoundaryStyle = string(ddBoundaryStyle.Value);
        if ~isempty(S.maskEditor)
            S.maskEditor.setStyle(S.maskBoundaryStyle);
        end
        updateMaskCurveGraphics();
        txtDetails.Value = {sprintf('Boundary style: %s.', char(S.maskBoundaryStyle))};
    end

    function onUndoMaskAnchor(~, ~)
        if ~isempty(S.maskEditor)
            S.maskEditor.undoLast();
        end
    end

    function onClearMaskBoundary(~, ~)
        if ~isempty(S.maskEditor)
            S.maskEditor.clearPoints();
        else
            S.maskPoints = [];
            updateMaskDraft();
        end
        addLog('Cleared mask ROI boundary anchors.');
    end

    function onClearMaskCanvas(~, ~)
        if isempty(S.maskImage)
            return;
        end
        pushMaskHistory('clear mask canvas');
        S.maskImage = [];
        showMaskCanvas('ROI mask canvas');
        addLog('Cleared ROI mask canvas.');
        refreshSummary();
    end

    function updateMaskDraft()
        updateMaskCurveGraphics();
        dic_preprocess.userInterface.updateMaskEditControls(controls, S);
        txtDetails.Value = dic_preprocess.userInterface.maskDraftDetails(S.maskPoints);
        refreshSummary();
    end

    function updateMaskCurveGraphics()
        if ~isempty(S.maskEditor)
            S.maskEditor.refresh();
        end
    end

    function onPreviewMaskRoi(~, ~)
        previewMaskImage(true);
    end

    function onAddBoundaryToMask(~, ~)
        [boundaryMask, ok] = currentBoundaryMask(true);
        if ~ok
            return;
        end
        pushMaskHistory('add boundary to mask');
        S.maskImage = dic_preprocess.appState.applyBoundaryToMask( ...
            S.maskImage, S.currentReferenceImage, boundaryMask, 'add');
        showMaskCanvas('ROI mask canvas');
        addLog(sprintf('Added %s boundary to ROI mask canvas.', char(S.maskBoundaryStyle)));
        refreshSummary();
    end

    function onSubtractBoundaryFromMask(~, ~)
        [boundaryMask, ok] = currentBoundaryMask(true);
        if ~ok
            return;
        end
        pushMaskHistory('subtract boundary from mask');
        S.maskImage = dic_preprocess.appState.applyBoundaryToMask( ...
            S.maskImage, S.currentReferenceImage, boundaryMask, 'subtract');
        showMaskCanvas('ROI mask canvas');
        addLog(sprintf('Subtracted %s boundary from ROI mask canvas.', char(S.maskBoundaryStyle)));
        refreshSummary();
    end

    function onUndoMaskEdit(~, ~)
        if isempty(S.maskHistory)
            return;
        end
        snapshot = S.maskHistory(end);
        S.maskHistory(end) = [];
        S = dic_preprocess.appState.restoreMaskSnapshot(S, snapshot);
        if ~isempty(S.maskEditor)
            S.maskEditor.setPoints(S.maskPoints);
        end
        updateMaskCurveGraphics();
        showMaskCanvas('ROI mask canvas');
        addLog(sprintf('Undid mask edit: %s.', snapshot.description));
        refreshSummary();
    end

    function onSaveMask(~, ~)
        if isempty(S.maskImage)
            [boundaryMask, ok] = currentBoundaryMask(false);
            if ~ok
                labkit.ui.runtime.showAlert(fig, 'Draw a mask ROI or add a boundary to the mask canvas before saving.', 'Save ROI mask');
                return;
            end
            S.maskImage = boundaryMask;
        end

        [out, cancelled] = dic_preprocess.sourceFiles.saveMask( ...
            S.maskImage, S.referencePath, ...
            labkit.ui.runtime.defaultDialogFolder("output"));
        if cancelled
            addLog('Save ROI mask cancelled.');
            return;
        end

        addLog(sprintf('Saved ROI mask: %s', out));
    end

    function ok = previewMaskImage(showAlert)
        [boundaryMask, ok] = currentBoundaryMask(showAlert);
        if ok
            ddPreview.Value = 'ROI mask';
            dic_preprocess.userInterface.showImage(ui, 'current', ...
                dic_preprocess.analysisRun.maskRgb(boundaryMask), 'ROI boundary preview');
            updateMaskCurveGraphics();
            addLog(sprintf('Previewed %s ROI boundary with %d anchors.', ...
                char(S.maskBoundaryStyle), size(S.maskPoints, 1)));
            txtDetails.Value = {'Boundary preview updated. Add it to the mask canvas, subtract it, or keep editing anchors.'};
            refreshSummary();
            return;
        end
        if ~isempty(S.maskImage)
            ddPreview.Value = 'ROI mask';
            showMaskCanvas('ROI mask canvas');
            ok = true;
        end
    end

    function [boundaryMask, ok] = currentBoundaryMask(showAlert)
        if ~isempty(S.maskEditor) && isstruct(S.maskEditor) && ...
                isfield(S.maskEditor, 'getPoints') && isa(S.maskEditor.getPoints, 'function_handle')
            S.maskPoints = S.maskEditor.getPoints();
        end
        [boundaryMask, ok] = dic_preprocess.analysisRun.boundaryMaskFromEditor( ...
            S.maskPoints, size(S.currentReferenceImage), ...
            S.maskBoundaryStyle, S.maskEditor);
        if ~ok && showAlert
            labkit.ui.runtime.showAlert(fig, 'Mask ROI needs at least three anchors.', 'Not enough anchors');
        end
    end

    function showMaskCanvas(titleText)
        ddPreview.Value = 'ROI mask';
        dic_preprocess.userInterface.drawMaskCanvas(ui, ...
            S.currentReferenceImage, S.maskImage, titleText);
        dic_preprocess.userInterface.updateMaskEditControls(controls, S);
    end

    function pushMaskHistory(description)
        S.maskHistory = dic_preprocess.appState.appendMaskHistory( ...
            S.maskHistory, S.maskImage, S.maskPoints, description);
        dic_preprocess.userInterface.updateMaskEditControls(controls, S);
    end

    function onPointMatchingChanged(referencePoints, movingPoints, instruction)
        updatePointMatchingControls();
        completePairs = min(size(referencePoints, 1), size(movingPoints, 1));
        txtDetails.Value = {sprintf('Complete point pairs: %d. %s', ...
            completePairs, instruction)};
    end

    function updatePointMatchingControls()
        active = ~isempty(pointMatcher) && pointMatcher.isActive();
        complete = active && pointMatcher.hasCompleteAlignment();
        controls.btnStartPointMatching.Enable = ...
            dic_preprocess.userInterface.onOff(~active);
        controls.btnApplyPointAlignment.Enable = ...
            dic_preprocess.userInterface.onOff(active && complete);
        controls.btnCancelPointMatching.Enable = ...
            dic_preprocess.userInterface.onOff(active);
        controls.btnUndoPointPair.Enable = dic_preprocess.userInterface.onOff( ...
            active && pointMatcher.hasPoints());
    end

    function stopPointMatching()
        if ~isempty(pointMatcher)
            pointMatcher.stop();
        end
        updatePointMatchingControls();
    end

    function refreshPreview()
        S = dic_preprocess.userInterface.clearCropRoiState(S, controls);
        S = dic_preprocess.userInterface.clearMaskRoiState(S, controls);
        request = dic_preprocess.userInterface.previewRequest(S, ddPreview.Value);
        dic_preprocess.userInterface.drawPreview(ui, request);
        refreshSummary();
    end

    function refreshSummary()
        labkit.ui.control.setValue(ui, 'referenceFile', fileValue(S.referencePath));
        labkit.ui.control.setValue(ui, 'movingFile', fileValue(S.movingPath));
        txtSummary.Value = dic_preprocess.userInterface.buildSummary(S);
        dic_preprocess.userInterface.updateUndoButton(controls, S);
    end

    function resetWorkflowStateForNewInput()
        S = dic_preprocess.appState.resetForNewInput(S);
        S = dic_preprocess.userInterface.clearCropRoiState(S, controls);
        S = dic_preprocess.userInterface.clearMaskRoiState(S, controls);
        dic_preprocess.userInterface.updateUndoButton(controls, S);
    end

    function chooseDefaultPreviewAfterLoad()
        if dic_preprocess.appState.hasImagePair(S)
            ddPreview.Value = 'False-color overlay';
        else
            ddPreview.Value = 'Current pair';
    end
end

function hImage = findPreviewImage(ax)
    hImage = findobj(ax, 'Type', 'Image');
    if ~isempty(hImage)
        hImage = hImage(1);
    end
end

function value = titleCase(value)
    value = char(value);
    value(1) = upper(value(1));
end

    function setupDebugSamples()
        try
            pack = dic_preprocess.debug.writeSamplePack(debugLog);
            addLog(sprintf('Debug sample files: %s', char(pack.sampleFolder)));
            addLog(sprintf('Debug output folder: %s', char(pack.outputFolder)));
        catch ME
            debugLog.reportException('dicPreprocess', 'Debug sample setup failed', ME);
            addLog(sprintf('Debug sample setup failed: %s', ME.message));
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

    function pushHistory(description)
        [S.history, appended] = dic_preprocess.appState.appendEditHistory( ...
            S.history, S, description);
        if appended
            dic_preprocess.userInterface.updateUndoButton(controls, S);
        end
    end

    function clearDerivedStateAndMaskEditor()
        S = dic_preprocess.appState.clearOperationDerivedState(S);
        S = dic_preprocess.userInterface.clearMaskRoiState(S, controls);
    end

    function addLog(msg)
        labkit.ui.control.appendLog(ui, 'appLog', msg);
        debugLog.append(msg);
    end

end
