function ui = plotOptionsPanel(parent, rowCount, row)
%CREATEPLOTOPTIONSPANEL Create the shared plot-options panel grid.
%
% Inputs:
%   parent - parent grid.
%   rowCount - number of rows inside the options grid.
%   row - optional logical parent row, default 3.
%
% Output:
%   ui - section struct from labkit.ui.view.section.

    if nargin < 3 || isempty(row)
        row = 3;
    end

    ui = labkit.ui.view.section(parent, 'Plot Options', row, [rowCount 2]);
end
