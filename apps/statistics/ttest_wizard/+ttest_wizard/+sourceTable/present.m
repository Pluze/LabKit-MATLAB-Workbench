% App-owned implementation for ttest_wizard.sourceTable.present within the ttest_wizard product workflow.
function view = present(source, selectedCells, selectionMessage)
%PRESENT Describe the visible source worksheet and cell selection.
%
% Inputs:
%   source - Decoded source-table cache value.
%   selectedCells - Numeric N-by-2 cell coordinates.
%   selectionMessage - Scalar selection summary text.
%
% Outputs:
%   view - Snapshot fragment for source controls and sourceGrid.

[data, columns, rows] = tablePresentation(source);
view = labkit.app.view.Snapshot() ...
    .choices("sourceSheet", source.sheetNames) ...
    .value("sourceSheet", source.sheet) ...
    .enabled("sourceSheet", source.ok && numel(source.sheetNames) > 1) ...
    .text("sourceSummary", source.message) ...
    .text("selectionSummary", selectionMessage) ...
    .tableData("sourceGrid", data, ...
        Columns=columns, RowNames=rows) ...
    .tableCellSelection("sourceGrid", ...
        labkit.app.event.TableCellSelection(selectedCells));
end

function [data, columns, rows] = tablePresentation(source)
if source.ok && source.rowCount > 0 && source.columnCount > 0
    data = source.cells;
    columns = source.columnNames;
    rows = source.rowNames;
else
    data = {'Open a CSV or workbook from the Data controls.'};
    columns = {'A'};
    rows = {'1'};
end
end
