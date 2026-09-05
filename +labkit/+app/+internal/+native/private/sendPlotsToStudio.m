function sendPlotsToStudio(ax, tool, execute, profileTransfer)
% Send one plot through a timed native handoff, with duplicate-input protection.
% Caller owns the source axes and supplies a narrow diagnostic executor.
if nargin < 4
    profileTransfer = false;
end
sourceFigure = ancestor(ax, "figure");
if isappdata(sourceFigure, "labkitStudioTransferActive") && ...
        getappdata(sourceFigure, "labkitStudioTransferActive")
    return;
end
setappdata(sourceFigure, "labkitStudioTransferActive", true);
oldPointer = sourceFigure.Pointer;
sourceFigure.Pointer = "watch";
oldEnabled = tool.Enable;
tool.Enable = "off";
cleanup = onCleanup(@() restoreInput(sourceFigure, tool, oldPointer, oldEnabled));
drawnow nocallbacks;
try
    if profileTransfer
        profileHandoff(@() execute("plots.studio_handoff", @() handoff(ax, execute)));
    else
        execute("plots.studio_handoff", @() handoff(ax, execute));
    end
catch cause
    if isgraphics(sourceFigure)
        if isa(sourceFigure, "matlab.ui.Figure") && ...
                isprop(sourceFigure, "Scrollable")
            uialert(sourceFigure, cause.message, "Figure Studio");
        else
            warning("labkit:app:plot:StudioHandoffFailed", "%s", cause.message);
        end
    end
end
end

function handoff(ax, execute)
root = fileparts(mfilename("fullpath"));
for level = 1:5
    root = fileparts(root);
end
apps = execute("plots.studio_discovery", ...
    @() labkit.app.internal.discovery.discoverApps(root));
match = find(string({apps.command}) == "labkit_FigureStudio_app", 1);
if isempty(match)
    error("labkit:app:plot:FigureStudioUnavailable", ...
        "Figure Studio is not available in this LabKit installation.");
end
figureValue = execute("plots.studio_launch", ...
    @() labkit.app.internal.discovery.invokeDiscoveredApp(apps(match), "axes", ax));
if isappdata(figureValue, "labkitAppStartupFailure")
    error("labkit:app:plot:StudioStartupFailed", ...
        "Figure Studio could not prepare the plot. Inspect its session log.");
end
end

function profileHandoff(operation)
status = profile("status");
if string(status.ProfilerStatus) == "on"
    error("labkit:app:plot:ProfilerActive", ...
        "Stop the active MATLAB profiler before profiling a Studio handoff.");
end
root = fileparts(mfilename("fullpath"));
for level = 1:5
    root = fileparts(root);
end
labkit.app.internal.launcher.invokeLauncherTool( ...
    root, fullfile("tools", "profiling"), "profileLabKitTarget", ...
    operation, [], OpenReport=false, WaitForGuiClose=false, ...
    PrintSummary=true, RethrowError=true);
end
function restoreInput(fig, tool, pointer, enabled)
if isgraphics(fig)
    fig.Pointer = pointer;
    setappdata(fig, "labkitStudioTransferActive", false);
end
if isgraphics(tool)
    tool.Enable = enabled;
end
end
