function state = undo(state, callbackContext)
[state.session.editor.history, document] = ...
    figure_studio.figureDocument.history("undo", ...
    state.session.editor.history, state.session.editor.document);
state = replaceDocument(state, document, "Undo figure edit");
callbackContext.log("info", "figure_studio.axisediting.undo.status", ...
    state.session.workflow.status);
end

function state = replaceDocument(state, document, label)
state.session.editor.document = document;
state.session.cache.plotData = figure_studio.figureDocument.toPlotData( ...
    document, state.session.editor.activePanelId);
state.session.cache.limitState = figure_studio.sourceAxes.limitControls( ...
    state.session.cache.plotData);
state.session.cache.viewRevision = state.session.cache.viewRevision + 1;
state.session.workflow.status = label + ".";
state.project.results.lastExport = [];
state.project.results.lastOutputPath = "";
end
