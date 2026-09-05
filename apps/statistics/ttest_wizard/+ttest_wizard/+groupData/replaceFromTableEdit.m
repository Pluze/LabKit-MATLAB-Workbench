% App-owned implementation for ttest_wizard.groupData.replaceFromTableEdit within the ttest_wizard product workflow.
function state = replaceFromTableEdit(state, edit, context)
%REPLACEFROMTABLEEDIT Validate and store the complete editable group table.
%
% Expected caller: dataTable OnCellEdited. The typed edit carries the full
% displayed table; this callback rebuilds the durable ordered groups while
% preserving source metadata for labels that still exist.

arguments
    state (1, 1) struct
    edit (1, 1) labkit.app.event.TableCellEdit
    context (1, 1) labkit.app.CallbackContext
end

data = edit.Data;
if ~iscell(data) || size(data, 2) < 2
    context.alert( ...
        "The data table must contain Group and Value columns.", ...
        "Edit analysis data");
    return;
end
[groups, ok, message] = groupsFromRows( ...
    data(:, 1), data(:, 2), state.project.inputs.groups);
if ~ok
    context.alert(message, "Edit analysis data");
    return;
end
state.project.inputs.groups = groups;
if ~any([groups.label] == string(state.project.parameters.captureTarget))
    state.project.parameters.captureTarget = "(new group)";
end
state.project.results.lastDataExport = "";
context.log("info", "ttest_wizard.groupdata.replacefromtableedit.status", sprintf( ...
    'Updated analysis data: %d group(s), %d value(s).', ...
    numel(groups), sum(arrayfun( ...
    @(group) numel(group.values), groups))));
end

function [groups, ok, message] = groupsFromRows( ...
        labels, values, priorGroups)
groups = repmat(ttest_wizard.groupData.emptyGroup("Group 1"), numel(values), 1);
groupCount = 0;
ok = true;
message = "";
priorLabel = "";
for row = 1:numel(values)
    label = strip(string(labels{row}));
    value = values{row};
    if isBlankValue(value) && strlength(label) == 0
        continue;
    end
    if strlength(label) == 0
        label = priorLabel;
    end
    if strlength(label) == 0
        ok = false;
        message = sprintf( ...
            'Row %d needs a group name before its value.', row);
        return;
    end
    [number, valid] = finiteScalar(value);
    if ~valid
        ok = false;
        message = sprintf( ...
            'Row %d Value must be one finite number.', row);
        return;
    end
    groupIndex = find(strcmpi(label, [groups(1:groupCount).label]), 1);
    if isempty(groupIndex)
        group = ttest_wizard.groupData.emptyGroup(label);
        priorIndex = find(strcmpi(label, [priorGroups.label]), 1);
        if ~isempty(priorIndex)
            group = priorGroups(priorIndex);
            group.values = zeros(0, 1);
            group.cellAddresses = strings(0, 1);
        else
            group.sourceDisplayName = "Manual data table";
        end
        groupCount = groupCount + 1;
        groups(groupCount, 1) = group;
        groupIndex = groupCount;
    end
    groups(groupIndex).values(end + 1, 1) = number;
    priorLabel = groups(groupIndex).label;
end
groups = groups(1:groupCount);
% Category editing owns category order; blank destinations have no table rows.
ordered = priorGroups(:);
count = 0;
for k = 1:numel(priorGroups)
    index = find(strcmpi(priorGroups(k).label, string({groups.label})), 1);
    if ~isempty(index)
        count = count + 1;
        ordered(count) = groups(index);
    elseif isempty(priorGroups(k).values)
        count = count + 1;
        ordered(count) = priorGroups(k);
    end
end
ordered = ordered(1:count);
new = ~ismember(lower(string({groups.label})), lower(string({priorGroups.label})));
groups = [ordered(:); groups(new)];
end

function tf = isBlankValue(value)
tf = isempty(value) || ...
    ((ischar(value) || (isstring(value) && isscalar(value))) && ...
    strlength(strip(string(value))) == 0);
end

function [number, valid] = finiteScalar(value)
if (isnumeric(value) || islogical(value)) && isscalar(value)
    number = double(value);
elseif ischar(value) || (isstring(value) && isscalar(value))
    number = str2double(strip(string(value)));
else
    number = NaN;
end
valid = isfinite(number);
end
