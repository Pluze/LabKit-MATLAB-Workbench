% App-owned action registry for Curvature Measurement. Expected caller is
% curvature.definition. Output maps semantic action ids to handlers used by
% labkit.ui.runtime.run while preserving the existing curve-edit workflow.
function actions = definitionActions()
%DEFINITIONACTIONS Build the Curvature Measurement runtime action map.

    S = [];
    ui = [];
    fig = [];
    debugLog = [];
    imageRuntime = [];
    scaleTool = [];
    controls = [];
    txtPointCount = [];
    btnStartCurve = [];
    btnUndoPoint = [];
    btnClearCurve = [];
    chkDensify = [];
    edtDenseN = [];
    chkShowDense = [];
    btnFit = [];
    btnMeasureLength = [];
    btnExportCSV = [];
    btnExportOverlay = [];
    resultTable = [];
    txtDetails = [];
    txtLog = [];

    actions = struct( ...
        'startup', @onStartup, ...
        'onImageChosen', @dispatchImageChosen, ...
        'onImageCleared', @dispatchImageCleared, ...
        'onStartCurveEdit', @dispatchStartCurveEdit, ...
        'onUndoCurvePoint', @dispatchUndoCurvePoint, ...
        'onClearCurve', @dispatchClearCurve, ...
        'onShowDenseChanged', @dispatchShowDenseChanged, ...
        'onFitCurvature', @dispatchFitCurvature, ...
        'onMeasureCurveLength', @dispatchMeasureCurveLength, ...
        'onExportCSV', @dispatchExportCSV, ...
        'onExportOverlay', @dispatchExportOverlay);

    function state = onStartup(state, ~, services)
        S = state;
        ui = services.ui;
        fig = services.figure;
        debugLog = services.debug;
        ui.topAxes = ui.controls.imageAxes.primaryAxes;
        imageRuntime = labkit.ui.interaction.runtime(ui.topAxes, ...
            struct('figure', fig, ...
            'onTrace', debugLog.trace));

        scaleTool = labkit.ui.interaction.scaleBar(ui.controls.scaleBarHost.grid, ...
            1, imageRuntime, struct( ...
            'onBeforeReferenceEdit', @onBeforeReferenceEdit, ...
            'onReferenceEditChanged', @onReferenceEditChanged, ...
            'onCalibrationChanged', @onCalibrationSettingsChanged, ...
            'onScaleBarChanged', @onScaleBarSettingsChanged, ...
            'onScaleBarPlaced', @onScaleBarPlaced, ...
            'onError', @onScaleToolError, ...
            'onTrace', debugLog.trace));
        controls = curvature.userInterface.mapControlHandles(ui, scaleTool);
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
            debugLog.trace('Curvature measurement debug trace enabled.');
            setupDebugSamples();
        end

        resetAxes();
        refreshScaleReadout();
        state = S;
    end

    function state = dispatchWithEvent(~, payload, callback)
        callback([], payload.event);
        state = S;
    end

    function state = dispatchNoEvent(~, ~, callback)
        callback([], []);
        state = S;
    end

    function state = dispatchImageChosen(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onImageChosen);
    end
    function state = dispatchImageCleared(state, payload, ~)
        state = dispatchNoEvent(state, payload, @onImageCleared);
    end
    function state = dispatchStartCurveEdit(state, payload, ~)
        state = dispatchNoEvent(state, payload, @onStartCurveEdit);
    end
    function state = dispatchUndoCurvePoint(state, payload, ~)
        state = dispatchNoEvent(state, payload, @onUndoCurvePoint);
    end
    function state = dispatchClearCurve(state, payload, ~)
        state = dispatchNoEvent(state, payload, @onClearCurve);
    end
    function state = dispatchShowDenseChanged(state, payload, ~)
        state = dispatchNoEvent(state, payload, @refreshImageOverlayCallback);
    end
    function state = dispatchFitCurvature(state, payload, ~)
        state = dispatchNoEvent(state, payload, @onFitCurvature);
    end
    function state = dispatchMeasureCurveLength(state, payload, ~)
        state = dispatchNoEvent(state, payload, @onMeasureCurveLength);
    end
    function state = dispatchExportCSV(state, payload, ~)
        state = dispatchNoEvent(state, payload, @onExportCSV);
    end
    function state = dispatchExportOverlay(state, payload, ~)
        state = dispatchNoEvent(state, payload, @onExportOverlay);
    end

    function onImageChosen(~, event)
        paths = labkit.ui.control.filePaths(event.addedFiles);
        if isempty(paths)
            addLog('Image selection cancelled.');
            return;
        end

        filepath = paths(1);
        try
            img = imread(filepath);
        catch ME
            showException('Could not read image', ME);
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
        S.fit = curvature.appState.emptyFitResult();
        S.length = curvature.appState.emptyLengthResult();
        clearTaskFingerprints();
        addLog(sprintf('Loaded image: %s', filepath));
        refreshAll();
    end

    function onImageCleared()
        S.imagePath = "";
        S.image = [];
        S.xPix = [];
        S.yPix = [];
        S.curveEditActive = false;
        if ~isempty(S.curveEditor)
            S.curveEditor.delete();
        end
        S.curveEditor = [];
        S.fit = curvature.appState.emptyFitResult();
        S.length = curvature.appState.emptyLengthResult();
        clearTaskFingerprints();
        resetAxes();
        addLog('Cleared image file.');
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
        S.fit = curvature.appState.emptyFitResult();
        S.lastFitFingerprint = "";
        addLog('Started curve edit. Double-click blank image space to add/insert points; drag points to move; double-click a point to delete it.');
        refreshAll();
    end

    function onCurveEditorChanged(points, reason)
        S.xPix = points(:, 1);
        S.yPix = points(:, 2);
        S.fit = curvature.appState.emptyFitResult();
        S.length = curvature.appState.emptyLengthResult();
        clearTaskFingerprints();
        refreshSummary();
        if any(strcmp(reason, {'add point', 'delete point', 'move point'}))
            addLog(sprintf('Curve edit updated: %d point(s).', numel(S.xPix)));
        end
        syncRuntimeState();
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
            S.fit = curvature.appState.emptyFitResult();
            S.length = curvature.appState.emptyLengthResult();
            clearTaskFingerprints();
            refreshAll();
        end
        addLog('Cleared curve points.');
    end

    function onBeforeReferenceEdit(~, ~)
        S.curveEditActive = false;
        if ~isempty(S.curveEditor)
            S.curveEditor.setActive(false);
        end
        syncRuntimeState();
    end

    function onReferenceEditChanged(~, reason)
        S.fit = curvature.appState.emptyFitResult();
        S.length = curvature.appState.emptyLengthResult();
        clearTaskFingerprints();
        reasonText = char(string(reason));
        if strcmp(reasonText, 'start')
            addLog('Started reference-pixel edit. Double-click two endpoints, then drag endpoints to refine.');
        elseif strcmp(reasonText, 'finish')
            addLog('Finished reference-pixel edit.');
        end
        refreshScaleReadout();
        refreshSummary();
        syncRuntimeState();
    end

    function onScaleBarPlaced(~, ~)
        scaleBar = scaleTool.placedScaleBar();
        cal = scaleTool.calibration();
        addLog(sprintf('Placed scale bar: %.6g %s (%.6g px).', ...
            scaleBar.barLength, cal.unit, scaleBar.barLength * cal.pixelsPerUnit));
        refreshAll();
        syncRuntimeState();
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
            task = curvature.appState.fitTask([S.xPix(:), S.yPix(:)], ...
                fitPath, scaleTool.calibration(), struct( ...
                'doDensify', chkDensify.Value, ...
                'denseN', round(edtDenseN.Value)));
            if S.fit.ok && S.lastFitFingerprint == task.fingerprint
                addLog('Curvature fit already matches current curve and scale.');
                refreshSummary();
                return;
            end

            S.fit = curvature.analysisRun.computeCurvatureFit( ...
                task.points(:, 1), task.points(:, 2), task.calibration, ...
                task.options.doDensify, task.options.denseN, ...
                task.fitPath(:, 1), task.fitPath(:, 2));
            S.length = curvature.appState.lengthResultFromFit(S.fit);
            S.lastFitFingerprint = task.fingerprint;
            S.lastLengthFingerprint = "";
        catch ME
            showException('Circle fit failed', ME);
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

        try
            points = currentCurveLengthPoints();
            task = curvature.appState.lengthTask([S.xPix(:), S.yPix(:)], ...
                points, scaleTool.calibration());
            if S.length.ok && S.lastLengthFingerprint == task.fingerprint
                addLog('Curve length already matches current curve and scale.');
                refreshSummary();
                return;
            end

            S.length = curvature.analysisRun.computeCurveLength( ...
                task.lengthPath(:, 1), task.lengthPath(:, 2), task.calibration);
            S.lastLengthFingerprint = task.fingerprint;
        catch ME
            showException('Curve length failed', ME);
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

        [filepath, cancelled] = labkit.ui.runtime.promptOutputFile( ...
            '*.csv', 'Export curvature result CSV', 'curvature_result.csv');
        if cancelled
            addLog('Export result CSV cancelled.');
            return;
        end

        try
            T = curvature.resultFiles.buildResultTable(S.fit, S.imagePath, S.length);
            writetable(T, filepath);
        catch ME
            showException('Could not export result CSV', ME);
            return;
        end
        addLog(sprintf('Exported result CSV: %s', filepath));
    end

    function onExportOverlay(~, ~)
        if isempty(S.image)
            showError('No image loaded', 'Open an image before exporting an overlay.');
            return;
        end

        [filepath, cancelled] = labkit.ui.runtime.promptOutputFile( ...
            '*.png', 'Export overlay PNG', 'curvature_overlay.png');
        if cancelled
            addLog('Export overlay PNG cancelled.');
            return;
        end

        try
            refreshImageOverlay();
            exportgraphics(ui.topAxes, filepath, 'Resolution', 300);
        catch ME
            showException('Could not export overlay PNG', ME);
            return;
        end
        addLog(sprintf('Exported overlay PNG: %s', filepath));
    end

    function refreshAll()
        labkit.ui.control.setValue(ui, 'imageFile', fileValue(S.imagePath));
        refreshScaleReadout();
        refreshImageOverlay();
        refreshSummary();
    end

    function ensureCurveEditor()
        if isempty(S.image)
            return;
        end
        if isempty(S.curveEditor)
            S.curveEditor = labkit.ui.interaction.anchorEditor(imageRuntime, size(S.image), ...
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
        S.fit = curvature.appState.emptyFitResult();
        S.length = curvature.appState.emptyLengthResult();
        clearTaskFingerprints();
        scaleTool.clearScaleBar();
        if curvature.userInterface.isReferenceEditReason(reason)
            refreshScaleReadout();
            refreshSummary();
        else
            refreshAll();
        end
        syncRuntimeState();
    end

    function onScaleBarSettingsChanged(~, ~)
        refreshAll();
        syncRuntimeState();
    end

    function refreshImageOverlayCallback(~, ~)
        refreshImageOverlay();
    end

    function clearTaskFingerprints()
        S.lastFitFingerprint = "";
        S.lastLengthFingerprint = "";
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

    function syncRuntimeState()
        if isempty(fig) || ~isvalid(fig) || ...
                ~isappdata(fig, 'labkitUiAppRuntime')
            return;
        end
        runtime = getappdata(fig, 'labkitUiAppRuntime');
        runtime.state = S;
        setappdata(fig, 'labkitUiAppRuntime', runtime);
    end

    function updateModeControls()
        hasImage = ~isempty(S.image);
        hasCurve = ~isempty(S.xPix);
        referenceEditActive = scaleTool.isReferenceEditActive();
        editActive = S.curveEditActive || referenceEditActive;

        btnStartCurve.Enable = curvature.userInterface.ternary(hasImage, 'on', 'off');
        btnStartCurve.Text = curvature.userInterface.ternary(S.curveEditActive, ...
            'Finish curve edit', 'Start curve edit');
        scaleTool.setEnabled(struct( ...
            'hasImage', hasImage, ...
            'blockInputs', S.curveEditActive, ...
            'blockPlacement', editActive));

        btnUndoPoint.Enable = curvature.userInterface.ternary(hasCurve && ~referenceEditActive, 'on', 'off');
        btnClearCurve.Enable = curvature.userInterface.ternary(hasCurve && ~referenceEditActive, 'on', 'off');
        chkDensify.Enable = curvature.userInterface.ternary(~editActive, 'on', 'off');
        edtDenseN.Enable = curvature.userInterface.ternary(~editActive, 'on', 'off');
        chkShowDense.Enable = curvature.userInterface.ternary(S.fit.ok && ~editActive, 'on', 'off');
        btnFit.Enable = curvature.userInterface.ternary(numel(S.xPix) >= 3 && ~editActive, 'on', 'off');
        btnMeasureLength.Enable = curvature.userInterface.ternary(numel(S.xPix) >= 2 && ~editActive, 'on', 'off');
        btnExportCSV.Enable = curvature.userInterface.ternary((S.fit.ok || S.length.ok) && ~editActive, 'on', 'off');
        btnExportOverlay.Enable = curvature.userInterface.ternary(hasImage && ~editActive, 'on', 'off');
    end

    function refreshImageOverlay()
        ax = ui.topAxes;
        labkit.ui.plot.clear(ax, "ResetScale", true);

        if isempty(S.image)
            title(ax, 'Image + Circle Fit');
            axis(ax, 'normal');
            xlim(ax, [0 1]);
            ylim(ax, [0 1]);
            return;
        end

        hImage = labkit.ui.plot.image(ui, 'imageAxes', S.image, ...
            "title", "Image + Circle Fit", ...
            "options", struct('clearAxes', false));
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
    end

    function plotStaticCurveAnchors(ax)
        points = [S.xPix(:), S.yPix(:)];
        curve = points;
        if ~isempty(S.curveEditor)
            curve = S.curveEditor.curvePoints();
        end
        curvature.userInterface.plotStaticCurveAnchors(ax, points, curve, S.fit, chkShowDense.Value);
    end

    function refreshSummary()
        summary = curvature.userInterface.summaryViewData(S.imagePath, S.xPix, S.fit, ...
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
        labkit.ui.control.appendLog(ui, 'appLog', message);
        debugLog.append(message);
    end

    function setupDebugSamples()
        try
            pack = curvature.debug.writeSamplePack(debugLog);
            addLog(sprintf('Debug sample files: %s', char(pack.sampleFolder)));
            addLog(sprintf('Debug output folder: %s', char(pack.outputFolder)));
        catch ME
            debugLog.reportException('curvature', 'Debug sample setup failed', ME);
            addLog(sprintf('Debug sample setup failed: %s', ME.message));
        end
    end

    function showError(titleText, message)
        addLog(sprintf('%s: %s', titleText, message));
        labkit.ui.runtime.showAlert(fig, message, titleText);
    end

    function showException(titleText, exception)
        debugLog.reportException('curvature', titleText, exception);
        showError(titleText, exception.message);
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
