function spec = resultTable(id, titleText, varargin)
%RESULTTABLE Create a titled result table spec.
%
% App-facing contract:
%   spec = labkit.ui.spec.resultTable(id, title, "columns", columns, ...)
%
% Inputs:
%   id - globally unique result table id.
%   titleText - table panel title.
%   columns - cell array of column names, default {}.
%   data - initial table data, default empty cell array.
%   columnEditable - optional logical row vector or scalar applied to
%       uitable ColumnEditable.
%   columnFormat - optional cell array applied to uitable ColumnFormat.
%   rowName - optional row header labels. Defaults to {} so compact LabKit
%       tables do not show MATLAB row numbers.
%   onCellEdit - optional callback invoked after a user edits a table cell.
%   onSelectionChange - optional callback invoked after table cell selection.
%   Concrete table sizing and column widths are owned by the framework.
%
% Output:
%   spec - scalar data-only UI spec struct.

    props = optionStruct(varargin);
    props.title = char(string(titleText));
    spec = makeSpec('resultTable', id, props, {}, struct());
end
