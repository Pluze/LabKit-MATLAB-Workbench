% Private UI runtime helper. Expected caller: createTabbedWorkbenchShell. Inputs
% are the app figure, parent grid, and optional utility spec. Side effects:
% creates framework-owned top-level utility menus for plot actions, app
% screenshots, and project save/load.
function panel = createUtilityBar(fig, parent, utilities)
    visible = utilityEnabled(utilities, 'Visible', true);
    panel = uipanel(parent, ...
        'BorderType', 'none', ...
        'Tag', 'labkitUiUtilityBar', ...
        'Visible', 'off');
    if ~visible
        return;
    end

    plotMenu = uimenu(fig, 'Text', 'Plot', 'Tag', 'labkitUiUtilityPlotMenu', ...
        'Enable', matlabOnOff(utilityEnabled(utilities, 'Plot', true)));
    addMenuItem(plotMenu, "Pop out all plots", "labkitUiUtilityPopout", ...
        utilityEnabled(utilities, 'Plot', true), ...
        @(~,~) runUtility(fig, @() popoutAllPlots(fig)));
    addMenuItem(plotMenu, "Copy all plots", "labkitUiUtilityCopyPlot", ...
        utilityEnabled(utilities, 'Plot', true), ...
        @(~,~) runUtility(fig, @() copyAllPlots(fig)));
    addMenuItem(plotMenu, "Save all plots", "labkitUiUtilitySavePlot", ...
        utilityEnabled(utilities, 'Plot', true), ...
        @(~,~) runUtility(fig, @() saveAllPlots(fig)));

    if utilityEnabled(utilities, 'Screenshot', true)
        addTopLevelMenu(fig, "Screenshot", "labkitUiUtilityScreenshot", ...
            @(~,~) runUtility(fig, @() saveAppScreenshot(fig)));
    end
    if stateUtilityEnabled(utilities)
        addTopLevelMenu(fig, "Save State", "labkitUiUtilitySaveState", ...
            @(~,~) runUtility(fig, @() saveAppState(fig)));
        addTopLevelMenu(fig, "Load State", "labkitUiUtilityLoadState", ...
            @(~,~) runUtility(fig, @() loadAppState(fig)));
    end
end

function item = addTopLevelMenu(fig, label, tag, callback)
    item = uimenu(fig, ...
        'Text', char(label), ...
        'Tag', char(tag), ...
        'Enable', 'on', ...
        'MenuSelectedFcn', callback);
end

function item = addMenuItem(parent, label, tag, enabled, callback)
    item = uimenu(parent, ...
        'Text', char(label), ...
        'Tag', char(tag), ...
        'Enable', matlabOnOff(enabled), ...
        'MenuSelectedFcn', callback);
end

function runUtility(fig, action)
    try
        action();
    catch ME
        showAlert(fig, string(ME.message), "LabKit Utility");
    end
end

function popoutAllPlots(fig)
    axesHandles = allWorkbenchAxes(fig);
    for k = 1:numel(axesHandles)
        labkit.ui.interaction.enablePopout(axesHandles(k));
        menu = findall(axesHandles(k).ContextMenu, 'Type', 'uimenu', ...
            'Tag', 'labkitAxesPopoutMenu');
        menu(1).MenuSelectedFcn(menu(1), []);
    end
end

function copyAllPlots(fig)
    axesHandles = allWorkbenchAxes(fig);
    if numel(axesHandles) == 1
        copygraphics(axesHandles(1), 'ContentType', 'image');
        return;
    end
    copygraphics(fig, 'ContentType', 'image');
end

function saveAllPlots(fig)
    axesHandles = allWorkbenchAxes(fig);
    filepath = injectedPath(fig, 'labkitUiUtilityPlotFile');
    if strlength(filepath) == 0
        [file, path] = uiputfile( ...
            {'*.png', 'PNG image (*.png)'; '*.pdf', 'PDF file (*.pdf)'}, ...
            'Save Plots');
        if isequal(file, 0) || isequal(path, 0)
            return;
        end
        filepath = string(fullfile(path, file));
    end
    for k = 1:numel(axesHandles)
        exportgraphics(axesHandles(k), plotFilepath(filepath, axesHandles(k), ...
            k, numel(axesHandles)), 'ContentType', 'image');
    end
end

function axesHandles = allWorkbenchAxes(fig)
    axesHandles = currentWorkbenchAxes(fig, "All", true);
end

function filepath = plotFilepath(basePath, ax, index, count)
    filepath = string(basePath);
    if count == 1
        return;
    end
    [folder, name, ext] = fileparts(filepath);
    label = axesFileLabel(ax, index);
    filepath = string(fullfile(folder, sprintf('%s_%02d_%s%s', ...
        char(name), index, char(label), char(ext))));
end

function label = axesFileLabel(ax, index)
    raw = string(ax.Title.String);
    raw = join(raw(:), " ");
    label = string(matlab.lang.makeValidName(char(raw)));
    if strlength(label) == 0
        label = "plot" + string(index);
    end
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
        labkit.ui.runtime.saveState(fig);
    else
        labkit.ui.runtime.saveState(fig, filepath);
    end
end

function loadAppState(fig)
    filepath = injectedPath(fig, 'labkitUiUtilityStateFile');
    if strlength(filepath) == 0
        labkit.ui.runtime.loadState(fig);
    else
        labkit.ui.runtime.loadState(fig, filepath);
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
