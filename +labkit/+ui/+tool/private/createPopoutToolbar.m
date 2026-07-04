% Private UI tool helper. Expected caller: labkit.ui.tool.popoutAxes.
% Inputs are a standalone MATLAB figure and its copied axes. Side effects:
% installs toolbar push tools whose callbacks mutate or export only the copied
% figure; source app axes and app state are not touched.
function toolbar = createPopoutToolbar(fig, ax)
    toolbar = uitoolbar(fig, 'Tag', 'labkitAxesPopoutToolbar');
    addTool(toolbar, "Font +", "labkitAxesPopoutFontIncreaseTool", ...
        [0.16 0.39 0.68], @(~,~) applyAxesStyleCommand(ax, "fontIncrease"));
    addTool(toolbar, "Font -", "labkitAxesPopoutFontDecreaseTool", ...
        [0.16 0.39 0.68], @(~,~) applyAxesStyleCommand(ax, "fontDecrease"));
    addTool(toolbar, "Line +", "labkitAxesPopoutLineIncreaseTool", ...
        [0.16 0.55 0.34], @(~,~) applyAxesStyleCommand(ax, "lineIncrease"));
    addTool(toolbar, "Line -", "labkitAxesPopoutLineDecreaseTool", ...
        [0.16 0.55 0.34], @(~,~) applyAxesStyleCommand(ax, "lineDecrease"));
    addTool(toolbar, "Copy Plot", "labkitAxesPopoutCopyTool", ...
        [0.43 0.28 0.61], @(~,~) copyPlot(ax));
    addTool(toolbar, "Save Plot", "labkitAxesPopoutSaveTool", ...
        [0.43 0.28 0.61], @(~,~) savePlot(fig, ax));
    addTool(toolbar, "Export Data", "labkitAxesPopoutDataTool", ...
        [0.70 0.42 0.12], @(~,~) exportData(fig, ax));
    addTool(toolbar, "Generate Script", "labkitAxesPopoutScriptTool", ...
        [0.70 0.42 0.12], @(~,~) exportData(fig, ax));
end

function tool = addTool(toolbar, label, tag, color, callback)
    cdata = icon(color);
    tool = uipushtool(toolbar, ...
        'Tooltip', char(label), ...
        'Tag', char(tag), ...
        'CData', cdata, ...
        'ClickedCallback', callback);
end

function cdata = icon(color)
    cdata = ones(16, 16, 3);
    for channel = 1:3
        cdata(:, :, channel) = color(channel);
    end
    cdata(2:15, 2:15, :) = min(1, cdata(2:15, 2:15, :) + 0.18);
    cdata(5:12, 5:12, :) = max(0, cdata(5:12, 5:12, :) - 0.18);
end

function copyPlot(ax)
    try
        copygraphics(ax);
    catch ME
        warning('labkit:ui:CopyGraphicsFailed', ...
            'Could not copy plot graphics: %s', ME.message);
    end
end

function savePlot(fig, ax)
    filepath = injectedPath(fig, 'labkitAxesPopoutSaveFile');
    if strlength(filepath) == 0
        [file, path] = uiputfile( ...
            {'*.png', 'PNG image (*.png)'; '*.pdf', 'PDF file (*.pdf)'}, ...
            'Save Plot');
        if isequal(file, 0) || isequal(path, 0)
            return;
        end
        filepath = string(fullfile(path, file));
    end
    exportgraphics(ax, filepath);
end

function exportData(fig, ax)
    folder = injectedPath(fig, 'labkitAxesPopoutExportFolder');
    if strlength(folder) == 0
        selected = uigetdir(pwd, 'Export Plot Data');
        if isequal(selected, 0)
            return;
        end
        folder = string(selected);
    end
    writeAxesDataExport(ax, folder);
end

function value = injectedPath(fig, key)
    value = "";
    if isappdata(fig, key)
        value = string(getappdata(fig, key));
    end
end
