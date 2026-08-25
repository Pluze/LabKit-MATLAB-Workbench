function state = deleteTicks(state, callbackContext)
rows = unique(state.session.editor.selectedTickRows(:));
if isempty(rows), return; end
before = state.session.editor.document;
document = before;
panelIndex = find(string({document.panels.id}) == ...
    state.session.editor.activePanelId, 1);
if isempty(panelIndex), panelIndex = 1; end
axisName = char(figure_studio.axisEditing.axisField( ...
    state.session.editor.axisTarget));
axisValue = document.panels(panelIndex).axes.(axisName);
rows = rows(rows >= 1 & rows <= numel(axisValue.ticks));
axisValue.ticks(rows) = [];
axisValue.locator.mode = "explicit";
axisValue.locator.values = [axisValue.ticks.value];
axisValue.formatter.mode = "explicit";
axisValue.formatter.labels = string({axisValue.ticks.label});
document.panels(panelIndex).axes.(axisName) = axisValue;
state.session.editor.selectedTickRows = zeros(0, 1);
state = figure_studio.axisEditing.commitDocument( ...
    state, before, document, "Delete ticks");
callbackContext.log("info", "figure_studio.axisediting.deleteticks.status", ...
    state.session.workflow.status);
end
