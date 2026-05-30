function varargout = gui_only_app_template(varargin)
%GUI_ONLY_APP_TEMPLATE Minimal app that uses only the reusable GUI surface.

    if nargin > 0
        error('gui_only_app_template:UnsupportedInput', ...
            'gui_only_app_template does not accept input arguments.');
    end
    if nargout > 1
        error('gui_only_app_template:TooManyOutputs', ...
            'gui_only_app_template returns at most the figure handle.');
    end

    ui = labkit.ui.createStandardWorkbenchShell( ...
        'GUI Only Template', [80 80 1100 700], 300, ...
        'Preview', [1 1], {'1x'}, 8);
    fig = ui.fig;

    controls = uigridlayout(ui.filesAnalysisGrid, [3 2]);
    controls.Layout.Row = [1 3];
    controls.RowHeight = {'fit', 'fit', '1x'};
    controls.ColumnWidth = {'fit', '1x'};
    controls.Padding = [0 0 0 0];
    controls.RowSpacing = 8;
    controls.ColumnSpacing = 8;

    [~, modeDropDown] = labkit.ui.createLabeledDropdown( ...
        controls, 'Mode:', ...
        'Items', {'Default', 'Alternate'}, ...
        'Value', 'Default');
    [~, valueField] = labkit.ui.createLabeledEditField( ...
        controls, 'Value:', 'numeric', ...
        'Value', 1);

    logUi = labkit.ui.createLogPanel(ui.logGrid, 1, {'Ready.'});
    ax = labkit.ui.createAxes(ui.rightGrid, 1, 'Preview', 'X', 'Y');

    modeDropDown.ValueChangedFcn = @refreshPreview;
    valueField.ValueChangedFcn = @refreshPreview;
    refreshPreview();

    if nargout == 1
        varargout{1} = fig;
    end

    function refreshPreview(~, ~)
        x = 0:0.1:10;
        scale = valueField.Value;
        if strcmp(modeDropDown.Value, 'Alternate')
            y = scale .* cos(x);
        else
            y = scale .* sin(x);
        end
        labels = struct('title', 'Preview', 'x', 'X', 'y', 'Y');
        opts = struct('lineWidth', 1.5, 'markerSize', 4, 'marker', 'none');
        labkit.ui.plotXY(ax, x, y, labels, opts);
        labkit.ui.appendLog(logUi.textArea, sprintf('Updated: %s', modeDropDown.Value));
    end
end
