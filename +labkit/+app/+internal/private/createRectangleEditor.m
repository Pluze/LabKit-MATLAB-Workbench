% Private UI runtime helper. Creates a controlled rectangular selection.
function editor = createRectangleEditor(runtime, imageSize, position, opts)
%
% Internal usage:
%   editor = createRectangleEditor(interactionAdapter, size(image), ...
%       [20 20 80 60], struct('onMoved', @storePosition));
%
% Inputs:
%   runtime - App runtime interaction-hub adapter.
%   imageSize - [height width] or full image size used to constrain the ROI.
%   position - [x y width height] rectangle in image coordinates.
%   opts - optional struct.
%
% Options:
%   fixedAspectRatio - logical, default false.
%   color - RGB edge/handle color, default [1 1 0].
%   lineWidth - positive scalar, default 1.5.
%   lineStyle - MATLAB line style, default '-'.
%   minimumSize - [width height], default [1 1].
%   movable - logical, default true.
%   resizable - logical, default true.
%   onMoving - callback(position) during pointer movement, default [].
%   onMoved - callback(position) after pointer release, default [].
%   onBackgroundDown - callback(src,event) for plot clicks outside the
%       rectangle and clicks on the rectangle that do not begin a drag,
%       default [].
%
% Returned editor API:
%   getPosition(), setPosition(position), setImageSize(imageSize),
%   setBounds([xmin xmax ymin ymax]), setBackground(handle),
%   setActive(tf), activateIfAvailable(), isValid(), graphics(), refresh(),
%   and delete().
%
% The editor uses ordinary MATLAB graphics and the LabKit interaction runtime;
% it does not require Image Processing Toolbox ROI objects.

    if nargin < 4
        opts = struct();
    end
    assert(isstruct(runtime) && isfield(runtime, 'axes') && ...
        isa(runtime.axes, 'function_handle') && ...
        isfield(runtime, 'createSession') && ...
        isa(runtime.createSession, 'function_handle'), ...
        'First input must be a App runtime interaction adapter.');

    state = struct();
    state.ax = runtime.axes();
    state.imageSize = normalizeImageSize(imageSize);
    state.bounds = boundsFromImageSize(state.imageSize);
    state.fixedAspectRatio = logical(optionValue(opts, 'fixedAspectRatio', false));
    state.minimumSize = normalizeMinimumSize(optionValue(opts, 'minimumSize', [1 1]));
    state.position = constrainPosition(position, state.bounds, [], false, ...
        state.minimumSize);
    state.aspectRatio = state.position(3) ./ state.position(4);
    state.color = optionValue(opts, 'color', [1 1 0]);
    state.lineWidth = optionValue(opts, 'lineWidth', 1.5);
    state.lineStyle = optionValue(opts, 'lineStyle', '-');
    state.movable = logical(optionValue(opts, 'movable', true));
    state.resizable = logical(optionValue(opts, 'resizable', true));
    state.onMoving = optionValue(opts, 'onMoving', []);
    state.onMoved = optionValue(opts, 'onMoved', []);
    state.onBackgroundDown = optionValue(opts, 'onBackgroundDown', []);
    state.box = [];
    state.cornerHandles = gobjects(0);
    state.dragMode = "";
    state.dragCorner = 0;
    state.dragStartPoint = [0 0];
    state.dragStartPosition = state.position;
    state.dragMoved = false;
    state.session = runtime.createSession(struct( ...
        'name', 'rectangleEditor', ...
        'onPointerDown', @onPointerDown, ...
        'installScrollWheel', false));

    editor = struct( ...
        'getPosition', @getPosition, ...
        'setPosition', @setPosition, ...
        'setImageSize', @setImageSize, ...
        'setBounds', @setBounds, ...
        'setBackground', @setBackground, ...
        'setActive', @setActive, ...
        'activateIfAvailable', @activateIfAvailable, ...
        'isValid', @isValid, ...
        'graphics', @editorGraphics, ...
        'refresh', @refresh, ...
        'delete', @deleteEditor);

    refresh();
    setActive(true);

    function value = getPosition()
        value = state.position;
    end

    function setPosition(value)
        state.position = constrainPosition(value, state.bounds, ...
            state.aspectRatio, state.fixedAspectRatio, state.minimumSize);
        refresh();
    end

    function setImageSize(value)
        state.imageSize = normalizeImageSize(value);
        state.bounds = boundsFromImageSize(state.imageSize);
        setPosition(state.position);
    end

    function setBounds(value)
        value = double(value(:).');
        assert(numel(value) == 4 && all(isfinite(value)) && ...
            value(2) > value(1) && value(4) > value(3), ...
            'bounds must be finite increasing [xmin xmax ymin ymax] values.');
        state.bounds = value;
        setPosition(state.position);
    end

    function setBackground(value)
        state.session.setBackground(value);
    end

    function setActive(value)
        if logical(value)
            state.session.activate();
        else
            state.session.deactivate();
        end
    end

    function activateIfAvailable()
        state.session.activateIfAvailable();
    end

    function tf = isValid()
        expectedCorners = 4 .* double(state.resizable);
        tf = isValidGraphic(state.box) && ...
            numel(state.cornerHandles) == expectedCorners && ...
            all(isgraphics(state.cornerHandles));
    end

    function handles = editorGraphics()
        handles = [state.box state.cornerHandles];
        handles = handles(isgraphics(handles));
    end

    function refresh()
        ensureGraphics();
        if ~isValidGraphic(state.box)
            return;
        end
        state.box.Position = state.position;
        corners = rectangleCorners(state.position);
        for iCorner = 1:numel(state.cornerHandles)
            state.cornerHandles(iCorner).XData = corners(iCorner, 1);
            state.cornerHandles(iCorner).YData = corners(iCorner, 2);
        end
        state.session.setGraphics(editorGraphics());
        state.session.refresh();
    end

    function deleteEditor()
        state.session.delete();
        deleteGraphics(state.cornerHandles);
        deleteGraphics(state.box);
        state.cornerHandles = gobjects(0);
        state.box = [];
    end

    function ensureGraphics()
        if ~isValidGraphic(state.ax)
            return;
        end
        if ~isValidGraphic(state.box)
            state.box = rectangle(state.ax, 'Position', state.position, ...
                'EdgeColor', state.color, 'LineWidth', state.lineWidth, ...
                'LineStyle', state.lineStyle);
        end
        if ~state.resizable
            deleteGraphics(state.cornerHandles);
            state.cornerHandles = gobjects(0);
        elseif numel(state.cornerHandles) ~= 4 || ...
                ~all(isgraphics(state.cornerHandles))
            deleteGraphics(state.cornerHandles);
            state.cornerHandles = gobjects(1, 4);
            for iCorner = 1:4
                state.cornerHandles(iCorner) = line(state.ax, NaN, NaN, ...
                    'LineStyle', 'none', 'Marker', 's', 'MarkerSize', 7, ...
                    'MarkerEdgeColor', state.color, ...
                    'MarkerFaceColor', state.color);
            end
        end
    end

    function onPointerDown(src, event)
        if ~isValid()
            return;
        end
        state.dragCorner = find(state.cornerHandles == src, 1);
        if ~isempty(state.dragCorner)
            state.dragMode = "resize";
        elseif state.movable && (isequal(src, state.box) || ...
                positionContainsPoint(state.position, axesPoint(state.ax)))
            state.dragCorner = 0;
            state.dragMode = "move";
        else
            invokePointerCallback(state.onBackgroundDown, src, event);
            return;
        end
        state.dragStartPoint = axesPoint(state.ax);
        state.dragStartPosition = state.position;
        state.dragMoved = false;
        state.session.captureDrag(@onDrag, @onRelease);
    end

    function onDrag(~, ~)
        point = axesPoint(state.ax);
        if state.dragMode == "move"
            candidate = state.dragStartPosition;
            candidate(1:2) = candidate(1:2) + point - state.dragStartPoint;
        else
            candidate = resizedPosition(state.dragStartPosition, ...
                state.dragCorner, point, state.fixedAspectRatio, state.aspectRatio);
        end
        state.position = constrainPosition(candidate, state.bounds, ...
            state.aspectRatio, state.fixedAspectRatio, state.minimumSize);
        state.dragMoved = state.dragMoved || any( ...
            abs(state.position - state.dragStartPosition) > 1e-9);
        refresh();
        invokeCallback(state.onMoving, state.position);
    end

    function onRelease(src, event)
        moved = state.dragMoved;
        state.dragMode = "";
        state.dragCorner = 0;
        state.dragMoved = false;
        if ~moved && ~isempty(state.onBackgroundDown)
            invokePointerCallback(state.onBackgroundDown, src, event);
        else
            invokeCallback(state.onMoved, state.position);
        end
    end
end

function value = optionValue(options, name, fallback)
    value = fallback;
    if isfield(options, name) && ~isempty(options.(name))
        value = options.(name);
    end
end

function tf = positionContainsPoint(position, point)
    tf = isnumeric(position) && numel(position) == 4 && ...
        isnumeric(point) && numel(point) == 2 && ...
        all(isfinite(double([position(:); point(:)]))) && ...
        point(1) >= position(1) && point(1) <= position(1) + position(3) && ...
        point(2) >= position(2) && point(2) <= position(2) + position(4);
end

function imageSize = normalizeImageSize(value)
    value = double(value(:).');
    assert(numel(value) >= 2 && all(isfinite(value(1:2))) && ...
        all(value(1:2) >= 1), ...
        'imageSize must provide finite positive height and width values.');
    imageSize = value(1:2);
end

function bounds = boundsFromImageSize(imageSize)
    bounds = [1 imageSize(2) 1 imageSize(1)];
end

function value = normalizeMinimumSize(value)
    value = double(value(:).');
    assert(numel(value) == 2 && all(isfinite(value)) && all(value > 0), ...
        'minimumSize must be a finite positive [width height] vector.');
end

function point = axesPoint(ax)
    current = double(ax.CurrentPoint);
    point = current(1, 1:2);
end

function corners = rectangleCorners(position)
    x = position(1);
    y = position(2);
    x2 = x + position(3);
    y2 = y + position(4);
    corners = [x y; x2 y; x2 y2; x y2];
end

function position = resizedPosition(startPosition, corner, point, fixedAspect, aspectRatio)
    corners = rectangleCorners(startPosition);
    oppositeCorner = mod(corner + 1, 4) + 1;
    opposite = corners(oppositeCorner, :);
    dragged = point;
    if fixedAspect
        signs = sign(dragged - opposite);
        signs(signs == 0) = 1;
        height = max(abs(dragged(2) - opposite(2)), ...
            abs(dragged(1) - opposite(1)) ./ aspectRatio);
        dragged = opposite + signs .* [height .* aspectRatio, height];
    end
    position = [min(opposite, dragged), abs(dragged - opposite)];
end

function position = constrainPosition(value, bounds, aspectRatio, fixedAspect, minimumSize)
    value = double(value(:).');
    assert(numel(value) == 4 && all(isfinite(value)), ...
        'position must be a finite [x y width height] vector.');
    maxSize = [bounds(2) - bounds(1), bounds(4) - bounds(3)];
    extent = max(value(3:4), minimumSize);
    if fixedAspect && ~isempty(aspectRatio)
        height = max(extent(2), extent(1) ./ aspectRatio);
        extent = [height .* aspectRatio, height];
    end
    extent = extent .* min([1, maxSize(1) ./ extent(1), ...
        maxSize(2) ./ extent(2)]);
    origin = min(max(value(1:2), bounds([1 3])), bounds([2 4]) - extent);
    position = [origin extent];
end

function invokeCallback(callback, position)
    if ~isempty(callback)
        callback(position);
    end
end

function invokePointerCallback(callback, source, event)
    if ~isempty(callback)
        callback(source, event);
    end
end

function deleteGraphics(handles)
    handles = handles(isgraphics(handles));
    if ~isempty(handles)
        delete(handles);
    end
end

function tf = isValidGraphic(handle)
    tf = ~isempty(handle) && isgraphics(handle);
end
