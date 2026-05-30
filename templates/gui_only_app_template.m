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

    ui = gamrywb.ui.createTwoPaneShell( ...
        'GUI Only Template', [80 80 1100 700], 300, ...
        'Preview', [1 1], {'1x'}, 8);
    fig = ui.fig;

    controls = uigridlayout(ui.leftGrid, [3 1]);
    controls.Layout.Row = [1 5];
    controls.RowHeight = {'fit', 'fit', '1x'};
    controls.ColumnWidth = {'1x'};

    [~, modeDropDown] = gamrywb.ui.createLabeledDropdown( ...
        controls, 'Mode:', {'Default', 'Alternate'}, 'Default', 1);
    [~, valueField] = gamrywb.ui.createLabeledEditField( ...
        controls, 'Value:', 'numeric', 1, 2);

    logUi = gamrywb.ui.createLogPanel(controls, 3, {'Ready.'});
    ax = gamrywb.ui.createAxes(ui.rightGrid, 1, 'Preview', 'X', 'Y');

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
        gamrywb.ui.plotXY(ax, x, y, labels, opts);
        gamrywb.ui.appendLog(logUi.textArea, sprintf('Updated: %s', modeDropDown.Value));
    end
end
