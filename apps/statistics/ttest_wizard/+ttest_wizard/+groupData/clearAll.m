% App-owned implementation for ttest_wizard.groupData.clearAll within the ttest_wizard product workflow.
function state = clearAll(state, context)
%CLEARALL Remove every analysis group and reset related transient choices.
%
% Expected caller: clearGroups button.

arguments
    state (1, 1) struct
    context (1, 1) labkit.app.CallbackContext
end

state.project.inputs.groups = repmat( ...
    ttest_wizard.groupData.emptyGroup("Group 1"), 0, 1);
state.project.parameters.captureTarget = "(new group)";
state.session.selection.analysisCells = zeros(0, 2);
state.session.selection.batchGroupTarget = "(select group)";
state.project.results.lastDataExport = "";
context.log("info", "ttest_wizard.groupdata.clearall.status", "Cleared all analysis data.");
end
