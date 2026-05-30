function varargout = labkit_DICPreprocess_app(varargin)
%LABKIT_DICPREPROCESS_APP Image registration and paired-crop app for DIC workflows.

    if nargin > 0
        error('labkit_DICPreprocess_app:UnsupportedInput', ...
            'labkit_DICPreprocess_app does not accept input arguments.');
    end
    if nargout > 1
        error('labkit_DICPreprocess_app:TooManyOutputs', ...
            'labkit_DICPreprocess_app returns at most the app figure handle.');
    end

    S = struct();
    S.referencePath = "";
    S.movingPath = "";
    S.referenceImage = [];
    S.movingImage = [];
    S.alignedImage = [];
    S.cropReference = [];
    S.cropMoving = [];
    S.cropRect = [];
    S.cropRoiTop = [];
    S.cropRoiBottom = [];
    S.cropRoiListeners = {};
    S.cropSourceLabel = "";
    S.maskImage = [];
    S.maskPoints = [];
    S.maskLine = [];

    workbenchOpts = struct('rightKind', 'dualPlot', ...
        'rightTitle', 'Image Preview', ...
        'topPlotTitle', 'Reference', ...
        'bottomPlotTitle', 'Current Preview', ...
        'showPlotControls', false);
    ui = labkit.ui.createWorkbench( ...
        'DIC Image Preprocess', [80 60 1400 860], 370, workbenchOpts);
    fig = ui.fig;

    layFA = ui.filesAnalysisGrid;
    laySR = ui.summaryResultsGrid;
    layLog = ui.logGrid;
    layFA.RowHeight = {260, 6, 240, 6, 120};
    laySR.RowHeight = {150, 6, '1x'};

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

    txtReference = uieditfield(fileGrid, 'text', 'Editable', 'off', ...
        'Value', 'No reference image loaded');
    txtReference.Layout.Row = 2;
    txtReference.Layout.Column = [1 2];
    txtMoving = uieditfield(fileGrid, 'text', 'Editable', 'off', ...
        'Value', 'No moving image loaded');
    txtMoving.Layout.Row = 3;
    txtMoving.Layout.Column = [1 2];

    [lblPreview, ddPreview] = labkit.ui.createLabeledDropdown(fileGrid, 'Preview:', ...
        'Items', {'Moving image', 'Aligned image', 'False-color overlay', 'Crop pair', 'ROI mask'}, ...
        'Value', 'Moving image', ...
        'ValueChangedFcn', @(~,~) refreshPreview());
    lblPreview.Layout.Row = 4;
    lblPreview.Layout.Column = 1;
    ddPreview.Layout.Row = 4;
    ddPreview.Layout.Column = 2;

    actionPanel = labkit.ui.createPanelGrid(layFA, 'Registration + Crop', 3, [8 2], ...
        struct('rowHeight', {{'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'}}, ...
        'columnWidth', {{'1x', '1x'}}));
    actionGrid = actionPanel.grid;

    btnAlign = uibutton(actionGrid, 'Text', 'Select points + align', ...
        'ButtonPushedFcn', @onAlign);
    btnAlign.Layout.Row = 1;
    btnAlign.Layout.Column = [1 2];
    btnSaveAligned = uibutton(actionGrid, 'Text', 'Save aligned image', ...
        'ButtonPushedFcn', @onSaveAligned);
    btnSaveAligned.Layout.Row = 2;
    btnSaveAligned.Layout.Column = [1 2];
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
    btnSaveCrops = uibutton(actionGrid, 'Text', 'Save crop images', ...
        'ButtonPushedFcn', @onSaveCrops);
    btnSaveCrops.Layout.Row = 5;
    btnSaveCrops.Layout.Column = [1 2];
    btnDrawMask = uibutton(actionGrid, 'Text', 'Draw mask ROI', ...
        'ButtonPushedFcn', @onDrawMaskRoi);
    btnDrawMask.Layout.Row = 6;
    btnDrawMask.Layout.Column = 1;
    btnFinishMask = uibutton(actionGrid, 'Text', 'Finish mask ROI', ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @onFinishMaskRoi);
    btnFinishMask.Layout.Row = 6;
    btnFinishMask.Layout.Column = 2;
    btnSaveMask = uibutton(actionGrid, 'Text', 'Save ROI mask', ...
        'ButtonPushedFcn', @onSaveMask);
    btnSaveMask.Layout.Row = 7;
    btnSaveMask.Layout.Column = [1 2];

    notePanel = labkit.ui.createPanelGrid(layFA, 'Workflow Notes', 5, [1 1], ...
        struct('rowHeight', {{'1x'}}, 'columnWidth', {{'1x'}}));
    txtNotes = uitextarea(notePanel.grid, 'Editable', 'off');
    txtNotes.Value = { ...
        '1. Load a reference image and a moving image.', ...
        '2. Use point selection to rigidly align the moving image to the reference image.', ...
        '3. Start a square crop ROI on the right preview, adjust it, then apply the crop.', ...
        '4. Draw a mask ROI by clicking boundary points, finish it, then save a white-inside / black-outside mask.'};

    txtSummary = uitextarea(laySR, 'Editable', 'off');
    txtSummary.Layout.Row = 1;
    txtSummary.Value = {'No images loaded.'};

    txtDetails = uitextarea(laySR, 'Editable', 'off');
    txtDetails.Layout.Row = 3;
    txtDetails.Value = {'Alignment and crop details will appear here.'};

    labkit.ui.addRowResizeHandle(fig, layFA, 2, ...
        struct('minTopHeight', 150, 'minBottomHeight', 120));
    labkit.ui.addRowResizeHandle(fig, layFA, 4, ...
        struct('minTopHeight', 120, 'minBottomHeight', 90));
    labkit.ui.addRowResizeHandle(fig, laySR, 2, ...
        struct('minTopHeight', 90, 'minBottomHeight', 90));

    logUi = labkit.ui.createLogPanel(layLog, 1, {'Ready.'});
    txtLog = logUi.textArea;

    resetPreviewAxes();

    if nargout == 1
        varargout{1} = fig;
    end

    function onOpenReference(~, ~)
        filepath = chooseImageFile('Select reference image');
        if filepath == ""
            addLog('Reference image selection cancelled.');
            return;
        end
        S.referencePath = filepath;
        S.referenceImage = imread(filepath);
        S.alignedImage = [];
        S.cropReference = [];
        S.cropMoving = [];
        S.maskImage = [];
        txtReference.Value = char(filepath);
        addLog(sprintf('Loaded reference image: %s', filepath));
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
        S.alignedImage = [];
        S.cropMoving = [];
        txtMoving.Value = char(filepath);
        addLog(sprintf('Loaded moving image: %s', filepath));
        refreshPreview();
    end

    function onAlign(~, ~)
        if ~hasImagePair()
            uialert(fig, 'Load both reference and moving images before alignment.', 'Missing images');
            return;
        end

        addLog('Opening point selector. Choose matching points, then accept.');
        [movingPoints, fixedPoints] = cpselect(S.movingImage, S.referenceImage, 'Wait', true);
        if size(movingPoints, 1) < 2
            uialert(fig, 'Rigid registration requires at least two point pairs.', 'Not enough points');
            addLog('Alignment cancelled: fewer than two point pairs.');
            return;
        end

        [S.alignedImage, tform] = alignMovingToReference( ...
            S.referenceImage, S.movingImage, fixedPoints, movingPoints);
        ddPreview.Value = 'False-color overlay';
        addLog(sprintf('Aligned image using %d point pair(s).', size(movingPoints, 1)));
        txtDetails.Value = transformSummary(tform, size(S.referenceImage), size(S.movingImage));
        refreshPreview();
    end

    function onSaveAligned(~, ~)
        if isempty(S.alignedImage)
            uialert(fig, 'No aligned image is available. Run alignment first.', 'Save aligned image');
            return;
        end

        [folder, name, ext] = fileparts(char(S.movingPath));
        defaultName = [name '_aligned' ext];
        [f, p] = uiputfile({'*.png;*.jpg;*.jpeg;*.tif;*.tiff', 'Images'}, ...
            'Save aligned image', fullfile(folder, defaultName));
        if isequal(f, 0)
            addLog('Save aligned image cancelled.');
            return;
        end

        out = fullfile(p, f);
        imwrite(S.alignedImage, out);
        addLog(sprintf('Saved aligned image: %s', out));
    end

    function onStartCropRoi(~, ~)
        if ~hasImagePair()
            uialert(fig, 'Load both reference and moving images before cropping.', 'Missing images');
            return;
        end

        [currentImage, currentLabel] = currentCropImage();
        clearCropRoi();
        clearMaskRoi();
        resetPreviewAxes();
        showImage(ui.topAxes, S.referenceImage, 'Reference image');
        showImage(ui.bottomAxes, currentImage, sprintf('%s image', capitalizeText(currentLabel)));

        S.cropReference = [];
        S.cropMoving = [];
        S.cropSourceLabel = currentLabel;
        rect = defaultSquareRect(size(S.referenceImage));
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
        txtDetails.Value = cropSelectionSummary(rect, currentLabel);
        addLog(sprintf('Started crop ROI on the preview using the %s image.', currentLabel));
        refreshSummary();
    end

    function onApplyCropRoi(~, ~)
        if isempty(S.cropRoiTop) || ~isvalid(S.cropRoiTop)
            uialert(fig, 'Start a crop ROI before applying the crop.', 'No active ROI');
            return;
        end

        [currentImage, currentLabel] = currentCropImage();
        rect = squareRectInsideImage(S.cropRoiTop.Position, size(S.referenceImage));
        S.cropRect = rect;
        S.cropReference = imcrop(S.referenceImage, rect);
        S.cropMoving = imcrop(currentImage, rect);
        S.cropSourceLabel = currentLabel;
        clearCropRoi();
        ddPreview.Value = 'Crop pair';
        showCropPair();
        addLog(sprintf('Cropped reference and %s image with [%g %g %g %g].', ...
            currentLabel, rect(1), rect(2), rect(3), rect(4)));
        txtDetails.Value = cropSummary(rect, currentLabel);
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
        rect = squareRectInsideImage(pos, size(S.referenceImage));
        S.cropRect = rect;
        if ~isempty(S.cropRoiBottom) && isvalid(S.cropRoiBottom)
            S.cropRoiBottom.Position = rect;
        end
        txtDetails.Value = cropSelectionSummary(rect, S.cropSourceLabel);
    end

    function onSaveCrops(~, ~)
        if isempty(S.cropReference) || isempty(S.cropMoving)
            uialert(fig, 'No crop images are available. Draw a crop first.', 'Save crops');
            return;
        end

        folder = uigetdir(pwd, 'Select folder for crop images');
        if isequal(folder, 0)
            addLog('Save crop images cancelled.');
            return;
        end

        refOut = fullfile(folder, 'crop_reference.png');
        curOut = fullfile(folder, 'crop_current.png');
        imwrite(S.cropReference, refOut);
        imwrite(S.cropMoving, curOut);
        addLog(sprintf('Saved crop images: %s and %s', refOut, curOut));
    end

    function onDrawMaskRoi(~, ~)
        if isempty(S.referenceImage)
            uialert(fig, 'Load a reference image before drawing an ROI mask.', 'Missing image');
            return;
        end

        clearCropRoi();
        clearMaskRoi();
        resetPreviewAxes();
        showImage(ui.topAxes, S.referenceImage, 'Reference image');
        showImage(ui.bottomAxes, zeros(size(S.referenceImage, 1), size(S.referenceImage, 2), 3, 'uint8'), 'ROI mask preview');
        S.maskImage = [];
        S.maskPoints = [];
        S.maskLine = line(ui.topAxes, NaN, NaN, ...
            'Color', [0 0.45 0.95], ...
            'LineWidth', 1.5, ...
            'Marker', 'o', ...
            'MarkerFaceColor', [0 0.45 0.95], ...
            'HitTest', 'off');
        ui.topAxes.ButtonDownFcn = @onMaskPointClicked;
        btnFinishMask.Enable = 'on';
        addLog('Started point-by-point mask ROI. Click boundary points, then Finish mask ROI.');
        txtDetails.Value = {'Click boundary points on the reference preview. Use at least 3 points, then click Finish mask ROI.'};
    end

    function onMaskPointClicked(~, ~)
        point = ui.topAxes.CurrentPoint;
        x = point(1, 1);
        y = point(1, 2);
        if ~insideImageBounds(x, y, size(S.referenceImage))
            return;
        end
        S.maskPoints(end+1, :) = [x y];
        updateMaskLine();
        txtDetails.Value = {sprintf('Mask ROI points: %d. Finish requires at least 3 points.', size(S.maskPoints, 1))};
    end

    function updateMaskLine()
        if isempty(S.maskLine) || ~isvalid(S.maskLine)
            return;
        end
        points = S.maskPoints;
        if size(points, 1) >= 3
            points = [points; points(1, :)];
        end
        S.maskLine.XData = points(:, 1);
        S.maskLine.YData = points(:, 2);
    end

    function onFinishMaskRoi(~, ~)
        if size(S.maskPoints, 1) < 3
            uialert(fig, 'Mask ROI needs at least three boundary points.', 'Not enough points');
            return;
        end
        S.maskImage = freehandMaskImage(S.maskPoints, size(S.referenceImage));
        ui.topAxes.ButtonDownFcn = [];
        btnFinishMask.Enable = 'off';
        ddPreview.Value = 'ROI mask';
        showImage(ui.bottomAxes, maskRgb(S.maskImage), 'ROI mask');
        addLog(sprintf('Finished ROI mask with %d boundary points.', size(S.maskPoints, 1)));
        txtDetails.Value = {'ROI mask ready. The bottom preview shows white inside and black outside.'};
        refreshSummary();
    end

    function onSaveMask(~, ~)
        if isempty(S.maskImage)
            uialert(fig, 'Draw a mask ROI before saving the binary mask.', 'Save ROI mask');
            return;
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

    function refreshPreview()
        clearCropRoi();
        clearMaskRoi();
        resetPreviewAxes();
        if strcmp(ddPreview.Value, 'Crop pair')
            showCropPair();
            refreshSummary();
            return;
        elseif strcmp(ddPreview.Value, 'ROI mask')
            if ~isempty(S.referenceImage)
                showImage(ui.topAxes, S.referenceImage, 'Reference image');
            end
            if ~isempty(S.maskImage)
                showImage(ui.bottomAxes, maskRgb(S.maskImage), 'ROI mask');
            end
            refreshSummary();
            return;
        elseif ~isempty(S.referenceImage)
            showImage(ui.topAxes, S.referenceImage, 'Reference image');
        end

        previewImage = [];
        previewTitle = ddPreview.Value;
        switch ddPreview.Value
            case 'Moving image'
                previewImage = S.movingImage;
            case 'Aligned image'
                previewImage = S.alignedImage;
            case 'False-color overlay'
                if ~isempty(S.referenceImage) && ~isempty(S.alignedImage)
                    previewImage = makeFalseColorOverlay(S.referenceImage, S.alignedImage);
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
        lines{end+1} = sprintf('Aligned image: %s', ternary(~isempty(S.alignedImage), 'available', 'not generated'));
        lines{end+1} = sprintf('Crop images: %s', ternary(~isempty(S.cropReference), 'available', 'not generated'));
        lines{end+1} = sprintf('ROI mask: %s', ternary(~isempty(S.maskImage), 'available', 'not drawn'));
        txtSummary.Value = lines;
    end

    function tf = hasImagePair()
        tf = ~isempty(S.referenceImage) && ~isempty(S.movingImage);
    end

    function [currentImage, currentLabel] = currentCropImage()
        if ~isempty(S.alignedImage)
            currentImage = S.alignedImage;
            currentLabel = 'aligned';
        else
            currentImage = S.movingImage;
            currentLabel = 'moving';
        end
    end

    function showCropPair()
        resetPreviewAxes();
        if ~isempty(S.cropReference)
            showImage(ui.topAxes, S.cropReference, 'Reference crop');
        end
        if ~isempty(S.cropMoving)
            label = char(S.cropSourceLabel);
            if strlength(S.cropSourceLabel) == 0
                label = 'current';
            end
            showImage(ui.bottomAxes, S.cropMoving, sprintf('%s crop', capitalizeText(label)));
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
        deleteIfValid(S.maskLine);
        S.maskLine = [];
        S.maskPoints = [];
        btnFinishMask.Enable = 'off';
    end

    function resetPreviewAxes()
        labkit.ui.hardResetAxis(ui.topAxes, 'Reference', true);
        labkit.ui.hardResetAxis(ui.bottomAxes, 'Current Preview', true);
    end

    function addLog(msg)
        labkit.ui.appendLog(txtLog, msg);
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

function mask = freehandMaskImage(points, imageSize)
    H = imageSize(1);
    W = imageSize(2);
    if size(points, 1) < 3
        mask = uint8(false(H, W));
        return;
    end
    mask = uint8(poly2mask(points(:, 1), points(:, 2), H, W)) .* uint8(255);
end

function tf = insideImageBounds(x, y, imageSize)
    tf = isfinite(x) && isfinite(y) && ...
        x >= 0.5 && y >= 0.5 && ...
        x <= imageSize(2) + 0.5 && y <= imageSize(1) + 0.5;
end

function rgb = maskRgb(maskImage)
    rgb = repmat(maskImage, [1 1 3]);
end

function lines = cropSelectionSummary(rect, sourceLabel)
    lines = { ...
        sprintf('Active crop source: reference and %s image', sourceLabel), ...
        sprintf('Move or resize the ROI on the reference preview, then click Apply ROI crop.'), ...
        sprintf('Current square ROI: x=%d, y=%d, size=%d px', ...
        round(rect(1)), round(rect(2)), round(rect(3)))};
end

function showImage(ax, imageData, titleText)
    cla(ax);
    hImage = image(ax, imageData);
    hImage.HitTest = 'off';
    axis(ax, 'image');
    ax.XLim = [0.5, size(imageData, 2) + 0.5];
    ax.YLim = [0.5, size(imageData, 1) + 0.5];
    ax.YDir = 'reverse';
    ax.XTick = [];
    ax.YTick = [];
    title(ax, titleText);
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
    T = tform.T;
    lines = { ...
        sprintf('Reference size: %d x %d', referenceSize(1), referenceSize(2)), ...
        sprintf('Moving size: %d x %d', movingSize(1), movingSize(2)), ...
        'Rigid transform matrix:', ...
        sprintf('[%.6g %.6g %.6g]', T(1, 1), T(1, 2), T(1, 3)), ...
        sprintf('[%.6g %.6g %.6g]', T(2, 1), T(2, 2), T(2, 3)), ...
        sprintf('[%.6g %.6g %.6g]', T(3, 1), T(3, 2), T(3, 3))};
end

function lines = cropSummary(rect, sourceLabel)
    lines = { ...
        sprintf('Crop source: reference and %s image', sourceLabel), ...
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

function txt = capitalizeText(txt)
    txt = char(txt);
    if isempty(txt)
        return;
    end
    txt(1) = upper(txt(1));
end

function deleteIfValid(h)
    if isempty(h)
        return;
    end
    if isvalid(h)
        delete(h);
    end
end
