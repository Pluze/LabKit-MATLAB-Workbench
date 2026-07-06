% Private UI runtime helper. Expected caller: labkit.ui.runtime shell construction
% code. Inputs and outputs are internal uifigure, grid, tab, or resize handle
% values. Side effects are limited to UI object creation or callback wiring on
% supplied parents; assumes the caller owns component lifecycle.
function handle = addRowResizeHandle(fig, grid, handleRow, opts)
%ADDROWRESIZEHANDLE Add a draggable horizontal resize handle between grid rows.
%
% Usage:
%   handle = addRowResizeHandle(fig, grid, 2, ...
%       struct('topRow', 1));
%
% Inputs:
%   fig - owning figure.
%   grid - parent uigridlayout.
%   handleRow - physical row reserved for the drag handle.
%   opts - optional struct.
%
% Options:
%   topRow - physical row above handle, default handleRow-1.
%   minTopHeight - pixels, default 80.
%   handleHeight - pixels, default 6.
%
% Output:
%   handle - panel component used as the draggable separator.

    if nargin < 4
        opts = struct();
    end

    topRow = optionValue(opts, 'topRow', handleRow - 1);
    minTopHeight = optionValue(opts, 'minTopHeight', 80);
    handleHeight = optionValue(opts, 'handleHeight', 6);

    rows = grid.RowHeight;
    rows{handleRow} = handleHeight;
    grid.RowHeight = rows;

    handle = uipanel(grid, ...
        'BackgroundColor', [0.75 0.75 0.75], ...
        'BorderType', 'none');
    handle.Layout.Row = handleRow;
    handle.Layout.Column = 1;
    if isprop(handle, 'Tooltip')
        handle.Tooltip = 'Drag to resize panels';
    end

    attachDragHandle(fig, handle, struct( ...
        'pointer', 'top', ...
        'onStart', @startResize, ...
        'onDrag', @dragResize, ...
        'onTrace', optionValue(opts, 'onTrace', []), ...
        'traceName', 'row-resize'));

    function data = startResize(~)
        data = struct( ...
            'topHeight', rowHeightFromChild(grid, topRow, minTopHeight));
    end

    function dragResize(data, deltaPoint, ~)
        deltaDown = -deltaPoint(2);
        rowHeights = grid.RowHeight;
        rowHeights{topRow} = max(minTopHeight, data.topHeight + deltaDown);
        rowHeights{handleRow} = handleHeight;
        grid.RowHeight = rowHeights;
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
