function fig = showLaunchLog(log)
%SHOWLAUNCHLOG Open a readable view of the current Launcher event log.
% Expected caller: the Launcher's View Launch Log action. The source JSONL
% remains the durable record; this window performs no mutation.

fig = findall(groot,"-depth",1,"Type","figure","Tag","labkitLauncherLog");
file = string(log.file);
bytes = -1;
if file ~= ""
    info = dir(file);
    if ~isempty(info), bytes = info(1).bytes; end
end
if isempty(fig)
    values = readableLog(log);
    fig = uifigure(Name="LabKit Launcher Log",Tag="labkitLauncherLog", ...
        Position=centeredPosition(),Visible="off");
    if isprop(fig,"Theme"), fig.Theme = "light"; end
    style = labkit.app.internal.native.lightAppearance();
    grid = uigridlayout(fig,[3 1],RowHeight={34,'1x',22}, ...
        Padding=[18 14 18 14],RowSpacing=8,BackgroundColor=style.Background);
    header = uigridlayout(grid,[1 2],ColumnWidth={'1x','fit'},Padding=[0 0 0 0], ...
        BackgroundColor=style.Background);
    uilabel(header,Text="Launcher diagnostics",FontSize=19,FontWeight="bold",FontColor=style.Text);
    count = uilabel(header,Text=eventCount(values),FontSize=12,FontColor=style.Muted);
    font = get(groot,"FixedWidthFontName");
    if ismac, font = "Menlo"; end
    textArea = uitextarea(grid,Editable="off",Value=values,FontName=font, ...
        FontSize=12,WordWrap="off",FontColor=style.Text,BackgroundColor=style.Surface);
    pathLabel = uilabel(grid,Text=logPathText(log),Tooltip=file,FontSize=11,FontColor=style.Muted);
    view = struct("pathLabel",pathLabel,"textArea",textArea,"count",count,"file",file,"bytes",bytes);
    setappdata(fig,"labkitLauncherLogView",view);
else
    view = getappdata(fig,"labkitLauncherLogView");
    % Launcher session files are append-only. Leave the text and scroll
    % position alone when a click only brings the viewer to the front.
    if ~isfield(view,"file") || view.file ~= file || view.bytes ~= bytes
        values = readableLog(log);
        view.textArea.Value = values;
        if isfield(view,"count"), view.count.Text = eventCount(values); end
        view.pathLabel.Text = logPathText(log);
        view.pathLabel.Tooltip = file;
        view.file = file;
        view.bytes = bytes;
        setappdata(fig,"labkitLauncherLogView",view);
    end
end
if labkit.app.internal.launcher.launcherGuiTestMode() ~= "hidden"
    if fig.WindowState == "minimized", fig.WindowState = "normal"; end
    fig.Visible = "on";
    figure(fig);
end
end

function text = logPathText(log)
if strlength(string(log.file)) == 0
    text = "Launcher logging is unavailable for this installation.";
else
    text = "Current log: " + string(log.file);
end
end

function values = readableLog(log)
header = compose("%-24s  %9s  %-11s  %-37s  %9s  %s","UTC","Elapsed","Outcome","Event","Duration","App / error");
if strlength(string(log.file)) == 0 || ~isfile(log.file)
    values = "No Launcher log is available.";
    return;
end
lines = readlines(log.file);
lines = lines(strlength(strip(lines)) > 0);
values = strings(numel(lines) + 1, 1);
values(1) = header;
for k = 1:numel(lines)
    try
        event = jsondecode(lines(k));
        values(k + 1) = formatEvent(event);
    catch
        values(k + 1) = "Unreadable log entry.";
    end
end
end

function value = formatEvent(event)
duration = "";
if ~isempty(event.durationSeconds)
    duration = compose("%.3f s", event.durationSeconds);
end
fields = [string(event.appCommand),string(event.errorIdentifier)];
detail = strjoin(fields(fields ~= ""),"  ");
value = compose("%-24s  %9s  %-11s  %-37s  %9s  %s",string(event.timestampUtc), ...
    compose("%.3f s",event.elapsedSeconds),string(event.outcome), ...
    string(event.eventName),duration,detail);
end

function text = eventCount(values)
text = compose("%d events",numel(values)-1);
end

function position = centeredPosition()
screen = double(get(groot, "ScreenSize"));
width = min(1120, max(720, screen(3) - 160));
height = min(620, max(420, screen(4) - 220));
position = round([screen(1) + (screen(3) - width) / 2, ...
    screen(2) + (screen(4) - height) / 2, width, height]);
end
