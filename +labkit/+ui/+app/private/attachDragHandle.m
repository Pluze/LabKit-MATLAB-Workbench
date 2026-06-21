% Private UI app helper. Expected caller: UI app shell resize helpers.
% Inputs are a figure, a draggable UI component, and callbacks for drag start
% and motion. Side effects are limited to installing handle and temporary
% figure callbacks, then restoring the previous figure callback state.
function attachDragHandle(fig, handle, opts)
%ATTACHDRAGHANDLE Install shared drag lifecycle behavior on a UI handle.
%
% Inputs:
%   fig - owning uifigure whose pointer and window callbacks are used.
%   handle - UI component receiving the initial pointer down event.
%   opts - struct with optional fields:
%       pointer - pointer shape during drag, default 'arrow'.
%       onStart - function data = onStart(startPoint).
%       onDrag - function onDrag(data, deltaPoint, currentPoint).
%       onStop - function onStop(data).
%       onTrace - function trace(message), default [].
%       traceName - label in trace messages, default 'drag-handle'.
%
% The helper centralizes the behavior used by column and row resize handles:
% make the handle pickable when supported, save existing figure callbacks,
% install temporary motion/release/cancel callbacks, and restore the previous
% state on release. A click outside the drag handle or Escape cancels a stuck
% drag lifecycle when a slow app misses the mouse-up event.

    if nargin < 3
        opts = struct();
    end

    applyPointerHitTarget(handle);
    handle.ButtonDownFcn = @startDrag;

    drag = struct('active', false, 'startPoint', [NaN NaN], 'data', [], ...
        'oldPointer', '', 'oldMotionFcn', [], 'oldUpFcn', [], ...
        'oldDownFcn', [], 'oldKeyPressFcn', []);

    function startDrag(~, evt)
        if drag.active
            finishDrag(false, 'restart');
        end
        drawnow;
        drag.active = true;
        drag.startPoint = pointerPoint(fig, evt);
        drag.oldPointer = fig.Pointer;
        drag.oldMotionFcn = fig.WindowButtonMotionFcn;
        drag.oldUpFcn = fig.WindowButtonUpFcn;
        drag.oldDownFcn = fig.WindowButtonDownFcn;
        drag.oldKeyPressFcn = fig.WindowKeyPressFcn;
        drag.data = invokeStart(optionValue(opts, 'onStart', []), ...
            drag.startPoint);
        fig.Pointer = optionValue(opts, 'pointer', 'arrow');
        fig.WindowButtonMotionFcn = @doDrag;
        fig.WindowButtonUpFcn = @stopDrag;
        fig.WindowButtonDownFcn = @cancelDrag;
        fig.WindowKeyPressFcn = @keyCancelDrag;
        trace(opts, 'begin', drag.startPoint, [0 0]);
    end

    function doDrag(~, evt)
        if ~drag.active || ~isLiveHandle(fig)
            finishDrag(false, 'invalid');
            return;
        end
        currentPoint = pointerPoint(fig, evt);
        if any(~isfinite(currentPoint))
            return;
        end
        callback = optionValue(opts, 'onDrag', []);
        if ~isempty(callback)
            callback(drag.data, currentPoint - drag.startPoint, currentPoint);
        end
        trace(opts, 'drag', currentPoint, currentPoint - drag.startPoint);
    end

    function stopDrag(~, ~)
        finishDrag(true, 'end');
    end

    function cancelDrag(~, ~)
        finishDrag(false, 'cancel');
    end

    function keyCancelDrag(~, evt)
        if isEscapeKey(evt)
            finishDrag(false, 'cancel');
            return;
        end
        oldCallback = drag.oldKeyPressFcn;
        if isa(oldCallback, 'function_handle')
            oldCallback(fig, evt);
        elseif iscell(oldCallback) && ~isempty(oldCallback) && ...
                isa(oldCallback{1}, 'function_handle')
            oldCallback{1}(fig, evt, oldCallback{2:end});
        end
    end

    function finishDrag(runStopCallback, eventName)
        if ~drag.active
            return;
        end
        if runStopCallback
            callback = optionValue(opts, 'onStop', []);
            if ~isempty(callback)
                callback(drag.data);
            end
        end
        restoreDragState();
        drag.active = false;
        trace(opts, eventName, [NaN NaN], [NaN NaN]);
    end

    function restoreDragState()
        if ~isLiveHandle(fig)
            return;
        end
        fig.WindowButtonMotionFcn = drag.oldMotionFcn;
        fig.WindowButtonUpFcn = drag.oldUpFcn;
        fig.WindowButtonDownFcn = drag.oldDownFcn;
        fig.WindowKeyPressFcn = drag.oldKeyPressFcn;
        fig.Pointer = drag.oldPointer;
    end
end

function trace(opts, eventName, point, delta)
    callback = optionValue(opts, 'onTrace', []);
    if isempty(callback)
        return;
    end
    name = optionValue(opts, 'traceName', 'drag-handle');
    try
        callback(sprintf(['component=%s event=%s point=[%.1f %.1f] ' ...
            'delta=[%.1f %.1f]'], name, eventName, point(1), point(2), ...
            delta(1), delta(2)));
    catch
    end
end

function data = invokeStart(callback, startPoint)
    data = [];
    if ~isempty(callback)
        data = callback(startPoint);
    end
end

function applyPointerHitTarget(handle)
    if isprop(handle, 'HitTest')
        handle.HitTest = 'on';
    end
    if isprop(handle, 'PickableParts')
        handle.PickableParts = 'all';
    end
end

function point = pointerPoint(fig, evt)
    point = [NaN NaN];
    if nargin >= 2 && ~isempty(evt)
        point = pointFromEvent(evt);
    end
    if any(~isfinite(point))
        try
            value = fig.CurrentPoint;
            if isnumeric(value) && numel(value) >= 2
                point = value(1:2);
            end
        catch
        end
    end
end

function point = pointFromEvent(evt)
    point = [NaN NaN];
    names = {'CurrentPoint', 'Point', 'Position'};
    for k = 1:numel(names)
        value = eventValue(evt, names{k});
        if isnumeric(value) && numel(value) >= 2
            point = value(1:2);
            return;
        end
    end
end

function value = eventValue(evt, name)
    value = [];
    if isstruct(evt) && isfield(evt, name)
        value = evt.(name);
    elseif isobject(evt) && isprop(evt, name)
        value = evt.(name);
    end
end

function tf = isEscapeKey(evt)
    key = string(eventValue(evt, 'Key'));
    character = string(eventValue(evt, 'Character'));
    tf = any(strcmpi([key character], ["escape" "esc"]));
end

function tf = isLiveHandle(h)
    tf = false;
    try
        tf = ~isempty(h) && isvalid(h);
    catch
        tf = false;
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
