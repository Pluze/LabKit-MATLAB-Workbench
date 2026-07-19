function view = present(groups, captureTarget, batchTarget, ...
        analysisCells, sourceReady, sourceCells)
%PRESENT Describe editable groups and the actions available for selections.
%
% Inputs:
%   groups - Ordered durable group struct array.
%   captureTarget - Current destination for source values.
%   batchTarget - Current destination for selected analysis rows.
%   analysisCells - Selected analysis-table cell coordinates.
%   sourceReady - Logical scalar indicating a decoded source table.
%   sourceCells - Selected source-table cell coordinates.
%
% Outputs:
%   view - Snapshot fragment for group controls and dataTable.

captureChoices = ["(new group)", [groups.label]];
captureValue = legalChoice(captureTarget, captureChoices);
batchChoices = ["(select group)", [groups.label]];
batchValue = legalChoice(batchTarget, batchChoices);
view = labkit.app.view.Snapshot() ...
    .choices("captureTarget", captureChoices) ...
    .value("captureTarget", captureValue) ...
    .enabled("captureGroup", sourceReady && ~isempty(sourceCells)) ...
    .choices("batchGroupTarget", batchChoices) ...
    .value("batchGroupTarget", batchValue) ...
    .enabled("batchGroupTarget", ~isempty(groups)) ...
    .enabled("assignRowsToGroup", ...
        ~isempty(groups) && ~isempty(analysisCells) && ...
        batchValue ~= "(select group)") ...
    .enabled("deleteSelectedRows", ...
        hasSelectedObservationRows(analysisCells, groups)) ...
    .enabled("clearGroups", ~isempty(groups)) ...
    .tableData("dataTable", observationRows(groups), ...
        Columns=["Group", "Value"], ColumnEditable=[true true]) ...
    .tableCellSelection("dataTable", ...
        labkit.app.event.TableCellSelection(analysisCells));
end

function value = legalChoice(value, choices)
value = string(value);
if ~any(choices == value)
    value = choices(1);
end
end

function data = observationRows(groups)
valueCount = sum(arrayfun(@(group) numel(group.values), groups));
blankRows = 8;
data = cell(valueCount + blankRows, 2);
row = 0;
for groupIndex = 1:numel(groups)
    for valueIndex = 1:numel(groups(groupIndex).values)
        row = row + 1;
        data{row, 1} = char(groups(groupIndex).label);
        data{row, 2} = groups(groupIndex).values(valueIndex);
    end
end
for k = row + 1:size(data, 1)
    data{k, 1} = '';
    data{k, 2} = '';
end
end

function tf = hasSelectedObservationRows(selected, groups)
observationCount = sum(arrayfun(@(group) numel(group.values), groups));
tf = isnumeric(selected) && size(selected, 2) == 2 && ...
    any(selected(:, 1) >= 1 & selected(:, 1) <= observationCount);
end
