% App-owned implementation for ttest_wizard.groupData.assignSelectedRows within the ttest_wizard product workflow.
function state = assignSelectedRows(state, context)
%ASSIGNSELECTEDROWS Move selected observations into the chosen group.
%
% Expected caller: assignRowsToGroup button. The callback derives visible
% observation rows from the current groups and clears the selection afterward.

arguments
    state (1, 1) struct
    context (1, 1) labkit.app.CallbackContext
end

target = string(state.session.selection.batchGroupTarget);
selectedRows = selectedObservationRows(state);
if target == "(select group)" || isempty(selectedRows)
    return;
end
state.project.inputs.groups = reassignRows( ...
    state.project.inputs.groups, selectedRows, target);
state.session.selection.analysisCells = zeros(0, 2);
state.project.results.lastDataExport = "";
context.appendStatus(sprintf( ...
    'Changed %d selected row(s) to %s.', numel(selectedRows), target));
end

function groups = reassignRows(groups, selectedRows, target)
visibleRows = cell(numel(groups), 1);
movedValueParts = repmat({zeros(0, 1)}, numel(groups), 1);
movedAddressParts = repmat({strings(0, 1)}, numel(groups), 1);
rowOffset = 0;
for groupIndex = 1:numel(groups)
    count = numel(groups(groupIndex).values);
    visibleRows{groupIndex} = rowOffset + (1:count);
    rowOffset = rowOffset + count;
    move = ismember(visibleRows{groupIndex}, selectedRows);
    if groups(groupIndex).label ~= target
        movedValueParts{groupIndex} = groups(groupIndex).values(move);
        addresses = string(groups(groupIndex).cellAddresses(:));
        if numel(addresses) == count
            movedAddressParts{groupIndex} = addresses(move);
            groups(groupIndex).cellAddresses = addresses(~move);
        end
        groups(groupIndex).values = groups(groupIndex).values(~move);
    end
end
movedValues = vertcat(movedValueParts{:});
movedAddresses = vertcat(movedAddressParts{:});
targetIndex = find([groups.label] == target, 1);
groups(targetIndex).values = [groups(targetIndex).values(:); movedValues];
groups(targetIndex).cellAddresses = [ ...
    string(groups(targetIndex).cellAddresses(:)); movedAddresses];
groups = groups(arrayfun(@(group) ~isempty(group.values), groups));
end

function rows = selectedObservationRows(state)
rows = unique(state.session.selection.analysisCells(:, 1), 'stable');
observationCount = sum(arrayfun( ...
    @(group) numel(group.values), state.project.inputs.groups));
rows = rows(rows >= 1 & rows <= observationCount);
end
