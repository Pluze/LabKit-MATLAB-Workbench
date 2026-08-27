%COMMITDOCUMENT Record and publish one atomic Figure Studio presentation edit.
function state = commitDocument(state, before, document, label)
[state.session.editor.history, ~] = figure_studio.figureDocument.history( ...
    "commit", state.session.editor.history, before, label);
state = replaceDocument(state, document, label);
end

function state = replaceDocument(state, document, label)
state.session.editor.document = document;
state.session.cache.plotData = figure_studio.figureDocument.toPlotData( ...
    document, state.session.editor.activePanelId);
state.session.cache.limitState = figure_studio.sourceAxes.limitControls( ...
    state.session.cache.plotData);
state.session.workflow.status = string(label) + ".";
state.project.results.lastExport = [];
state.project.results.lastOutputPath = "";
end
