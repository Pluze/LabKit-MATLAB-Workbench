function ui = createStandardWorkbenchShell(figName, figPosition, leftWidth, rightTitle, rightGridSize, rightRowHeight, rightRowSpacing)
%CREATESTANDARDWORKBENCHSHELL Create the standard three-tab workbench shell.
%
% Inputs:
%   figName, figPosition, leftWidth - forwarded to createWorkbench.
%   rightTitle - optional right panel title, default "Plots".
%   rightGridSize, rightRowHeight, rightRowSpacing - custom right grid.
%
% Output:
%   ui - workbench struct from createWorkbench.
%
% Calling guidance:
%   Prefer createWorkbench for new apps; this wrapper preserves the older
%   standard-shell call shape.

    if nargin < 1 || isempty(rightTitle)
        rightTitle = 'Plots';
    end

    opts = struct();
    opts.rightTitle = rightTitle;
    opts.rightGridSize = rightGridSize;
    opts.rightRowHeight = rightRowHeight;
    opts.rightRowSpacing = rightRowSpacing;
    ui = labkit.ui.createWorkbench(figName, figPosition, leftWidth, opts);
end
