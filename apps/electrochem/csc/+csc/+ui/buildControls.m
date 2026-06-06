% Build the CSC app's static shell and controls. Expected caller is
% csc.ui.runApp. Input callbacks is a struct of runner-owned callback handles.
% Output is a struct of UI handles used by the runner. Side effects are limited
% to creating MATLAB UI components in a new figure.
function C = buildControls(callbacks)
%BUILDCONTROLS Create CSC app controls.

    C = struct();

    ui = labkit.ui.app.createShell(struct( ...
        'title', 'Gamry DTA GUI (literature CSC)', ...
        'position', [50 30 1580 950], ...
        'leftWidth', 390, ...
        'options', struct('rightKind', 'dualPlot')));
    C.fig = ui.fig;

    fileLabels = struct( ...
        'panelTitle', 'Files', ...
        'openFiles', 'Open DTA file(s)', ...
        'openFolder', 'Open folder recursively', ...
        'clearAll', 'Clear all', ...
        'export', 'Reload selected', ...
        'loadedText', 'No files loaded');
    fileUi = labkit.ui.view.panel(ui.filesAnalysisGrid, 'files', fileLabels, callbacks);
    C.lbFiles = fileUi.listbox;
    C.txtLoaded = fileUi.loadedText;

    curveUi = labkit.ui.view.section(ui.filesAnalysisGrid, 'Curve', 2, [4 2]);
    gf = curveUi.grid;
    uilabel(gf, 'Text', 'File:', 'HorizontalAlignment', 'right');
    C.txtFile = labkit.ui.view.form(gf, 'readonly');
    C.txtFile.Layout.Row = 1; C.txtFile.Layout.Column = 2;

    uilabel(gf, 'Text', 'Scan rate:', 'HorizontalAlignment', 'right');
    C.txtScan = labkit.ui.view.form(gf, 'readonly');
    C.txtScan.Layout.Row = 2; C.txtScan.Layout.Column = 2;

    uilabel(gf, 'Text', 'Curve:', 'HorizontalAlignment', 'right');
    C.ddCurve = uidropdown(gf, 'Items', {'(none)'}, ...
        'ValueChangedFcn', callbacks.onCurveChanged);
    C.ddCurve.Layout.Row = 3; C.ddCurve.Layout.Column = 2;

    btnAuto = uibutton(gf, 'Text', 'Auto CV + CT', ...
        'ButtonPushedFcn', callbacks.onAutoPresetAndRefresh);
    btnAuto.Layout.Row = 4; btnAuto.Layout.Column = [1 2];

    actionOpts = struct('columnWidth', {{'1x', '1x'}});
    actionUi = labkit.ui.view.section(ui.filesAnalysisGrid, ...
        'Actions', 3, [2 2], actionOpts);
    ga = actionUi.grid;
    btnSwap = uibutton(ga, 'Text', 'Swap Top/Bottom', ...
        'ButtonPushedFcn', callbacks.onSwapPlots);
    btnSwap.Layout.Row = 1; btnSwap.Layout.Column = 1;
    btnCompare = uibutton(ga, 'Text', 'Compare Q / CSC', ...
        'ButtonPushedFcn', callbacks.onRefreshCompare);
    btnCompare.Layout.Row = 1; btnCompare.Layout.Column = 2;
    btnRefresh = uibutton(ga, 'Text', 'Refresh Plots', ...
        'ButtonPushedFcn', callbacks.onRefreshPlotsOnly);
    btnRefresh.Layout.Row = 2; btnRefresh.Layout.Column = 1;
    btnClear = uibutton(ga, 'Text', 'Clear Both', ...
        'ButtonPushedFcn', callbacks.onClearBothAxes);
    btnClear.Layout.Row = 2; btnClear.Layout.Column = 2;

    compUi = labkit.ui.view.section(ui.summaryResultsGrid, ...
        'CSC / Comparison', 1, [8 2]);
    gc = compUi.grid;
    uilabel(gc, 'Text', 'Mode:', 'HorizontalAlignment', 'right');
    C.ddMode = uidropdown(gc, ...
        'Items', {'Full', 'Cathodic', 'Anodic'}, ...
        'Value', 'Full', ...
        'ValueChangedFcn', callbacks.onRefreshCompare);
    C.ddMode.Layout.Row = 1; C.ddMode.Layout.Column = 2;

    uilabel(gc, 'Text', 'Area (cm^2):', 'HorizontalAlignment', 'right');
    C.edArea = uieditfield(gc, 'text', 'Value', '');
    C.edArea.ValueChangedFcn = callbacks.onRefreshCompare;
    C.edArea.Layout.Row = 2; C.edArea.Layout.Column = 2;

    uilabel(gc, 'Text', 'CT charge / CSC:', 'HorizontalAlignment', 'right');
    C.txtQct = labkit.ui.view.form(gc, 'readonly');
    C.txtQct.Layout.Row = 3; C.txtQct.Layout.Column = 2;

    uilabel(gc, 'Text', 'CV charge / CSC:', 'HorizontalAlignment', 'right');
    C.txtQcv = labkit.ui.view.form(gc, 'readonly');
    C.txtQcv.Layout.Row = 4; C.txtQcv.Layout.Column = 2;

    uilabel(gc, 'Text', 'Difference:', 'HorizontalAlignment', 'right');
    C.txtDiff = labkit.ui.view.form(gc, 'readonly');
    C.txtDiff.Layout.Row = 5; C.txtDiff.Layout.Column = 2;

    uilabel(gc, 'Text', 'Relative diff:', 'HorizontalAlignment', 'right');
    C.txtRel = labkit.ui.view.form(gc, 'readonly');
    C.txtRel.Layout.Row = 6; C.txtRel.Layout.Column = 2;

    uilabel(gc, 'Text', 'max|dt-|dV|/v|:', 'HorizontalAlignment', 'right');
    C.txtDtErr = labkit.ui.view.form(gc, 'readonly');
    C.txtDtErr.Layout.Row = 7; C.txtDtErr.Layout.Column = 2;

    C.lblStatus = uilabel(gc, 'Text', 'Ready');
    C.lblStatus.Layout.Row = 8; C.lblStatus.Layout.Column = [1 2];
    C.lblStatus.FontWeight = 'bold';

    logUi = labkit.ui.view.panel(ui.logGrid, 'log', 1, {'GUI started.'});
    C.txtLog = logUi.textArea;
    C.txtLog.Value = {'GUI started.'};

    topPlotDefaults = struct('x', '(none)', 'y', '(none)', 'grid', true);
    bottomPlotDefaults = struct('x', '(none)', 'y', '(none)', 'grid', true);
    C.plotControls = labkit.ui.view.panel( ...
        ui.topControlsPanel, ...
        'topBottomPlotControls', ...
        ui.bottomControlsPanel, ...
        {'(none)'}, ...
        {'(none)'}, ...
        topPlotDefaults, ...
        bottomPlotDefaults, ...
        callbacks.onRefreshPlotsOnly);
    C.ddTopX = C.plotControls.topX;
    C.ddTopY = C.plotControls.topY;
    C.cbTopGrid = C.plotControls.topGridCheckbox;
    C.ddBotX = C.plotControls.bottomX;
    C.ddBotY = C.plotControls.bottomY;
    C.cbBotGrid = C.plotControls.bottomGridCheckbox;
    C.axTop = ui.topAxes;
    C.axBottom = ui.bottomAxes;
    title(C.axTop, 'Top Plot');
    xlabel(C.axTop, 'X');
    ylabel(C.axTop, 'Y');
    title(C.axBottom, 'Bottom Plot');
    xlabel(C.axBottom, 'X');
    ylabel(C.axBottom, 'Y');

    C.plotControls.topGrid.ColumnWidth = {'fit','1x','fit','1x','fit','fit','fit'};
    C.cbTopHold = uicheckbox(C.plotControls.topGrid, ...
        'Text', 'Hold', 'Value', false);
    C.cbTopHold.Layout.Row = 1; C.cbTopHold.Layout.Column = 6;
    C.cbTopTrim = uicheckbox(C.plotControls.topGrid, ...
        'Text', 'Show Trim', 'Value', true, ...
        'ValueChangedFcn', callbacks.onRefreshCompare);
    C.cbTopTrim.Layout.Row = 1; C.cbTopTrim.Layout.Column = 7;

    C.plotControls.bottomGrid.ColumnWidth = {'fit','1x','fit','1x','fit','fit','fit'};
    C.cbBotHold = uicheckbox(C.plotControls.bottomGrid, ...
        'Text', 'Hold', 'Value', false);
    C.cbBotHold.Layout.Row = 1; C.cbBotHold.Layout.Column = 6;
    C.cbBotTrim = uicheckbox(C.plotControls.bottomGrid, ...
        'Text', 'Show Trim', 'Value', true, ...
        'ValueChangedFcn', callbacks.onRefreshCompare);
    C.cbBotTrim.Layout.Row = 1; C.cbBotTrim.Layout.Column = 7;
end
