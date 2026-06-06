% Private UI app helper. Expected caller: labkit.ui.app shell construction
% code. Inputs and outputs are internal uifigure, grid, tab, or resize handle
% values. Side effects are limited to UI object creation or callback wiring on
% supplied parents; assumes the caller owns component lifecycle.
function handle = addRowResizeHandle(fig, grid, handleRow, opts)
%ADDROWRESIZEHANDLE Add a draggable horizontal resize handle between grid rows.
%
% Usage:
%   handle = addRowResizeHandle(fig, grid, 2, ...
%       struct('topRow', 1, 'bottomRow', 3));
%
% Inputs:
%   fig - owning figure.
%   grid - parent uigridlayout.
%   handleRow - physical row reserved for the drag handle.
%   opts - optional struct.
%
% Options:
%   topRow - physical row above handle, default handleRow-1.
%   bottomRow - physical row below handle, default handleRow+1.
%   minTopHeight - pixels, default 80.
%   minBottomHeight - pixels, default 80.
%   handleHeight - pixels, default 6.
%
% Output:
%   handle - uipanel used as the draggable separator.

    if nargin < 4
        opts = struct();
    end

    topRow = optionValue(opts, 'topRow', handleRow - 1);
    bottomRow = optionValue(opts, 'bottomRow', handleRow + 1);
    minTopHeight = optionValue(opts, 'minTopHeight', 80);
    minBottomHeight = optionValue(opts, 'minBottomHeight', 80);
    handleHeight = optionValue(opts, 'handleHeight', 6);

    rows = grid.RowHeight;
    rows{handleRow} = handleHeight;
    grid.RowHeight = rows;

    handle = uipanel(grid, ...
        'BackgroundColor', [0.75 0.75 0.75], ...
        'BorderType', 'none');
    handle.Layout.Row = handleRow;
    handle.Layout.Column = 1;
    handle.ButtonDownFcn = @startDrag;

    drag = struct('startY', 0, 'topHeight', 0, 'bottomHeight', 0);

    function startDrag(~, ~)
        drawnow;
        drag.startY = fig.CurrentPoint(2);
        drag.topHeight = rowHeightFromChild(grid, topRow, minTopHeight);
        drag.bottomHeight = rowHeightFromChild(grid, bottomRow, minBottomHeight);
        fig.Pointer = 'top';
        fig.WindowButtonMotionFcn = @doDrag;
        fig.WindowButtonUpFcn = @stopDrag;
    end

    function doDrag(~, ~)
        deltaDown = drag.startY - fig.CurrentPoint(2);
        newTop = max(minTopHeight, drag.topHeight + deltaDown);
        newBottom = max(minBottomHeight, drag.bottomHeight - deltaDown);

        rowHeights = grid.RowHeight;
        rowHeights{topRow} = newTop;
        rowHeights{handleRow} = handleHeight;
        rowHeights{bottomRow} = newBottom;
        grid.RowHeight = rowHeights;
    end

    function stopDrag(~, ~)
        fig.WindowButtonMotionFcn = '';
        fig.WindowButtonUpFcn = '';
        fig.Pointer = 'arrow';
    end
end

function height = rowHeightFromChild(grid, row, fallback)
    height = fallback;
    children = grid.Children;
    for k = 1:numel(children)
        layout = children(k).Layout;
        if isprop(layout, 'Row') && isequal(layout.Row, row)
            pos = children(k).Position;
            if numel(pos) >= 4 && isfinite(pos(4)) && pos(4) > 0
                height = pos(4);
                return;
            end
        end
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isfield(opts, name)
        value = opts.(name);
    end
end
