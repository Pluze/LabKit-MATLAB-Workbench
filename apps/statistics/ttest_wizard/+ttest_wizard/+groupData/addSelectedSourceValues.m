function state = addSelectedSourceValues(state, context)
%ADDSELECTEDSOURCEVALUES Append selected numeric source cells to one group.
%
% Expected caller: captureGroup button. The callback reads the source-table
% cache and selection, updates durable groups, and reports the accepted count.

arguments
    state (1, 1) struct
    context (1, 1) labkit.app.CallbackContext
end

source = state.session.cache.source;
indices = state.session.selection.sourceCells;
if ~source.ok || isempty(indices)
    context.alert("Select cells in the opened table first.", "Select data");
    return;
end
selected = ttest_wizard.sourceTable.extractNumericSelection( ...
    source.cells, indices);
state.session.selection.selectionMessage = selected.message;
if ~selected.ok
    context.alert(selected.message, "Selected cells cannot be used");
    return;
end

groups = state.project.inputs.groups;
target = string(state.project.parameters.captureTarget);
groupIndex = find(string({groups.label}) == target, 1);
if isempty(groupIndex)
    label = ttest_wizard.sourceTable.suggestGroupLabel( ...
        source.cells, indices, [groups.label]);
    group = ttest_wizard.groupData.emptyGroup(label);
    group.sourceDisplayName = source.displayName;
    group.sheet = source.sheet;
    groups(end + 1, 1) = group;
    groupIndex = numel(groups);
end
groups(groupIndex).values = [ ...
    groups(groupIndex).values(:); selected.values(:)];
groups(groupIndex).cellAddresses = [ ...
    groups(groupIndex).cellAddresses(:); selected.addresses(:)];
state.project.inputs.groups = groups;
state.project.parameters.captureTarget = "(new group)";
state.project.results.lastDataExport = "";
context.appendStatus(sprintf( ...
    'Added %d value(s) to %s.', ...
    selected.acceptedCount, groups(groupIndex).label));
end
