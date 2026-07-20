classdef (Sealed) TableCellEdit
    %TABLEEDIT Describe one validated table-cell edit signal.
    %
    % Usage:
    %   edit = labkit.app.event.TableCellEdit(Name=Value)
    %
    % Description:
    %   TableEdit replaces raw MATLAB CellEditData and event metadata with
    %   stable row/column identity, the previous and proposed values, and the
    %   complete proposed table data when the callback must interpret pasted
    %   or related rows atomically.
    %
    % Required Name-Value Arguments:
    %   RowIndex - Positive integer row index.
    %   ColumnIndex - Positive integer column index.
    %   PreviousValue - App-owned value before the edit.
    %   NewValue - App-owned proposed value.
    %
    % Optional Name-Value Arguments:
    %   RowId - Empty or nonempty scalar text stable across sorting. Default:
    %       empty.
    %   ColumnId - Empty or nonempty scalar text stable across display-name
    %       changes. Default: empty.
    %   Data - Complete proposed table data after the edit. Default: empty.
    %
    % Outputs:
    %   edit - Immutable labkit.app.event.TableCellEdit value.
    %
    % Errors:
    %   labkit:app:contract:UnknownArgument - An option is missing, unknown,
    %       duplicated, or unpaired.
    %   labkit:app:contract:InvalidValue - An index or ID is malformed.
    %
    % Example:
    %   edit = labkit.app.event.TableCellEdit(RowIndex=2, ColumnIndex=3, ...
    %       ColumnId="group", PreviousValue="A", NewValue="B");
    %   assert(edit.ColumnId == "group")
    %
    % See also labkit.app.layout.dataTable, labkit.app.event.ListSelection

    properties (SetAccess = immutable)
        RowId (1, 1) string
        RowIndex (1, 1) double
        ColumnId (1, 1) string
        ColumnIndex (1, 1) double
        PreviousValue
        NewValue
        Data
    end

    methods
        function obj = TableCellEdit(varargin)
            names = ["RowId", "RowIndex", "ColumnId", "ColumnIndex", ...
                "PreviousValue", "NewValue", "Data"];
            options = labkit.app.internal.OptionParser.parse( ...
                "labkit.app.event.TableCellEdit", names, varargin{:});
            for name = ["RowIndex", "ColumnIndex", ...
                    "PreviousValue", "NewValue"]
                if ~isfield(options, name)
                    error("labkit:app:contract:UnknownArgument", ...
                        "labkit.app.event.TableCellEdit requires argument %s.", name);
                end
            end
            obj.RowId = optionalText(options, "RowId");
            obj.RowIndex = positiveIndex(options.RowIndex, "RowIndex");
            obj.ColumnId = optionalText(options, "ColumnId");
            obj.ColumnIndex = positiveIndex( ...
                options.ColumnIndex, "ColumnIndex");
            obj.PreviousValue = options.PreviousValue;
            obj.NewValue = options.NewValue;
            obj.Data = optionValue(options, "Data", []);
        end
    end
end

function value = optionValue(options, name, defaultValue)
    value = defaultValue;
    if isfield(options, name)
        value = options.(name);
    end
end

function value = positiveIndex(value, name)
    if ~(isnumeric(value) && isscalar(value) && isfinite(value) && ...
            value >= 1 && value == fix(value))
        error("labkit:app:contract:InvalidValue", ...
            "TableEdit %s must be a positive integer.", name);
    end
    value = double(value);
end

function value = optionalText(options, name)
    value = "";
    if isfield(options, name)
        supplied = options.(name);
        if ~(ischar(supplied) || (isstring(supplied) && isscalar(supplied)))
            error("labkit:app:contract:InvalidValue", ...
                "TableEdit %s must be scalar text.", name);
        end
        value = string(supplied);
    end
end
