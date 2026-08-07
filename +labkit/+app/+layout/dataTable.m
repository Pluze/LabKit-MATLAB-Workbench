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
%   Title - Reader-facing panel title or blank. A single-table section
%       supplies its title when this is blank. Default: blank.
%   Columns - Column-label text row. Default: strings(1,0).
%   RowNames - Row-label text row. Default: strings(1,0).
%   ColumnEditable - Logical scalar or row matching Columns. Any editable
%       column requires OnCellEdited. Default: false.
%   OnCellEdited - Scalar callback
%       state = callback(state,edit,context), where edit is a
%       labkit.app.event.TableCellEdit. Default: [].
%   OnCellSelectionChanged - Scalar callback
%       state = callback(state,selection,context), where selection is a
%       labkit.app.event.TableCellSelection. Default: [].
%
% Outputs:
%   node - Immutable internal layout node accepted by layout containers.
%
% Errors:
%   Throws labkit:app:contract:* for invalid options, callback signatures,
%   or editable columns without an OnCellEdited owner.
%
% Typical Call:
%   node = labkit.app.layout.dataTable("results", Columns=["Name" "Value"]);
%
% See also labkit.app.event.TableCellEdit,
%   labkit.app.event.TableCellSelection
node = labkit.app.internal.contract.LayoutNode.dataTable(id, varargin{:});
end
