function layout = resultTable(id, titleText, varargin)
%RESULTTABLE Create a titled result table layout node.
%
% Usage:
%   layout = labkit.ui.layout.resultTable(id, titleText)
%   layout = labkit.ui.layout.resultTable(id, titleText, Name=Value)
%
% Inputs:
%   id - Text scalar used to identify the table. It must be a valid MATLAB
%       variable name and unique within the workbench.
%   titleText - Text displayed in the table panel title.
%
% Name-Value Arguments:
%   columns - Column names as a cell array. Default: {}.
%   data - Initial table, numeric/logical array, or cell data. Default: an empty
%       cell array with one column per entry in columns.
%   columnEditable - Logical scalar or row vector passed to uitable.
%   columnFormat - Cell array of MATLAB uitable column formats.
%   rowName - Row labels. Default: {}, which hides MATLAB row numbers.
%   onCellEdit - Function handle called as onCellEdit(control,event) after an
%       edit. event.value is the complete table data; event.indices,
%       previousData, newData, and editData describe the edited cell.
%   onSelectionChange - Function handle called after a completed cell
%       selection change. event.value is the complete data and event.indices
%       identifies cells. Rapid intermediate selection changes are coalesced
%       so the callback receives the latest completed range. A presenter may
%       update the displayed Data, ColumnName, and RowName properties through
%       the table control's presentation spec.
%
% Outputs:
%   layout - Scalar resultTable node with kind, id, props, children, and slots
%       fields.
%
% Description:
%   resultTable creates a titled uitable that can be placed in a section or the
%   workspace. String and other displayable cell values are converted to text
%   when the table is built. Programmatic data updates do not call onCellEdit.
%
% Errors:
%   labkit:ui:layout:InvalidId, InvalidOptions, or InvalidOptionName - id or
%   Name-value syntax is malformed. Table data, formats, editability, and
%   callback values are validated by MATLAB when the runtime builds the table.
%
% Example:
%   results = labkit.ui.layout.resultTable("summary", "Summary", ...
%       "columns", {"Metric","Value"}, ...
%       "data", {"Mean", 2.5});
%   assert(numel(results.props.columns) == 2)
%
% See also labkit.ui.layout.statusPanel, labkit.ui.layout.workspace

    props = optionStruct(varargin);
    props.title = char(string(titleText));
    layout = makeLayoutNode('resultTable', id, props, {}, struct());
end
