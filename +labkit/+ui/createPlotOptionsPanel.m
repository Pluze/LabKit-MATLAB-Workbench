function ui = createPlotOptionsPanel(parent, rowCount, row)
%CREATEPLOTOPTIONSPANEL Create the shared plot-options panel grid.

    if nargin < 3 || isempty(row)
        row = 3;
    end

    ui = labkit.ui.createPanelGrid(parent, 'Plot Options', row, [rowCount 2]);
end
