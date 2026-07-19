classdef (Sealed) TableEdit
    %TABLEEDIT Describe one validated table-cell edit signal.
    %
    % Usage:
    %   edit = labkit.ui.TableEdit(Name=Value)
    %
    % Description:
    %   TableEdit replaces raw MATLAB CellEditData and event metadata with
    %   stable row/column identity plus the previous and proposed values.
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
    %
    % Outputs:
    %   edit - Immutable labkit.ui.TableEdit value.
    %
    % Errors:
    %   labkit:ui:contract:UnknownArgument - An option is missing, unknown,
    %       duplicated, or unpaired.
    %   labkit:ui:contract:InvalidValue - An index or ID is malformed.
    %
    % Example:
    %   edit = labkit.ui.TableEdit(RowIndex=2, ColumnIndex=3, ...
    %       ColumnId="group", PreviousValue="A", NewValue="B");
    %   assert(edit.ColumnId == "group")
    %
    % See also labkit.ui.Command, labkit.ui.Selection

    properties (SetAccess = immutable)
        RowId (1, 1) string
        RowIndex (1, 1) double
        ColumnId (1, 1) string
        ColumnIndex (1, 1) double
        PreviousValue
        NewValue
    end

    methods
        function obj = TableEdit(varargin)
            names = ["RowId", "RowIndex", "ColumnId", "ColumnIndex", ...
                "PreviousValue", "NewValue"];
            options = parseContractOptions( ...
                "labkit.ui.TableEdit", names, varargin{:});
            for name = ["RowIndex", "ColumnIndex", ...
                    "PreviousValue", "NewValue"]
                if ~isfield(options, name)
                    error("labkit:ui:contract:UnknownArgument", ...
                        "labkit.ui.TableEdit requires argument %s.", name);
                end
            end
            obj.RowId = optionalText(options, "RowId");
            obj.RowIndex = positiveIndex(options.RowIndex, "RowIndex");
            obj.ColumnId = optionalText(options, "ColumnId");
            obj.ColumnIndex = positiveIndex( ...
                options.ColumnIndex, "ColumnIndex");
            obj.PreviousValue = options.PreviousValue;
            obj.NewValue = options.NewValue;
        end
    end
end

function value = positiveIndex(value, name)
    if ~(isnumeric(value) && isscalar(value) && isfinite(value) && ...
            value >= 1 && value == fix(value))
        error("labkit:ui:contract:InvalidValue", ...
            "TableEdit %s must be a positive integer.", name);
    end
    value = double(value);
end

function value = optionalText(options, name)
    value = "";
    if isfield(options, name)
        supplied = options.(name);
        if ~(ischar(supplied) || (isstring(supplied) && isscalar(supplied)))
            error("labkit:ui:contract:InvalidValue", ...
                "TableEdit %s must be scalar text.", name);
        end
        value = string(supplied);
    end
end
