classdef (Sealed) TableCellSelection
    %TABLECELLSELECTION Describe selected cells in a semantic data table.
    %
    % Usage:
    %   selection = labkit.app.event.TableCellSelection(cellIndices)
    %
    % Description:
    %   TableCellSelection carries unique N-by-2 row/column index pairs.
    %   It replaces native MATLAB table-selection event shapes at the App
    %   callback boundary.
    %
    % Inputs:
    %   cellIndices - Unique positive integer N-by-2 matrix. An empty
    %       selection is zeros(0,2).
    %
    % Outputs:
    %   selection - Immutable TableCellSelection value.
    %
    % Errors:
    %   labkit:app:contract:InvalidValue - cellIndices is not a unique
    %       positive integer N-by-2 matrix.
    %
    % Example:
    %   selection = labkit.app.event.TableCellSelection([1 2; 3 1]);
    %   assert(isequal(selection.CellIndices, [1 2; 3 1]))
    %
    % See also labkit.app.event.TableCellEdit,
    %   labkit.app.StateHandler

    properties (SetAccess = immutable)
        CellIndices (:, 2) double
    end

    methods
        function obj = TableCellSelection(cellIndices)
            if ~(isnumeric(cellIndices) && size(cellIndices, 2) == 2 && ...
                    all(isfinite(cellIndices), "all") && ...
                    all(cellIndices >= 1, "all") && ...
                    all(cellIndices == fix(cellIndices), "all") && ...
                    size(unique(cellIndices, "rows"), 1) == ...
                    size(cellIndices, 1))
                error("labkit:app:contract:InvalidValue", ...
                    "TableCellSelection requires unique positive " + ...
                    "row/column index pairs.");
            end
            obj.CellIndices = double(cellIndices);
        end
    end
end
