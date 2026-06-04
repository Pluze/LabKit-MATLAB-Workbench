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
    S.referencePx = NaN;
    S.referenceLine = [];
    S.scaleBar = [];
    S.curveEditor = [];
    S.referenceEditor = [];
    S.referenceEditActive = false;
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

    scaleUi = labkit.ui.createScaleBarPanel(layFA, 3, ...
        struct('onMeasureReference', @onMeasureReferencePixels, ...
        'onCalibrationChanged', @onCalibrationSettingsChanged, ...
        'onScaleBarChanged', @onScaleBarSettingsChanged, ...
        'onPlaceScaleBar', @onPlaceScaleBar));

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
    ui.topAxes = uiaxes(ui.rightGrid);
    ui.topAxes.Layout.Row = 1;

    resetAxes();
    refreshScaleReadout();

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
        S.referencePx = NaN;
        S.referenceLine = [];
        S.scaleBar = [];
        scaleUi.clearReferencePixels();
        S.referenceEditActive = false;
        S.curveEditActive = false;
        if ~isempty(S.curveEditor)
            S.curveEditor.delete();
        end
        S.curveEditor = [];
        if ~isempty(S.referenceEditor)
            S.referenceEditor.delete();
        end
        S.referenceEditor = [];
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

        S.referenceEditActive = false;
        if ~isempty(S.referenceEditor)
            S.referenceEditor.setActive(false);
        end
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

    function onMeasureReferencePixels(~, ~)
        if isempty(S.image)
            showError('No image loaded', 'Open an image before measuring reference pixels.');
            return;
        end

        if S.referenceEditActive
            S.referenceEditActive = false;
            if ~isempty(S.referenceEditor)
                S.referenceEditor.setActive(false);
            end
            addLog('Finished reference-pixel edit.');
            refreshAll();
            return;
        end

        S.curveEditActive = false;
        if ~isempty(S.curveEditor)
            S.curveEditor.setActive(false);
        end
        S.referenceEditActive = true;
        ensureReferenceEditor();
        if isempty(S.referenceLine)
            S.referenceEditor.setPoints(zeros(0, 2));
            S.referenceEditor.setActive(true);
        else
            S.referenceEditor.start(S.referenceLine);
        end
        S.fit = emptyFitResult();
        S.length = emptyLengthResult();
        S.scaleBar = [];
        addLog('Started reference-pixel edit. Double-click two endpoints, then drag endpoints to refine.');
        refreshAll();
    end

    function onPlaceScaleBar(~, ~)
        if isempty(S.image)
            showError('No image loaded', 'Open an image before placing a scale bar.');
            return;
        end
        [pxPerUnit, scaleUnit] = currentPixelsPerUnit();
        if pxPerUnit <= 0
            showError('Calibration required', ...
                'Measure or enter reference pixels, then enter a positive real reference length and unit.');
            return;
        end

        try
            S.scaleBar = scaleUi.scaleBarSpec(size(S.image));
        catch ME
            showError('Could not place scale bar', ME.message);
            return;
        end
        S.curveEditActive = false;
        if ~isempty(S.curveEditor)
            S.curveEditor.setActive(false);
        end
        S.referenceEditActive = false;
        if ~isempty(S.referenceEditor)
            S.referenceEditor.setActive(false);
        end
        addLog(sprintf('Placed scale bar: %.6g %s (%.6g px).', ...
            S.scaleBar.barLength, scaleUnit, S.scaleBar.barLength * pxPerUnit));
        refreshAll();
    end

    function onFitCurvature(~, ~)
        if numel(S.xPix) < 3
            showError('Not enough points', 'At least 3 curve points are required to fit curvature.');
            return;
        end

        try
            fitPath = currentCurveFitPoints();
            S.fit = computeCurvatureFit(S.xPix, S.yPix, scaleUi.referencePixels(), ...
                scaleUi.referenceLength(), scaleUi.scaleUnit(), ...
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
                scaleUi.referencePixels(), scaleUi.referenceLength(), scaleUi.scaleUnit());
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
            S.curveEditor = labkit.ui.createAnchorCurveEditor(ui.topAxes, size(S.image), ...
                struct('figure', fig, ...
                'closed', false, ...
                'style', 'Curve', ...
                'onChanged', @onCurveEditorChanged));
        else
            S.curveEditor.setImageSize(size(S.image));
            S.curveEditor.setStyle('Curve');
        end
    end

    function ensureReferenceEditor()
        if isempty(S.image)
            return;
        end
        if isempty(S.referenceEditor)
            S.referenceEditor = labkit.ui.createAnchorCurveEditor(ui.topAxes, size(S.image), ...
                struct('figure', fig, ...
                'closed', false, ...
                'style', 'Straight lines', ...
                'maxPoints', 2, ...
                'onChanged', @onReferenceEditorChanged));
        else
            S.referenceEditor.setImageSize(size(S.image));
            S.referenceEditor.setStyle('Straight lines');
        end
    end

    function onReferenceEditorChanged(points, ~)
        S.referenceLine = points;
        if size(points, 1) == 2
            referencePx = hypot(points(2, 1) - points(1, 1), ...
                points(2, 2) - points(1, 2));
            if referencePx > 0
                S.referencePx = referencePx;
                scaleUi.setReferencePixels(referencePx);
            else
                S.referencePx = NaN;
                scaleUi.clearReferencePixels();
            end
        else
            S.referencePx = NaN;
            scaleUi.clearReferencePixels();
        end
        S.fit = emptyFitResult();
        S.length = emptyLengthResult();
        S.scaleBar = [];
        refreshScaleReadout();
        refreshSummary();
    end

    function onCalibrationSettingsChanged(~, ~)
        S.referencePx = scaleUi.referencePixels();
        S.fit = emptyFitResult();
        S.length = emptyLengthResult();
        S.scaleBar = [];
        refreshAll();
    end

    function onScaleBarSettingsChanged(~, ~)
        if isempty(S.image) || isempty(S.scaleBar)
            refreshAll();
            return;
        end
        [pxPerUnit, ~] = currentPixelsPerUnit();
        if pxPerUnit <= 0 || scaleUi.scaleBarLength() <= 0
            S.scaleBar = [];
            refreshAll();
            return;
        end
        try
            S.scaleBar = scaleUi.scaleBarSpec(size(S.image));
        catch
            S.scaleBar = [];
        end
        refreshAll();
    end

    function [pxPerUnit, scaleUnit] = currentPixelsPerUnit()
        [pxPerUnit, scaleUnit] = scaleUi.pixelsPerUnit();
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
        scaleUi.updateReadout();
    end

    function updateModeControls()
        hasImage = ~isempty(S.image);
        hasCurve = ~isempty(S.xPix);
        editActive = S.curveEditActive || S.referenceEditActive;

        btnStartCurve.Enable = ternary(hasImage, 'on', 'off');
        btnStartCurve.Text = ternary(S.curveEditActive, ...
            'Finish curve edit', 'Start curve edit');
        scaleUi.setEnabled(struct( ...
            'hasImage', hasImage, ...
            'referenceEditActive', S.referenceEditActive, ...
            'blockInputs', S.curveEditActive, ...
            'blockPlacement', editActive));

        btnUndoPoint.Enable = ternary(hasCurve && ~S.referenceEditActive, 'on', 'off');
        btnClearCurve.Enable = ternary(hasCurve && ~S.referenceEditActive, 'on', 'off');
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
        fig.WindowScrollWheelFcn = @onPreviewScroll;
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
        elseif S.referenceEditActive
            ensureReferenceEditor();
            S.referenceEditor.setBackground(hImage);
            S.referenceEditor.refresh();
        else
            ax.ButtonDownFcn = [];
            hImage.HitTest = 'off';
            hImage.PickableParts = 'none';
            plotStaticCurveAnchors(ax);
        end

        drawScaleBarOverlay(ax, S.scaleBar);
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
            elseif S.referenceEditActive
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
    [referencePx, referenceLength, scaleUnit] = scaleOptionsFromStruct(opts);
    doDensify = optionValue(opts, 'doDensify', true);
    denseN = optionValue(opts, 'denseN', 300);
    fitPathX = optionValue(opts, 'fitPathX', []);
    fitPathY = optionValue(opts, 'fitPathY', []);
    outputs = {computeCurvatureFit(args{1}, args{2}, referencePx, ...
        referenceLength, scaleUnit, doDensify, denseN, fitPathX, fitPathY)};
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
    [referencePx, referenceLength, scaleUnit] = scaleOptionsFromStruct(opts);
    outputs = {computeCurveLength(args{1}, args{2}, referencePx, ...
        referenceLength, scaleUnit)};
end

function fit = computeCurvatureFit(xPix, yPix, referencePx, referenceLength, scaleUnit, doDensify, denseN, fitPathX, fitPathY)
    fit = emptyFitResult();
    xPix = xPix(:);
    yPix = yPix(:);
    [xPix, yPix] = removeDuplicateNeighbors(xPix, yPix, 1e-9);

    if numel(xPix) < 3
        error('labkit_CurvatureMeasurement_app:NotEnoughPoints', ...
            'At least 3 unique points are required to fit a circle.');
    end

    if nargin < 6 || isempty(doDensify)
        doDensify = true;
    end
    if nargin < 7 || isempty(denseN)
        denseN = 300;
    end
    denseN = max(3, round(denseN));

    fitSourceX = xPix;
    fitSourceY = yPix;
    hasFitPath = nargin >= 9 && ~isempty(fitPathX) && ~isempty(fitPathY);
    if hasFitPath
        fitPathX = fitPathX(:);
        fitPathY = fitPathY(:);
        if numel(fitPathX) == numel(fitPathY)
            [fitPathX, fitPathY] = removeDuplicateNeighbors(fitPathX, fitPathY, 1e-9);
            if numel(fitPathX) >= 3
                fitSourceX = fitPathX;
                fitSourceY = fitPathY;
            end
        end
    end

    xFit = xPix;
    yFit = yPix;
    if doDensify && (numel(fitSourceX) >= 5 || (hasFitPath && numel(fitSourceX) >= 3))
        [xFit, yFit] = resamplePathByArcLength(fitSourceX, fitSourceY, denseN);
    end

    [xc0, yc0, R0] = circleInitKasa(xFit, yFit);
    [xc, yc, R_px, rmse_px] = fitCircleGeomWithFallback(xFit, yFit, xc0, yc0, R0);
    if ~isfinite(R_px) || R_px <= 0
        error('labkit_CurvatureMeasurement_app:InvalidFit', ...
            'Circle fit produced an invalid radius.');
    end

    scaleUnit = char(normalizeScaleUnit(scaleUnit));
    pxPerUnit = scalePixelsPerUnit(referencePx, referenceLength);
    usePhysicalScale = pxPerUnit > 0;
    kappa_px = 1 / R_px;
    lengthResult = computeCurveLength(fitSourceX, fitSourceY, referencePx, referenceLength, scaleUnit);

    if usePhysicalScale
        unitLen = scaleUnit;
        unitK = sprintf('1/%s', scaleUnit);
        R_show = R_px / pxPerUnit;
        rmse_show = rmse_px / pxPerUnit;
        kappa_show = 1 / R_show;
        residuals_show = radialResiduals(xPix, yPix, xc, yc, R_px) / pxPerUnit;
    else
        unitLen = 'px';
        unitK = '1/px';
        R_show = R_px;
        rmse_show = rmse_px;
        kappa_show = kappa_px;
        residuals_show = radialResiduals(xPix, yPix, xc, yc, R_px);
    end

    fit.ok = true;
    fit.message = '';
    fit.xc_px = xc;
    fit.yc_px = yc;
    fit.R_px = R_px;
    fit.kappa_per_px = kappa_px;
    fit.rmse_px = rmse_px;
    fit.referencePx = referencePx;
    fit.referenceLength = referenceLength;
    fit.scaleUnit = scaleUnit;
    fit.px_per_unit = pxPerUnit;
    fit.usePhysicalScale = usePhysicalScale;
    fit.R_show = R_show;
    fit.kappa_show = kappa_show;
    fit.rmse_show = rmse_show;
    fit.unitLen = unitLen;
    fit.unitK = unitK;
    fit.residuals_show = residuals_show;
    fit.xPix = xPix;
    fit.yPix = yPix;
    fit.xFit = xFit;
    fit.yFit = yFit;
    fit.curveLength_px = lengthResult.length_px;
    fit.curveLength_show = lengthResult.length_show;
    fit.curveLengthUnit = lengthResult.unitLen;
    fit.curvePointCount = lengthResult.pointCount;
end

function lengthResult = computeCurveLength(xPix, yPix, referencePx, referenceLength, scaleUnit)
    lengthResult = emptyLengthResult();
    xPix = xPix(:);
    yPix = yPix(:);
    [xPix, yPix] = removeDuplicateNeighbors(xPix, yPix, 1e-9);

    if numel(xPix) < 2
        error('labkit_CurvatureMeasurement_app:NotEnoughLengthPoints', ...
            'At least 2 unique points are required to measure curve length.');
    end

    lengthPx = sum(hypot(diff(xPix), diff(yPix)));
    scaleUnit = char(normalizeScaleUnit(scaleUnit));
    pxPerUnit = scalePixelsPerUnit(referencePx, referenceLength);
    usePhysicalScale = pxPerUnit > 0;
    if usePhysicalScale
        lengthShow = lengthPx / pxPerUnit;
        unitLen = scaleUnit;
    else
        lengthShow = lengthPx;
        unitLen = 'px';
    end

    lengthResult.ok = true;
    lengthResult.message = '';
    lengthResult.length_px = lengthPx;
    lengthResult.length_show = lengthShow;
    lengthResult.unitLen = unitLen;
    lengthResult.referencePx = referencePx;
    lengthResult.referenceLength = referenceLength;
    lengthResult.scaleUnit = scaleUnit;
    lengthResult.px_per_unit = pxPerUnit;
    lengthResult.usePhysicalScale = usePhysicalScale;
    lengthResult.pointCount = numel(xPix);
end

function pxPerUnit = scalePixelsPerUnit(referencePx, referenceLength)
    pxPerUnit = 0;
    if nargin < 1 || isempty(referencePx)
        referencePx = NaN;
    end
    if nargin < 2 || isempty(referenceLength)
        referenceLength = 0;
    end

    validateattributes(referenceLength, {'numeric'}, {'scalar', 'finite', 'nonnegative'});
    if isfinite(referencePx) && referencePx > 0 && referenceLength > 0
        pxPerUnit = referencePx / referenceLength;
    end
end

function [x, y] = removeDuplicateNeighbors(x, y, tol)
    x = x(:);
    y = y(:);
    if isempty(x)
        return;
    end
    keep = [true; hypot(diff(x), diff(y)) > tol];
    x = x(keep);
    y = y(keep);
end

function [xDense, yDense] = resamplePathByArcLength(x, y, denseN)
    s = [0; cumsum(hypot(diff(x), diff(y)))];
    if s(end) <= 0
        xDense = x;
        yDense = y;
        return;
    end
    s2 = linspace(0, s(end), denseN).';
    xDense = interp1(s, x, s2, 'linear');
    yDense = interp1(s, y, s2, 'linear');
end

function [xc, yc, R] = circleInitKasa(x, y)
    x = x(:);
    y = y(:);
    A = [2*x, 2*y, ones(size(x))];
    b = x.^2 + y.^2;
    p = A\b;
    xc = p(1);
    yc = p(2);
    R = sqrt(max(p(3) + xc^2 + yc^2, eps));
end

function [xc, yc, R, rmse] = fitCircleGeomWithFallback(x, y, xc0, yc0, R0)
    x = x(:);
    y = y(:);
    p0 = [xc0; yc0; R0];
    residual = @(p) sqrt((x - p(1)).^2 + (y - p(2)).^2) - abs(p(3));

    useLSQ = exist('lsqnonlin', 'file') == 2;
    if useLSQ
        try
            opts = optimoptions('lsqnonlin', ...
                'Display', 'off', ...
                'MaxFunctionEvaluations', 2e4, ...
                'MaxIterations', 2e4);
            p = lsqnonlin(residual, p0, [], [], opts);
        catch
            useLSQ = false;
        end
    end

    if ~useLSQ
        f = @(p) sum(residual(p).^2);
        opts = optimset('Display', 'off', 'MaxFunEvals', 2e4, 'MaxIter', 2e4);
        p = fminsearch(f, p0, opts);
    end

    xc = p(1);
    yc = p(2);
    R = abs(p(3));
    rmse = sqrt(mean(residual([xc; yc; R]).^2));
end

function residuals = radialResiduals(x, y, xc, yc, R)
    residuals = sqrt((x(:) - xc).^2 + (y(:) - yc).^2) - R;
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

function drawScaleBarOverlay(ax, scaleBar)
    if isempty(scaleBar)
        return;
    end

    plot(ax, scaleBar.line(:, 1), scaleBar.line(:, 2), '-', ...
        'Color', scaleBar.color, ...
        'LineWidth', 3, ...
        'HitTest', 'off', ...
        'PickableParts', 'none', ...
        'DisplayName', 'scale bar');
    text(ax, scaleBar.labelPosition(1), scaleBar.labelPosition(2), ...
        scaleBar.label, ...
        'Color', scaleBar.color, ...
        'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', scaleBar.verticalAlignment, ...
        'HitTest', 'off', ...
        'PickableParts', 'none');
end

function T = buildCurvatureResultTable(fit, imagePath, lengthResult)
    if nargin < 3 || isempty(lengthResult)
        lengthResult = lengthResultFromFit(fit);
    end
    scaleInfo = resultScaleInfo(fit, lengthResult);
    T = table( ...
        string(imagePath), ...
        fit.xc_px, ...
        fit.yc_px, ...
        fit.R_px, ...
        fit.kappa_per_px, ...
        fit.rmse_px, ...
        scaleInfo.referencePx, ...
        scaleInfo.referenceLength, ...
        string(scaleInfo.scaleUnit), ...
        scaleInfo.pxPerUnit, ...
        fit.R_show, ...
        string(fit.unitLen), ...
        fit.kappa_show, ...
        string(fit.unitK), ...
        fit.rmse_show, ...
        lengthResult.length_px, ...
        lengthResult.length_show, ...
        string(lengthResult.unitLen), ...
        lengthResult.pointCount, ...
        'VariableNames', {'Image', 'CenterX_px', 'CenterY_px', ...
        'Radius_px', 'Curvature_1_per_px', 'RMSE_px', 'ReferencePixels_px', ...
        'ReferenceLength', 'ReferenceUnit', 'PixelsPerUnit', 'Radius', 'RadiusUnit', ...
        'Curvature', 'CurvatureUnit', 'RMSE', ...
        'CurveLength_px', 'CurveLength', 'CurveLengthUnit', 'CurvePointCount'});
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

function fit = emptyFitResult()
    fit = struct( ...
        'ok', false, ...
        'message', 'No fit result.', ...
        'xc_px', NaN, ...
        'yc_px', NaN, ...
        'R_px', NaN, ...
        'kappa_per_px', NaN, ...
        'rmse_px', NaN, ...
        'referencePx', NaN, ...
        'referenceLength', 0, ...
        'scaleUnit', 'um', ...
        'px_per_unit', 0, ...
        'usePhysicalScale', false, ...
        'R_show', NaN, ...
        'kappa_show', NaN, ...
        'rmse_show', NaN, ...
        'unitLen', 'px', ...
        'unitK', '1/px', ...
        'residuals_show', [], ...
        'xPix', [], ...
        'yPix', [], ...
        'xFit', [], ...
        'yFit', [], ...
        'curveLength_px', NaN, ...
        'curveLength_show', NaN, ...
        'curveLengthUnit', 'px', ...
        'curvePointCount', 0);
end

function lengthResult = lengthResultFromFit(fit)
    lengthResult = emptyLengthResult();
    if isstruct(fit) && isfield(fit, 'curveLength_px') && ...
            isfinite(fit.curveLength_px) && fit.curveLength_px >= 0
        lengthResult.ok = true;
        lengthResult.message = '';
        lengthResult.length_px = fit.curveLength_px;
        lengthResult.length_show = fit.curveLength_show;
        lengthResult.unitLen = fit.curveLengthUnit;
        lengthResult.referencePx = fit.referencePx;
        lengthResult.referenceLength = fit.referenceLength;
        lengthResult.scaleUnit = fit.scaleUnit;
        lengthResult.px_per_unit = fit.px_per_unit;
        lengthResult.usePhysicalScale = fit.usePhysicalScale;
        lengthResult.pointCount = fit.curvePointCount;
    end
end

function lengthResult = emptyLengthResult()
    lengthResult = struct( ...
        'ok', false, ...
        'message', 'No curve length result.', ...
        'length_px', NaN, ...
        'length_show', NaN, ...
        'unitLen', 'px', ...
        'referencePx', NaN, ...
        'referenceLength', 0, ...
        'scaleUnit', 'um', ...
        'px_per_unit', 0, ...
        'usePhysicalScale', false, ...
        'pointCount', 0);
end

function scaleInfo = resultScaleInfo(fit, lengthResult)
    scaleInfo = struct('referencePx', NaN, 'referenceLength', 0, ...
        'scaleUnit', 'um', 'pxPerUnit', 0);
    if isstruct(lengthResult) && isfield(lengthResult, 'px_per_unit') && ...
            lengthResult.px_per_unit > 0
        scaleInfo.referencePx = lengthResult.referencePx;
        scaleInfo.referenceLength = lengthResult.referenceLength;
        scaleInfo.scaleUnit = lengthResult.scaleUnit;
        scaleInfo.pxPerUnit = lengthResult.px_per_unit;
    elseif isstruct(fit) && isfield(fit, 'px_per_unit')
        scaleInfo.referencePx = fit.referencePx;
        scaleInfo.referenceLength = fit.referenceLength;
        scaleInfo.scaleUnit = fit.scaleUnit;
        scaleInfo.pxPerUnit = fit.px_per_unit;
    end
end

function [referencePx, referenceLength, scaleUnit] = scaleOptionsFromStruct(opts)
    referencePx = optionValue(opts, 'referencePx', optionValue(opts, 'rawpx', NaN));
    referenceLength = optionValue(opts, 'referenceLength', optionValue(opts, 'scaleLengthMm', 0));
    scaleUnit = optionValue(opts, 'scaleUnit', 'um');
    referencePx = positiveOrNaN(referencePx);
    if isempty(referenceLength) || ~isfinite(referenceLength) || referenceLength < 0
        referenceLength = 0;
    end

    manualPxPerMm = optionValue(opts, 'manualPxPerMm', 0);
    if isempty(manualPxPerMm) || ~isfinite(manualPxPerMm) || manualPxPerMm < 0
        manualPxPerMm = 0;
    end
    if ~(isfinite(referencePx) && referencePx > 0 && referenceLength > 0) && manualPxPerMm > 0
        referencePx = manualPxPerMm;
        referenceLength = 1;
        scaleUnit = 'mm';
    end
    scaleUnit = char(normalizeScaleUnit(scaleUnit));
end

function scaleUnit = normalizeScaleUnit(scaleUnit)
    scaleUnit = string(scaleUnit);
    validUnits = ["nm", "um", "mm", "cm"];
    if ~any(scaleUnit == validUnits)
        scaleUnit = "um";
    end
end

function value = positiveOrNaN(value)
    if isempty(value) || ~isfinite(value) || value <= 0
        value = NaN;
    end
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

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
