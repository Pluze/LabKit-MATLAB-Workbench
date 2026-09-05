function applicationState = openFigure(applicationState, callbackContext)
%OPENFIGURE Open a detached editable copy of the complete current document.
% Called by Open figure. The output outlives Studio and preserves all panels,
% styles, and legend edits; later Studio edits do not mutate existing outputs.
session = applicationState.session;
style = applicationState.project.parameters.style;
if isempty(session.cache.plotData), return; end
document = session.editor.document;
report = figure_studio.preflight.check(document, style);
if report.errors > 0
    callbackContext.alert("Resolve blocking preflight issues before opening the figure.", ...
        "Figure Studio Preflight");
    return;
end
sourceAxes = [];
if session.editor.nativePassThrough, sourceAxes = session.cache.sourceAxes; end
[fig, ~] = figure_studio.resultFiles.createStyledFigure( ...
    session.cache.plotData, style, sourceAxes, document);
fig.Name = 'Figure Studio';
fig.Tag = 'figureStudioOutput';
fig.MenuBar = 'figure';
fig.ToolBar = 'figure';
fig.Visible = get(groot, 'DefaultFigureVisible');
callbackContext.log("info", "figure_studio.figure_opened", ...
    "Opened the complete styled figure.");
end
