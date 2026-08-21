% Private App plot helper that installs copied-figure editing controls.
function toolbar = createPopoutToolbar(fig, ax)
toolbar = uipanel(fig, 'Tag', 'labkitAxesPopoutToolbar', ...
    'BorderType', 'none', 'Units', 'normalized', ...
    'Position', [0.00 0.93 1.00 0.07], ...
    'BackgroundColor', [0.94 0.94 0.94]);
labels = ["Font +", "Font -", "Line +", "Line -", ...
    "Axes +", "Axes -", "Grid +", "Grid -", "X labels /", ...
    "Send to Studio"];
tags = ["labkitAxesPopoutFontIncreaseTool", ...
    "labkitAxesPopoutFontDecreaseTool", ...
    "labkitAxesPopoutLineIncreaseTool", ...
    "labkitAxesPopoutLineDecreaseTool", ...
    "labkitAxesPopoutAxesIncreaseTool", ...
    "labkitAxesPopoutAxesDecreaseTool", ...
    "labkitAxesPopoutGridIncreaseTool", ...
    "labkitAxesPopoutGridDecreaseTool", ...
    "labkitAxesPopoutXLabelRotationTool", ...
    "labkitAxesPopoutStudioTool"];
callbacks = {
    @(~,~) applyStyleAndLayout(fig, toolbar, ax, "fontIncrease")
    @(~,~) applyStyleAndLayout(fig, toolbar, ax, "fontDecrease")
    @(~,~) applyStyleAndLayout(fig, toolbar, ax, "lineIncrease")
    @(~,~) applyStyleAndLayout(fig, toolbar, ax, "lineDecrease")
    @(~,~) applyStyleAndLayout(fig, toolbar, ax, "axesIncrease")
    @(~,~) applyStyleAndLayout(fig, toolbar, ax, "axesDecrease")
    @(~,~) applyStyleAndLayout(fig, toolbar, ax, "gridIncrease")
    @(~,~) applyStyleAndLayout(fig, toolbar, ax, "gridDecrease")
    @(tool,~) toggleXLabelRotation(tool, fig, toolbar, ax)
    @(~,~) sendToStudio(ax)};
for k = 1:numel(labels)
    addTool(toolbar, labels(k), tags(k), ...
        k, numel(labels), callbacks{k});
end
rotationTool = findobj( ...
    toolbar, 'Tag', 'labkitAxesPopoutXLabelRotationTool');
updateXLabelRotationTool(rotationTool, ax);
layoutPopoutAxes(fig, toolbar, ax);
fig.SizeChangedFcn = @(~,~) layoutPopoutAxes(fig, toolbar, ax);
end

function tool = addTool(parent, label, tag, index, count, callback)
width = 1 / count;
tool = uicontrol(parent, 'Style', 'pushbutton', ...
    'String', char(label), 'Tag', char(tag), ...
    'Units', 'normalized', ...
    'Position', [(index - 1) * width, 0, width, 1], ...
    'FontSize', 10, 'FontWeight', 'normal', ...
    'BackgroundColor', [0.96 0.96 0.96], ...
    'Callback', callback);
end

function applyStyleAndLayout(fig, toolbar, ax, command)
applyAxesStyleCommand(ax, command);
layoutPopoutAxes(fig, toolbar, ax);
end

function toggleXLabelRotation(tool, fig, toolbar, ax)
if abs(ax.XTickLabelRotation) < eps
    ax.XTickLabelRotation = 45;
else
    ax.XTickLabelRotation = 0;
end
updateXLabelRotationTool(tool, ax);
layoutPopoutAxes(fig, toolbar, ax);
end

function updateXLabelRotationTool(tool, ax)
if abs(ax.XTickLabelRotation) < eps
    tool.String = 'X labels /';
else
    tool.String = 'X labels -';
end
tool.TooltipString = ...
    'Switch X-axis tick labels between angled and horizontal.';
end

function layoutPopoutAxes(fig, toolbar, ax)
if isempty(fig) || ~isvalid(fig) || isempty(toolbar) || ...
        ~isvalid(toolbar) || isempty(ax) || ~isvalid(ax)
    return;
end
toolbar.Units = 'normalized';
toolbar.Position = [0.00 0.93 1.00 0.07];
ax.Units = 'normalized';
ax.OuterPosition = [0.02 0.02 0.96 0.89];
ax.ActivePositionProperty = 'outerposition';
drawnow limitrate nocallbacks;
end

function sendToStudio(ax)
root = fileparts(mfilename("fullpath"));
for level = 1:5
    root = fileparts(root);
end
apps = labkit.app.internal.discovery.discoverApps(root);
match = find(string({apps.command}) == "labkit_FigureStudio_app", 1);
if isempty(match)
    warning('labkit:app:plot:FigureStudioUnavailable', ...
        'Figure Studio is not available in this LabKit installation.');
    return;
end
labkit.app.internal.discovery.invokeDiscoveredApp( ...
    apps(match), "axes", ax);
end
