% Private App runtime controlled interaction. Expected caller:
% reconcileInteractions. It owns fixed point-slot placement, single/set
% dragging, graphics, figure callbacks, and cleanup outside app state.
function editor = createPointSlotsEditor(runtime, imageSize, opts, onChanged)
    ax = runtime.axes();
    imageSize = normalizeImageSize(imageSize);
    color = optionValue(opts, 'color', [0.05 0.45 0.95]);
    selectedColor = optionValue(opts, 'selectedColor', [1 0.9 0.15]);
    placeSelectedOnBackground = logical(optionValue( ...
        opts, 'placeSelectedOnBackground', false));
    value = normalizeValue(struct("points", NaN(1, 2), ...
        "selectedIndex", 1, "locked", false));
    anchorLine = gobjects(1, 0);
    selectedLine = gobjects(1, 0);
    dragIndex = [];
    dragMode = "single";
    dragStartPoint = [NaN NaN];
    dragStartPoints = NaN(0, 2);
    session = runtime.createSession(struct( ...
        "name", "pointSlots", "onPointerDown", @pointerDown, ...
        "installScrollWheel", false));
    session.activate();
    editor = struct("setValue", @setValue, "getValue", @getValue, ...
        "insertPoint", @insertPoint, "delete", @deleteEditor);
    refresh();

    function setValue(nextValue)
        value = normalizeValue(nextValue);
        refresh();
    end

    function current = getValue()
        current = value;
    end

    function insertPoint(point)
        targetIndex = nextPlacementIndex();
        if isempty(targetIndex) && placeSelectedOnBackground
            targetIndex = value.selectedIndex;
        end
        if isempty(targetIndex)
            return;
        end
        value.points(targetIndex, :) = clampPoint(point);
        value.selectedIndex = nextUnplacedIndex(targetIndex);
        refresh();
        notify("place", targetIndex);
    end

    function pointerDown(~, ~)
        point = currentPoint();
        nearest = nearestIndex(point);
        if isempty(nearest)
            insertPoint(point);
            return;
        end
        value.selectedIndex = nearest;
        dragIndex = nearest;
        dragMode = "single";
        if value.locked
            dragMode = "set";
        end
        dragStartPoint = point;
        dragStartPoints = value.points;
        refresh();
        session.captureDrag(@drag, @release);
    end

    function drag(~, ~)
        updateDraggedPoint();
    end

    function release(~, ~)
        updateDraggedPoint();
        changedIndex = dragIndex;
        reason = "move";
        if dragMode == "set"
            reason = "moveSet";
        end
        dragIndex = [];
        dragMode = "single";
        notify(reason, changedIndex);
    end

    function updateDraggedPoint()
        if isempty(dragIndex)
            return;
        end
        point = currentPoint();
        if dragMode == "set"
            valid = all(isfinite(dragStartPoints), 2);
            shifted = dragStartPoints;
            shifted(valid, :) = shifted(valid, :) + point - dragStartPoint;
            shifted(valid, 1) = min(max(shifted(valid, 1), 1), imageSize(2));
            shifted(valid, 2) = min(max(shifted(valid, 2), 1), imageSize(1));
            value.points(valid, :) = shifted(valid, :);
        else
            value.points(dragIndex, :) = point;
        end
        refresh();
    end

    function point = currentPoint()
        current = double(ax.CurrentPoint);
        point = clampPoint(current(1, 1:2));
    end

    function point = clampPoint(point)
        point = double(point(:).');
        if numel(point) ~= 2 || any(~isfinite(point))
            point = [1 1];
        end
        point = min([imageSize(2), imageSize(1)], max([1 1], point));
    end

    function index = nearestIndex(point)
        index = [];
        valid = all(isfinite(value.points), 2);
        if ~any(valid)
            return;
        end
        candidates = find(valid);
        distance = hypot(value.points(valid, 1) - point(1), ...
            value.points(valid, 2) - point(2));
        [bestDistance, position] = min(distance);
        threshold = 0.025 * max(max(1, diff(ax.XLim)), max(1, diff(ax.YLim)));
        if bestDistance <= threshold
            index = candidates(position);
        end
    end

    function index = nextPlacementIndex()
        if any(~isfinite(value.points(value.selectedIndex, :)))
            index = value.selectedIndex;
        else
            index = find(~all(isfinite(value.points), 2), 1);
        end
    end

    function index = nextUnplacedIndex(placedIndex)
        missing = find(~all(isfinite(value.points), 2));
        if isempty(missing)
            index = placedIndex;
            return;
        end
        after = missing(missing > placedIndex);
        if isempty(after)
            index = missing(1);
        else
            index = after(1);
        end
    end

    function refresh()
        ensureGraphics();
        anchorLine.XData = value.points(:, 1);
        anchorLine.YData = value.points(:, 2);
        point = value.points(value.selectedIndex, :);
        if all(isfinite(point))
            selectedLine.XData = point(1);
            selectedLine.YData = point(2);
        else
            selectedLine.XData = NaN;
            selectedLine.YData = NaN;
        end
        session.setGraphics([anchorLine; selectedLine]);
        session.refresh();
    end

    function ensureGraphics()
        if isempty(anchorLine) || ~isgraphics(anchorLine)
            anchorLine = line(ax, NaN, NaN, "LineStyle", "none", ...
                "Marker", "o", "MarkerSize", 7, "Color", selectedColor, ...
                "MarkerFaceColor", color, "HitTest", "off", ...
                "PickableParts", "none");
        end
        if isempty(selectedLine) || ~isgraphics(selectedLine)
            selectedLine = line(ax, NaN, NaN, "LineStyle", "none", ...
                "Marker", "o", "MarkerSize", 11, "LineWidth", 2, ...
                "Color", selectedColor, "MarkerFaceColor", "none", ...
                "HitTest", "off", "PickableParts", "none");
        end
    end

    function notify(reason, changedIndex)
        emitted = value;
        emitted.changedIndex = changedIndex;
        emitted.reason = string(reason);
        onChanged(emitted);
    end

    function deleteEditor()
        session.delete();
        deleteIfValid(anchorLine);
        deleteIfValid(selectedLine);
    end

    function normalized = normalizeValue(input)
        if ~isstruct(input) || ~isscalar(input) || ~isfield(input, 'points')
            error('labkit:app:runtime:InvalidPointSlotsValue', ...
                'pointSlots Value must contain a fixed Nx2 points array.');
        end
        points = double(input.points);
        if size(points, 2) ~= 2 || isempty(points)
            error('labkit:app:runtime:InvalidPointSlotsValue', ...
                'pointSlots points must be a nonempty Nx2 array.');
        end
        selectedIndex = optionValue(input, 'selectedIndex', 1);
        selectedIndex = round(double(selectedIndex));
        if ~isscalar(selectedIndex) || ~isfinite(selectedIndex)
            selectedIndex = 1;
        end
        normalized = struct("points", points, ...
            "selectedIndex", min(max(1, selectedIndex), size(points, 1)), ...
            "locked", logical(optionValue(input, 'locked', false)));
    end
end

function imageSize = normalizeImageSize(value)
    imageSize = double(value(:).');
    if numel(imageSize) < 2 || any(~isfinite(imageSize(1:2))) || ...
            any(imageSize(1:2) < 1)
        error('labkit:app:runtime:InvalidPointSlotsImageSize', ...
            'pointSlots requires a finite positive image size.');
    end
    imageSize = imageSize(1:2);
end

function value = optionValue(opts, name, fallback)
    value = fallback;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end

function deleteIfValid(handle)
    if ~isempty(handle) && all(isgraphics(handle))
        delete(handle);
    end
end
