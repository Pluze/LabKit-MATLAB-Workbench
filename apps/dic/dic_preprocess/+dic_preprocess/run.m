% App-owned DIC preprocess runner. Expected caller: labkit_DICPreprocess_app.
% Input is the debug context prepared by the public launcher. Output is the app
% figure. Side effects are GUI creation, user-driven file I/O, and debug trace
% attachment exactly as in the original entrypoint body.
function fig = run(debugLog)
%RUN Build and run the DIC preprocess app body.

    S = dic_preprocess.state.initialState();
    callbacks = struct( ...
        'referenceChosen', @onReferenceChosen, ...
        'referenceCleared', @(~, ~) onReferenceCleared(), ...
        'movingChosen', @onMovingChosen, ...
        'movingCleared', @(~, ~) onMovingCleared(), ...
        'previewChanged', @(~,~) refreshPreview(), ...
        'align', @onAlign, ...
        'autoAlign', @onAutoAlign, ...
        'startCropRoi', @onStartCropRoi, ...
        'applyCropRoi', @onApplyCropRoi, ...
        'cancelCropRoi', @onCancelCropRoi, ...
        'undoEdit', @onUndoEdit, ...
        'saveCurrentImages', @onSaveCurrentImages, ...
        'resetToOriginals', @onResetToOriginals, ...
        'startMaskEdit', @onStartMaskEdit, ...
        'boundaryStyleChanged', @onBoundaryStyleChanged, ...
        'previewMaskRoi', @onPreviewMaskRoi, ...
        'addBoundaryToMask', @onAddBoundaryToMask, ...
        'subtractBoundaryFromMask', @onSubtractBoundaryFromMask, ...
        'undoMaskAnchor', @onUndoMaskAnchor, ...
        'undoMaskEdit', @onUndoMaskEdit, ...
        'clearMaskBoundary', @onClearMaskBoundary, ...
        'clearMaskCanvas', @onClearMaskCanvas, ...
        'saveMask', @onSaveMask);
    spec = dic_preprocess.ui.buildSpec(callbacks);
    ui = labkit.ui.app.create(spec, "debug", debugLog);
    fig = ui.fig;
    ui.topAxes = ui.controls.previewAxes.axesById.reference;
    ui.bottomAxes = ui.controls.previewAxes.axesById.current;
    imageRuntime = labkit.ui.tool.createRuntime(ui.topAxes, ...
        struct('figure', fig));
    ui.imageRuntime = imageRuntime;
    controls = dic_preprocess.ui.mapControlHandles(ui);
    txtSummary = ui.controls.summaryText.textArea;
    txtDetails = ui.controls.detailsText.textArea;
    ddPreview = controls.ddPreview;
    ddBoundaryStyle = controls.ddBoundaryStyle;
    btnApplyCrop = controls.btnApplyCrop;
    btnCancelCrop = controls.btnCancelCrop;
    if debugLog.enabled
        debugLog.trace('DIC preprocess debug trace enabled.');
    end

    refreshPreview();


    function onReferenceChosen(~, event)
        paths = labkit.ui.view.filePaths(event.addedFiles);
        if isempty(paths)
            addLog('Reference image selection cancelled.');
            return;
        end
        filepath = paths(1);
        S = dic_preprocess.state.setLoadedImage( ...
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
        paths = labkit.ui.view.filePaths(event.addedFiles);
        if isempty(paths)
            addLog('Moving image selection cancelled.');
            return;
        end
        filepath = paths(1);
        S = dic_preprocess.state.setLoadedImage( ...
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
        if dic_preprocess.ui.alertIfMissingImagePair(fig, S, ...
                'Load both reference and moving images before alignment.', ...
                'Missing images')
            return;
        end

        addLog('Opening point selector. Choose matching points, then accept.');
        [movingPoints, fixedPoints] = cpselect(S.currentMovingImage, S.currentReferenceImage, 'Wait', true);
        if size(movingPoints, 1) < 2
            labkit.ui.app.showAlert(fig, 'Rigid registration requires at least two point pairs.', 'Not enough points');
            addLog('Alignment cancelled: fewer than two point pairs.');
            return;
        end

        pushHistory('manual alignment');
        [alignedImage, tform] = dic_preprocess.ops.alignMovingToReference( ...
            S.currentReferenceImage, S.currentMovingImage, fixedPoints, movingPoints);
        S.currentMovingImage = alignedImage;
        S.alignedImage = alignedImage;
        clearDerivedStateAndMaskEditor();
        ddPreview.Value = 'False-color overlay';
        addLog(sprintf('Aligned image using %d point pair(s).', size(movingPoints, 1)));
        txtDetails.Value = dic_preprocess.view.transformSummary( ...
            tform, size(S.currentReferenceImage), size(S.currentMovingImage));
        refreshPreview();
    end

    function onAutoAlign(~, ~)
        if dic_preprocess.ui.alertIfMissingImagePair(fig, S, ...
                'Load both reference and moving images before automatic alignment.', ...
                'Missing images')
            return;
        end

        try
            [alignedImage, tform, method] = dic_preprocess.ops.autoAlignMovingToReference( ...
                S.currentReferenceImage, S.currentMovingImage);
        catch err
            labkit.ui.app.showAlert(fig, sprintf('Automatic alignment failed:\n%s', err.message), 'Auto align failed');
            addLog(sprintf('Automatic alignment failed: %s', err.message));
            return;
        end

        pushHistory('automatic alignment');
        S.currentMovingImage = alignedImage;
        S.alignedImage = alignedImage;
        clearDerivedStateAndMaskEditor();
        ddPreview.Value = 'False-color overlay';
        addLog(sprintf('Automatically aligned current pair using %s.', method));
        txtDetails.Value = dic_preprocess.view.transformSummary( ...
            tform, size(S.currentReferenceImage), size(S.currentMovingImage));
        refreshPreview();
    end

    function onStartCropRoi(~, ~)
        if dic_preprocess.ui.alertIfMissingImagePair(fig, S, ...
                'Load both reference and moving images before cropping.', ...
                'Missing images')
            return;
        end

        S = dic_preprocess.ui.clearCropRoiState(S, controls);
        S = dic_preprocess.ui.clearMaskRoiState(S, controls);

        S.cropReference = [];
        S.cropMoving = [];
        rect = dic_preprocess.ops.defaultSquareRect(size(S.currentReferenceImage));
        S.cropRect = rect;
        cropUi = dic_preprocess.ui.startCropRoi(ui, ...
            S.currentReferenceImage, S.currentMovingImage, rect, @onCropRoiMoved);
        S.cropRoiTop = cropUi.top;
        S.cropRoiBottom = cropUi.bottom;
        S.cropRoiListeners = cropUi.listeners;
        btnApplyCrop.Enable = 'on';
        btnCancelCrop.Enable = 'on';
        txtDetails.Value = dic_preprocess.view.cropSelectionSummary(rect);
        addLog('Started crop ROI on the current pair preview.');
        refreshSummary();
    end

    function onApplyCropRoi(~, ~)
        if isempty(S.cropRoiTop) || ~isvalid(S.cropRoiTop)
            labkit.ui.app.showAlert(fig, 'Start a crop ROI before applying the crop.', 'No active ROI');
            return;
        end

        rect = dic_preprocess.ops.squareRectInsideImage(S.cropRoiTop.Position, size(S.currentReferenceImage));
        pushHistory('crop');
        S.cropRect = rect;
        S.currentReferenceImage = imcrop(S.currentReferenceImage, rect);
        S.currentMovingImage = imcrop(S.currentMovingImage, rect);
        S.cropReference = S.currentReferenceImage;
        S.cropMoving = S.currentMovingImage;
        clearDerivedStateAndMaskEditor();
        S = dic_preprocess.ui.clearCropRoiState(S, controls);
        ddPreview.Value = 'Current pair';
        dic_preprocess.ui.drawPreview(ui, ...
            dic_preprocess.view.previewRequest(S, 'Current pair'));
        addLog(sprintf('Cropped current pair with [%g %g %g %g].', ...
            rect(1), rect(2), rect(3), rect(4)));
        txtDetails.Value = dic_preprocess.view.cropSummary(rect);
        refreshSummary();
    end

    function onCancelCropRoi(~, ~)
        S = dic_preprocess.ui.clearCropRoiState(S, controls);
        addLog('Crop ROI cancelled.');
        refreshPreview();
    end

    function onCropRoiMoved(~, evt)
        if isprop(evt, 'CurrentPosition')
            pos = evt.CurrentPosition;
        else
            pos = S.cropRoiTop.Position;
        end
        rect = dic_preprocess.ops.squareRectInsideImage(pos, size(S.currentReferenceImage));
        S.cropRect = rect;
        if ~isempty(S.cropRoiBottom) && isvalid(S.cropRoiBottom)
            S.cropRoiBottom.Position = rect;
        end
        txtDetails.Value = dic_preprocess.view.cropSelectionSummary(rect);
    end

    function onUndoEdit(~, ~)
        if isempty(S.history)
            labkit.ui.app.showAlert(fig, 'No align or crop operation is available to undo.', 'Undo');
            return;
        end

        snapshot = S.history(end);
        S.history(end) = [];
        S = dic_preprocess.ui.clearCropRoiState(S, controls);
        S = dic_preprocess.ui.clearMaskRoiState(S, controls);
        S = dic_preprocess.state.restoreEditSnapshot(S, snapshot);
        ddPreview.Value = 'Current pair';
        addLog(sprintf('Undid %s.', snapshot.description));
        txtDetails.Value = {sprintf('Restored state before %s.', snapshot.description)};
        refreshPreview();
        dic_preprocess.ui.updateUndoButton(controls, S);
    end

    function onResetToOriginals(~, ~)
        if isempty(S.referenceImage) || isempty(S.movingImage)
            labkit.ui.app.showAlert(fig, 'Load both images before resetting the working pair.', 'Reset');
            return;
        end
        pushHistory('reset to originals');
        S = dic_preprocess.ui.clearCropRoiState(S, controls);
        S = dic_preprocess.ui.clearMaskRoiState(S, controls);
        S = dic_preprocess.state.resetToOriginals(S);
        ddPreview.Value = 'Current pair';
        addLog('Reset current working pair to the original loaded images.');
        txtDetails.Value = {'Current working pair reset to originals.'};
        refreshPreview();
    end

    function onSaveCurrentImages(~, ~)
        if dic_preprocess.ui.alertIfMissingImagePair(fig, S, ...
                'Load both images before saving the current pair.', ...
                'Save current images')
            return;
        end

        [outputs, cancelled] = dic_preprocess.io.saveCurrentImages( ...
            S.currentReferenceImage, S.currentMovingImage, ...
            S.referencePath, S.movingPath, ...
            labkit.ui.app.defaultDialogFolder("output"));
        if cancelled
            addLog('Save current images cancelled.');
            return;
        end

        addLog(sprintf('Saved current images: %s and %s', ...
            outputs.referencePath, outputs.movingPath));
    end

    function onStartMaskEdit(~, ~)
        if isempty(S.currentReferenceImage)
            labkit.ui.app.showAlert(fig, 'Load a reference image before drawing an ROI mask.', 'Missing image');
            return;
        end

        S = dic_preprocess.ui.clearCropRoiState(S, controls);
        S = dic_preprocess.ui.clearMaskRoiState(S, controls);
        S.maskImage = [];
        S.maskPoints = [];
        S.maskHistory = S.maskHistory([]);
        S.maskBoundaryStyle = string(ddBoundaryStyle.Value);
        S.maskEditor = dic_preprocess.ui.startMaskEdit(ui, imageRuntime, ...
            S.currentReferenceImage, S.maskPoints, ...
            S.maskBoundaryStyle, @onMaskEditorChanged);
        S = dic_preprocess.ui.setMaskEditControls(S, controls, true);
        addLog('Started mask ROI canvas. Add/insert, move, or delete anchors; add/subtract boundaries on the mask canvas.');
        txtDetails.Value = {'ROI edit started. Double-click blank space to add/insert points, drag points to move them, double-click points to delete them.'};
        dic_preprocess.ui.updateMaskEditControls(controls, S);
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
        dic_preprocess.ui.updateMaskEditControls(controls, S);
        txtDetails.Value = dic_preprocess.view.maskDraftDetails(S.maskPoints);
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
        S.maskImage = dic_preprocess.state.applyBoundaryToMask( ...
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
        S.maskImage = dic_preprocess.state.applyBoundaryToMask( ...
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
        S = dic_preprocess.state.restoreMaskSnapshot(S, snapshot);
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
                labkit.ui.app.showAlert(fig, 'Draw a mask ROI or add a boundary to the mask canvas before saving.', 'Save ROI mask');
                return;
            end
            S.maskImage = boundaryMask;
        end

        [out, cancelled] = dic_preprocess.io.saveMask( ...
            S.maskImage, S.referencePath, ...
            labkit.ui.app.defaultDialogFolder("output"));
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
            dic_preprocess.ui.showImage(ui, 'current', ...
                dic_preprocess.ops.maskRgb(boundaryMask), 'ROI boundary preview');
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
        [boundaryMask, ok] = dic_preprocess.ops.boundaryMaskFromEditor( ...
            S.maskPoints, size(S.currentReferenceImage), ...
            S.maskBoundaryStyle, S.maskEditor);
        if ~ok && showAlert
            labkit.ui.app.showAlert(fig, 'Mask ROI needs at least three anchors.', 'Not enough anchors');
        end
    end

    function showMaskCanvas(titleText)
        ddPreview.Value = 'ROI mask';
        dic_preprocess.ui.drawMaskCanvas(ui, ...
            S.currentReferenceImage, S.maskImage, titleText);
        dic_preprocess.ui.updateMaskEditControls(controls, S);
    end

    function pushMaskHistory(description)
        S.maskHistory = dic_preprocess.state.appendMaskHistory( ...
            S.maskHistory, S.maskImage, S.maskPoints, description);
        dic_preprocess.ui.updateMaskEditControls(controls, S);
    end

    function refreshPreview()
        S = dic_preprocess.ui.clearCropRoiState(S, controls);
        S = dic_preprocess.ui.clearMaskRoiState(S, controls);
        request = dic_preprocess.view.previewRequest(S, ddPreview.Value);
        dic_preprocess.ui.drawPreview(ui, request);
        refreshSummary();
    end

    function refreshSummary()
        labkit.ui.view.setValue(ui, 'referenceFile', fileValue(S.referencePath));
        labkit.ui.view.setValue(ui, 'movingFile', fileValue(S.movingPath));
        txtSummary.Value = dic_preprocess.view.buildSummary(S);
        dic_preprocess.ui.updateUndoButton(controls, S);
    end

    function resetWorkflowStateForNewInput()
        S = dic_preprocess.state.resetForNewInput(S);
        S = dic_preprocess.ui.clearCropRoiState(S, controls);
        S = dic_preprocess.ui.clearMaskRoiState(S, controls);
        dic_preprocess.ui.updateUndoButton(controls, S);
    end

    function chooseDefaultPreviewAfterLoad()
        if dic_preprocess.state.hasImagePair(S)
            ddPreview.Value = 'False-color overlay';
        else
            ddPreview.Value = 'Current pair';
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
        [S.history, appended] = dic_preprocess.state.appendEditHistory( ...
            S.history, S, description);
        if appended
            dic_preprocess.ui.updateUndoButton(controls, S);
        end
    end

    function clearDerivedStateAndMaskEditor()
        S = dic_preprocess.state.clearOperationDerivedState(S);
        S = dic_preprocess.ui.clearMaskRoiState(S, controls);
    end

    function addLog(msg)
        labkit.ui.view.appendLog(ui, 'appLog', msg);
        debugLog.append(msg);
    end

end
