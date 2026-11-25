function view = createLauncherView()
% Build one native workspace around the catalog and its selected application.
version = labkit.app.internal.launcher.launcherVersion();
position = defaultLauncherPosition();
close(findall(groot, "Type", "figure", "Tag", "labkitLauncher"));
fig = uifigure(Name=version.displayName + " v" + version.version + ...
    " (" + version.updated + ")", Tag="labkitLauncher", ...
    Position=position, Visible="off", AutoResizeChildren="off");
body = uigridlayout(fig, [1 2], Padding=[0 0 0 0], ColumnSpacing=1);
policy = labkit.app.internal.native.NativeAdapterValues.layoutPolicy();
topInset = policy.HeaderTopInset;
outerInset = 20;
headingHeight = policy.HeaderContentHeight;
catalog = uigridlayout(body, [3 1], RowHeight={headingHeight,32,'1x'}, ...
    Padding=[16 outerInset outerInset topInset], RowSpacing=8);
catalog.Layout.Row = 1;
catalog.Layout.Column = 2;
titleGroup = uigridlayout(catalog,[1 4],ColumnWidth={'fit','fit','1x','fit'}, ...
    Padding=[0 0 0 0],ColumnSpacing=6);
count = uilabel(titleGroup,Text="",FontSize=12);
count.Layout.Column = 2;
catalogTitle = uilabel(titleGroup,Text="Applications",FontSize=18,FontWeight="bold");
catalogTitle.Layout.Row = 1;
catalogTitle.Layout.Column = 1;
packageButton = uibutton(titleGroup,Text="Package Checked",Visible="off");
packageButton.Layout.Column = 4;
catalogBar = uigridlayout(catalog,[1 4],ColumnWidth={'1x',132,82,106}, ...
    Padding=[0 0 0 0],ColumnSpacing=6);
search = uieditfield(catalogBar,"text",Placeholder="Search applications…");
family = uidropdown(catalogBar,Items="All families");
scope = uidropdown(catalogBar,Items=["All apps","Public","Private"]);
refreshButton = uibutton(catalogBar,Text="Refresh App List");
appTable = uitable(catalog, ...
    "ColumnName", { ...
        "Package", "Family", "App", "Version", "Access", "Updated"}, ...
    "ColumnEditable", [true false false false false false], ...
    "RowName", {}, ...
    "ColumnWidth", {88,'2x','3x',80,78,90}, ...
    "FontSize", 12);
appTable.ColumnSortable = true(1, 6);
if isprop(appTable, "ColumnFormat")
    appTable.ColumnFormat = { ...
        'logical', 'char', 'char', 'char', 'char', 'char'};
end

style = labkit.app.internal.native.lightAppearance();
side = uigridlayout(body,[6 1],RowHeight={headingHeight,1,131,32,1,'1x'}, ...
    Padding=[outerInset outerInset 20 topInset],RowSpacing=policy.HeaderBottomGap,BackgroundColor=style.Background);
side.Layout.Row = 1;
side.Layout.Column = 1;
brand = uigridlayout(side,[1 2],ColumnWidth={28,'1x'},Padding=[0 0 0 0], ...
    ColumnSpacing=8,BackgroundColor=style.Background);
labkit.app.internal.native.installBrandMark(brand);
brandButton = uibutton(brand,Text="LabKit MATLAB Workbench",FontSize=14, ...
    FontWeight="bold",FontColor=style.Text,BackgroundColor=style.Background, ...
    Tooltip="Open the LabKit MATLAB Workbench repository on GitHub");
uilabel(side,Text="",BackgroundColor=style.Line);
selection = uigridlayout(side,[4 2],RowHeight={14,26,48,34}, ...
    ColumnWidth={'1x',106},Padding=[0 0 0 0],RowSpacing=3,ColumnSpacing=8, ...
    BackgroundColor=style.Background);
eyebrow = uilabel(selection,Text="Selected app",FontSize=11,FontColor=style.Muted);
eyebrow.Layout.Column = [1 2];
selectionTitle = uilabel(selection,Text="Loading…",FontSize=18,FontWeight="bold",WordWrap="off");
selectionTitle.Layout.Column = [1 2];
description = uilabel(selection,Text="",WordWrap="on",VerticalAlignment="top",FontSize=12);
description.Layout.Column = [1 2];
openButton = uibutton(selection, Text="Open Selected App", FontWeight="bold");
appDocsButton = uibutton(selection, Text="Open App Guide");
toolsButton = uibutton(side,Text="Workbench tools  ▾");
uilabel(side,Text="",BackgroundColor=style.Line);

activity = uigridlayout(side,[2 2],RowHeight={26,'1x'}, ...
    ColumnWidth={'1x','fit'},Padding=[0 0 0 0],RowSpacing=6,BackgroundColor=style.Background);
activityTitle = uilabel(activity,Text="Session log",FontSize=14,FontWeight="bold");
reportButton = uibutton(activity,Text="Open report",Visible="off");
status = uitextarea(activity,Editable="off",WordWrap="on",FontName=get(groot,"DefaultUicontrolFontName"), ...
    FontSize=13,FontColor=style.Text,BackgroundColor=style.Surface);
status.Layout.Column = [1 2];
menu = uicontextmenu(fig);
toolsButton.ContextMenu = menu;
toolsButton.ButtonPushedFcn = @(source,~) openTools(source,menu);
profileButton = uimenu(menu,Text="Profile Selected App");
docsToolButton = uimenu(menu,Text="Doc Generation",Separator="on");
codeButton = uimenu(menu,Text="Run Code Analyzer");
cleanButton = uimenu(menu,Text="Clean Artifacts");
logButton = uimenu(menu,Text="View Launch Log",Separator="on");
versionsButton = uimenu(menu,Text="Update to a specific version…",Separator="on");
latestButton = uimenu(menu,Text="Update to latest release…");

view = struct( ...
    "figure", fig, "search", search, "family", family, "scope", scope, "count", count, ...
    "brandButton", brandButton, "openButton", openButton, ...
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
    "status", status, "toolsButton", toolsButton, "reportButton", reportButton, "selectionTitle", selectionTitle, ...
    "description", description, ...
    "appTable", appTable, ...
    "controls", struct( ...
        "appTable", struct("table", appTable)));

applyPalette(style);
setappdata(fig, "labkitLauncherView", view);
fig.SizeChangedFcn = @(~,~) resizeLauncher();
resizeLauncher();
if labkit.app.internal.launcher.launcherGuiTestMode() ~= "hidden"
    fig.Visible = "on";
end

    function applyPalette(style)
        if isprop(fig, "Theme")
            fig.Theme = "light";
        end
        body.BackgroundColor = style.Line;
        count.FontColor = style.Muted;
        set([catalog catalogBar titleGroup], 'BackgroundColor', style.Surface);
        set([catalogTitle selectionTitle activityTitle], 'FontColor', style.Text);
        description.FontColor = style.Muted;
        set(openButton, 'BackgroundColor', style.Primary, 'FontColor', style.OnPrimary);
        buttons = [refreshButton appDocsButton toolsButton packageButton reportButton];
        set(buttons, 'BackgroundColor', style.Paper, 'FontColor', style.Text);
        set([buttons openButton brandButton], 'Interruptible','off','BusyAction','cancel');
        set(menu.Children,'Interruptible','off','BusyAction','cancel');
        set(appTable,'Interruptible','off','BusyAction','cancel');
        set(appTable, 'BackgroundColor', style.Surface, 'ForegroundColor', style.Text);
        addStyle(appTable,uistyle(FontWeight="bold"),"column",3);
        addStyle(appTable,uistyle(FontColor=style.Muted),"column",[2 4 5 6]);
    end

    function resizeLauncher()
        width = fig.Position(3);
        sideWidth = min(340, max(268, round(width * .27)));
        body.ColumnWidth = {sideWidth, '1x'};

    end
end

function openTools(button,menu)
bounds = getpixelposition(button,true);
open(menu,bounds(1),bounds(2)+bounds(4));
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
