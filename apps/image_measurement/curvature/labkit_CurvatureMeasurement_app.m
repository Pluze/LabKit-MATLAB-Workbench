function varargout = labkit_CurvatureMeasurement_app(varargin)
%LABKIT_CURVATUREMEASUREMENT_APP Measure curve radius and curvature from images.

    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'labkit_CurvatureMeasurement_app', varargin, nargout);
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
    S.fit = curvature.state.emptyFitResult();
    S.length = curvature.state.emptyLengthResult();

    ui = labkit.ui.app.createShell(struct( ...
        'title', 'Image Curvature Measurement', ...
        'position', [90 70 1420 860], ...
        'leftWidth', 390, ...
        'options', curvature.ui.appShellOptions()));
    fig = ui.fig;
    layFA = ui.filesAnalysisGrid;
    laySR = ui.summaryResultsGrid;
    layLog = ui.logGrid;
    ui.topAxes = uiaxes(ui.rightGrid);
    ui.topAxes.Layout.Row = 1;
    imageRuntime = labkit.ui.tool.createRuntime(ui.topAxes, ...
        struct('figure', fig, ...
        'defaultScrollFcn', @onPreviewScroll, ...
        'onTrace', debugLog.trace));

    controls = curvature.ui.createControls(layFA, laySR, layLog, imageRuntime, struct( ...
        'onOpenImage', @onOpenImage, ...
        'onStartCurveEdit', @onStartCurveEdit, ...
        'onUndoCurvePoint', @onUndoCurvePoint, ...
        'onClearCurve', @onClearCurve, ...
        'onBeforeReferenceEdit', @onBeforeReferenceEdit, ...
        'onReferenceEditChanged', @onReferenceEditChanged, ...
        'onCalibrationSettingsChanged', @onCalibrationSettingsChanged, ...
        'onScaleBarSettingsChanged', @onScaleBarSettingsChanged, ...
        'onScaleBarPlaced', @onScaleBarPlaced, ...
        'onScaleToolError', @onScaleToolError, ...
        'onShowDenseChanged', @(~,~) refreshImageOverlay(), ...
        'onFitCurvature', @onFitCurvature, ...
        'onMeasureCurveLength', @onMeasureCurveLength, ...
        'onExportCSV', @onExportCSV, ...
        'onExportOverlay', @onExportOverlay, ...
        'onTrace', debugLog.trace));
    txtImage = controls.txtImage;
    txtPointCount = controls.txtPointCount;
    btnStartCurve = controls.btnStartCurve;
    btnUndoPoint = controls.btnUndoPoint;
    btnClearCurve = controls.btnClearCurve;
    scaleTool = controls.scaleTool;
    chkDensify = controls.chkDensify;
    edtDenseN = controls.edtDenseN;
    chkShowDense = controls.chkShowDense;
    btnFit = controls.btnFit;
    btnMeasureLength = controls.btnMeasureLength;
    btnExportCSV = controls.btnExportCSV;
    btnExportOverlay = controls.btnExportOverlay;
    resultTable = controls.resultTable;
    txtDetails = controls.txtDetails;
    txtLog = controls.txtLog;

    if debugLog.enabled
        debugLog.attachTextLog(txtLog);
        debugLog.trace('Curvature measurement debug trace enabled.');
        debugLog.instrumentFigure(fig);
    end

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
        scaleTool.resetForNewImage(size(S.image));
        S.curveEditActive = false;
        if ~isempty(S.curveEditor)
            S.curveEditor.delete();
        end
        S.curveEditor = [];
        S.fit = curvature.state.emptyFitResult();
        S.length = curvature.state.emptyLengthResult();
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
        S.fit = curvature.state.emptyFitResult();
        addLog('Started curve edit. Double-click blank image space to add/insert points; drag points to move; double-click a point to delete it.');
        refreshAll();
    end

    function onCurveEditorChanged(points, reason)
        S.xPix = points(:, 1);
        S.yPix = points(:, 2);
        S.fit = curvature.state.emptyFitResult();
        S.length = curvature.state.emptyLengthResult();
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
            S.fit = curvature.state.emptyFitResult();
            S.length = curvature.state.emptyLengthResult();
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
        S.fit = curvature.state.emptyFitResult();
        S.length = curvature.state.emptyLengthResult();
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
            S.fit = curvature.ops.computeCurvatureFit(S.xPix, S.yPix, scaleTool.calibration(), ...
                chkDensify.Value, round(edtDenseN.Value), ...
                fitPath(:, 1), fitPath(:, 2));
            S.length = curvature.state.lengthResultFromFit(S.fit);
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
            S.length = curvature.ops.computeCurveLength(points(:, 1), points(:, 2), ...
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
            T = curvature.export.buildResultTable(S.fit, S.imagePath, S.length);
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
            S.curveEditor = labkit.ui.tool.anchorEditor(imageRuntime, size(S.image), ...
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
        S.fit = curvature.state.emptyFitResult();
        S.length = curvature.state.emptyLengthResult();
        scaleTool.clearScaleBar();
        if curvature.ui.isReferenceEditReason(reason)
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

        btnStartCurve.Enable = curvature.view.ternary(hasImage, 'on', 'off');
        btnStartCurve.Text = curvature.view.ternary(S.curveEditActive, ...
            'Finish curve edit', 'Start curve edit');
        scaleTool.setEnabled(struct( ...
            'hasImage', hasImage, ...
            'blockInputs', S.curveEditActive, ...
            'blockPlacement', editActive));

        btnUndoPoint.Enable = curvature.view.ternary(hasCurve && ~referenceEditActive, 'on', 'off');
        btnClearCurve.Enable = curvature.view.ternary(hasCurve && ~referenceEditActive, 'on', 'off');
        chkDensify.Enable = curvature.view.ternary(~editActive, 'on', 'off');
        edtDenseN.Enable = curvature.view.ternary(~editActive, 'on', 'off');
        chkShowDense.Enable = curvature.view.ternary(S.fit.ok && ~editActive, 'on', 'off');
        btnFit.Enable = curvature.view.ternary(numel(S.xPix) >= 3 && ~editActive, 'on', 'off');
        btnMeasureLength.Enable = curvature.view.ternary(numel(S.xPix) >= 2 && ~editActive, 'on', 'off');
        btnExportCSV.Enable = curvature.view.ternary((S.fit.ok || S.length.ok) && ~editActive, 'on', 'off');
        btnExportOverlay.Enable = curvature.view.ternary(hasImage && ~editActive, 'on', 'off');
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

        hImage = labkit.ui.view.draw(ax, 'image', S.image, 'Image + Circle Fit', ...
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
        labkit.ui.view.draw(ax, 'popout');
    end

    function plotStaticCurveAnchors(ax)
        points = [S.xPix(:), S.yPix(:)];
        curve = points;
        if ~isempty(S.curveEditor)
            curve = S.curveEditor.curvePoints();
        end
        curvature.view.plotStaticCurveAnchors(ax, points, curve, S.fit, chkShowDense.Value);
    end

    function onPreviewScroll(~, event)
        if isempty(S.image)
            return;
        end
        point = ui.topAxes.CurrentPoint;
        x = point(1, 1);
        y = point(1, 2);
        if ~curvature.view.insideImageBounds(x, y, size(S.image))
            return;
        end
        curvature.view.zoomAxesAtPoint(ui.topAxes, x, y, event.VerticalScrollCount, size(S.image));
    end

    function refreshSummary()
        summary = curvature.view.summaryViewData(S.imagePath, S.xPix, S.fit, ...
            S.length, S.curveEditActive, scaleTool.isReferenceEditActive());
        txtPointCount.Value = summary.pointCountText;
        resultTable.Data = summary.tableData;
        txtDetails.Value = summary.details;
        updateModeControls();
    end

    function resetAxes()
        refreshImageOverlay();
        refreshSummary();
    end

    function addLog(message)
        labkit.ui.view.update(txtLog, 'appendLog', message);
        debugLog.append(message);
    end

    function showError(titleText, message)
        addLog(sprintf('%s: %s', titleText, message));
        uialert(fig, message, titleText);
    end
end
