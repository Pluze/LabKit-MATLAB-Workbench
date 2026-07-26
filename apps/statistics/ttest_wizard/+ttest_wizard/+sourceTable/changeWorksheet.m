% App-owned implementation for ttest_wizard.sourceTable.changeWorksheet within the ttest_wizard product workflow.
function state = changeWorksheet(state, requested, context)
%CHANGEWORKSHEET Load the requested worksheet and reset its cell selection.
%
% Expected caller: sourceSheet OnValueChanged. The callback depends only on
% the current source cache, portable source record, and selected worksheet;
% it preserves existing analysis groups.

arguments
    state (1, 1) struct
    requested
    context (1, 1) labkit.app.CallbackContext
end

source = state.session.cache.source;
if ~source.ok || isempty(state.project.inputs.sources)
    return;
end
requested = string(requested);
if ~isscalar(requested) || ~any(requested == source.sheetNames)
    requested = source.sheetNames(1);
end
paths = context.resolveSourcePaths(state.project.inputs.sources);
try
    source = ttest_wizard.sourceTable.readSourceTable(paths(1), requested);
catch ME
    context.reportError("Change worksheet", ME);
    context.alert(ME.message, "Worksheet");
    return;
end
state.project.inputs.sourceSheet = source.sheet;
state.session.cache.source = source;
state.session.selection.sourceCells = zeros(0, 2);
state.session.selection.selectionMessage = ...
    "Select numeric cells in the new worksheet.";
context.log("info", "ttest_wizard.sourcetable.changeworksheet.status", ...
    "Selected a source worksheet.");
end
