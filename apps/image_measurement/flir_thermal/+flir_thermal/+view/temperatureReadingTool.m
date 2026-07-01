% Expected caller: FLIR thermal runner. Inputs are the app figure, thermal
% axes, and callbacks with onPoint/onRoi fields. Output is a small tool that
% wires image-click and drag ROI reading through labkit.ui.tool runtime.
function tool = temperatureReadingTool(fig, ax, callbacks)

    state = struct('startXY', [], 'dragRect', []);
    runtime = labkit.ui.tool.createRuntime(ax, struct('figure', fig));
    session = runtime.createSession(struct( ...
        'name', 'flirTemperatureReading', ...
        'onPointerDown', @onPointerDown, ...
        'installScrollWheel', false));

    tool = struct();
    tool.setBackground = @setBackground;
    tool.activate = @activate;

    function setBackground(imageHandle)
        session.setBackground(imageHandle);
    end

    function activate()
        session.activateIfAvailable();
    end

    function onPointerDown(~, event)
        state.startXY = eventPointXY(event);
        deleteDragRect();
        session.captureDrag(@onPointerMotion, @onPointerUp);
    end

    function onPointerMotion(~, ~)
        if isempty(state.startXY)
            return;
        end
        rect = rectFromPoints(state.startXY, eventPointXY(struct()));
        if rect(3) < 1 || rect(4) < 1
            return;
        end
        if isempty(state.dragRect) || ~isvalid(state.dragRect)
            state.dragRect = rectangle(ax, 'Position', rect, ...
                'EdgeColor', [1 1 1], ...
                'LineStyle', '--', ...
                'LineWidth', 1.2, ...
                'HitTest', 'off', ...
                'PickableParts', 'none');
        else
            state.dragRect.Position = rect;
        end
    end

    function onPointerUp(~, event)
        if isempty(state.startXY)
            return;
        end
        endXY = eventPointXY(event);
        startXY = state.startXY;
        state.startXY = [];
        deleteDragRect();
        if max(abs(endXY - startXY)) <= 2
            dispatchPoint(endXY);
        else
            dispatchRoi(startXY, endXY);
        end
    end

    function dispatchPoint(pointXY)
        if isfield(callbacks, 'onPoint') && ~isempty(callbacks.onPoint)
            callbacks.onPoint(pointXY);
        end
    end

    function dispatchRoi(startXY, endXY)
        if isfield(callbacks, 'onRoi') && ~isempty(callbacks.onRoi)
            callbacks.onRoi(startXY, endXY);
        end
    end

    function deleteDragRect()
        if ~isempty(state.dragRect) && isvalid(state.dragRect)
            delete(state.dragRect);
        end
        state.dragRect = [];
    end

    function pointXY = eventPointXY(event)
        if isstruct(event) && isfield(event, 'IntersectionPoint')
            point = double(event.IntersectionPoint);
            pointXY = point(1, 1:2);
            return;
        end
        point = double(ax.CurrentPoint);
        pointXY = point(1, 1:2);
    end

    function rect = rectFromPoints(a, b)
        a = double(a(:)).';
        b = double(b(:)).';
        left = min(a(1), b(1));
        top = min(a(2), b(2));
        rect = [left, top, abs(diff([a(1), b(1)])), ...
            abs(diff([a(2), b(2)]))];
    end
end
