function applicationState = copyFigure(applicationState, callbackContext)
% Copy the current complete styled document after publication preflight.
% The clipboard is the explicit output; file-export destinations stay intact.
session = applicationState.session;
style = applicationState.project.parameters.style;
if isempty(session.cache.plotData)
    callbackContext.alert("Load a figure before copying.", "Figure Studio");
    return;
end
document = session.editor.document;
report = figure_studio.preflight.check(document, style);
if report.errors > 0
    callbackContext.alert( ...
        "Resolve the blocking publication preflight issues before copying.", ...
        "Figure Studio Preflight");
    return;
end
sourceAxes = [];
if session.editor.nativePassThrough
    sourceAxes = session.cache.sourceAxes;
end
[fig, ~] = figure_studio.resultFiles.createStyledFigure( ...
    session.cache.plotData, style, sourceAxes, document);
cleanup = onCleanup(@() delete(fig));
copygraphics(fig, ContentType="image", ...
    Resolution=max(72, round(300 * style.exportScale)));
callbackContext.log("info", "figure_studio.figure_copied", ...
    "Copied the complete styled figure to the clipboard.");
end
