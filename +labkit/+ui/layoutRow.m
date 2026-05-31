function row = layoutRow(parent, logicalRow)
%LAYOUTROW Map a workbench tab's logical row to its physical grid row.
%
% Inputs:
%   parent - workbench tab grid or ordinary grid.
%   logicalRow - row index used by app code.
%
% Output:
%   row - physical grid row. Ordinary grids return logicalRow unchanged.

    row = logicalRow;
    if isempty(logicalRow) || ~isprop(parent, 'UserData')
        return;
    end

    data = parent.UserData;
    if ~isstruct(data) || ~isfield(data, 'LabKitLogicalRowMap')
        return;
    end

    rowMap = data.LabKitLogicalRowMap;
    for k = 1:numel(logicalRow)
        idx = logicalRow(k);
        if isnumeric(idx) && isfinite(idx) && idx >= 1 && idx <= numel(rowMap) && idx == floor(idx)
            row(k) = rowMap(idx);
        end
    end
end
