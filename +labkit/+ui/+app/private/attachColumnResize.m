function attachColumnResize(fig, grid, leftColumn, separatorColumn, opts)
%ATTACHCOLUMNRESIZE Attach drag-to-resize behavior to a grid separator.
%
% Called by:
%   createTabbedWorkbenchShell and other UI shell internals.
%
% Inputs:
%   fig - owning uifigure whose pointer and window callbacks are used.
%   grid - uigridlayout with a separator panel in separatorColumn.
%   leftColumn - column index whose width should be resized.
%   separatorColumn - column index containing the drag handle panel.
%   opts - optional struct with minWidth, rightReserve, and separatorWidth.
%
% Side effects:
%   Installs ButtonDownFcn on the separator and temporary figure
%   WindowButtonMotionFcn/WindowButtonUpFcn callbacks while dragging.
%
% Notes:
%   This helper mutates layout handles only; apps should normally request
%   resizable shells through labkit.ui.app.createShell.

    if nargin < 5
        opts = struct();
    end

    minWidth = optionValue(opts, 'minWidth', 260);
    rightReserve = optionValue(opts, 'rightReserve', 360);
    separatorWidth = optionValue(opts, 'separatorWidth', 6);

    separator = findSeparator(grid, separatorColumn);
    separator.ButtonDownFcn = @startDrag;

    function startDrag(~, ~)
        fig.Pointer = 'left';
        fig.WindowButtonMotionFcn = @doDrag;
        fig.WindowButtonUpFcn = @stopDrag;
    end

    function doDrag(~, ~)
        pointer = fig.CurrentPoint;
        newWidth = max(minWidth, pointer(1) - grid.Position(1));
        maxWidth = max(minWidth, fig.Position(3) - rightReserve);
        newWidth = min(newWidth, maxWidth);

        widths = grid.ColumnWidth;
        widths{leftColumn} = newWidth;
        widths{separatorColumn} = separatorWidth;
        grid.ColumnWidth = widths;
    end

    function stopDrag(~, ~)
        fig.WindowButtonMotionFcn = '';
        fig.WindowButtonUpFcn = '';
        fig.Pointer = 'arrow';
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isfield(opts, name)
        value = opts.(name);
    end
end

function separator = findSeparator(grid, separatorColumn)
    separator = [];
    children = grid.Children;
    for k = 1:numel(children)
        layout = children(k).Layout;
        if isprop(layout, 'Column') && isequal(layout.Column, separatorColumn)
            separator = children(k);
            return;
        end
    end

    error('labkit:ui:MissingSeparator', ...
        'Could not find a grid child in separator column %d.', separatorColumn);
end
