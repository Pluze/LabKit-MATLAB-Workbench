function ui = createStandardWorkbenchShell(figName, figPosition, leftWidth, rightTitle, rightGridSize, rightRowHeight, rightRowSpacing)
%CREATESTANDARDWORKBENCHSHELL Create the standard three-tab workbench shell.
%
% Inputs:
%   figName, figPosition, leftWidth - forwarded to createWorkbench.
%   rightTitle - optional right panel title, default "Plots".
%   rightGridSize - optional custom right grid size, default [1 1].
%   rightRowHeight - optional custom right row heights, default {'1x'}.
%   rightRowSpacing - optional custom right row spacing, default 8.
%
% Output:
%   ui - workbench struct from createWorkbench.
%
% Calling guidance:
%   Prefer createWorkbench for new apps. This compatibility wrapper only
%   preserves the older standard-shell call shape.

    if nargin < 4 || isempty(rightTitle)
        rightTitle = 'Plots';
    end
    if nargin < 5 || isempty(rightGridSize)
        rightGridSize = [1 1];
    end
    if nargin < 6 || isempty(rightRowHeight)
        rightRowHeight = {'1x'};
    end
    if nargin < 7 || isempty(rightRowSpacing)
        rightRowSpacing = 8;
    end

    opts = struct();
    opts.rightTitle = rightTitle;
    opts.rightGridSize = rightGridSize;
    opts.rightRowHeight = rightRowHeight;
    opts.rightRowSpacing = rightRowSpacing;
    ui = labkit.ui.createWorkbench(figName, figPosition, leftWidth, opts);
end
