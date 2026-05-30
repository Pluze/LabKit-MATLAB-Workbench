function varargout = labkit_CurvatureMeasurement_app(varargin)
%LABKIT_CURVATUREMEASUREMENT_APP Measure curve radius and curvature from images.

    if nargin > 0
        [handled, outputs] = handleCurvatureTestRequest(varargin, nargout);
        if handled
            varargout = outputs;
            return;
        end
        error('labkit_CurvatureMeasurement_app:UnsupportedInput', ...
            'labkit_CurvatureMeasurement_app does not accept input arguments.');
    end
    if nargout > 1
        error('labkit_CurvatureMeasurement_app:TooManyOutputs', ...
            'labkit_CurvatureMeasurement_app returns at most the app figure handle.');
    end

    S = struct();
    S.imagePath = "";
    S.image = [];
    S.xPix = [];
    S.yPix = [];
    S.rawpx = NaN;
    S.scaleLine = [];
    S.curveLine = [];
    S.anchorLine = [];
    S.dragIndex = [];
    S.curveEditActive = false;
    S.curveStyle = "Curve";
    S.fit = emptyFitResult();

    workbenchOpts = struct( ...
        'rightKind', 'dualPlot', ...
        'rightTitle', 'Measurement Preview', ...
        'topPlotTitle', 'Image + Circle Fit', ...
        'bottomPlotTitle', 'Radial Residuals', ...
        'showPlotControls', false);
    workbenchOpts.tabs = [ ...
        labkit.ui.tabSpec('filesAnalysis', 'Files + Analysis', [4 1], ...
            {250, 330, 140, 175}, ...
            struct('resizeRows', [1 2 3], ...
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

    imagePanel = labkit.ui.createPanelGrid(layFA, 'Image + Curve Points', 1, [6 2], ...
        struct('rowHeight', {{'fit', 'fit', 'fit', 'fit', 'fit', 'fit'}}, ...
        'columnWidth', {{150, '1x'}}));
    imageGrid = imagePanel.grid;

    btnOpenImage = uibutton(imageGrid, 'Text', 'Open image', ...
        'ButtonPushedFcn', @onOpenImage);
    btnOpenImage.Layout.Row = 1;
    btnOpenImage.Layout.Column = [1 2];

    txtImage = uieditfield(imageGrid, 'text', 'Editable', 'off', ...
        'Value', 'No image loaded');
    txtImage.Layout.Row = 2;
    txtImage.Layout.Column = [1 2];

    btnStartCurve = uibutton(imageGrid, 'Text', 'Start curve edit', ...
        'ButtonPushedFcn', @onStartCurveEdit);
    btnStartCurve.Layout.Row = 3;
    btnStartCurve.Layout.Column = [1 2];

    [lblCurveStyle, ddCurveStyle] = labkit.ui.createLabeledDropdown(imageGrid, ...
        'Display:', ...
        'Items', {'Curve', 'Straight lines'}, ...
        'Value', 'Curve', ...
        'ValueChangedFcn', @onCurveStyleChanged);
    lblCurveStyle.Layout.Row = 4;
    lblCurveStyle.Layout.Column = 1;
    ddCurveStyle.Layout.Row = 4;
    ddCurveStyle.Layout.Column = 2;

    btnUndoPoint = uibutton(imageGrid, 'Text', 'Undo last point', ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @onUndoCurvePoint);
    btnUndoPoint.Layout.Row = 5;
    btnUndoPoint.Layout.Column = 1;
    btnClearCurve = uibutton(imageGrid, 'Text', 'Clear curve', ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @onClearCurve);
    btnClearCurve.Layout.Row = 5;
    btnClearCurve.Layout.Column = 2;

    txtPointCount = uieditfield(imageGrid, 'text', 'Editable', 'off', ...
        'Value', 'Points: 0');
    txtPointCount.Layout.Row = 6;
    txtPointCount.Layout.Column = [1 2];

    fitPanel = labkit.ui.createPanelGrid(layFA, 'Scale + Circle Fit', 2, [8 2], ...
        struct('rowHeight', {{'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'}}, ...
        'columnWidth', {{150, '1x'}}));
    fitGrid = fitPanel.grid;

    [lblScaleLen, edtScaleLen] = labkit.ui.createLabeledEditField(fitGrid, ...
        'Scale bar length (mm):', 'numeric', 'Value', 5, 'Limits', [0 Inf], ...
        'ValueChangedFcn', @(~,~) refreshScaleReadout());
    lblScaleLen.Layout.Row = 1;
    lblScaleLen.Layout.Column = 1;
    edtScaleLen.Layout.Row = 1;
    edtScaleLen.Layout.Column = 2;

    [lblManualScale, edtManualScale] = labkit.ui.createLabeledEditField(fitGrid, ...
        'Manual px/mm:', 'numeric', 'Value', 0, 'Limits', [0 Inf], ...
        'ValueChangedFcn', @(~,~) refreshScaleReadout());
    lblManualScale.Layout.Row = 2;
    lblManualScale.Layout.Column = 1;
    edtManualScale.Layout.Row = 2;
    edtManualScale.Layout.Column = 2;

    btnMeasureScale = uibutton(fitGrid, 'Text', 'Measure scale bar', ...
        'ButtonPushedFcn', @onMeasureScale);
    btnMeasureScale.Layout.Row = 3;
    btnMeasureScale.Layout.Column = [1 2];

    [txtRawPx, lblRawPx] = labkit.ui.createReadOnlyInfoRow(fitGrid, 4, 'Raw scale px:');
    [txtPxPerMm, lblPxPerMm] = labkit.ui.createReadOnlyInfoRow(fitGrid, 5, 'Computed px/mm:');
    lblRawPx.HorizontalAlignment = 'right';
    lblPxPerMm.HorizontalAlignment = 'right';

    chkDensify = uicheckbox(fitGrid, 'Text', 'Densify before circle fit', 'Value', true);
    chkDensify.Layout.Row = 6;
    chkDensify.Layout.Column = [1 2];

    [lblDenseN, edtDenseN] = labkit.ui.createLabeledEditField(fitGrid, ...
        'Dense point count:', 'numeric', 'Value', 300, 'Limits', [3 Inf]);
    lblDenseN.Layout.Row = 7;
    lblDenseN.Layout.Column = 1;
    edtDenseN.Layout.Row = 7;
    edtDenseN.Layout.Column = 2;

    btnFit = uibutton(fitGrid, 'Text', 'Fit circle + curvature', ...
        'ButtonPushedFcn', @onFitCurvature);
    btnFit.Layout.Row = 8;
    btnFit.Layout.Column = [1 2];

    exportPanel = labkit.ui.createPanelGrid(layFA, 'Exports', 3, [2 1], ...
        struct('rowHeight', {{'fit', 'fit'}}));
    exportGrid = exportPanel.grid;
    btnExportCSV = uibutton(exportGrid, 'Text', 'Export result CSV', ...
        'ButtonPushedFcn', @onExportCSV);
    btnExportCSV.Layout.Row = 1;
    btnExportOverlay = uibutton(exportGrid, 'Text', 'Export overlay PNG', ...
        'ButtonPushedFcn', @onExportOverlay);
    btnExportOverlay.Layout.Row = 2;

    notePanel = labkit.ui.createPanelGrid(layFA, 'Workflow Notes', 4, [1 1], ...
        struct('rowHeight', {{'1x'}}, 'columnWidth', {{'1x'}}));
    txtNotes = uitextarea(notePanel.grid, 'Editable', 'off');
    txtNotes.Value = { ...
        '1. Open an image and start curve editing.', ...
        '2. Double-click blank space to add/insert points; drag points to move; double-click a point to delete it.', ...
        '3. Measure the scale bar or enter a manual px/mm value.', ...
        '4. Fit the circle, inspect residuals, then export the result CSV or overlay PNG.'};

    resultTable = uitable(laySR, ...
        'ColumnName', {'Metric', 'Value'}, ...
        'Data', initialResultTable());
    resultTable.Layout.Row = 1;

    txtDetails = uitextarea(laySR, 'Editable', 'off');
    txtDetails.Layout.Row = labkit.ui.layoutRow(laySR, 2);
    txtDetails.Value = {'No curvature result yet.'};

    logUi = labkit.ui.createLogPanel(layLog, 1, {'Ready.'});
    txtLog = logUi.textArea;

    resetAxes();
    refreshScaleReadout();

    if nargout == 1
        varargout{1} = fig;
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
        S.rawpx = NaN;
        S.scaleLine = [];
        S.dragIndex = [];
        S.curveEditActive = false;
        S.fit = emptyFitResult();
        txtImage.Value = char(filepath);
        addLog(sprintf('Loaded image: %s', filepath));
        refreshAll();
    end

    function onStartCurveEdit(~, ~)
        if isempty(S.image)
            showError('No image loaded', 'Open an image before editing curve points.');
            return;
        end

        S.curveEditActive = true;
        S.curveStyle = string(ddCurveStyle.Value);
        S.fit = emptyFitResult();
        addLog('Started curve edit. Double-click blank space to add/insert points; drag points to move; double-click a point to delete it.');
        refreshAll();
    end

    function onCurveStyleChanged(~, ~)
        S.curveStyle = string(ddCurveStyle.Value);
        S.fit = emptyFitResult();
        refreshAll();
    end

    function onCurveAxesClicked(~, ~)
        if ~S.curveEditActive || isempty(S.image)
            return;
        end

        point = ui.topAxes.CurrentPoint;
        x = point(1, 1);
        y = point(1, 2);
        if ~insideImageBounds(x, y, size(S.image))
            return;
        end

        idx = nearestCurveAnchor(x, y);
        if strcmp(fig.SelectionType, 'open')
            if ~isempty(idx)
                removeCurveAnchor(idx);
                addLog(sprintf('Deleted curve point %d.', idx));
            else
                addOrInsertCurveAnchor([x y]);
                addLog(sprintf('Added curve point. Points: %d.', numel(S.xPix)));
            end
            S.fit = emptyFitResult();
            refreshAll();
            return;
        end

        if ~isempty(idx)
            S.dragIndex = idx;
            updateDraggedCurveAnchor();
            fig.WindowButtonMotionFcn = @onCurveAnchorDragged;
            fig.WindowButtonUpFcn = @onCurveAnchorReleased;
        end
    end

    function onCurveAnchorDragged(~, ~)
        updateDraggedCurveAnchor();
    end

    function onCurveAnchorReleased(~, ~)
        updateDraggedCurveAnchor();
        fig.WindowButtonMotionFcn = '';
        fig.WindowButtonUpFcn = '';
        S.dragIndex = [];
        S.fit = emptyFitResult();
        refreshAll();
    end

    function updateDraggedCurveAnchor()
        if isempty(S.dragIndex) || S.dragIndex > numel(S.xPix)
            return;
        end
        point = ui.topAxes.CurrentPoint;
        x = min(max(point(1, 1), 0.5), size(S.image, 2) + 0.5);
        y = min(max(point(1, 2), 0.5), size(S.image, 1) + 0.5);
        S.xPix(S.dragIndex) = x;
        S.yPix(S.dragIndex) = y;
        S.fit = emptyFitResult();
        updateCurveGraphics();
        refreshSummary();
    end

    function onUndoCurvePoint(~, ~)
        if isempty(S.xPix)
            return;
        end
        S.xPix(end) = [];
        S.yPix(end) = [];
        S.fit = emptyFitResult();
        addLog('Removed the last curve point.');
        refreshAll();
    end

    function onClearCurve(~, ~)
        S.xPix = [];
        S.yPix = [];
        S.dragIndex = [];
        S.fit = emptyFitResult();
        addLog('Cleared curve points.');
        refreshAll();
    end

    function onMeasureScale(~, ~)
        if isempty(S.image)
            showError('No image loaded', 'Open an image before measuring a scale bar.');
            return;
        end

        refreshImageOverlay();
        addLog('Drawing scale bar. Drag endpoints, then double-click to finish.');
        previousButtonDown = ui.topAxes.ButtonDownFcn;
        ui.topAxes.ButtonDownFcn = [];
        try
            roi = drawline(ui.topAxes, 'Color', 'c', 'LineWidth', 2);
            wait(roi);
            pos = roi.Position;
            delete(roi);
            ui.topAxes.ButtonDownFcn = previousButtonDown;
        catch ME
            ui.topAxes.ButtonDownFcn = previousButtonDown;
            showError('Scale-bar drawing failed', ME.message);
            return;
        end

        if size(pos, 1) < 2
            addLog('Scale measurement cancelled.');
            refreshImageOverlay();
            return;
        end

        rawpx = abs(pos(2, 1) - pos(1, 1));
        if rawpx <= 0
            showError('Invalid scale bar', 'The scale bar must have nonzero horizontal pixel length.');
            return;
        end

        y0 = mean(pos(:, 2));
        S.scaleLine = [pos(1, 1), y0; pos(2, 1), y0];
        S.rawpx = rawpx;
        S.fit = emptyFitResult();
        addLog(sprintf('Measured scale bar: %.3f px horizontal length.', rawpx));
        refreshAll();
    end

    function onFitCurvature(~, ~)
        if numel(S.xPix) < 3
            showError('Not enough points', 'At least 3 curve points are required to fit curvature.');
            return;
        end

        try
            S.fit = computeCurvatureFit(S.xPix, S.yPix, S.rawpx, ...
                edtScaleLen.Value, edtManualScale.Value, ...
                chkDensify.Value, round(edtDenseN.Value));
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

    function onExportCSV(~, ~)
        if ~S.fit.ok
            showError('No fit result', 'Fit curvature before exporting a result CSV.');
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
            T = buildCurvatureResultTable(S.fit, S.imagePath);
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
        refreshResidualPlot();
        refreshSummary();
    end

    function addOrInsertCurveAnchor(newPoint)
        points = [S.xPix(:), S.yPix(:)];
        points = addOrInsertOpenCurveAnchor(points, newPoint, ui.topAxes);
        S.xPix = points(:, 1);
        S.yPix = points(:, 2);
    end

    function removeCurveAnchor(idx)
        S.xPix(idx) = [];
        S.yPix(idx) = [];
    end

    function idx = nearestCurveAnchor(x, y)
        idx = [];
        if isempty(S.xPix)
            return;
        end
        dx = S.xPix(:) - x;
        dy = S.yPix(:) - y;
        [dist, bestIdx] = min(hypot(dx, dy));
        xSpan = max(1, diff(ui.topAxes.XLim));
        ySpan = max(1, diff(ui.topAxes.YLim));
        threshold = 0.025 * max(xSpan, ySpan);
        if dist <= threshold
            idx = bestIdx;
        end
    end

    function updateCurveGraphics()
        refreshImageOverlay();
    end

    function refreshScaleReadout()
        if isfinite(S.rawpx)
            txtRawPx.Value = sprintf('%.6g', S.rawpx);
        else
            txtRawPx.Value = '-';
        end

        pxPerMm = scalePixelsPerMm(S.rawpx, edtScaleLen.Value, edtManualScale.Value);
        if pxPerMm > 0
            txtPxPerMm.Value = sprintf('%.6g', pxPerMm);
        else
            txtPxPerMm.Value = '-';
        end
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

        hImage = image(ax, S.image);
        hImage.HitTest = 'off';
        axis(ax, 'image');
        ax.XLim = [0.5, size(S.image, 2) + 0.5];
        ax.YLim = [0.5, size(S.image, 1) + 0.5];
        ax.YDir = 'reverse';
        ax.XTick = [];
        ax.YTick = [];
        enableImageNavigation(ax);
        if S.curveEditActive
            ax.ButtonDownFcn = @onCurveAxesClicked;
        else
            ax.ButtonDownFcn = [];
        end
        hold(ax, 'on');

        if ~isempty(S.xPix)
            curve = curveDisplayPoints([S.xPix(:), S.yPix(:)], size(S.image), S.curveStyle);
            if ~isempty(curve)
                plot(ax, curve(:, 1), curve(:, 2), '-', ...
                    'Color', [1 0.9 0], ...
                    'LineWidth', 1.5, ...
                    'HitTest', 'off', ...
                    'DisplayName', 'curve');
            end
            plot(ax, S.xPix, S.yPix, 'o', ...
                'Color', [0 0.45 0.95], ...
                'MarkerFaceColor', [1 0.9 0], ...
                'LineWidth', 1.4, 'MarkerSize', 12, ...
                'HitTest', 'off', ...
                'DisplayName', 'curve points');
        end

        if ~isempty(S.scaleLine)
            plot(ax, S.scaleLine(:, 1), S.scaleLine(:, 2), 'c-', ...
                'LineWidth', 3, ...
                'HitTest', 'off', ...
                'DisplayName', 'scale bar');
            text(ax, mean(S.scaleLine(:, 1)), mean(S.scaleLine(:, 2)) - 12, ...
                sprintf('%.3g px', S.rawpx), ...
                'Color', 'c', 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom');
        end

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
        hold(ax, 'off');
    end

    function refreshResidualPlot()
        ax = ui.bottomAxes;
        cla(ax);
        if ~S.fit.ok
            title(ax, 'Radial Residuals');
            xlim(ax, [0 1]);
            ylim(ax, [0 1]);
            return;
        end

        n = numel(S.fit.residuals_show);
        plot(ax, 1:n, S.fit.residuals_show, 'o-', 'LineWidth', 1.2);
        grid(ax, 'on');
        xlabel(ax, 'Point index');
        ylabel(ax, sprintf('Residual (%s)', S.fit.unitLen));
        title(ax, 'Radial residual from fitted circle');
    end

    function refreshSummary()
        txtPointCount.Value = sprintf('Points: %d', numel(S.xPix));
        btnUndoPoint.Enable = ternary(~isempty(S.xPix), 'on', 'off');
        btnClearCurve.Enable = ternary(~isempty(S.xPix), 'on', 'off');
        if S.fit.ok
            resultTable.Data = fitResultTableData(S.fit);
            txtDetails.Value = { ...
                sprintf('Image: %s', emptyDash(S.imagePath)), ...
                sprintf('Center: xc = %.6f px, yc = %.6f px', S.fit.xc_px, S.fit.yc_px), ...
                sprintf('Radius: %.6f %s', S.fit.R_show, S.fit.unitLen), ...
                sprintf('Curvature: %.6f %s', S.fit.kappa_show, S.fit.unitK), ...
                sprintf('RMSE: %.6f %s', S.fit.rmse_show, S.fit.unitLen), ...
                sprintf('rawpx = %s; px/mm = %.6g', mat2str(S.fit.rawpx), S.fit.px_per_mm)};
        else
            resultTable.Data = initialResultTable();
            if numel(S.xPix) >= 3
                txtDetails.Value = {'Curve points are ready. Fit curvature to compute radius and curvature.'};
            elseif S.curveEditActive
                txtDetails.Value = {'Curve edit active. Double-click blank space to add/insert points, drag points to move them, double-click a point to delete it.'};
            else
                txtDetails.Value = {'Load an image and start curve editing.'};
            end
        end
    end

    function resetAxes()
        refreshImageOverlay();
        refreshResidualPlot();
        refreshSummary();
    end

    function addLog(message)
        labkit.ui.appendLog(txtLog, message);
    end

    function showError(titleText, message)
        addLog(sprintf('%s: %s', titleText, message));
        uialert(fig, message, titleText);
    end
end

function [handled, outputs] = handleCurvatureTestRequest(args, nout)
    handled = false;
    outputs = {};
    if isempty(args) || ~(ischar(args{1}) || isstring(args{1}))
        return;
    end

    handled = true;
    request = char(args{1});
    switch request
        case '__test_computeCurvatureFit__'
            requireNargout(nout, 1, request);
            opts = struct();
            if numel(args) >= 4
                opts = args{4};
            end
            rawpx = optionValue(opts, 'rawpx', NaN);
            scaleLenMm = optionValue(opts, 'scaleLengthMm', 0);
            manualPxPerMm = optionValue(opts, 'manualPxPerMm', 0);
            doDensify = optionValue(opts, 'doDensify', true);
            denseN = optionValue(opts, 'denseN', 300);
            outputs = {computeCurvatureFit(args{2}, args{3}, rawpx, ...
                scaleLenMm, manualPxPerMm, doDensify, denseN)};
        case '__test_buildCurvatureResultTable__'
            requireNargout(nout, 1, request);
            outputs = {buildCurvatureResultTable(args{2}, string(args{3}))};
        otherwise
            error('labkit_CurvatureMeasurement_app:UnknownTestRequest', ...
                'Unknown test request: %s', request);
    end
end

function fit = computeCurvatureFit(xPix, yPix, rawpx, scaleLengthMm, manualPxPerMm, doDensify, denseN)
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

    xFit = xPix;
    yFit = yPix;
    if doDensify && numel(xPix) >= 5
        [xFit, yFit] = densifyPolyline(xPix, yPix, denseN);
    end

    [xc0, yc0, R0] = circleInitKasa(xFit, yFit);
    [xc, yc, R_px, rmse_px] = fitCircleGeomWithFallback(xFit, yFit, xc0, yc0, R0);
    if ~isfinite(R_px) || R_px <= 0
        error('labkit_CurvatureMeasurement_app:InvalidFit', ...
            'Circle fit produced an invalid radius.');
    end

    pxPerMm = scalePixelsPerMm(rawpx, scaleLengthMm, manualPxPerMm);
    useMM = pxPerMm > 0;
    kappa_px = 1 / R_px;

    if useMM
        unitLen = 'mm';
        unitK = '1/mm';
        R_show = R_px / pxPerMm;
        rmse_show = rmse_px / pxPerMm;
        kappa_show = 1 / R_show;
        residuals_show = radialResiduals(xPix, yPix, xc, yc, R_px) / pxPerMm;
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
    fit.rawpx = rawpx;
    fit.scaleLength_mm = scaleLengthMm;
    fit.px_per_mm = pxPerMm;
    fit.useMM = useMM;
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
end

function pxPerMm = scalePixelsPerMm(rawpx, scaleLengthMm, manualPxPerMm)
    pxPerMm = 0;
    if nargin < 2 || isempty(scaleLengthMm)
        scaleLengthMm = 0;
    end
    if nargin < 3 || isempty(manualPxPerMm)
        manualPxPerMm = 0;
    end

    validateattributes(scaleLengthMm, {'numeric'}, {'scalar', 'finite', 'nonnegative'});
    validateattributes(manualPxPerMm, {'numeric'}, {'scalar', 'finite', 'nonnegative'});

    if scaleLengthMm > 0 && isfinite(rawpx) && rawpx > 0
        pxPerMm = rawpx / scaleLengthMm;
    elseif manualPxPerMm > 0
        pxPerMm = manualPxPerMm;
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

function [xDense, yDense] = densifyPolyline(x, y, denseN)
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

function T = buildCurvatureResultTable(fit, imagePath)
    T = table( ...
        string(imagePath), ...
        fit.xc_px, ...
        fit.yc_px, ...
        fit.R_px, ...
        fit.kappa_per_px, ...
        fit.rmse_px, ...
        fit.rawpx, ...
        fit.scaleLength_mm, ...
        fit.px_per_mm, ...
        fit.R_show, ...
        string(fit.unitLen), ...
        fit.kappa_show, ...
        string(fit.unitK), ...
        fit.rmse_show, ...
        'VariableNames', {'Image', 'CenterX_px', 'CenterY_px', ...
        'Radius_px', 'Curvature_1_per_px', 'RMSE_px', 'RawScale_px', ...
        'ScaleLength_mm', 'PixelsPerMm', 'Radius', 'RadiusUnit', ...
        'Curvature', 'CurvatureUnit', 'RMSE'});
end

function data = initialResultTable()
    data = { ...
        'Radius', '-'; ...
        'Curvature', '-'; ...
        'RMSE', '-'; ...
        'Center X', '-'; ...
        'Center Y', '-'; ...
        'Pixels/mm', '-'};
end

function data = fitResultTableData(fit)
    data = { ...
        'Radius', sprintf('%.6g %s', fit.R_show, fit.unitLen); ...
        'Curvature', sprintf('%.6g %s', fit.kappa_show, fit.unitK); ...
        'RMSE', sprintf('%.6g %s', fit.rmse_show, fit.unitLen); ...
        'Center X', sprintf('%.6f px', fit.xc_px); ...
        'Center Y', sprintf('%.6f px', fit.yc_px); ...
        'Pixels/mm', sprintf('%.6g', fit.px_per_mm)};
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
        'rawpx', NaN, ...
        'scaleLength_mm', 0, ...
        'px_per_mm', 0, ...
        'useMM', false, ...
        'R_show', NaN, ...
        'kappa_show', NaN, ...
        'rmse_show', NaN, ...
        'unitLen', 'px', ...
        'unitK', '1/px', ...
        'residuals_show', [], ...
        'xPix', [], ...
        'yPix', [], ...
        'xFit', [], ...
        'yFit', []);
end

function curve = curveDisplayPoints(points, imageSize, curveStyle)
    if isempty(points)
        curve = [];
        return;
    end
    if size(points, 1) < 3 || strcmp(string(curveStyle), "Straight lines")
        curve = points;
    else
        n = size(points, 1);
        samplesPerSegment = max(12, ceil(240 / max(1, n - 1)));
        curve = zeros((n - 1) * samplesPerSegment + 1, 2);
        out = 1;
        for i = 1:(n - 1)
            p0 = points(max(1, i - 1), :);
            p1 = points(i, :);
            p2 = points(i + 1, :);
            p3 = points(min(n, i + 2), :);
            for k = 0:(samplesPerSegment - 1)
                t = k / samplesPerSegment;
                curve(out, :) = catmullRomPoint(p0, p1, p2, p3, t);
                out = out + 1;
            end
        end
        curve(out, :) = points(end, :);
        curve = curve(1:out, :);
    end
    curve(:, 1) = min(max(curve(:, 1), 0.5), imageSize(2) + 0.5);
    curve(:, 2) = min(max(curve(:, 2), 0.5), imageSize(1) + 0.5);
end

function p = catmullRomPoint(p0, p1, p2, p3, t)
    p = 0.5 .* ((2 .* p1) + ...
        (-p0 + p2) .* t + ...
        (2 .* p0 - 5 .* p1 + 4 .* p2 - p3) .* t.^2 + ...
        (-p0 + 3 .* p1 - 3 .* p2 + p3) .* t.^3);
end

function points = addOrInsertOpenCurveAnchor(points, newPoint, ax)
    n = size(points, 1);
    if n < 2
        points(end+1, :) = newPoint;
        return;
    end

    [segmentIdx, distance] = nearestOpenCurveSegment(points, newPoint);
    xSpan = max(1, diff(ax.XLim));
    ySpan = max(1, diff(ax.YLim));
    threshold = 0.035 * max(xSpan, ySpan);
    if isempty(segmentIdx) || distance > threshold
        points(end+1, :) = newPoint;
        return;
    end

    points = [points(1:segmentIdx, :); newPoint; points((segmentIdx + 1):end, :)];
end

function [segmentIdx, bestDistance] = nearestOpenCurveSegment(points, point)
    segmentIdx = [];
    bestDistance = inf;
    n = size(points, 1);
    if n < 2
        return;
    end
    for k = 1:(n - 1)
        distance = pointSegmentDistance(point, points(k, :), points(k + 1, :));
        if distance < bestDistance
            bestDistance = distance;
            segmentIdx = k;
        end
    end
end

function distance = pointSegmentDistance(point, a, b)
    ab = b - a;
    denom = dot(ab, ab);
    if denom <= eps
        distance = hypot(point(1) - a(1), point(2) - a(2));
        return;
    end
    t = dot(point - a, ab) / denom;
    t = min(max(t, 0), 1);
    projection = a + t .* ab;
    distance = hypot(point(1) - projection(1), point(2) - projection(2));
end

function tf = insideImageBounds(x, y, imageSize)
    tf = isfinite(x) && isfinite(y) && ...
        x >= 0.5 && y >= 0.5 && ...
        x <= imageSize(2) + 0.5 && y <= imageSize(1) + 0.5;
end

function enableImageNavigation(ax)
    try
        enableDefaultInteractivity(ax);
    catch
    end
    try
        ax.Interactions = zoomInteraction;
    catch
    end
    try
        ax.Toolbar.Visible = 'on';
    catch
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

function requireNargout(actual, maxAllowed, request)
    if actual > maxAllowed
        error('labkit_CurvatureMeasurement_app:TooManyOutputs', ...
            '%s returns at most %d output(s).', request, maxAllowed);
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
