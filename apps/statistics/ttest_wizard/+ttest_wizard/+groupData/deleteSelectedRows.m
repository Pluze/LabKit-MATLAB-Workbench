function state = deleteSelectedRows(state, context)
%DELETESELECTEDROWS Remove selected observations from durable group data.
%
% Expected caller: deleteSelectedRows button. Empty groups and now-invalid
% capture/assignment choices are removed or reset atomically.

arguments
    state (1, 1) struct
    context (1, 1) labkit.app.CallbackContext
end

selectedRows = selectedObservationRows(state);
if isempty(selectedRows)
    return;
end
groups = deleteRows(state.project.inputs.groups, selectedRows);
state.project.inputs.groups = groups;
state.session.selection.analysisCells = zeros(0, 2);
labels = string({groups.label});
if ~any(labels == string(state.project.parameters.captureTarget))
    state.project.parameters.captureTarget = "(new group)";
end
if ~any(labels == string(state.session.selection.batchGroupTarget))
    state.session.selection.batchGroupTarget = "(select group)";
end
state.project.results.lastDataExport = "";
context.appendStatus(sprintf( ...
    'Deleted %d selected row(s).', numel(selectedRows)));
end

function groups = deleteRows(groups, selectedRows)
rowOffset = 0;
for groupIndex = 1:numel(groups)
    count = numel(groups(groupIndex).values);
    visibleRows = rowOffset + (1:count);
    rowOffset = rowOffset + count;
    remove = ismember(visibleRows, selectedRows);
    groups(groupIndex).values = groups(groupIndex).values(~remove);
    addresses = string(groups(groupIndex).cellAddresses(:));
    if numel(addresses) == count
        groups(groupIndex).cellAddresses = addresses(~remove);
    else
        groups(groupIndex).cellAddresses = strings(0, 1);
    end
end
groups = groups(arrayfun(@(group) ~isempty(group.values), groups));
end

function rows = selectedObservationRows(state)
rows = unique(state.session.selection.analysisCells(:, 1), 'stable');
observationCount = sum(arrayfun( ...
    @(group) numel(group.values), state.project.inputs.groups));
rows = rows(rows >= 1 & rows <= observationCount);
end
