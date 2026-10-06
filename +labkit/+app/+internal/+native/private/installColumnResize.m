% Private App SDK native-adapter implementation for installColumnResize; called only by the internal runtime.
function separator = installColumnResize( ...
        figureHandle, grid, leftColumn, separatorColumn)
% Private workbench splitter. Expected caller: MatlabPlatformAdapter.
% Runtime-owned native handles use the SDK layout policy for width bounds. The
% separator temporarily owns figure pointer callbacks only while dragging,
% then restores the interaction hub callbacks exactly.

policy = nativeLayoutPolicy();
widths = grid.ColumnWidth;
widths{leftColumn} = policy.ControlPaneWidth;
widths{separatorColumn} = policy.SplitterThickness;
grid.ColumnWidth = widths;
separator = uipanel(grid, BorderType="none", ...
    BackgroundColor=[0.72 0.72 0.72], ...
    Tag="labkitAppColumnResize");
separator.Layout.Row = 1;
separator.Layout.Column = separatorColumn;
if isprop(separator, "Tooltip")
    separator.Tooltip = "Drag to resize the task panel";
end
if isprop(separator, "HitTest")
    separator.HitTest = "on";
end
if isprop(separator, "PickableParts")
    separator.PickableParts = "all";
end
separator.ButtonDownFcn = @beginDrag;

drag = struct("Active", false, "Motion", [], "Up", [], "Down", [], ...
    "Key", [], "Pointer", "arrow");

    function beginDrag(~, ~)
        if drag.Active || ~isvalid(figureHandle)
            return
        end
        drag.Active = true;
        drag.Motion = figureHandle.WindowButtonMotionFcn;
        drag.Up = figureHandle.WindowButtonUpFcn;
        drag.Down = figureHandle.WindowButtonDownFcn;
        drag.Key = figureHandle.WindowKeyPressFcn;
        drag.Pointer = figureHandle.Pointer;
        figureHandle.Pointer = "left";
        figureHandle.WindowButtonMotionFcn = @resize;
        figureHandle.WindowButtonUpFcn = @(~, ~) finishDrag();
        figureHandle.WindowButtonDownFcn = @(~, ~) finishDrag();
        figureHandle.WindowKeyPressFcn = @cancelOnEscape;
    end

    function resize(~, ~)
        point = figureHandle.CurrentPoint;
        width = max(policy.MinimumControlPaneWidth, point(1) - grid.Position(1));
        maximum = max(policy.MinimumControlPaneWidth, ...
            figureHandle.Position(3) - policy.MinimumWorkspaceWidth);
        widths = grid.ColumnWidth;
        widths{leftColumn} = min(width, maximum);
        widths{separatorColumn} = policy.SplitterThickness;
        grid.ColumnWidth = widths;
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
        if isappdata(figureHandle, "labkitAppLayoutChanged")
            callback = getappdata(figureHandle, "labkitAppLayoutChanged");
            callback();
        end
    end
end
