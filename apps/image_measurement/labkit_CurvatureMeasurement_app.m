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
    S.curveEditor = [];
    S.scaleEditor = [];
    S.scaleEditActive = false;
    S.curveEditActive = false;
    S.curveStyle = "Curve";
    S.fit = emptyFitResult();

    workbenchOpts = struct( ...
        'rightTitle', 'Measurement Preview', ...
        'rightGridSize', [1 1], ...
        'rightRowHeight', {{'1x'}});
    workbenchOpts.tabs = [ ...
        labkit.ui.tabSpec('filesAnalysis', 'Files + Analysis', [4 1], ...
            {140, 365, 205, 175}, ...
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

    imagePanel = labkit.ui.createPanelGrid(layFA, 'Image', 1, [3 2], ...
        struct('rowHeight', {{'fit', 'fit', 'fit'}}, ...
        'columnWidth', {{145, '1x'}}));
    imageGrid = imagePanel.grid;

    btnOpenImage = uibutton(imageGrid, 'Text', 'Open image', ...
        'ButtonPushedFcn', @onOpenImage);
    btnOpenImage.Layout.Row = 1;
    btnOpenImage.Layout.Column = [1 2];

    txtImage = uieditfield(imageGrid, 'text', 'Editable', 'off', ...
        'Value', 'No image loaded');
    txtImage.Layout.Row = 2;
    txtImage.Layout.Column = [1 2];

    txtPointCount = uieditfield(imageGrid, 'text', 'Editable', 'off', ...
        'Value', 'Points: 0');
    txtPointCount.Layout.Row = 3;
    txtPointCount.Layout.Column = [1 2];

    editPanel = labkit.ui.createPanelGrid(layFA, 'Curve + Scale Editing', 2, [8 2], ...
        struct('rowHeight', {{'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'}}, ...
        'columnWidth', {{145, '1x'}}));
    editGrid = editPanel.grid;

    btnStartCurve = uibutton(editGrid, 'Text', 'Start curve edit', ...
        'ButtonPushedFcn', @onStartCurveEdit);
    btnStartCurve.Layout.Row = 1;
    btnStartCurve.Layout.Column = [1 2];

    [lblCurveStyle, ddCurveStyle] = labkit.ui.createLabeledDropdown(editGrid, ...
        'Display:', ...
        'Items', {'Curve', 'Straight lines'}, ...
        'Value', 'Curve', ...
        'ValueChangedFcn', @onCurveStyleChanged);
    lblCurveStyle.Layout.Row = 2;
    lblCurveStyle.Layout.Column = 1;
    ddCurveStyle.Layout.Row = 2;
    ddCurveStyle.Layout.Column = 2;

    btnUndoPoint = uibutton(editGrid, 'Text', 'Undo last point', ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @onUndoCurvePoint);
    btnUndoPoint.Layout.Row = 3;
    btnUndoPoint.Layout.Column = 1;
    btnClearCurve = uibutton(editGrid, 'Text', 'Clear curve', ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @onClearCurve);
    btnClearCurve.Layout.Row = 3;
    btnClearCurve.Layout.Column = 2;

    btnMeasureScale = uibutton(editGrid, 'Text', 'Measure scale bar', ...
        'ButtonPushedFcn', @onMeasureScale);
    btnMeasureScale.Layout.Row = 4;
    btnMeasureScale.Layout.Column = [1 2];

    [lblScaleLen, edtScaleLen] = labkit.ui.createLabeledEditField(editGrid, ...
        'Scale bar length (mm):', 'numeric', 'Value', 5, 'Limits', [0 Inf], ...
        'ValueChangedFcn', @(~,~) refreshScaleReadout());
    lblScaleLen.Layout.Row = 5;
    lblScaleLen.Layout.Column = 1;
    edtScaleLen.Layout.Row = 5;
    edtScaleLen.Layout.Column = 2;

    [lblManualScale, edtManualScale] = labkit.ui.createLabeledEditField(editGrid, ...
        'Manual px/mm:', 'numeric', 'Value', 0, 'Limits', [0 Inf], ...
        'ValueChangedFcn', @(~,~) refreshScaleReadout());
    lblManualScale.Layout.Row = 6;
    lblManualScale.Layout.Column = 1;
    edtManualScale.Layout.Row = 6;
    edtManualScale.Layout.Column = 2;

    [txtRawPx, lblRawPx] = labkit.ui.createReadOnlyInfoRow(editGrid, 7, 'Raw scale px:');
    [txtPxPerMm, lblPxPerMm] = labkit.ui.createReadOnlyInfoRow(editGrid, 8, 'Computed px/mm:');
    lblRawPx.HorizontalAlignment = 'right';
    lblPxPerMm.HorizontalAlignment = 'right';

    fitPanel = labkit.ui.createPanelGrid(layFA, 'Fit + Export', 3, [6 2], ...
        struct('rowHeight', {{'fit', 'fit', 'fit', 'fit', 'fit', 'fit'}}, ...
        'columnWidth', {{145, '1x'}}));
    fitGrid = fitPanel.grid;

    chkDensify = uicheckbox(fitGrid, 'Text', 'Densify before circle fit', 'Value', true);
    chkDensify.Layout.Row = 1;
    chkDensify.Layout.Column = [1 2];

    [lblDenseN, edtDenseN] = labkit.ui.createLabeledEditField(fitGrid, ...
        'Dense point count:', 'numeric', 'Value', 300, 'Limits', [3 Inf]);
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

    btnExportCSV = uibutton(fitGrid, 'Text', 'Export result CSV', ...
        'ButtonPushedFcn', @onExportCSV);
    btnExportCSV.Layout.Row = 5;
    btnExportCSV.Layout.Column = [1 2];
    btnExportOverlay = uibutton(fitGrid, 'Text', 'Export overlay PNG', ...
        'ButtonPushedFcn', @onExportOverlay);
    btnExportOverlay.Layout.Row = 6;
    btnExportOverlay.Layout.Column = [1 2];

    notePanel = labkit.ui.createPanelGrid(layFA, 'Workflow Notes', 4, [1 1], ...
        struct('rowHeight', {{'1x'}}, 'columnWidth', {{'1x'}}));
    txtNotes = uitextarea(notePanel.grid, 'Editable', 'off');
    txtNotes.Value = { ...
        '1. Open an image and start curve editing.', ...
        '2. Double-click blank image space to add/insert points; drag points to move; double-click a point to delete it.', ...
        '3. Measure the scale bar or enter a manual px/mm value.', ...
        '4. Finish active edit modes before fitting or exporting.'};

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
        S.scaleEditActive = false;
        S.curveEditActive = false;
        if ~isempty(S.curveEditor)
            S.curveEditor.delete();
        end
        S.curveEditor = [];
        if ~isempty(S.scaleEditor)
            S.scaleEditor.delete();
        end
        S.scaleEditor = [];
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

        if S.curveEditActive
            S.curveEditActive = false;
            if ~isempty(S.curveEditor)
                S.curveEditor.setActive(false);
            end
            addLog('Finished curve edit.');
            refreshAll();
            return;
        end

        S.scaleEditActive = false;
        if ~isempty(S.scaleEditor)
            S.scaleEditor.setActive(false);
        end
        S.curveEditActive = true;
        S.curveStyle = string(ddCurveStyle.Value);
        ensureCurveEditor();
        S.curveEditor.start([S.xPix(:), S.yPix(:)]);
        S.fit = emptyFitResult();
        addLog('Started curve edit. Double-click blank image space to add/insert points; drag points to move; double-click a point to delete it.');
        refreshAll();
    end

    function onCurveStyleChanged(~, ~)
        S.curveStyle = string(ddCurveStyle.Value);
        if ~isempty(S.curveEditor)
            S.curveEditor.setStyle(S.curveStyle);
        end
        S.fit = emptyFitResult();
        refreshAll();
    end

    function onCurveEditorChanged(points, reason)
        S.xPix = points(:, 1);
        S.yPix = points(:, 2);
        S.fit = emptyFitResult();
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
            refreshAll();
        end
        addLog('Cleared curve points.');
    end

    function onMeasureScale(~, ~)
        if isempty(S.image)
            showError('No image loaded', 'Open an image before measuring a scale bar.');
            return;
        end

        if S.scaleEditActive
            S.scaleEditActive = false;
            if ~isempty(S.scaleEditor)
                S.scaleEditor.setActive(false);
            end
            addLog('Finished scale-bar edit.');
            refreshAll();
            return;
        end

        S.curveEditActive = false;
        if ~isempty(S.curveEditor)
            S.curveEditor.setActive(false);
        end
        S.scaleEditActive = true;
        ensureScaleEditor();
        if isempty(S.scaleLine)
            S.scaleEditor.start(zeros(0, 2));
        else
            S.scaleEditor.start(S.scaleLine);
        end
        S.fit = emptyFitResult();
        addLog('Started scale-bar edit. Double-click two endpoints, then drag endpoints to refine.');
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
                'style', S.curveStyle, ...
                'onChanged', @onCurveEditorChanged));
        else
            S.curveEditor.setImageSize(size(S.image));
            S.curveEditor.setStyle(S.curveStyle);
        end
    end

    function ensureScaleEditor()
        if isempty(S.image)
            return;
        end
        if isempty(S.scaleEditor)
            S.scaleEditor = labkit.ui.createAnchorCurveEditor(ui.topAxes, size(S.image), ...
                struct('figure', fig, ...
                'closed', false, ...
                'style', 'Straight lines', ...
                'maxPoints', 2, ...
                'onChanged', @onScaleEditorChanged));
        else
            S.scaleEditor.setImageSize(size(S.image));
            S.scaleEditor.setStyle('Straight lines');
        end
    end

    function onScaleEditorChanged(points, ~)
        S.scaleLine = points;
        if size(points, 1) == 2
            rawpx = hypot(points(2, 1) - points(1, 1), ...
                points(2, 2) - points(1, 2));
            if rawpx > 0
                S.rawpx = rawpx;
            else
                S.rawpx = NaN;
            end
        else
            S.rawpx = NaN;
        end
        S.fit = emptyFitResult();
        refreshScaleReadout();
        refreshSummary();
    end

    function updateCurveGraphics()
        if ~isempty(S.curveEditor)
            S.curveEditor.refresh();
        end
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

    function updateModeControls()
        hasImage = ~isempty(S.image);
        hasCurve = ~isempty(S.xPix);
        editActive = S.curveEditActive || S.scaleEditActive;

        btnStartCurve.Enable = ternary(hasImage, 'on', 'off');
        btnMeasureScale.Enable = ternary(hasImage, 'on', 'off');
        btnStartCurve.Text = ternary(S.curveEditActive, ...
            'Finish curve edit', 'Start curve edit');
        btnMeasureScale.Text = ternary(S.scaleEditActive, ...
            'Finish scale-bar edit', 'Measure scale bar');

        ddCurveStyle.Enable = ternary(hasImage && ~S.scaleEditActive, 'on', 'off');
        edtScaleLen.Enable = ternary(hasImage && ~S.curveEditActive, 'on', 'off');
        edtManualScale.Enable = ternary(hasImage && ~S.curveEditActive, 'on', 'off');

        btnUndoPoint.Enable = ternary(hasCurve && ~S.scaleEditActive, 'on', 'off');
        btnClearCurve.Enable = ternary(hasCurve && ~S.scaleEditActive, 'on', 'off');
        chkDensify.Enable = ternary(~editActive, 'on', 'off');
        edtDenseN.Enable = ternary(~editActive, 'on', 'off');
        chkShowDense.Enable = ternary(S.fit.ok && ~editActive, 'on', 'off');
        btnFit.Enable = ternary(numel(S.xPix) >= 3 && ~editActive, 'on', 'off');
        btnExportCSV.Enable = ternary(S.fit.ok && ~editActive, 'on', 'off');
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

        hImage = image(ax, S.image);
        axis(ax, 'image');
        ax.XLim = [0.5, size(S.image, 2) + 0.5];
        ax.YLim = [0.5, size(S.image, 1) + 0.5];
        ax.YDir = 'reverse';
        ax.XTick = [];
        ax.YTick = [];
        enableImageNavigation(ax);
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
        elseif S.scaleEditActive
            ensureScaleEditor();
            S.scaleEditor.setBackground(hImage);
            S.scaleEditor.refresh();
        else
            ax.ButtonDownFcn = [];
            hImage.HitTest = 'off';
            hImage.PickableParts = 'none';
            plotStaticCurveAnchors(ax);
            if ~isempty(S.scaleLine)
                plot(ax, S.scaleLine(:, 1), S.scaleLine(:, 2), 'c-', ...
                    'LineWidth', 3, ...
                    'HitTest', 'off', ...
                    'DisplayName', 'scale bar');
            end
        end

        if ~isempty(S.scaleLine) && isfinite(S.rawpx)
            text(ax, mean(S.scaleLine(:, 1)), mean(S.scaleLine(:, 2)) - 12, ...
                sprintf('%.3g px', S.rawpx), ...
                'Color', 'c', 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom');
        end
        hold(ax, 'off');
    end

    function plotStaticCurveAnchors(ax)
        points = [S.xPix(:), S.yPix(:)];
        if isempty(points)
            return;
        end

        curve = points;
        if strcmp(S.curveStyle, "Curve") && ~isempty(S.curveEditor)
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
            if S.curveEditActive
                txtDetails.Value = {'Curve edit active. Double-click blank image space to add/insert points, drag points to move them, double-click a point to delete it. Use the scroll wheel over the image to zoom.'};
            elseif S.scaleEditActive
                txtDetails.Value = {'Scale-bar edit active. Double-click two scale-bar endpoints or drag existing endpoints; the scroll wheel remains available for zoom.'};
            elseif numel(S.xPix) >= 3
                txtDetails.Value = {'Curve points are ready. Fit curvature to compute radius and curvature.'};
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
