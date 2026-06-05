% App-owned DIC preprocess runner. Expected caller: labkit_DICPreprocess_app.
% Input is the debug context prepared by the public launcher. Output is the app
% figure. Side effects are GUI creation, user-driven file I/O, and debug trace
% attachment exactly as in the original entrypoint body.
function fig = runDICPreprocessApp(debugLog)
%RUNDICPREPROCESSAPP Build and run the DIC preprocess app body.

    S = struct();
    S.referencePath = "";
    S.movingPath = "";
    S.referenceImage = [];
    S.movingImage = [];
    S.currentReferenceImage = [];
    S.currentMovingImage = [];
    S.alignedImage = [];
    S.cropReference = [];
    S.cropMoving = [];
    S.cropRect = [];
    S.cropRoiTop = [];
    S.cropRoiBottom = [];
    S.cropRoiListeners = {};
    S.maskImage = [];
    S.maskPoints = [];
    S.maskEditor = [];
    S.maskBoundaryStyle = "Curve";
    S.maskEditActive = false;
    S.maskHistory = struct('maskImage', {}, 'maskPoints', {}, 'description', {});
    S.history = struct('reference', {}, 'moving', {}, 'aligned', {}, ...
        'cropReference', {}, 'cropMoving', {}, 'maskImage', {}, ...
        'maskPoints', {}, 'description', {});

    workbenchOpts = struct('rightKind', 'dualPlot', ...
        'rightTitle', 'Image Preview', ...
        'topPlotTitle', 'Reference', ...
        'bottomPlotTitle', 'Current Preview', ...
        'showPlotControls', false);
    workbenchOpts.tabs = [ ...
        labkit.ui.app.tab('filesAnalysis', 'Files + Analysis', [4 1], ...
            {240, 210, 330, 170}, ...
            struct('resizeRows', [1 2 3], ...
            'resizeOptions', struct('minTopHeight', 120, 'minBottomHeight', 80))), ...
        labkit.ui.app.tab('summaryResults', 'Summary + Results', [2 1], ...
            {150, '1x'}, ...
            struct('resizeRows', 1, ...
            'resizeOptions', struct('minTopHeight', 90, 'minBottomHeight', 90))), ...
        labkit.ui.app.tab('log', 'Log', [1 1], {'1x'})];
    ui = labkit.ui.app.createShell(struct( ...
        'title', 'DIC Image Preprocess', ...
        'position', [80 60 1400 860], ...
        'leftWidth', 370, ...
        'options', workbenchOpts));
    fig = ui.fig;
    imageRuntime = labkit.ui.tool.createRuntime(ui.topAxes, ...
        struct('figure', fig, 'defaultScrollFcn', @onPreviewScrollZoom));

    layFA = ui.filesAnalysisGrid;
    laySR = ui.summaryResultsGrid;
    layLog = ui.logGrid;
    filePanel = labkit.ui.view.section(layFA, 'Images', 1, [4 2], ...
        struct('rowHeight', {{'fit', 'fit', 'fit', 'fit'}}, ...
        'columnWidth', {{'1x', '1x'}}));
    fileGrid = filePanel.grid;

    btnReference = uibutton(fileGrid, 'Text', 'Open reference image', ...
        'ButtonPushedFcn', @onOpenReference);
    btnReference.Layout.Row = 1;
    btnReference.Layout.Column = 1;
    btnMoving = uibutton(fileGrid, 'Text', 'Open moving image', ...
        'ButtonPushedFcn', @onOpenMoving);
    btnMoving.Layout.Row = 1;
    btnMoving.Layout.Column = 2;

    txtReference = labkit.ui.view.form(fileGrid, 'readonly', ...
        'Value', 'No reference image loaded');
    txtReference.Layout.Row = 2;
    txtReference.Layout.Column = [1 2];
    txtMoving = labkit.ui.view.form(fileGrid, 'readonly', ...
        'Value', 'No moving image loaded');
    txtMoving.Layout.Row = 3;
    txtMoving.Layout.Column = [1 2];

    [lblPreview, ddPreview] = labkit.ui.view.form(fileGrid, 'dropdown', 'Preview:', ...
        'Items', {'Current pair', 'Current moving image', 'False-color overlay', 'Original pair', 'ROI mask'}, ...
        'Value', 'Current pair', ...
        'ValueChangedFcn', @(~,~) refreshPreview());
    lblPreview.Layout.Row = 4;
    lblPreview.Layout.Column = 1;
    ddPreview.Layout.Row = 4;
    ddPreview.Layout.Column = 2;

    actionPanel = labkit.ui.view.section(layFA, 'Registration + Crop', 2, [6 2], ...
        struct('rowHeight', {{'fit', 'fit', 'fit', 'fit', 'fit', 'fit'}}, ...
        'columnWidth', {{'1x', '1x'}}));
    actionGrid = actionPanel.grid;

    btnAlign = uibutton(actionGrid, 'Text', 'Select points + align', ...
        'ButtonPushedFcn', @onAlign);
    btnAlign.Layout.Row = 1;
    btnAlign.Layout.Column = [1 2];
    btnAutoAlign = uibutton(actionGrid, 'Text', 'Auto align current pair', ...
        'ButtonPushedFcn', @onAutoAlign);
    btnAutoAlign.Layout.Row = 2;
    btnAutoAlign.Layout.Column = [1 2];
    btnCrop = uibutton(actionGrid, 'Text', 'Start/reset crop ROI', ...
        'ButtonPushedFcn', @onStartCropRoi);
    btnCrop.Layout.Row = 3;
    btnCrop.Layout.Column = [1 2];
    btnApplyCrop = uibutton(actionGrid, 'Text', 'Apply ROI crop', ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @onApplyCropRoi);
    btnApplyCrop.Layout.Row = 4;
    btnApplyCrop.Layout.Column = 1;
    btnCancelCrop = uibutton(actionGrid, 'Text', 'Cancel ROI', ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @onCancelCropRoi);
    btnCancelCrop.Layout.Row = 4;
    btnCancelCrop.Layout.Column = 2;
    btnUndoEdit = uibutton(actionGrid, 'Text', 'Undo align/crop', ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @onUndoEdit);
    btnUndoEdit.Layout.Row = 5;
    btnUndoEdit.Layout.Column = 1;
    btnSaveCurrent = uibutton(actionGrid, 'Text', 'Save current images', ...
        'ButtonPushedFcn', @onSaveCurrentImages);
    btnSaveCurrent.Layout.Row = 5;
    btnSaveCurrent.Layout.Column = 2;
    btnResetCurrent = uibutton(actionGrid, 'Text', 'Reset to originals', ...
        'ButtonPushedFcn', @onResetToOriginals);
    btnResetCurrent.Layout.Row = 6;
    btnResetCurrent.Layout.Column = [1 2];
    maskPanel = labkit.ui.view.section(layFA, 'Mask ROI', 3, [7 2], ...
        struct('rowHeight', {{'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'}}, ...
        'columnWidth', {{'1x', '1x'}}));
    maskGrid = maskPanel.grid;

    btnStartMask = uibutton(maskGrid, 'Text', 'Start ROI edit', ...
        'ButtonPushedFcn', @onStartMaskEdit);
    btnStartMask.Layout.Row = 1;
    btnStartMask.Layout.Column = [1 2];
    [lblBoundaryStyle, ddBoundaryStyle] = labkit.ui.view.form(maskGrid, 'dropdown', 'Boundary:', ...
        'Items', {'Curve', 'Straight lines'}, ...
        'Value', 'Curve', ...
        'ValueChangedFcn', @onBoundaryStyleChanged);
    lblBoundaryStyle.Layout.Row = 2;
    lblBoundaryStyle.Layout.Column = 1;
    ddBoundaryStyle.Layout.Row = 2;
    ddBoundaryStyle.Layout.Column = 2;
    ddBoundaryStyle.Enable = 'off';
    btnPreviewMask = uibutton(maskGrid, 'Text', 'Preview ROI mask', ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @onPreviewMaskRoi);
    btnPreviewMask.Layout.Row = 3;
    btnPreviewMask.Layout.Column = 1;
    btnUnionMask = uibutton(maskGrid, 'Text', 'Add to mask', ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @onAddBoundaryToMask);
    btnUnionMask.Layout.Row = 3;
    btnUnionMask.Layout.Column = 2;
    btnSubtractMask = uibutton(maskGrid, 'Text', 'Subtract from mask', ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @onSubtractBoundaryFromMask);
    btnSubtractMask.Layout.Row = 4;
    btnSubtractMask.Layout.Column = 1;
    btnUndoMask = uibutton(maskGrid, 'Text', 'Undo point', ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @onUndoMaskAnchor);
    btnUndoMask.Layout.Row = 4;
    btnUndoMask.Layout.Column = 2;
    btnUndoMaskEdit = uibutton(maskGrid, 'Text', 'Undo mask edit', ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @onUndoMaskEdit);
    btnUndoMaskEdit.Layout.Row = 5;
    btnUndoMaskEdit.Layout.Column = 1;
    btnClearBoundary = uibutton(maskGrid, 'Text', 'Clear boundary', ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @onClearMaskBoundary);
    btnClearBoundary.Layout.Row = 5;
    btnClearBoundary.Layout.Column = 2;
    btnClearMask = uibutton(maskGrid, 'Text', 'Clear mask', ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @onClearMaskCanvas);
    btnClearMask.Layout.Row = 6;
    btnClearMask.Layout.Column = [1 2];
    btnSaveMask = uibutton(maskGrid, 'Text', 'Save ROI mask', ...
        'ButtonPushedFcn', @onSaveMask);
    btnSaveMask.Layout.Row = 7;
    btnSaveMask.Layout.Column = [1 2];

    labkit.ui.view.panel(layFA, 'text', 'Workflow Notes', 4, { ...
        '1. Load a reference image and a moving image.', ...
        '2. Align or crop the current working pair in any order; each apply step can be undone.', ...
        '3. False-color preview compares the current pair even before alignment.', ...
        '4. Draw curve or straight-line ROI boundaries, add/subtract them on the mask canvas, then save the mask.'});

    txtSummary = uitextarea(laySR, 'Editable', 'off');
    txtSummary.Layout.Row = 1;
    txtSummary.Value = {'No images loaded.'};

    txtDetails = uitextarea(laySR, 'Editable', 'off');
    labkit.ui.view.place(txtDetails, laySR, 2);
    txtDetails.Value = {'Alignment and crop details will appear here.'};

    logUi = labkit.ui.view.panel(layLog, 'log', 1, {'Ready.'});
    txtLog = logUi.textArea;
    if debugLog.enabled
        debugLog.attachTextLog(txtLog);
        debugLog.trace('DIC preprocess debug trace enabled.');
        debugLog.instrumentFigure(fig);
    end

    resetPreviewAxes();


    function onOpenReference(~, ~)
        filepath = chooseImageFile('Select reference image');
        if filepath == ""
            addLog('Reference image selection cancelled.');
            return;
        end
        S.referencePath = filepath;
        S.referenceImage = imread(filepath);
        S.currentReferenceImage = S.referenceImage;
        resetWorkflowStateForNewInput();
        txtReference.Value = char(filepath);
        addLog(sprintf('Loaded reference image: %s', filepath));
        chooseDefaultPreviewAfterLoad();
        refreshPreview();
    end

    function onOpenMoving(~, ~)
        filepath = chooseImageFile('Select moving image');
        if filepath == ""
            addLog('Moving image selection cancelled.');
            return;
        end
        S.movingPath = filepath;
        S.movingImage = imread(filepath);
        S.currentMovingImage = S.movingImage;
        resetWorkflowStateForNewInput();
        txtMoving.Value = char(filepath);
        addLog(sprintf('Loaded moving image: %s', filepath));
        chooseDefaultPreviewAfterLoad();
        refreshPreview();
    end

    function onAlign(~, ~)
        if ~hasImagePair()
            uialert(fig, 'Load both reference and moving images before alignment.', 'Missing images');
            return;
        end

        addLog('Opening point selector. Choose matching points, then accept.');
        [movingPoints, fixedPoints] = cpselect(S.currentMovingImage, S.currentReferenceImage, 'Wait', true);
        if size(movingPoints, 1) < 2
            uialert(fig, 'Rigid registration requires at least two point pairs.', 'Not enough points');
            addLog('Alignment cancelled: fewer than two point pairs.');
            return;
        end

        pushHistory('manual alignment');
        [alignedImage, tform] = alignMovingToReference( ...
            S.currentReferenceImage, S.currentMovingImage, fixedPoints, movingPoints);
        S.currentMovingImage = alignedImage;
        S.alignedImage = alignedImage;
        clearOperationDerivedState();
        ddPreview.Value = 'False-color overlay';
        addLog(sprintf('Aligned image using %d point pair(s).', size(movingPoints, 1)));
        txtDetails.Value = transformSummary(tform, size(S.currentReferenceImage), size(S.currentMovingImage));
        refreshPreview();
    end

    function onAutoAlign(~, ~)
        if ~hasImagePair()
            uialert(fig, 'Load both reference and moving images before automatic alignment.', 'Missing images');
            return;
        end

        try
            [alignedImage, tform, method] = autoAlignMovingToReference( ...
                S.currentReferenceImage, S.currentMovingImage);
        catch err
            uialert(fig, sprintf('Automatic alignment failed:\n%s', err.message), 'Auto align failed');
            addLog(sprintf('Automatic alignment failed: %s', err.message));
            return;
        end

        pushHistory('automatic alignment');
        S.currentMovingImage = alignedImage;
        S.alignedImage = alignedImage;
        clearOperationDerivedState();
        ddPreview.Value = 'False-color overlay';
        addLog(sprintf('Automatically aligned current pair using %s.', method));
        txtDetails.Value = transformSummary(tform, size(S.currentReferenceImage), size(S.currentMovingImage));
        refreshPreview();
    end

    function onStartCropRoi(~, ~)
        if ~hasImagePair()
            uialert(fig, 'Load both reference and moving images before cropping.', 'Missing images');
            return;
        end

        clearCropRoi();
        clearMaskRoi();
        resetPreviewAxes();
        showImage(ui.topAxes, S.currentReferenceImage, 'Current reference');
        showImage(ui.bottomAxes, S.currentMovingImage, 'Current moving');

        S.cropReference = [];
        S.cropMoving = [];
        rect = defaultSquareRect(size(S.currentReferenceImage));
        S.cropRect = rect;
        S.cropRoiTop = drawrectangle(ui.topAxes, ...
            'Position', rect, ...
            'FixedAspectRatio', true, ...
            'Color', [1 0.85 0], ...
            'LineWidth', 1.5);
        S.cropRoiBottom = rectangle(ui.bottomAxes, ...
            'Position', rect, ...
            'EdgeColor', [1 0.85 0], ...
            'LineWidth', 1.5, ...
            'LineStyle', '--');
        S.cropRoiListeners = { ...
            addlistener(S.cropRoiTop, 'MovingROI', @onCropRoiMoved), ...
            addlistener(S.cropRoiTop, 'ROIMoved', @onCropRoiMoved)};
        btnApplyCrop.Enable = 'on';
        btnCancelCrop.Enable = 'on';
        txtDetails.Value = cropSelectionSummary(rect);
        addLog('Started crop ROI on the current pair preview.');
        refreshSummary();
    end

    function onApplyCropRoi(~, ~)
        if isempty(S.cropRoiTop) || ~isvalid(S.cropRoiTop)
            uialert(fig, 'Start a crop ROI before applying the crop.', 'No active ROI');
            return;
        end

        rect = squareRectInsideImage(S.cropRoiTop.Position, size(S.currentReferenceImage));
        pushHistory('crop');
        S.cropRect = rect;
        S.currentReferenceImage = imcrop(S.currentReferenceImage, rect);
        S.currentMovingImage = imcrop(S.currentMovingImage, rect);
        S.cropReference = S.currentReferenceImage;
        S.cropMoving = S.currentMovingImage;
        clearOperationDerivedState();
        clearCropRoi();
        ddPreview.Value = 'Current pair';
        showCurrentPair();
        addLog(sprintf('Cropped current pair with [%g %g %g %g].', ...
            rect(1), rect(2), rect(3), rect(4)));
        txtDetails.Value = cropSummary(rect);
        refreshSummary();
    end

    function onCancelCropRoi(~, ~)
        clearCropRoi();
        addLog('Crop ROI cancelled.');
        refreshPreview();
    end

    function onCropRoiMoved(~, evt)
        if isprop(evt, 'CurrentPosition')
            pos = evt.CurrentPosition;
        else
            pos = S.cropRoiTop.Position;
        end
        rect = squareRectInsideImage(pos, size(S.currentReferenceImage));
        S.cropRect = rect;
        if ~isempty(S.cropRoiBottom) && isvalid(S.cropRoiBottom)
            S.cropRoiBottom.Position = rect;
        end
        txtDetails.Value = cropSelectionSummary(rect);
    end

    function onUndoEdit(~, ~)
        if isempty(S.history)
            uialert(fig, 'No align or crop operation is available to undo.', 'Undo');
            return;
        end

        snapshot = S.history(end);
        S.history(end) = [];
        clearCropRoi();
        clearMaskRoi();
        S.currentReferenceImage = snapshot.reference;
        S.currentMovingImage = snapshot.moving;
        S.alignedImage = snapshot.aligned;
        S.cropReference = snapshot.cropReference;
        S.cropMoving = snapshot.cropMoving;
        S.maskImage = snapshot.maskImage;
        S.maskPoints = snapshot.maskPoints;
        ddPreview.Value = 'Current pair';
        addLog(sprintf('Undid %s.', snapshot.description));
        txtDetails.Value = {sprintf('Restored state before %s.', snapshot.description)};
        refreshPreview();
        updateUndoButton();
    end

    function onResetToOriginals(~, ~)
        if isempty(S.referenceImage) || isempty(S.movingImage)
            uialert(fig, 'Load both images before resetting the working pair.', 'Reset');
            return;
        end
        pushHistory('reset to originals');
        S.currentReferenceImage = S.referenceImage;
        S.currentMovingImage = S.movingImage;
        S.alignedImage = [];
        S.cropReference = [];
        S.cropMoving = [];
        clearCropRoi();
        clearMaskRoi();
        clearOperationDerivedState();
        ddPreview.Value = 'Current pair';
        addLog('Reset current working pair to the original loaded images.');
        txtDetails.Value = {'Current working pair reset to originals.'};
        refreshPreview();
    end

    function onSaveCurrentImages(~, ~)
        if ~hasImagePair()
            uialert(fig, 'Load both images before saving the current pair.', 'Save current images');
            return;
        end

        folder = uigetdir(defaultSaveFolder(), 'Select folder for current images');
        if isequal(folder, 0)
            addLog('Save current images cancelled.');
            return;
        end

        refOut = fullfile(folder, 'current_reference.png');
        curOut = fullfile(folder, 'current_moving.png');
        imwrite(S.currentReferenceImage, refOut);
        imwrite(S.currentMovingImage, curOut);
        addLog(sprintf('Saved current images: %s and %s', refOut, curOut));
    end

    function onStartMaskEdit(~, ~)
        if isempty(S.currentReferenceImage)
            uialert(fig, 'Load a reference image before drawing an ROI mask.', 'Missing image');
            return;
        end

        clearCropRoi();
        clearMaskRoi();
        resetPreviewAxes();
        hTopImage = showImage(ui.topAxes, S.currentReferenceImage, 'Current reference');
        showImage(ui.bottomAxes, zeros(size(S.currentReferenceImage, 1), size(S.currentReferenceImage, 2), 3, 'uint8'), 'ROI mask preview');
        S.maskImage = [];
        S.maskPoints = [];
        S.maskHistory = S.maskHistory([]);
        S.maskBoundaryStyle = string(ddBoundaryStyle.Value);
        S.maskEditor = labkit.ui.tool.anchorEditor(imageRuntime, size(S.currentReferenceImage), ...
            struct('closed', true, ...
            'style', S.maskBoundaryStyle, ...
            'installScrollWheel', false, ...
            'onChanged', @onMaskEditorChanged));
        S.maskEditor.setBackground(hTopImage);
        S.maskEditor.start(S.maskPoints);
        setMaskEditControls(true);
        addLog('Started mask ROI canvas. Add/insert, move, or delete anchors; add/subtract boundaries on the mask canvas.');
        txtDetails.Value = {'ROI edit started. Double-click blank space to add/insert points, drag points to move them, double-click points to delete them.'};
        updateMaskEditControls();
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
        updateMaskEditControls();
        if size(S.maskPoints, 1) >= 3
            txtDetails.Value = {sprintf('Mask ROI anchors: %d. Preview, Add to mask, or Subtract from mask.', size(S.maskPoints, 1))};
        else
            txtDetails.Value = {sprintf('Mask ROI anchors: %d. Need at least 3 anchors to form a closed ROI boundary.', size(S.maskPoints, 1))};
        end
        refreshSummary();
    end

    function updateMaskCurveGraphics()
        if ~isempty(S.maskEditor)
            S.maskEditor.refresh();
        end
    end

    function setMaskEditControls(enabled)
        S.maskEditActive = enabled;
        state = ternary(enabled, 'on', 'off');
        ddBoundaryStyle.Enable = state;
        updateMaskEditControls();
    end

    function updateMaskEditControls()
        editActive = S.maskEditActive;
        hasPoints = ~isempty(S.maskPoints);
        canBoundary = size(S.maskPoints, 1) >= 3;
        canUndoCanvas = ~isempty(S.maskHistory);
        canClearCanvas = ~isempty(S.maskImage);
        btnPreviewMask.Enable = ternary(editActive && (canBoundary || canClearCanvas), 'on', 'off');
        btnUnionMask.Enable = ternary(editActive && canBoundary, 'on', 'off');
        btnSubtractMask.Enable = ternary(editActive && canBoundary, 'on', 'off');
        btnUndoMask.Enable = ternary(editActive && hasPoints, 'on', 'off');
        btnClearBoundary.Enable = ternary(editActive && hasPoints, 'on', 'off');
        btnUndoMaskEdit.Enable = ternary(editActive && canUndoCanvas, 'on', 'off');
        btnClearMask.Enable = ternary(editActive && canClearCanvas, 'on', 'off');
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
        S.maskImage = max(maskCanvas(), boundaryMask);
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
        canvas = maskCanvas();
        canvas(boundaryMask > 0) = 0;
        S.maskImage = canvas;
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
        S.maskImage = snapshot.maskImage;
        S.maskPoints = snapshot.maskPoints;
        if ~isempty(S.maskEditor)
            S.maskEditor.setPoints(S.maskPoints);
        end
        updateMaskCurveGraphics();
        showMaskCanvas('ROI mask canvas');
        addLog(sprintf('Undid mask edit: %s.', snapshot.description));
        refreshSummary();
    end

    function onPreviewScrollZoom(~, evt)
        ax = previewAxesUnderPointer();
        if isempty(ax)
            return;
        end

        point = ax.CurrentPoint;
        x = point(1, 1);
        y = point(1, 2);
        imageSize = axesImageSize(ax);
        if isempty(imageSize) || ~insideImageBounds(x, y, imageSize)
            return;
        end
        zoomAxesAtPoint(ax, x, y, evt.VerticalScrollCount, imageSize);
    end

    function ax = previewAxesUnderPointer()
        ax = [];
        try
            hit = hittest(fig);
            ax = ancestor(hit, 'matlab.ui.control.UIAxes');
        catch
            ax = [];
        end
        if isequal(ax, ui.topAxes) || isequal(ax, ui.bottomAxes)
            return;
        end
        ax = [];
    end

    function onSaveMask(~, ~)
        if isempty(S.maskImage)
            [boundaryMask, ok] = currentBoundaryMask(false);
            if ~ok
                uialert(fig, 'Draw a mask ROI or add a boundary to the mask canvas before saving.', 'Save ROI mask');
                return;
            end
            S.maskImage = boundaryMask;
        end

        [folder, name] = fileparts(char(S.referencePath));
        if isempty(folder)
            folder = pwd;
        end
        defaultName = fullfile(folder, [name '_roi_mask.png']);
        [f, p] = uiputfile({'*.png', 'PNG mask'}, 'Save ROI mask', defaultName);
        if isequal(f, 0)
            addLog('Save ROI mask cancelled.');
            return;
        end

        out = fullfile(p, f);
        imwrite(S.maskImage, out);
        addLog(sprintf('Saved ROI mask: %s', out));
    end

    function ok = previewMaskImage(showAlert)
        [boundaryMask, ok] = currentBoundaryMask(showAlert);
        if ok
            ddPreview.Value = 'ROI mask';
            showImage(ui.bottomAxes, maskRgb(boundaryMask), 'ROI boundary preview');
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
        ok = false;
        boundaryMask = [];
        if size(S.maskPoints, 1) < 3
            if showAlert
                uialert(fig, 'Mask ROI needs at least three anchors.', 'Not enough anchors');
            end
            return;
        end
        if ~isempty(S.maskEditor)
            curve = S.maskEditor.curvePoints();
            boundaryMask = maskFromCurve(curve, size(S.currentReferenceImage));
        else
            boundaryMask = boundaryMaskImage(S.maskPoints, size(S.currentReferenceImage), S.maskBoundaryStyle);
        end
        ok = true;
    end

    function canvas = maskCanvas()
        if isempty(S.maskImage)
            canvas = zeros(size(S.currentReferenceImage, 1), size(S.currentReferenceImage, 2), 'uint8');
        else
            canvas = S.maskImage;
        end
    end

    function showMaskCanvas(titleText)
        if isempty(S.maskImage)
            mask = zeros(size(S.currentReferenceImage, 1), size(S.currentReferenceImage, 2), 'uint8');
        else
            mask = S.maskImage;
        end
        ddPreview.Value = 'ROI mask';
        showImage(ui.bottomAxes, maskRgb(mask), titleText);
        updateMaskEditControls();
    end

    function pushMaskHistory(description)
        snapshot = struct( ...
            'maskImage', S.maskImage, ...
            'maskPoints', S.maskPoints, ...
            'description', description);
        S.maskHistory(end+1) = snapshot;
        maxUndoSteps = 20;
        if numel(S.maskHistory) > maxUndoSteps
            S.maskHistory = S.maskHistory((end - maxUndoSteps + 1):end);
        end
        updateMaskEditControls();
    end

    function refreshPreview()
        clearCropRoi();
        clearMaskRoi();
        resetPreviewAxes();
        if strcmp(ddPreview.Value, 'Current pair')
            showCurrentPair();
            refreshSummary();
            return;
        elseif strcmp(ddPreview.Value, 'Original pair')
            showOriginalPair();
            refreshSummary();
            return;
        elseif strcmp(ddPreview.Value, 'ROI mask')
            if ~isempty(S.currentReferenceImage)
                showImage(ui.topAxes, S.currentReferenceImage, 'Current reference');
            end
            if ~isempty(S.maskImage)
                showImage(ui.bottomAxes, maskRgb(S.maskImage), 'ROI mask');
            end
            refreshSummary();
            return;
        elseif ~isempty(S.currentReferenceImage)
            showImage(ui.topAxes, S.currentReferenceImage, 'Current reference');
        end

        previewImage = [];
        previewTitle = ddPreview.Value;
        switch ddPreview.Value
            case 'Current moving image'
                previewImage = S.currentMovingImage;
            case 'False-color overlay'
                if hasImagePair()
                    previewImage = makeFalseColorOverlay(S.currentReferenceImage, S.currentMovingImage);
                end
        end

        if ~isempty(previewImage)
            showImage(ui.bottomAxes, previewImage, previewTitle);
        end
        refreshSummary();
    end

    function refreshSummary()
        lines = {};
        lines{end+1} = sprintf('Reference: %s', displayPath(S.referencePath));
        lines{end+1} = sprintf('Moving: %s', displayPath(S.movingPath));
        lines{end+1} = sprintf('Current pair: %s', ternary(hasImagePair(), currentPairSizeText(), 'not loaded'));
        lines{end+1} = sprintf('Undo steps: %d', numel(S.history));
        lines{end+1} = sprintf('Last aligned image: %s', ternary(~isempty(S.alignedImage), 'available', 'not generated'));
        lines{end+1} = sprintf('ROI mask: %s', ternary(~isempty(S.maskImage), 'available', 'not drawn'));
        txtSummary.Value = lines;
        updateUndoButton();
    end

    function tf = hasImagePair()
        tf = ~isempty(S.currentReferenceImage) && ~isempty(S.currentMovingImage);
    end

    function txt = currentPairSizeText()
        if ~hasImagePair()
            txt = 'not loaded';
            return;
        end
        txt = sprintf('reference %d x %d, moving %d x %d', ...
            size(S.currentReferenceImage, 1), size(S.currentReferenceImage, 2), ...
            size(S.currentMovingImage, 1), size(S.currentMovingImage, 2));
    end

    function showCurrentPair()
        resetPreviewAxes();
        if ~isempty(S.currentReferenceImage)
            showImage(ui.topAxes, S.currentReferenceImage, 'Current reference');
        end
        if ~isempty(S.currentMovingImage)
            showImage(ui.bottomAxes, S.currentMovingImage, 'Current moving');
        end
    end

    function showOriginalPair()
        resetPreviewAxes();
        if ~isempty(S.referenceImage)
            showImage(ui.topAxes, S.referenceImage, 'Original reference');
        end
        if ~isempty(S.movingImage)
            showImage(ui.bottomAxes, S.movingImage, 'Original moving');
        end
    end

    function clearCropRoi()
        for iListener = 1:numel(S.cropRoiListeners)
            deleteIfValid(S.cropRoiListeners{iListener});
        end
        S.cropRoiListeners = {};
        deleteIfValid(S.cropRoiTop);
        deleteIfValid(S.cropRoiBottom);
        S.cropRoiTop = [];
        S.cropRoiBottom = [];
        btnApplyCrop.Enable = 'off';
        btnCancelCrop.Enable = 'off';
    end

    function clearMaskRoi()
        if ~isempty(S.maskEditor)
            S.maskEditor.delete();
        end
        S.maskEditor = [];
        S.maskPoints = [];
        setMaskEditControls(false);
    end

    function resetWorkflowStateForNewInput()
        if ~isempty(S.referenceImage)
            S.currentReferenceImage = S.referenceImage;
        end
        if ~isempty(S.movingImage)
            S.currentMovingImage = S.movingImage;
        end
        S.alignedImage = [];
        S.cropReference = [];
        S.cropMoving = [];
        S.cropRect = [];
        S.maskImage = [];
        S.maskPoints = [];
        S.maskHistory = S.maskHistory([]);
        S.history = S.history([]);
        clearCropRoi();
        clearMaskRoi();
        updateUndoButton();
    end

    function chooseDefaultPreviewAfterLoad()
        if hasImagePair()
            ddPreview.Value = 'False-color overlay';
        else
            ddPreview.Value = 'Current pair';
        end
    end

    function pushHistory(description)
        if ~hasImagePair()
            return;
        end
        snapshot = struct( ...
            'reference', S.currentReferenceImage, ...
            'moving', S.currentMovingImage, ...
            'aligned', S.alignedImage, ...
            'cropReference', S.cropReference, ...
            'cropMoving', S.cropMoving, ...
            'maskImage', S.maskImage, ...
            'maskPoints', S.maskPoints, ...
            'description', description);
        S.history(end+1) = snapshot;
        maxUndoSteps = 12;
        if numel(S.history) > maxUndoSteps
            S.history = S.history((end - maxUndoSteps + 1):end);
        end
        updateUndoButton();
    end

    function clearOperationDerivedState()
        S.maskImage = [];
        S.maskPoints = [];
        S.maskHistory = S.maskHistory([]);
        clearMaskRoi();
    end

    function updateUndoButton()
        btnUndoEdit.Enable = ternary(~isempty(S.history), 'on', 'off');
    end

    function folder = defaultSaveFolder()
        [folder, ~] = fileparts(char(S.referencePath));
        if isempty(folder)
            [folder, ~] = fileparts(char(S.movingPath));
        end
        if isempty(folder)
            folder = pwd;
        end
    end

    function resetPreviewAxes()
        labkit.ui.view.draw(ui.topAxes, 'reset', 'Reference', true);
        labkit.ui.view.draw(ui.bottomAxes, 'reset', 'Current Preview', true);
    end

    function addLog(msg)
        labkit.ui.view.update(txtLog, 'appendLog', msg);
        debugLog.append(msg);
    end
end
