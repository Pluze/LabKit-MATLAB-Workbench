function varargout = labkit_CurvatureMeasurement_app(varargin)
%LABKIT_CURVATUREMEASUREMENT_APP Measure curve radius and curvature from images.

    [requestHandled, requestOutputs, debugLog] = labkit.ui.handleAppRequest( ...
        'labkit_CurvatureMeasurement_app', varargin, nargout, curvatureAppTestHandlers());
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_CurvatureMeasurement_app:TooManyOutputs', ...
                'labkit_CurvatureMeasurement_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_CurvatureMeasurement_app:TooManyOutputs', ...
            'labkit_CurvatureMeasurement_app returns at most the app figure handle.');
    end

    S = struct();
    S.imagePath = "";
    S.image = [];
    S.xPix = [];
    S.yPix = [];
    S.curveEditor = [];
    S.curveEditActive = false;
    S.fit = emptyFitResult();
    S.length = emptyLengthResult();

    workbenchOpts = struct( ...
        'rightTitle', 'Measurement Preview', ...
        'rightGridSize', [1 1], ...
        'rightRowHeight', {{'1x'}});
    workbenchOpts.tabs = [ ...
        labkit.ui.tabSpec('filesAnalysis', 'Files + Analysis', [5 1], ...
            {140, 105, 355, 225, 160}, ...
            struct('resizeRows', [1 2 3 4], ...
            'resizeOptions', struct('minTopHeight', 140, 'minBottomHeight', 90))), ...
        labkit.ui.tabSpec('summaryResults', 'Summary + Results', [2 1], ...
            {170, '1x'}, ...
            struct('resizeRows', 1)), ...
        labkit.ui.tabSpec('log', 'Log', [1 1], {'1x'})];

    ui = labkit.ui.createWorkbench( ...
        'Image Curvature Measurement', [90 70 1420 860], 390, workbenchOpts);
    fig = ui.fig;
    layFA = ui.filesAnalysisGrid;
    laySR = ui.summaryResultsGrid;
    layLog = ui.logGrid;
    ui.topAxes = uiaxes(ui.rightGrid);
    ui.topAxes.Layout.Row = 1;
    imageRuntime = labkit.ui.createImageAxesRuntime(ui.topAxes, ...
        struct('figure', fig, ...
        'defaultScrollFcn', @onPreviewScroll, ...
        'onTrace', debugLog.trace));

    imagePanel = labkit.ui.createPanelGrid(layFA, 'Image', 1, [3 2], ...
        struct('rowHeight', {{'fit', 'fit', 'fit'}}, ...
        'columnWidth', {{145, '1x'}}));
    imageGrid = imagePanel.grid;

    btnOpenImage = uibutton(imageGrid, 'Text', 'Open image', ...
        'ButtonPushedFcn', @onOpenImage);
    btnOpenImage.Layout.Row = 1;
    btnOpenImage.Layout.Column = [1 2];

    txtImage = labkit.ui.createReadOnlyTextField(imageGrid, ...
        'Value', 'No image loaded');
    txtImage.Layout.Row = 2;
    txtImage.Layout.Column = [1 2];

    txtPointCount = labkit.ui.createReadOnlyTextField(imageGrid, ...
        'Value', 'Points: 0');
    txtPointCount.Layout.Row = 3;
    txtPointCount.Layout.Column = [1 2];

    editPanel = labkit.ui.createPanelGrid(layFA, 'Curve Editing', 2, [2 2], ...
        struct('rowHeight', {{'fit', 'fit'}}, ...
        'columnWidth', {{145, '1x'}}));
    editGrid = editPanel.grid;

    btnStartCurve = uibutton(editGrid, 'Text', 'Start curve edit', ...
        'ButtonPushedFcn', @onStartCurveEdit);
    btnStartCurve.Layout.Row = 1;
    btnStartCurve.Layout.Column = [1 2];

    btnUndoPoint = uibutton(editGrid, 'Text', 'Undo last point', ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @onUndoCurvePoint);
    btnUndoPoint.Layout.Row = 2;
    btnUndoPoint.Layout.Column = 1;
    btnClearCurve = uibutton(editGrid, 'Text', 'Clear curve', ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @onClearCurve);
    btnClearCurve.Layout.Row = 2;
    btnClearCurve.Layout.Column = 2;

    scaleTool = labkit.ui.createScaleBarTool(layFA, 3, imageRuntime, ...
        struct('onBeforeReferenceEdit', @onBeforeReferenceEdit, ...
        'onReferenceEditChanged', @onReferenceEditChanged, ...
        'onCalibrationChanged', @onCalibrationSettingsChanged, ...
        'onScaleBarChanged', @onScaleBarSettingsChanged, ...
        'onScaleBarPlaced', @onScaleBarPlaced, ...
        'onError', @onScaleToolError, ...
        'onTrace', debugLog.trace));

    fitPanel = labkit.ui.createPanelGrid(layFA, 'Fit + Export', 4, [7 2], ...
        struct('rowHeight', {{'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'}}, ...
        'columnWidth', {{145, '1x'}}));
    fitGrid = fitPanel.grid;

    chkDensify = uicheckbox(fitGrid, 'Text', 'Densify before circle fit', 'Value', true);
    chkDensify.Layout.Row = 1;
    chkDensify.Layout.Column = [1 2];

    [lblDenseN, edtDenseN] = labkit.ui.createLabeledSpinner(fitGrid, ...
        'Dense point count:', 'Value', 300, 'Limits', [3 Inf], 'Step', 25);
    lblDenseN.Layout.Row = 2;
    lblDenseN.Layout.Column = 1;
    edtDenseN.Layout.Row = 2;
    edtDenseN.Layout.Column = 2;

    chkShowDense = uicheckbox(fitGrid, 'Text', 'Show dense fit points', ...
        'Value', true, ...
        'ValueChangedFcn', @(~,~) refreshImageOverlay());
    chkShowDense.Layout.Row = 3;
    chkShowDense.Layout.Column = [1 2];

    btnFit = uibutton(fitGrid, 'Text', 'Fit circle + curvature', ...
        'ButtonPushedFcn', @onFitCurvature);
    btnFit.Layout.Row = 4;
    btnFit.Layout.Column = [1 2];

    btnMeasureLength = uibutton(fitGrid, 'Text', 'Measure curve length', ...
        'ButtonPushedFcn', @onMeasureCurveLength);
    btnMeasureLength.Layout.Row = 5;
    btnMeasureLength.Layout.Column = [1 2];

    btnExportCSV = uibutton(fitGrid, 'Text', 'Export result CSV', ...
        'ButtonPushedFcn', @onExportCSV);
    btnExportCSV.Layout.Row = 6;
    btnExportCSV.Layout.Column = [1 2];
    btnExportOverlay = uibutton(fitGrid, 'Text', 'Export overlay PNG', ...
        'ButtonPushedFcn', @onExportOverlay);
    btnExportOverlay.Layout.Row = 7;
    btnExportOverlay.Layout.Column = [1 2];

    labkit.ui.createReadOnlyTextPanel(layFA, 'Workflow Notes', 5, { ...
        '1. Open an image and start curve editing.', ...
        '2. Double-click blank image space to add/insert points; drag points to move; double-click a point to delete it.', ...
        '3. Calibrate with measured or typed reference pixels, a real reference length, and a unit.', ...
        '4. Place the final scale bar, then fit curvature or measure curve length.'});

    resultTable = uitable(laySR, ...
        'ColumnName', {'Metric', 'Value'}, ...
        'Data', initialResultTable());
    resultTable.Layout.Row = 1;

    txtDetails = uitextarea(laySR, 'Editable', 'off');
    txtDetails.Layout.Row = labkit.ui.layoutRow(laySR, 2);
    txtDetails.Value = {'No curvature result yet.'};

    logUi = labkit.ui.createLogPanel(layLog, 1, {'Ready.'});
    txtLog = logUi.textArea;

    if debugLog.enabled
        debugLog.attachTextLog(txtLog);
        debugLog.trace('Curvature measurement debug trace enabled.');
    end

    resetAxes();
    refreshScaleReadout();

    if debugLog.enabled
        debugLog.instrumentFigure(fig);
    end

    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end

    function onOpenImage(~, ~)
        [fn, fp] = uigetfile( ...
            {'*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp', 'Image files'}, ...
            'Select image');
        if isequal(fn, 0)
            addLog('Image selection cancelled.');
            return;
        end

        filepath = string(fullfile(fp, fn));
        try
            img = imread(filepath);
        catch ME
            showError('Could not read image', ME.message);
            return;
        end

        S.imagePath = filepath;
        S.image = img;
        S.xPix = [];
        S.yPix = [];
        scaleTool.resetForNewImage(size(S.image));
        S.curveEditActive = false;
        if ~isempty(S.curveEditor)
            S.curveEditor.delete();
        end
        S.curveEditor = [];
        S.fit = emptyFitResult();
        S.length = emptyLengthResult();
        txtImage.Value = char(filepath);
        addLog(sprintf('Loaded image: %s', filepath));
        refreshAll();
    end

    function onStartCurveEdit(~, ~)
        if isempty(S.image)
            showError('No image loaded', 'Open an image before editing curve points.');
            return;
        end

        if S.curveEditActive
            S.curveEditActive = false;
            if ~isempty(S.curveEditor)
                S.curveEditor.setActive(false);
            end
            addLog('Finished curve edit.');
            refreshAll();
            return;
        end

        scaleTool.finishReferenceEdit(false);
        S.curveEditActive = true;
        ensureCurveEditor();
        S.curveEditor.start([S.xPix(:), S.yPix(:)]);
        S.fit = emptyFitResult();
        addLog('Started curve edit. Double-click blank image space to add/insert points; drag points to move; double-click a point to delete it.');
        refreshAll();
    end

    function onCurveEditorChanged(points, reason)
        S.xPix = points(:, 1);
        S.yPix = points(:, 2);
        S.fit = emptyFitResult();
        S.length = emptyLengthResult();
        refreshSummary();
        if any(strcmp(reason, {'add point', 'delete point', 'move point'}))
            addLog(sprintf('Curve edit updated: %d point(s).', numel(S.xPix)));
        end
    end

    function onUndoCurvePoint(~, ~)
        if ~isempty(S.curveEditor)
            S.curveEditor.undoLast();
        end
    end

    function onClearCurve(~, ~)
        if ~isempty(S.curveEditor)
            S.curveEditor.clearPoints();
        else
            S.xPix = [];
            S.yPix = [];
            S.fit = emptyFitResult();
            S.length = emptyLengthResult();
            refreshAll();
        end
        addLog('Cleared curve points.');
    end

    function onBeforeReferenceEdit(~, ~)
        S.curveEditActive = false;
        if ~isempty(S.curveEditor)
            S.curveEditor.setActive(false);
        end
    end

    function onReferenceEditChanged(~, reason)
        S.fit = emptyFitResult();
        S.length = emptyLengthResult();
        reasonText = char(string(reason));
        if strcmp(reasonText, 'start')
            addLog('Started reference-pixel edit. Double-click two endpoints, then drag endpoints to refine.');
        elseif strcmp(reasonText, 'finish')
            addLog('Finished reference-pixel edit.');
        end
        refreshScaleReadout();
        refreshSummary();
    end

    function onScaleBarPlaced(~, ~)
        scaleBar = scaleTool.placedScaleBar();
        cal = scaleTool.calibration();
        addLog(sprintf('Placed scale bar: %.6g %s (%.6g px).', ...
            scaleBar.barLength, cal.unit, scaleBar.barLength * cal.pixelsPerUnit));
        refreshAll();
    end

    function onScaleToolError(titleText, message)
        showError(titleText, message);
    end

    function onFitCurvature(~, ~)
        if numel(S.xPix) < 3
            showError('Not enough points', 'At least 3 curve points are required to fit curvature.');
            return;
        end

        try
            fitPath = currentCurveFitPoints();
            S.fit = computeCurvatureFit(S.xPix, S.yPix, scaleTool.calibration(), ...
                chkDensify.Value, round(edtDenseN.Value), ...
                fitPath(:, 1), fitPath(:, 2));
            S.length = lengthResultFromFit(S.fit);
        catch ME
            showError('Circle fit failed', ME.message);
            return;
        end

        if S.fit.ok
            addLog(sprintf('Fit complete: R = %.6g %s, curvature = %.6g %s.', ...
                S.fit.R_show, S.fit.unitLen, S.fit.kappa_show, S.fit.unitK));
        else
            addLog(sprintf('Fit failed: %s', S.fit.message));
        end
        refreshAll();
    end

    function onMeasureCurveLength(~, ~)
        if numel(S.xPix) < 2
            showError('Not enough points', 'At least 2 curve points are required to measure curve length.');
            return;
        end

        points = currentCurveLengthPoints();
        try
            S.length = computeCurveLength(points(:, 1), points(:, 2), ...
                scaleTool.calibration());
        catch ME
            showError('Curve length failed', ME.message);
            return;
        end
        addLog(sprintf('Curve length measured: %.6g %s.', ...
            S.length.length_show, S.length.unitLen));
        refreshAll();
    end

    function onExportCSV(~, ~)
        if ~S.fit.ok && ~S.length.ok
            showError('No measurement result', ...
                'Fit curvature or measure curve length before exporting a result CSV.');
            return;
        end

        [fn, fp] = uiputfile('*.csv', 'Export curvature result CSV', ...
            'curvature_result.csv');
        if isequal(fn, 0)
            addLog('Export result CSV cancelled.');
            return;
        end

        filepath = string(fullfile(fp, fn));
        try
            T = buildCurvatureResultTable(S.fit, S.imagePath, S.length);
            writetable(T, filepath);
        catch ME
            showError('Could not export result CSV', ME.message);
            return;
        end
        addLog(sprintf('Exported result CSV: %s', filepath));
    end

    function onExportOverlay(~, ~)
        if isempty(S.image)
            showError('No image loaded', 'Open an image before exporting an overlay.');
            return;
        end

        [fn, fp] = uiputfile('*.png', 'Export overlay PNG', 'curvature_overlay.png');
        if isequal(fn, 0)
            addLog('Export overlay PNG cancelled.');
            return;
        end

        filepath = string(fullfile(fp, fn));
        try
            refreshImageOverlay();
            exportgraphics(ui.topAxes, filepath, 'Resolution', 300);
        catch ME
            showError('Could not export overlay PNG', ME.message);
            return;
        end
        addLog(sprintf('Exported overlay PNG: %s', filepath));
    end

    function refreshAll()
        refreshScaleReadout();
        refreshImageOverlay();
        refreshSummary();
    end

    function ensureCurveEditor()
        if isempty(S.image)
            return;
        end
        if isempty(S.curveEditor)
            S.curveEditor = labkit.ui.createAnchorCurveEditor(imageRuntime, size(S.image), ...
                struct('closed', false, ...
                'style', 'Curve', ...
                'onTrace', debugLog.trace, ...
                'onChanged', @onCurveEditorChanged));
        else
            S.curveEditor.setImageSize(size(S.image));
            S.curveEditor.setStyle('Curve');
        end
    end

    function onCalibrationSettingsChanged(~, reason)
        S.fit = emptyFitResult();
        S.length = emptyLengthResult();
        scaleTool.clearScaleBar();
        if isReferenceEditReason(reason)
            refreshScaleReadout();
            refreshSummary();
        else
            refreshAll();
        end
    end

    function onScaleBarSettingsChanged(~, ~)
        refreshAll();
    end

    function points = currentCurveLengthPoints()
        points = currentCurveDisplayPoints(2);
    end

    function points = currentCurveFitPoints()
        points = currentCurveDisplayPoints(3);
    end

    function points = currentCurveDisplayPoints(minPointCount)
        points = [S.xPix(:), S.yPix(:)];
        if ~isempty(S.curveEditor)
            curvePoints = S.curveEditor.curvePoints();
            if size(curvePoints, 1) >= minPointCount
                points = curvePoints;
            end
        end
    end

    function updateCurveGraphics()
        if ~isempty(S.curveEditor)
            S.curveEditor.refresh();
        end
    end

    function refreshScaleReadout()
        scaleTool.updateReadout();
    end

    function updateModeControls()
        hasImage = ~isempty(S.image);
        hasCurve = ~isempty(S.xPix);
        referenceEditActive = scaleTool.isReferenceEditActive();
        editActive = S.curveEditActive || referenceEditActive;

        btnStartCurve.Enable = ternary(hasImage, 'on', 'off');
        btnStartCurve.Text = ternary(S.curveEditActive, ...
            'Finish curve edit', 'Start curve edit');
        scaleTool.setEnabled(struct( ...
            'hasImage', hasImage, ...
            'blockInputs', S.curveEditActive, ...
            'blockPlacement', editActive));

        btnUndoPoint.Enable = ternary(hasCurve && ~referenceEditActive, 'on', 'off');
        btnClearCurve.Enable = ternary(hasCurve && ~referenceEditActive, 'on', 'off');
        chkDensify.Enable = ternary(~editActive, 'on', 'off');
        edtDenseN.Enable = ternary(~editActive, 'on', 'off');
        chkShowDense.Enable = ternary(S.fit.ok && ~editActive, 'on', 'off');
        btnFit.Enable = ternary(numel(S.xPix) >= 3 && ~editActive, 'on', 'off');
        btnMeasureLength.Enable = ternary(numel(S.xPix) >= 2 && ~editActive, 'on', 'off');
        btnExportCSV.Enable = ternary((S.fit.ok || S.length.ok) && ~editActive, 'on', 'off');
        btnExportOverlay.Enable = ternary(hasImage && ~editActive, 'on', 'off');
    end

    function refreshImageOverlay()
        ax = ui.topAxes;
        cla(ax);
        hold(ax, 'off');

        if isempty(S.image)
            title(ax, 'Image + Circle Fit');
            axis(ax, 'normal');
            xlim(ax, [0 1]);
            ylim(ax, [0 1]);
            return;
        end

        hImage = labkit.ui.showImageAxes(ax, S.image, 'Image + Circle Fit', ...
            struct('clearAxes', false));
        hold(ax, 'on');

        if S.fit.ok
            t = linspace(-pi, pi, 600);
            plot(ax, S.fit.xc_px + S.fit.R_px*cos(t), ...
                S.fit.yc_px + S.fit.R_px*sin(t), ...
                'r-', 'LineWidth', 2, ...
                'HitTest', 'off', ...
                'DisplayName', 'fit circle');
            plot(ax, S.fit.xc_px, S.fit.yc_px, 'ro', ...
                'MarkerFaceColor', 'r', ...
                'HitTest', 'off', ...
                'DisplayName', 'center');
            title(ax, sprintf('R = %.4g %s, curvature = %.4g %s, RMSE = %.3g %s', ...
                S.fit.R_show, S.fit.unitLen, S.fit.kappa_show, ...
                S.fit.unitK, S.fit.rmse_show, S.fit.unitLen));
        else
            title(ax, 'Image + Circle Fit');
        end

        if S.curveEditActive
            ensureCurveEditor();
            S.curveEditor.setBackground(hImage);
            S.curveEditor.refresh();
        elseif scaleTool.isReferenceEditActive()
            scaleTool.setBackground(hImage);
            scaleTool.refresh();
        else
            plotStaticCurveAnchors(ax);
        end

        scaleTool.renderOverlay(ax);
        hold(ax, 'off');
        labkit.ui.enableAxesPopout(ax);
    end

    function plotStaticCurveAnchors(ax)
        points = [S.xPix(:), S.yPix(:)];
        if isempty(points)
            return;
        end

        curve = points;
        if ~isempty(S.curveEditor)
            curve = S.curveEditor.curvePoints();
        end
        if ~isempty(curve)
            plot(ax, curve(:, 1), curve(:, 2), '-', ...
                'Color', [0 0.45 0.95], ...
                'LineWidth', 1.5, ...
                'HitTest', 'off', ...
                'DisplayName', 'curve');
        end
        if S.fit.ok
            if chkShowDense.Value
                plotDenseFitPoints(ax, S.fit);
            end
            plotAnchorResiduals(ax, points, S.fit);
        end
        plot(ax, points(:, 1), points(:, 2), 'o', ...
            'LineStyle', 'none', ...
            'Color', [1 0.85 0], ...
            'MarkerFaceColor', [0 0.45 0.95], ...
            'LineWidth', 1.2, ...
            'MarkerSize', 7, ...
            'HitTest', 'off', ...
            'DisplayName', 'anchors');
    end

    function onPreviewScroll(~, event)
        if isempty(S.image)
            return;
        end
        point = ui.topAxes.CurrentPoint;
        x = point(1, 1);
        y = point(1, 2);
        if ~insideImageBounds(x, y, size(S.image))
            return;
        end
        zoomAxesAtPoint(ui.topAxes, x, y, event.VerticalScrollCount, size(S.image));
    end

    function refreshSummary()
        txtPointCount.Value = sprintf('Points: %d', numel(S.xPix));
        if S.fit.ok
            resultTable.Data = fitResultTableData(S.fit, S.length);
            txtDetails.Value = { ...
                sprintf('Image: %s', emptyDash(S.imagePath)), ...
                sprintf('Center: xc = %.6f px, yc = %.6f px', S.fit.xc_px, S.fit.yc_px), ...
                sprintf('Radius: %.6f %s', S.fit.R_show, S.fit.unitLen), ...
                sprintf('Curvature: %.6f %s', S.fit.kappa_show, S.fit.unitK), ...
                sprintf('Curve length: %.6f %s', S.length.length_show, S.length.unitLen), ...
                sprintf('RMSE: %.6f %s', S.fit.rmse_show, S.fit.unitLen), ...
                sprintf('reference = %.6g px / %.6g %s; px/%s = %.6g', ...
                S.fit.referencePx, S.fit.referenceLength, S.fit.scaleUnit, ...
                S.fit.scaleUnit, S.fit.px_per_unit)};
        elseif S.length.ok
            resultTable.Data = lengthResultTableData(S.length);
            txtDetails.Value = { ...
                sprintf('Image: %s', emptyDash(S.imagePath)), ...
                sprintf('Curve length: %.6f %s', S.length.length_show, S.length.unitLen), ...
                sprintf('Curve length: %.6f px', S.length.length_px), ...
                sprintf('Points used: %d; px/%s = %.6g', ...
                S.length.pointCount, S.length.scaleUnit, S.length.px_per_unit)};
        else
            resultTable.Data = initialResultTable();
            if S.curveEditActive
                txtDetails.Value = {'Curve edit active. Double-click blank image space to add/insert points, drag points to move them, double-click a point to delete it. Use the scroll wheel over the image to zoom.'};
            elseif scaleTool.isReferenceEditActive()
                txtDetails.Value = {'Reference-pixel edit active. Double-click two endpoints or drag existing endpoints; this sets the calibration pixel length only.'};
            elseif numel(S.xPix) >= 3
                txtDetails.Value = {'Curve points are ready. Fit curvature or measure curve length.'};
            elseif numel(S.xPix) >= 2
                txtDetails.Value = {'Curve points are ready. Measure curve length, or add more points before fitting curvature.'};
            else
                txtDetails.Value = {'Load an image and start curve editing.'};
            end
        end
        updateModeControls();
    end

    function resetAxes()
        refreshImageOverlay();
        refreshSummary();
    end

    function addLog(message)
        labkit.ui.appendLog(txtLog, message);
        debugLog.append(message);
    end

    function showError(titleText, message)
        addLog(sprintf('%s: %s', titleText, message));
        uialert(fig, message, titleText);
    end
end

function handlers = curvatureAppTestHandlers()
    handlers = struct( ...
        'command', {'computeCurvatureFit', 'computeCurveLength', 'buildCurvatureResultTable'}, ...
        'minArgs', {3, 3, 2}, ...
        'maxArgs', {3, 3, 3}, ...
        'maxOutputs', {1, 1, 1}, ...
        'run', {@runComputeCurvatureFit, @runComputeCurveLength, @runBuildCurvatureResultTable});
end

function outputs = runComputeCurvatureFit(args)
    opts = args{3};
    calibration = scaleOptionsFromStruct(opts);
    doDensify = optionValue(opts, 'doDensify', true);
    denseN = optionValue(opts, 'denseN', 300);
    fitPathX = optionValue(opts, 'fitPathX', []);
    fitPathY = optionValue(opts, 'fitPathY', []);
    outputs = {computeCurvatureFit(args{1}, args{2}, calibration, ...
        doDensify, denseN, fitPathX, fitPathY)};
end

function outputs = runBuildCurvatureResultTable(args)
    if numel(args) >= 3
        lengthResult = args{3};
    else
        lengthResult = lengthResultFromFit(args{1});
    end
    outputs = {buildCurvatureResultTable(args{1}, string(args{2}), lengthResult)};
end

function outputs = runComputeCurveLength(args)
    opts = args{3};
    calibration = scaleOptionsFromStruct(opts);
    outputs = {computeCurveLength(args{1}, args{2}, calibration)};
end

function plotDenseFitPoints(ax, fit)
    if numel(fit.xFit) <= numel(fit.xPix)
        return;
    end
    plot(ax, fit.xFit, fit.yFit, '.', ...
        'Color', [0.95 0.2 0.95], ...
        'MarkerSize', 7, ...
        'HitTest', 'off', ...
        'DisplayName', 'dense fit points');
end

function plotAnchorResiduals(ax, points, fit)
    dx = points(:, 1) - fit.xc_px;
    dy = points(:, 2) - fit.yc_px;
    radii = hypot(dx, dy);
    valid = isfinite(radii) & radii > eps;
    if ~any(valid)
        return;
    end

    circleX = fit.xc_px + fit.R_px .* dx(valid) ./ radii(valid);
    circleY = fit.yc_px + fit.R_px .* dy(valid) ./ radii(valid);
    anchorX = points(valid, 1);
    anchorY = points(valid, 2);
    xSegments = [anchorX.'; circleX.'; NaN(1, numel(circleX))];
    ySegments = [anchorY.'; circleY.'; NaN(1, numel(circleY))];
    plot(ax, xSegments(:), ySegments(:), '--', ...
        'Color', [1 0.9 0], ...
        'LineWidth', 1.2, ...
        'HitTest', 'off', ...
        'DisplayName', 'anchor residuals');
end

function data = initialResultTable()
    data = { ...
        'Curve length', '-'; ...
        'Radius', '-'; ...
        'Curvature', '-'; ...
        'RMSE', '-'; ...
        'Center X', '-'; ...
        'Center Y', '-'; ...
        'Pixels/unit', '-'};
end

function tf = insideImageBounds(x, y, imageSize)
    tf = isfinite(x) && isfinite(y) && ...
        x >= 0.5 && y >= 0.5 && ...
        x <= imageSize(2) + 0.5 && y <= imageSize(1) + 0.5;
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

function data = fitResultTableData(fit, lengthResult)
    if nargin < 2 || isempty(lengthResult)
        lengthResult = lengthResultFromFit(fit);
    end
    data = { ...
        'Curve length', sprintf('%.6g %s', lengthResult.length_show, lengthResult.unitLen); ...
        'Radius', sprintf('%.6g %s', fit.R_show, fit.unitLen); ...
        'Curvature', sprintf('%.6g %s', fit.kappa_show, fit.unitK); ...
        'RMSE', sprintf('%.6g %s', fit.rmse_show, fit.unitLen); ...
        'Center X', sprintf('%.6f px', fit.xc_px); ...
        'Center Y', sprintf('%.6f px', fit.yc_px); ...
        sprintf('Pixels/%s', fit.scaleUnit), sprintf('%.6g', fit.px_per_unit)};
end

function data = lengthResultTableData(lengthResult)
    data = { ...
        'Curve length', sprintf('%.6g %s', lengthResult.length_show, lengthResult.unitLen); ...
        'Curve length px', sprintf('%.6g px', lengthResult.length_px); ...
        'Length points', sprintf('%d', lengthResult.pointCount); ...
        sprintf('Pixels/%s', lengthResult.scaleUnit), sprintf('%.6g', lengthResult.px_per_unit); ...
        'Radius', '-'; ...
        'Curvature', '-'; ...
        'RMSE', '-'};
end

function s = emptyDash(value)
    if strlength(string(value)) == 0
        s = '-';
    else
        s = char(value);
    end
end

function value = ternary(condition, trueValue, falseValue)
    if condition
        value = trueValue;
    else
        value = falseValue;
    end
end

function tf = isReferenceEditReason(reason)
    tf = false;
    if ischar(reason)
        text = string(reason);
    elseif isstring(reason) && isscalar(reason)
        text = reason;
    else
        return;
    end
    tf = any(text == ["set points", "add point", "delete point", ...
        "move point", "clear points", "start", "finish"]);
end
