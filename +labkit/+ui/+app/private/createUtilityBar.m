% Private UI app helper. Expected caller: createTabbedWorkbenchShell. Inputs
% are the app figure, parent grid, and optional utility spec. Side effects:
% creates framework-owned app utility controls for current-plot actions,
% app screenshots, and state snapshot save/load.
function panel = createUtilityBar(fig, parent, utilities)
    visible = utilityEnabled(utilities, 'Visible', true);
    panel = uipanel(parent, ...
        'BorderType', 'none', ...
        'Tag', 'labkitUiUtilityBar', ...
        'Visible', matlabVisibility(visible));
    grid = uigridlayout(panel, [1 7]);
    grid.RowHeight = {'1x'};
    grid.ColumnWidth = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', '1x'};
    grid.Padding = [0 0 0 0];
    grid.ColumnSpacing = 6;

    addButton(grid, 1, "Pop Out", "labkitUiUtilityPopout", ...
        utilityEnabled(utilities, 'Plot', true), ...
        @(~,~) runUtility(fig, @() popoutCurrentPlot(fig)));
    addButton(grid, 2, "Copy Plot", "labkitUiUtilityCopyPlot", ...
        utilityEnabled(utilities, 'Plot', true), ...
        @(~,~) runUtility(fig, @() copyCurrentPlot(fig)));
    addButton(grid, 3, "Save Plot", "labkitUiUtilitySavePlot", ...
        utilityEnabled(utilities, 'Plot', true), ...
        @(~,~) runUtility(fig, @() saveCurrentPlot(fig)));
    addButton(grid, 4, "Screenshot", "labkitUiUtilityScreenshot", ...
        utilityEnabled(utilities, 'Screenshot', true), ...
        @(~,~) runUtility(fig, @() saveAppScreenshot(fig)));
    addButton(grid, 5, "Save State", "labkitUiUtilitySaveState", ...
        stateUtilityEnabled(utilities), ...
        @(~,~) runUtility(fig, @() saveAppState(fig)));
    addButton(grid, 6, "Load State", "labkitUiUtilityLoadState", ...
        stateUtilityEnabled(utilities), ...
        @(~,~) runUtility(fig, @() loadAppState(fig)));
end

function button = addButton(parent, column, text, tag, enabled, callback)
    button = uibutton(parent, 'push', ...
        'Text', char(text), ...
        'Tag', char(tag), ...
        'Enable', matlabOnOff(enabled), ...
        'ButtonPushedFcn', callback);
    button.Layout.Row = 1;
    button.Layout.Column = column;
end

function runUtility(fig, action)
    try
        action();
    catch ME
        labkit.ui.app.showAlert(fig, string(ME.message), "LabKit Utility");
    end
end

function popoutCurrentPlot(fig)
    ax = currentWorkbenchAxes(fig);
    labkit.ui.tool.popoutAxes(ax);
end

function copyCurrentPlot(fig)
    ax = currentWorkbenchAxes(fig);
    copygraphics(ax);
end

function saveCurrentPlot(fig)
    ax = currentWorkbenchAxes(fig);
    filepath = injectedPath(fig, 'labkitUiUtilityPlotFile');
    if strlength(filepath) == 0
        [file, path] = uiputfile( ...
            {'*.png', 'PNG image (*.png)'; '*.pdf', 'PDF file (*.pdf)'}, ...
            'Save Current Plot');
        if isequal(file, 0) || isequal(path, 0)
            return;
        end
        filepath = string(fullfile(path, file));
    end
    exportgraphics(ax, filepath);
end

function saveAppScreenshot(fig)
    filepath = injectedPath(fig, 'labkitUiUtilityScreenshotFile');
    if strlength(filepath) == 0
        [file, path] = uiputfile( ...
            {'*.png', 'PNG image (*.png)'; '*.pdf', 'PDF file (*.pdf)'}, ...
            'Save App Screenshot');
        if isequal(file, 0) || isequal(path, 0)
            return;
        end
        filepath = string(fullfile(path, file));
    end
    exportapp(fig, filepath);
end

function saveAppState(fig)
    filepath = injectedPath(fig, 'labkitUiUtilityStateFile');
    if strlength(filepath) == 0
        labkit.ui.app.saveState(fig);
    else
        labkit.ui.app.saveState(fig, filepath);
    end
end

function loadAppState(fig)
    filepath = injectedPath(fig, 'labkitUiUtilityStateFile');
    if strlength(filepath) == 0
        labkit.ui.app.loadState(fig);
    else
        labkit.ui.app.loadState(fig, filepath);
    end
end

function value = injectedPath(fig, key)
    value = "";
    if isappdata(fig, key)
        value = string(getappdata(fig, key));
    end
end

function tf = stateUtilityEnabled(utilities)
    if isstruct(utilities) && isfield(utilities, 'State') && ...
            string(utilities.State) == "off"
        tf = false;
    else
        tf = true;
    end
end

function tf = utilityEnabled(utilities, field, defaultValue)
    tf = defaultValue;
    if isstruct(utilities) && isfield(utilities, field)
        tf = logical(utilities.(field));
    end
end

function value = matlabOnOff(tf)
    if tf
        value = 'on';
    else
        value = 'off';
    end
end

function value = matlabVisibility(tf)
    value = matlabOnOff(tf);
end
