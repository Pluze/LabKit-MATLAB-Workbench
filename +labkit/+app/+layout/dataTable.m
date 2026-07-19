function node = dataTable(id, varargin)
%DATATABLE Add a tabular data display with optional editing and selection.
%
% Usage:
%   node = labkit.app.layout.dataTable(id, Name=Value)
%
% Description:
%   Declares a semantic data table and typed cell callbacks.
%
% Inputs:
%   id - Unique MATLAB identifier for the layout target.
%
% Options:
%   Columns - Column-label text row. Default: strings(1,0).
%   RowNames - Row-label text row. Default: strings(1,0).
%   ColumnEditable - Logical scalar or row matching Columns. Default: false.
%   CellEdited - StateHandler with Event="tableCellEdit". Default: [].
%   CellSelectionChanged - StateHandler with Event="tableCellSelection".
%       Default: [].
%
% Outputs:
%   node - Immutable internal layout node accepted by layout containers.
%
% Errors:
%   Throws labkit:app:contract:* for invalid options or handler events.
%
% Typical Call:
%   node = labkit.app.layout.dataTable("results", Columns=["Name" "Value"]);
%
% See also labkit.app.event.TableCellEdit,
%   labkit.app.event.TableCellSelection
node = labkit.app.internal.LayoutNode.dataTable(id, varargin{:});
end
