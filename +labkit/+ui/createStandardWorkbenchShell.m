function ui = createStandardWorkbenchShell(figName, figPosition, leftWidth, rightTitle, rightGridSize, rightRowHeight, rightRowSpacing)
%CREATESTANDARDWORKBENCHSHELL Create the standard three-tab workbench shell.

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
