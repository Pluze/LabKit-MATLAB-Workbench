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

    workbenchOpts = struct();
    workbenchOpts.rightTitle = 'Preview';
    workbenchOpts.rightGridSize = [1 1];
    workbenchOpts.rightRowHeight = {'1x'};
    workbenchOpts.rightRowSpacing = 8;
    ui = labkit.ui.createWorkbench( ...
        'GUI Only Template', [80 80 1100 700], 300, workbenchOpts);
    fig = ui.fig;

    controlOpts = struct( ...
        'rowHeight', {{'fit', 'fit', '1x'}}, ...
        'padding', [0 0 0 0]);
    controlsUi = labkit.ui.createPanelGrid( ...
        ui.filesAnalysisGrid, 'Controls', [1 3], [3 2], controlOpts);
    controls = controlsUi.grid;

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
