function varargout = labkit_DICPreprocess_app(varargin)
%LABKIT_DICPREPROCESS_APP Image registration and paired-crop app for DIC workflows.

    [requestHandled, requestOutputs, debugLog] = labkit.ui.handleAppRequest( ...
        'labkit_DICPreprocess_app', varargin, nargout);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_DICPreprocess_app:TooManyOutputs', ...
                'labkit_DICPreprocess_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_DICPreprocess_app:TooManyOutputs', ...
            'labkit_DICPreprocess_app returns at most the app figure handle.');
    end

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
        labkit.ui.tabSpec('filesAnalysis', 'Files + Analysis', [4 1], ...
            {240, 210, 330, 170}, ...
            struct('resizeRows', [1 2 3], ...
            'resizeOptions', struct('minTopHeight', 120, 'minBottomHeight', 80))), ...
        labkit.ui.tabSpec('summaryResults', 'Summary + Results', [2 1], ...
            {150, '1x'}, ...
            struct('resizeRows', 1, ...
            'resizeOptions', struct('minTopHeight', 90, 'minBottomHeight', 90))), ...
        labkit.ui.tabSpec('log', 'Log', [1 1], {'1x'})];
    ui = labkit.ui.createWorkbench( ...
        'DIC Image Preprocess', [80 60 1400 860], 370, workbenchOpts);
    fig = ui.fig;
    fig.WindowScrollWheelFcn = @onPreviewScrollZoom;

    layFA = ui.filesAnalysisGrid;
    laySR = ui.summaryResultsGrid;
    layLog = ui.logGrid;
    filePanel = labkit.ui.createPanelGrid(layFA, 'Images', 1, [4 2], ...
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

    txtReference = labkit.ui.createReadOnlyTextField(fileGrid, ...
        'Value', 'No reference image loaded');
    txtReference.Layout.Row = 2;
    txtReference.Layout.Column = [1 2];
    txtMoving = labkit.ui.createReadOnlyTextField(fileGrid, ...
        'Value', 'No moving image loaded');
    txtMoving.Layout.Row = 3;
    txtMoving.Layout.Column = [1 2];

    [lblPreview, ddPreview] = labkit.ui.createLabeledDropdown(fileGrid, 'Preview:', ...
        'Items', {'Current pair', 'Current moving image', 'False-color overlay', 'Original pair', 'ROI mask'}, ...
        'Value', 'Current pair', ...
        'ValueChangedFcn', @(~,~) refreshPreview());
    lblPreview.Layout.Row = 4;
    lblPreview.Layout.Column = 1;
    ddPreview.Layout.Row = 4;
    ddPreview.Layout.Column = 2;

    actionPanel = labkit.ui.createPanelGrid(layFA, 'Registration + Crop', 2, [6 2], ...
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
    maskPanel = labkit.ui.createPanelGrid(layFA, 'Mask ROI', 3, [7 2], ...
        struct('rowHeight', {{'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'}}, ...
        'columnWidth', {{'1x', '1x'}}));
    maskGrid = maskPanel.grid;

    btnStartMask = uibutton(maskGrid, 'Text', 'Start ROI edit', ...
        'ButtonPushedFcn', @onStartMaskEdit);
    btnStartMask.Layout.Row = 1;
    btnStartMask.Layout.Column = [1 2];
    [lblBoundaryStyle, ddBoundaryStyle] = labkit.ui.createLabeledDropdown(maskGrid, 'Boundary:', ...
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

    labkit.ui.createReadOnlyTextPanel(layFA, 'Workflow Notes', 4, { ...
        '1. Load a reference image and a moving image.', ...
        '2. Align or crop the current working pair in any order; each apply step can be undone.', ...
        '3. False-color preview compares the current pair even before alignment.', ...
        '4. Draw curve or straight-line ROI boundaries, add/subtract them on the mask canvas, then save the mask.'});

    txtSummary = uitextarea(laySR, 'Editable', 'off');
    txtSummary.Layout.Row = 1;
    txtSummary.Value = {'No images loaded.'};

    txtDetails = uitextarea(laySR, 'Editable', 'off');
    txtDetails.Layout.Row = labkit.ui.layoutRow(laySR, 2);
    txtDetails.Value = {'Alignment and crop details will appear here.'};

    logUi = labkit.ui.createLogPanel(layLog, 1, {'Ready.'});
    txtLog = logUi.textArea;

    resetPreviewAxes();

    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end

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
        S.maskEditor = labkit.ui.createAnchorCurveEditor(ui.topAxes, size(S.currentReferenceImage), ...
            struct('figure', fig, ...
            'closed', true, ...
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
        ui.topAxes.ButtonDownFcn = [];
        fig.WindowButtonMotionFcn = '';
        fig.WindowButtonUpFcn = '';
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
        labkit.ui.hardResetAxis(ui.topAxes, 'Reference', true);
        labkit.ui.hardResetAxis(ui.bottomAxes, 'Current Preview', true);
    end

    function addLog(msg)
        labkit.ui.appendLog(txtLog, msg);
        debugLog.append(msg);
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

function [alignedImage, tformRigid] = alignMovingToReference(referenceImage, movingImage, fixedPoints, movingPoints)
    origClass = class(movingImage);
    [~, ~, tr] = procrustes(fixedPoints, movingPoints, ...
        'Scaling', false, 'Reflection', false);

    R = tr.T;
    t = tr.c(1, :);
    T = [R(1,1) R(1,2) 0; ...
         R(2,1) R(2,2) 0; ...
         t(1)   t(2)   1];
    tformRigid = affine2d(T);

    Rfixed = imref2d(size(referenceImage(:, :, 1)));
    alignedImage = imwarp(movingImage, tformRigid, ...
        'OutputView', Rfixed, 'FillValues', 0);
    alignedImage = cast(alignedImage, origClass);
end

function [alignedImage, tformRigid, method] = autoAlignMovingToReference(referenceImage, movingImage)
    origClass = class(movingImage);
    fixedGray = normalizeGray(referenceImage);
    movingGray = normalizeGray(movingImage);

    try
        tformRigid = imregcorr(movingGray, fixedGray, 'rigid');
        method = 'phase-correlation rigid registration';
    catch
        tformRigid = imregcorr(movingGray, fixedGray, 'translation');
        method = 'phase-correlation translation registration';
    end

    Rfixed = imref2d(size(fixedGray));
    alignedImage = imwarp(movingImage, tformRigid, ...
        'OutputView', Rfixed, 'FillValues', 0);
    alignedImage = cast(alignedImage, origClass);
end

function rect = defaultSquareRect(imageSize)
    H = imageSize(1);
    W = imageSize(2);
    side = max(1, round(0.5 * min(H, W)));
    x = round((W - side) / 2) + 1;
    y = round((H - side) / 2) + 1;
    rect = squareRectInsideImage([x y side side], imageSize);
end

function rect = squareRectInsideImage(roi, imageSize)
    x = roi(1);
    y = roi(2);
    w = roi(3);
    h = roi(4);
    side = round(max(w, h));
    side = max(side, 1);
    maxSide = max(1, min(imageSize(1), imageSize(2)) - 1);
    side = min(side, maxSide);

    cx = x + w / 2;
    cy = y + h / 2;
    xSq = round(cx - side / 2);
    ySq = round(cy - side / 2);

    maxX = max(1, imageSize(2) - side);
    maxY = max(1, imageSize(1) - side);
    xSq = min(max(1, xSq), maxX);
    ySq = min(max(1, ySq), maxY);
    rect = [xSq, ySq, side, side];
end

function mask = boundaryMaskImage(points, imageSize, boundaryStyle)
    curve = maskBoundaryCurve(points, imageSize, boundaryStyle);
    mask = maskFromCurve(curve, imageSize);
end

function mask = maskFromCurve(curve, imageSize)
    H = imageSize(1);
    W = imageSize(2);
    if isempty(curve)
        mask = uint8(false(H, W));
        return;
    end
    mask = uint8(poly2mask(curve(:, 1), curve(:, 2), H, W)) .* uint8(255);
end

function curve = maskBoundaryCurve(points, imageSize, boundaryStyle)
    if size(points, 1) < 3
        curve = [];
        return;
    end
    if strcmp(string(boundaryStyle), "Straight lines")
        curve = [points; points(1, :)];
        curve(:, 1) = min(max(curve(:, 1), 0.5), imageSize(2) + 0.5);
        curve(:, 2) = min(max(curve(:, 2), 0.5), imageSize(1) + 0.5);
        return;
    end

    n = size(points, 1);
    samplesPerSegment = max(12, ceil(240 / n));
    curve = zeros(n * samplesPerSegment + 1, 2);
    out = 1;
    for i = 1:n
        p0 = points(wrapIndex(i - 1, n), :);
        p1 = points(i, :);
        p2 = points(wrapIndex(i + 1, n), :);
        p3 = points(wrapIndex(i + 2, n), :);
        for k = 0:(samplesPerSegment - 1)
            t = k / samplesPerSegment;
            curve(out, :) = catmullRomPoint(p0, p1, p2, p3, t);
            out = out + 1;
        end
    end
    curve(out, :) = curve(1, :);
    curve = curve(1:out, :);
    curve(:, 1) = min(max(curve(:, 1), 0.5), imageSize(2) + 0.5);
    curve(:, 2) = min(max(curve(:, 2), 0.5), imageSize(1) + 0.5);
end

function p = catmullRomPoint(p0, p1, p2, p3, t)
    p = 0.5 .* ((2 .* p1) + ...
        (-p0 + p2) .* t + ...
        (2 .* p0 - 5 .* p1 + 4 .* p2 - p3) .* t.^2 + ...
        (-p0 + 3 .* p1 - 3 .* p2 + p3) .* t.^3);
end

function idx = wrapIndex(idx, n)
    idx = mod(idx - 1, n) + 1;
end

function tf = insideImageBounds(x, y, imageSize)
    tf = isfinite(x) && isfinite(y) && ...
        x >= 0.5 && y >= 0.5 && ...
        x <= imageSize(2) + 0.5 && y <= imageSize(1) + 0.5;
end

function rgb = maskRgb(maskImage)
    rgb = repmat(maskImage, [1 1 3]);
end

function lines = cropSelectionSummary(rect)
    lines = { ...
        sprintf('Active crop source: current reference and current moving images'), ...
        sprintf('Move or resize the ROI on the current reference preview, then click Apply ROI crop.'), ...
        sprintf('Current square ROI: x=%d, y=%d, size=%d px', ...
        round(rect(1)), round(rect(2)), round(rect(3)))};
end

function hImage = showImage(ax, imageData, titleText)
    hImage = labkit.ui.showImageAxes(ax, imageData, titleText);
end

function imageSize = axesImageSize(ax)
    imageSize = [];
    images = findobj(ax, 'Type', 'Image');
    if isempty(images)
        return;
    end
    data = images(1).CData;
    imageSize = size(data);
end

function zoomAxesAtPoint(ax, x, y, scrollCount, imageSize)
    if scrollCount == 0
        return;
    end

    fullX = [0.5, imageSize(2) + 0.5];
    fullY = [0.5, imageSize(1) + 0.5];
    zoomFactor = 1.20 ^ scrollCount;

    currentX = ax.XLim;
    currentY = ax.YLim;
    newWidth = diff(currentX) * zoomFactor;
    newHeight = diff(currentY) * zoomFactor;

    minSpan = 10;
    newWidth = min(max(newWidth, minSpan), diff(fullX));
    newHeight = min(max(newHeight, minSpan), diff(fullY));

    xFrac = (x - currentX(1)) / max(eps, diff(currentX));
    yFrac = (y - currentY(1)) / max(eps, diff(currentY));
    xFrac = min(max(xFrac, 0), 1);
    yFrac = min(max(yFrac, 0), 1);

    newX = [x - xFrac * newWidth, x + (1 - xFrac) * newWidth];
    newY = [y - yFrac * newHeight, y + (1 - yFrac) * newHeight];

    ax.XLim = clampLimits(newX, fullX);
    ax.YLim = clampLimits(newY, fullY);
end

function limits = clampLimits(limits, fullLimits)
    span = diff(limits);
    fullSpan = diff(fullLimits);
    if span >= fullSpan
        limits = fullLimits;
        return;
    end
    if limits(1) < fullLimits(1)
        limits = [fullLimits(1), fullLimits(1) + span];
    end
    if limits(2) > fullLimits(2)
        limits = [fullLimits(2) - span, fullLimits(2)];
    end
end

function overlay = makeFalseColorOverlay(referenceImage, alignedImage)
    refGray = normalizeGray(referenceImage);
    movGray = normalizeGray(alignedImage);
    if ~isequal(size(refGray), size(movGray))
        movGray = imresize(movGray, size(refGray), 'nearest');
    end
    overlay = zeros([size(refGray), 3]);
    overlay(:, :, 1) = movGray;
    overlay(:, :, 2) = refGray;
end

function gray = normalizeGray(imageData)
    if ndims(imageData) == 3
        gray = rgb2gray(imageData);
    else
        gray = imageData;
    end
    gray = im2double(gray);
    values = gray(:);
    values = values(~isnan(values));
    if isempty(values)
        return;
    end
    mn = min(values);
    mx = max(values);
    if isfinite(mn) && isfinite(mx) && mx > mn
        gray = (gray - mn) ./ (mx - mn);
    end
end

function lines = transformSummary(tform, referenceSize, movingSize)
    T = transformMatrix(tform);
    lines = { ...
        sprintf('Reference size: %d x %d', referenceSize(1), referenceSize(2)), ...
        sprintf('Moving size: %d x %d', movingSize(1), movingSize(2)), ...
        'Rigid transform matrix:', ...
        sprintf('[%.6g %.6g %.6g]', T(1, 1), T(1, 2), T(1, 3)), ...
        sprintf('[%.6g %.6g %.6g]', T(2, 1), T(2, 2), T(2, 3)), ...
        sprintf('[%.6g %.6g %.6g]', T(3, 1), T(3, 2), T(3, 3))};
end

function T = transformMatrix(tform)
    if isprop(tform, 'T')
        T = tform.T;
    elseif isprop(tform, 'A')
        T = tform.A;
    else
        T = eye(3);
    end
end

function lines = cropSummary(rect)
    lines = { ...
        sprintf('Crop source: current reference and current moving images'), ...
        sprintf('Crop rectangle: x=%g, y=%g, width=%g, height=%g', ...
        rect(1), rect(2), rect(3), rect(4))};
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

function deleteIfValid(h)
    if isempty(h)
        return;
    end
    if isvalid(h)
        delete(h);
    end
end
