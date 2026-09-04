function fig = showLaunchLog(log)
%SHOWLAUNCHLOG Open a readable view of the current Launcher event log.
% Expected caller: the Launcher's View Launch Log action. The source JSONL
% remains the durable record; this window performs no mutation.

close(findall(groot, "Type", "figure", "Tag", "labkitLauncherLog"));
args = {"Name", "LabKit Launcher Log", "Tag", "labkitLauncherLog", ...
    "Position", centeredPosition(), "Color", [0.97 0.98 0.99]};
if labkit.app.internal.launcher.launcherGuiTestMode() == "hidden"
    args = [args, {"Visible", "off"}];
end
fig = uifigure(args{:});
grid = uigridlayout(fig, [2 1]);
grid.RowHeight = {34, "1x"};
grid.Padding = [8 8 8 8];
pathLabel = uilabel(grid, "Text", logPathText(log));
pathLabel.Tooltip = string(log.file);
textArea = uitextarea(grid, "Editable", "off", ...
    "Value", readableLog(log), "FontName", "Monospaced");
setappdata(fig, "labkitLauncherLogView", struct( ...
    "pathLabel", pathLabel, "textArea", textArea));
end

function text = logPathText(log)
if strlength(string(log.file)) == 0
    text = "Launcher logging is unavailable for this installation.";
else
    text = "Current log: " + string(log.file);
end
end

function values = readableLog(log)
header = "UTC time | elapsed | event | app | outcome | duration | error";
if strlength(string(log.file)) == 0 || ~isfile(log.file)
    values = [header; "No Launcher log is available."];
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
value = string(event.timestampUtc) + " | " + ...
    compose("%.3f s", event.elapsedSeconds) + " | " + ...
    string(event.eventName) + " | " + string(event.appCommand) + ...
    " | " + string(event.outcome) + " | " + duration + " | " + ...
    string(event.errorIdentifier);
end

function position = centeredPosition()
screen = double(get(groot, "ScreenSize"));
width = min(1120, max(720, screen(3) - 160));
height = min(620, max(420, screen(4) - 220));
position = round([screen(1) + (screen(3) - width) / 2, ...
    screen(2) + (screen(4) - height) / 2, width, height]);
end
