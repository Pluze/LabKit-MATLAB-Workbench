function result = nativeGraphicsCapability(kind)
%NATIVEGRAPHICSCAPABILITY Probe the native engine before testing UI outputs.
% SDK and App clipboard tests use an independent Base MATLAB operation to
% distinguish successful image evidence from unavailable batch-display
% evidence. Callers must still assert the corresponding product outcome.
% No tests are skipped: unrelated errors and unavailable interactive sessions
% propagate. The probe owns and removes its figure and temporary capture.
arguments
    kind (1, 1) string {mustBeMember(kind, ["clipboard", "interface-capture"])}
end
result = struct("Available", true, "ErrorIdentifier", "");
filename = string(tempname) + ".png";
if kind == "interface-capture"
    fig = uifigure(Visible="off", Position=[100 100 200 150]);
    uilabel(fig, Text="Synthetic capture", Position=[10 10 160 30]);
else
    fig = figure(Visible="off");
    ax = axes(fig);
    plot(ax, 1:2, 1:2);
end
cleanup = onCleanup(@() cleanupProbe(fig, filename));
try
    if kind == "interface-capture"
        exportapp(fig, filename);
    else
        copygraphics(ax, ContentType="image");
    end
catch cause
    known = ["MATLAB:print:HeadlessFigureUnsupported", ...
        "MATLAB:javachk:featureNotAvailable"];
    if ~batchStartupOptionUsed() || ~any(string(cause.identifier) == known)
        rethrow(cause);
    end
    result.Available = false;
    result.ErrorIdentifier = string(cause.identifier);
end
fprintf("NATIVE_GRAPHICS capability=%s available=%d error=%s\n", ...
    kind, result.Available, result.ErrorIdentifier);
end

function cleanupProbe(fig, filename)
if isgraphics(fig), delete(fig); end
if isfile(filename), delete(filename); end
end
