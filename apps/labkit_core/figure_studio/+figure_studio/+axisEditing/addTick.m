function state = addTick(state, callbackContext)
before = state.session.editor.document;
document = before;
[panelIndex, axisName, axisValue] = activeAxis(state.session.editor);
values = [axisValue.ticks.value];
if isempty(values)
    value = mean(axisValue.limits);
elseif isscalar(values)
    value = values(end) + max(1, diff(axisValue.limits) / 5);
else
    value = values(end) + median(diff(values));
end
row = struct("value", value, "label", string(sprintf("%.15g", value)), ...
    "visible", true, "level", "major", "rotation", 0, ...
    "fontOverride", struct());
axisValue.ticks(end + 1, 1) = row;
[~, order] = sort([axisValue.ticks.value]);
axisValue.ticks = axisValue.ticks(order);
axisValue = synchronize(axisValue);
document.panels(panelIndex).axes.(axisName) = axisValue;
state = figure_studio.axisEditing.commitDocument( ...
    state, before, document, "Add tick");
callbackContext.log("info", "figure_studio.axisediting.addtick.status", ...
    state.session.workflow.status);
end

function [panelIndex, axisName, axisValue] = activeAxis(editor)
panelIndex = find(string({editor.document.panels.id}) == editor.activePanelId, 1);
if isempty(panelIndex), panelIndex = 1; end
axisName = char(figure_studio.axisEditing.axisField(editor.axisTarget));
axisValue = editor.document.panels(panelIndex).axes.(axisName);
end

function axisValue = synchronize(axisValue)
axisValue.locator.mode = "explicit";
axisValue.locator.values = [axisValue.ticks.value];
axisValue.formatter.mode = "explicit";
axisValue.formatter.labels = string({axisValue.ticks.label});
end
