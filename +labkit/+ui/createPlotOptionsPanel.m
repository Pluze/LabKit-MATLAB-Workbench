function ui = createPlotOptionsPanel(parent, rowCount, row)
%CREATEPLOTOPTIONSPANEL Create the shared plot-options panel grid.
%
% Inputs:
%   parent - parent grid.
%   rowCount - number of rows inside the options grid.
%   row - optional logical parent row, default 3.
%
% Output:
%   ui - panel-grid struct from createPanelGrid.

    if nargin < 3 || isempty(row)
        row = 3;
    end

    ui = labkit.ui.createPanelGrid(parent, 'Plot Options', row, [rowCount 2]);
end
