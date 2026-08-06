% Private App SDK native-adapter implementation for installRowResize; called only by the internal runtime.
function separator = installRowResize( ...
        figureHandle, grid, contentRow, separatorRow, varargin)
% Private control-panel splitter. Expected caller: MatlabPlatformAdapter.
% Inputs are runtime-owned native handles and bounded height options. The
% separator temporarily owns figure pointer callbacks only while dragging,
% then restores interaction callbacks exactly.

policy = nativeLayoutPolicy();
options = struct("MinimumHeight", policy.MinimumResizableRowHeight, ...
    "SeparatorHeight", policy.SplitterThickness);
if ~isempty(varargin)
    supplied = varargin{1};
    names = string(fieldnames(supplied));
    for name = names.'
        options.(name) = supplied.(name);
    end
end
heights = grid.RowHeight;
heights{separatorRow} = options.SeparatorHeight;
grid.RowHeight = heights;
separator = uipanel(grid, BorderType="none", ...
    BackgroundColor=[0.86 0.86 0.86], ...
    Tag="labkitAppRowResize");
separator.Layout.Row = separatorRow;
separator.Layout.Column = 1;
if isprop(separator, "Tooltip")
    separator.Tooltip = "Drag to resize this control group";
end
if isprop(separator, "HitTest")
    separator.HitTest = "on";
end
if isprop(separator, "PickableParts")
    separator.PickableParts = "all";
end
separator.ButtonDownFcn = @beginDrag;

drag = struct("Active", false, "StartY", NaN, "StartHeight", NaN, ...
    "Motion", [], "Up", [], "Down", [], "Key", [], ...
    "Pointer", "arrow");

    function beginDrag(~, ~)
        if drag.Active || ~isvalid(figureHandle)
            return
        end
        drag.Active = true;
        drag.StartY = figureHandle.CurrentPoint(2);
        drag.StartHeight = contentHeight();
        drag.Motion = figureHandle.WindowButtonMotionFcn;
        drag.Up = figureHandle.WindowButtonUpFcn;
        drag.Down = figureHandle.WindowButtonDownFcn;
        drag.Key = figureHandle.WindowKeyPressFcn;
        drag.Pointer = figureHandle.Pointer;
        figureHandle.Pointer = "top";
        figureHandle.WindowButtonMotionFcn = @resize;
        figureHandle.WindowButtonUpFcn = @(~, ~) finishDrag();
        figureHandle.WindowButtonDownFcn = @(~, ~) finishDrag();
        figureHandle.WindowKeyPressFcn = @cancelOnEscape;
    end

    function resize(~, ~)
        point = figureHandle.CurrentPoint;
        height = drag.StartHeight - (point(2) - drag.StartY);
        heights = grid.RowHeight;
        heights{contentRow} = max(options.MinimumHeight, height);
        heights{separatorRow} = options.SeparatorHeight;
        grid.RowHeight = heights;
    end

    function value = contentHeight()
        value = options.MinimumHeight;
        children = grid.Children;
        for k = 1:numel(children)
            layout = children(k).Layout;
            if isprop(layout, "Row") && isequal(layout.Row, contentRow)
                position = children(k).Position;
                if numel(position) >= 4 && isfinite(position(4)) && ...
                        position(4) > 0
                    value = position(4);
                    return
                end
            end
        end
    end

    function cancelOnEscape(~, event)
        if string(event.Key) == "escape"
            finishDrag();
        end
    end

    function finishDrag()
        if ~drag.Active || ~isvalid(figureHandle)
            return
        end
        figureHandle.WindowButtonMotionFcn = drag.Motion;
        figureHandle.WindowButtonUpFcn = drag.Up;
        figureHandle.WindowButtonDownFcn = drag.Down;
        figureHandle.WindowKeyPressFcn = drag.Key;
        figureHandle.Pointer = drag.Pointer;
        drag.Active = false;
    end
end
