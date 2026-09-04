function view = createLauncherView()
%CREATELAUNCHERVIEW Build the native Launcher window without product state.
% The returned handle struct owns concrete controls and responsive layout.
% Callers own discovery, selections, busy state, and action behavior.

panelFontSize = 15;
tableFontSize = 12;
version = labkit.app.internal.launcher.launcherVersion();
position = defaultLauncherPosition();
figArgs = { ...
    "Name", version.displayName + " v" + version.version + ...
        " (" + version.updated + ")", ...
    "Tag", "labkitLauncher", ...
    "Position", position, ...
    "AutoResizeChildren", "off", ...
    "Color", [0.97 0.98 0.99]};
if labkit.app.internal.launcher.launcherGuiTestMode() == "hidden"
    figArgs = [figArgs, {"Visible", "off"}];
end
close(findall(groot, "Type", "figure", "Tag", "labkitLauncher"));
fig = uifigure(figArgs{:});
rootPanel = uipanel(fig, ...
    "BorderType", "none", ...
    "BackgroundColor", fig.Color, ...
    "Units", "pixels", ...
    "Position", [1 1 position(3:4)]);
main = uigridlayout(rootPanel, [1 3]);
leftWidth = launcherControlWidth(position(3));
main.ColumnWidth = {leftWidth, 5, "1x"};
main.RowHeight = {"1x"};
main.Padding = [6 6 6 6];
main.ColumnSpacing = 0;

left = uipanel(main, "Title", "Launcher", "FontSize", panelFontSize);
left.Layout.Column = 1;
divider = uipanel(main, "BorderType", "none", ...
    "BackgroundColor", [0.78 0.80 0.82]);
divider.Layout.Column = 2;
right = uipanel(main, "Title", "Applications", "FontSize", panelFontSize);
right.Layout.Column = 3;

controls = uigridlayout(left, [5 1]);
controls.RowHeight = {142, 72, 108, 72, "1x"};
controls.Padding = [6 6 6 6];
controls.RowSpacing = 6;

runPanel = uipanel(controls, "Title", "Run Apps");
runPanel.Layout.Row = 1;
runGrid = uigridlayout(runPanel, [3 2]);
runGrid.RowHeight = {"1x", "1x", "1x"};
runGrid.ColumnWidth = {"1x", "1x"};
runGrid.Padding = [5 5 5 5];
runGrid.RowSpacing = 5;
runGrid.ColumnSpacing = 6;
openButton = uibutton(runGrid, "Text", "Open Selected App");
openButton.Layout.Row = 1;
openButton.Layout.Column = [1 2];
refreshButton = uibutton(runGrid, "Text", "Refresh App List");
refreshButton.Layout.Row = 2;
refreshButton.Layout.Column = 1;
appDocsButton = uibutton(runGrid, ...
    "Text", "Open App Guide");
appDocsButton.Layout.Row = 2;
appDocsButton.Layout.Column = 2;
appDocsButton.Tooltip = ...
    "Open the current online guide for the selected App.";
logButton = uibutton(runGrid, "Text", "View Launch Log");
logButton.Layout.Row = 3;
logButton.Layout.Column = [1 2];
logButton.Tooltip = ...
    "Inspect timed Launcher discovery and App-startup stages.";

versionPanel = uipanel(controls, "Title", "Versions and Install");
versionPanel.Layout.Row = 2;
versionGrid = uigridlayout(versionPanel, [1 2]);
versionGrid.ColumnWidth = {"1x", "1x"};
versionGrid.Padding = [5 5 5 5];
versionGrid.ColumnSpacing = 6;
latestButton = uibutton(versionGrid, "Text", "Latest");
versionsButton = uibutton(versionGrid, "Text", "Versions");
latestButton.Tooltip = "Download and apply the latest published release.";
versionsButton.Tooltip = ...
    "Choose a recent published release.";

maintenancePanel = uipanel(controls, ...
    "Title", "Development and Maintenance");
maintenancePanel.Layout.Row = 3;
maintenanceGrid = uigridlayout(maintenancePanel, [2 2]);
maintenanceGrid.ColumnWidth = {"1x", "1x"};
maintenanceGrid.RowHeight = {"1x", "1x"};
maintenanceGrid.Padding = [5 5 5 5];
maintenanceGrid.RowSpacing = 5;
maintenanceGrid.ColumnSpacing = 6;
docsToolButton = uibutton(maintenanceGrid, "Text", "Doc Generation");
codeButton = uibutton(maintenanceGrid, "Text", "Run Code Analyzer");
profileButton = uibutton(maintenanceGrid, "Text", "Profile Selected App");
cleanButton = uibutton(maintenanceGrid, "Text", "Clean Artifacts");
docsToolButton.Tooltip = ...
    "Rebuild the ignored local site from current documentation sources.";
codeButton.Tooltip = ...
    "Run MATLAB Code Analyzer and write the repository report.";
profileButton.Tooltip = ...
    "Profile the selected app and save its report without opening a browser.";
cleanButton.Tooltip = ...
    "Remove generated artifacts through the maintenance tool.";

packagePanel = uipanel(controls, "Title", "Package and Publish");
packagePanel.Layout.Row = 4;
packageGrid = uigridlayout(packagePanel, [1 1]);
packageGrid.ColumnWidth = {"1x"};
packageGrid.Padding = [5 5 5 5];
packageGrid.ColumnSpacing = 6;
packageButton = uibutton(packageGrid, "Text", "Package Checked");
packageButton.Tooltip = ...
    "Create one standalone source package containing every checked app.";

status = uitextarea(controls, "Editable", "off", "Value", "Ready.");
status.Layout.Row = 5;
tableGrid = uigridlayout(right, [1 1]);
tableGrid.Padding = [4 4 4 4];
appTable = uitable(tableGrid, ...
    "ColumnName", { ...
        "Package", "Family", "App", "Version", "Access", "Updated"}, ...
    "ColumnEditable", [true false false false false false], ...
    "RowName", {}, ...
    "FontSize", tableFontSize);
appTable.ColumnSortable = true(1, 6);
if isprop(appTable, "ColumnFormat")
    appTable.ColumnFormat = { ...
        'logical', 'char', 'char', 'char', 'char', 'char'};
end
appTable.ColumnWidth = launcherTableWidths(position(3), leftWidth);

view = struct( ...
    "figure", fig, ...
    "openButton", openButton, ...
    "refreshButton", refreshButton, ...
    "appDocsButton", appDocsButton, ...
    "logButton", logButton, ...
    "latestButton", latestButton, ...
    "versionsButton", versionsButton, ...
    "docsToolButton", docsToolButton, ...
    "codeButton", codeButton, ...
    "profileButton", profileButton, ...
    "cleanButton", cleanButton, ...
    "packageButton", packageButton, ...
    "status", status, ...
    "appTable", appTable, ...
    "controls", struct( ...
        "selectedDetails", struct("textArea", status), ...
        "statusLine", struct("textArea", status), ...
        "appTable", struct("table", appTable)));
setappdata(fig, "labkitLauncherView", view);
fig.SizeChangedFcn = @(~, ~) resizeLauncher();
resizeLauncher();

    function resizeLauncher()
        if ~isvalid(fig) || ~isvalid(appTable)
            return;
        end
        figureWidth = fig.Position(3);
        rootPanel.Position = [1 1 fig.Position(3:4)];
        resizedControlWidth = launcherControlWidth(figureWidth);
        main.ColumnWidth = {resizedControlWidth, 5, "1x"};
        appTable.ColumnWidth = launcherTableWidths( ...
            figureWidth, resizedControlWidth);
    end
end

function position = defaultLauncherPosition()
screen = double(get(groot, "ScreenSize"));
screenWidth = screen(3);
screenHeight = screen(4);
width = min(screenWidth, max(800, min(1280, screenWidth - 80)));
height = min(screenHeight, max(560, min(720, screenHeight - 120)));
x = screen(1) + max(0, (screenWidth - width) / 2);
y = screen(2) + max(0, (screenHeight - height) / 2);
position = round([x y width height]);
end

function width = launcherControlWidth(figureWidth)
width = min(390, max(350, round(double(figureWidth) * 0.29)));
end

function widths = launcherTableWidths(figureWidth, controlWidth)
tableWidth = max(640, double(figureWidth) - double(controlWidth) - 36);
minimum = [62 120 180 70 72 90];
preferred = [72 150 240 78 80 100];
if tableWidth <= sum(minimum)
    values = minimum;
elseif tableWidth < sum(preferred)
    fraction = (tableWidth - sum(minimum)) / ...
        (sum(preferred) - sum(minimum));
    values = minimum + fraction .* (preferred - minimum);
else
    extra = tableWidth - sum(preferred);
    values = preferred + extra .* [0 0.25 0.60 0 0 0.15];
end
widths = num2cell(round(values));
end
