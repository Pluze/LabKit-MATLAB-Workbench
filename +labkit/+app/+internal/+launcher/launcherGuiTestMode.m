function mode = launcherGuiTestMode()
%LAUNCHERGUITESTMODE Return the private visible/hidden Launcher test mode.

mode = "visible";
if isappdata(groot, "labkitLauncherGuiTestMode")
    mode = string(getappdata(groot, "labkitLauncherGuiTestMode"));
end
end
