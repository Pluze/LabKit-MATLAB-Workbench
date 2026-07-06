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
    fig = [];

    actions = struct( ...
        'startup', @onStartup, ...
        'referenceChosen', @dispatchReferenceChosen, ...
        'referenceCleared', @dispatchReferenceCleared, ...
        'movingChosen', @dispatchMovingChosen, ...
        'movingCleared', @dispatchMovingCleared, ...
        'previewChanged', @dispatchPreviewChanged, ...
        'align', @dispatchAlign, ...
        'autoAlign', @dispatchAutoAlign, ...
        'startCropRoi', @dispatchStartCropRoi, ...
        'applyCropRoi', @dispatchApplyCropRoi, ...
        'cancelCropRoi', @dispatchCancelCropRoi, ...
        'undoEdit', @dispatchUndoEdit, ...
        'saveCurrentImages', @dispatchSaveCurrentImages, ...
        'resetToOriginals', @dispatchResetToOriginals, ...
        'startMaskEdit', @dispatchStartMaskEdit, ...
        'boundaryStyleChanged', @dispatchBoundaryStyleChanged, ...
        'previewMaskRoi', @dispatchPreviewMaskRoi, ...
        'addBoundaryToMask', @dispatchAddBoundaryToMask, ...
        'subtractBoundaryFromMask', @dispatchSubtractBoundaryFromMask, ...
        'undoMaskAnchor', @dispatchUndoMaskAnchor, ...
        'undoMaskEdit', @dispatchUndoMaskEdit, ...
        'clearMaskBoundary', @dispatchClearMaskBoundary, ...
        'clearMaskCanvas', @dispatchClearMaskCanvas, ...
        'saveMask', @dispatchSaveMask);

    function state = onStartup(state, ~, services)
        S = state;
        ui = services.ui;
        fig = services.figure;
        debugLog = services.debug;
        ui.topAxes = ui.controls.previewAxes.axesById.reference;
        ui.bottomAxes = ui.controls.previewAxes.axesById.current;
        imageRuntime = labkit.ui.interaction.runtime(ui.topAxes, ...
            struct('figure', fig));
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

    function state = dispatchWithEvent(state, payload, callback)
        S = state;
        callback([], payload.event);
        state = S;
    end

    function state = dispatchNoEvent(state, ~, callback)
        S = state;
        callback();
        state = S;
    end

    function state = dispatchReferenceChosen(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onReferenceChosen);
    end
    function state = dispatchReferenceCleared(state, payload, ~)
        state = dispatchNoEvent(state, payload, @onReferenceCleared);
    end
    function state = dispatchMovingChosen(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onMovingChosen);
    end
    function state = dispatchMovingCleared(state, payload, ~)
        state = dispatchNoEvent(state, payload, @onMovingCleared);
    end
    function state = dispatchPreviewChanged(state, payload, ~)
        state = dispatchNoEvent(state, payload, @refreshPreview);
    end
    function state = dispatchAlign(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onAlign);
    end
    function state = dispatchAutoAlign(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onAutoAlign);
    end
    function state = dispatchStartCropRoi(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onStartCropRoi);
    end
    function state = dispatchApplyCropRoi(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onApplyCropRoi);
    end
    function state = dispatchCancelCropRoi(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onCancelCropRoi);
    end
    function state = dispatchUndoEdit(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onUndoEdit);
    end
    function state = dispatchSaveCurrentImages(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onSaveCurrentImages);
    end
    function state = dispatchResetToOriginals(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onResetToOriginals);
    end
    function state = dispatchStartMaskEdit(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onStartMaskEdit);
    end
    function state = dispatchBoundaryStyleChanged(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onBoundaryStyleChanged);
    end
    function state = dispatchPreviewMaskRoi(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onPreviewMaskRoi);
    end
    function state = dispatchAddBoundaryToMask(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onAddBoundaryToMask);
    end
    function state = dispatchSubtractBoundaryFromMask(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onSubtractBoundaryFromMask);
    end
    function state = dispatchUndoMaskAnchor(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onUndoMaskAnchor);
    end
    function state = dispatchUndoMaskEdit(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onUndoMaskEdit);
    end
    function state = dispatchClearMaskBoundary(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onClearMaskBoundary);
    end
    function state = dispatchClearMaskCanvas(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onClearMaskCanvas);
    end
    function state = dispatchSaveMask(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onSaveMask);
    end


    function onReferenceChosen(~, event)
        paths = labkit.ui.control.filePaths(event.addedFiles);
        if isempty(paths)
            addLog('Reference image selection cancelled.');
            return;
        end
        filepath = paths(1);
        S = dic_preprocess.appState.setLoadedImage( ...
            S, 'reference', filepath, imread(filepath));
        resetWorkflowStateForNewInput();
        addLog(sprintf('Loaded reference image: %s', filepath));
        chooseDefaultPreviewAfterLoad();
        refreshPreview();
    end

    function onReferenceCleared()
        S.referencePath = "";
        S.referenceImage = [];
        S.currentReferenceImage = [];
        resetWorkflowStateForNewInput();
        addLog('Cleared reference image file.');
        refreshPreview();
    end

    function onMovingChosen(~, event)
        paths = labkit.ui.control.filePaths(event.addedFiles);
        if isempty(paths)
            addLog('Moving image selection cancelled.');
            return;
        end
        filepath = paths(1);
        S = dic_preprocess.appState.setLoadedImage( ...
            S, 'moving', filepath, imread(filepath));
        resetWorkflowStateForNewInput();
        addLog(sprintf('Loaded moving image: %s', filepath));
        chooseDefaultPreviewAfterLoad();
        refreshPreview();
    end

    function onMovingCleared()
        S.movingPath = "";
        S.movingImage = [];
        S.currentMovingImage = [];
        resetWorkflowStateForNewInput();
        addLog('Cleared moving image file.');
        refreshPreview();
    end

    function onAlign(~, ~)
        if dic_preprocess.userInterface.alertIfMissingImagePair(fig, S, ...
                'Load both reference and moving images before alignment.', ...
                'Missing images')
            return;
        end

        addLog('Opening point selector. Choose matching points, then accept.');
        [movingPoints, fixedPoints] = cpselect(S.currentMovingImage, S.currentReferenceImage, 'Wait', true);
        if size(movingPoints, 1) < 2
            labkit.ui.runtime.showAlert(fig, 'Rigid registration requires at least two point pairs.', 'Not enough points');
            addLog('Alignment cancelled: fewer than two point pairs.');
            return;
        end

        pushHistory('manual alignment');
        [alignedImage, tform] = dic_preprocess.analysisRun.alignMovingToReference( ...
            S.currentReferenceImage, S.currentMovingImage, fixedPoints, movingPoints);
        S.currentMovingImage = alignedImage;
        S.alignedImage = alignedImage;
        clearDerivedStateAndMaskEditor();
        ddPreview.Value = 'False-color overlay';
        addLog(sprintf('Aligned image using %d point pair(s).', size(movingPoints, 1)));
        txtDetails.Value = dic_preprocess.userInterface.transformSummary( ...
            tform, size(S.currentReferenceImage), size(S.currentMovingImage));
        refreshPreview();
    end

    function onAutoAlign(~, ~)
        if dic_preprocess.userInterface.alertIfMissingImagePair(fig, S, ...
                'Load both reference and moving images before automatic alignment.', ...
                'Missing images')
            return;
        end

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

        S = dic_preprocess.userInterface.clearCropRoiState(S, controls);
        S = dic_preprocess.userInterface.clearMaskRoiState(S, controls);

        S.cropReference = [];
        S.cropMoving = [];
        rect = dic_preprocess.analysisRun.defaultSquareRect(size(S.currentReferenceImage));
        S.cropRect = rect;
        cropUi = dic_preprocess.userInterface.startCropRoi(ui, ...
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
        if isempty(S.cropRoiTop) || ~isvalid(S.cropRoiTop)
            labkit.ui.runtime.showAlert(fig, 'Start a crop ROI before applying the crop.', 'No active ROI');
            return;
        end

        rect = dic_preprocess.analysisRun.squareRectInsideImage(S.cropRoiTop.Position, size(S.currentReferenceImage));
        pushHistory('crop');
        S.cropRect = rect;
        S.currentReferenceImage = imcrop(S.currentReferenceImage, rect);
        S.currentMovingImage = imcrop(S.currentMovingImage, rect);
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

    function onCropRoiMoved(~, evt)
        if isprop(evt, 'CurrentPosition')
            pos = evt.CurrentPosition;
        else
            pos = S.cropRoiTop.Position;
        end
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
        txtDetails.Value = {'ROI edit started. Double-click blank space to add/insert points, drag points to move them, double-click points to delete them.'};
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
