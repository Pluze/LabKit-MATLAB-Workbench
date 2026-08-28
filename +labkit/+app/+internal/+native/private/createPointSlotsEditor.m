% Private App runtime controlled interaction. Expected caller:
% reconcileInteractions. It owns fixed point-slot placement, point/group
% dragging, empty-space marquee selection, graphics, and callback cleanup.
function editor = createPointSlotsEditor( ...
        runtime, imageSize, opts, onChanged, onSelectionChanged, onBackgroundPressed)
    ax = runtime.axes();
    imageSize = normalizeImageSize(imageSize);
    color = optionValue(opts, 'color', [0.05 0.45 0.95]);
    selectedColor = optionValue(opts, 'selectedColor', [1 0.9 0.15]);
    placeSelectedOnBackground = logical(optionValue( ...
        opts, 'placeSelectedOnBackground', false));
    value = normalizeValue(struct("points", NaN(1, 2), ...
        "selectedIndex", 1, "selectedIndices", 1, "locked", false));
    anchorLine = gobjects(1, 0);
    selectedLine = gobjects(1, 0);
    marquee = gobjects(1, 0);
    dragIndex = [];
    dragMode = "single";
    dragStartPoint = [NaN NaN];
    dragStartPoints = NaN(0, 2);
    selectionChanged = false;
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
        value.selectedIndices = value.selectedIndex;
        refresh();
        notify("place", targetIndex);
    end

    function pointerDown(~, ~)
        point = currentPoint();
        if value.backgroundClickOnly
            onBackgroundPressed(point);
            return;
        end
        nearest = nearestIndex(point);
        if isempty(nearest)
            if any(~all(isfinite(value.points), 2))
                insertPoint(point);
                return;
            end
            dragMode = "marquee";
            dragStartPoint = point;
            dragStartPoints = value.points;
            session.captureDrag(@drag, @release);
            return;
        end
        selectionChanged = ~ismember(nearest, value.selectedIndices);
        if selectionChanged
            value.selectedIndices = nearest;
        end
        value.selectedIndex = nearest;
        dragIndex = nearest;
        dragMode = "single";
        if value.locked
            dragMode = "set";
        elseif numel(value.selectedIndices) > 1
            dragMode = "selection";
        end
        dragStartPoint = point;
        dragStartPoints = value.points;
        refresh();
        session.captureDrag(@drag, @release);
    end

    function drag(~, ~)
        if dragMode == "marquee"
            updateMarquee();
        else
            updateDraggedPoint();
        end
    end

    function release(~, ~)
        if dragMode == "marquee"
            finishMarquee();
            return;
        end
        updateDraggedPoint();
        changedIndex = dragIndex;
        reason = "move";
        if dragMode == "set" || dragMode == "selection"
            reason = "moveSet";
        end
        dragIndex = [];
        dragMode = "single";
        notify(reason, changedIndex);
        if selectionChanged
            notifySelection();
        end
        selectionChanged = false;
    end

    function updateDraggedPoint()
        if isempty(dragIndex)
            return;
        end
        point = currentPoint();
        if dragMode == "single"
            value.points(dragIndex, :) = point;
            refresh();
            return;
        end
        valid = all(isfinite(dragStartPoints), 2);
        if dragMode == "selection"
            valid(:) = false;
            valid(value.selectedIndices) = true;
        end
        shifted = dragStartPoints;
        shifted(valid, :) = shifted(valid, :) + point - dragStartPoint;
        delta = boundedGroupDelta(shifted(valid, :), imageSize);
        shifted(valid, :) = shifted(valid, :) + delta;
        value.points(valid, :) = shifted(valid, :);
        refresh();
    end

    function updateMarquee()
        position = rectangleFromPoints(dragStartPoint, currentPoint());
        if isempty(marquee) || ~isgraphics(marquee)
            marquee = rectangle(ax, "Position", position, ...
                "EdgeColor", selectedColor, "LineWidth", 1.4, ...
                "LineStyle", "--", "HitTest", "off", ...
                "PickableParts", "none");
        else
            marquee.Position = position;
        end
        refreshGraphicsOwnership();
    end

    function finishMarquee()
        point = currentPoint();
        position = rectangleFromPoints(dragStartPoint, point);
        deleteIfValid(marquee);
        marquee = gobjects(1, 0);
        dragMode = "single";
        if max(position(3:4)) <= 2
            onBackgroundPressed(point);
            refresh();
            return;
        end
        indices = labkit.app.internal.interaction.selectPointsInRectangle( ...
            value.points, position);
        value.selectedIndices = indices;
        if ~isempty(indices)
            value.selectedIndex = indices(1);
        end
        refresh();
        notifySelection();
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
        inside = point(1) >= value.hitBounds(:, 1) & ...
            point(1) <= value.hitBounds(:, 1) + value.hitBounds(:, 3) & ...
            point(2) >= value.hitBounds(:, 2) & ...
            point(2) <= value.hitBounds(:, 2) + value.hitBounds(:, 4);
        ellipse = inside & value.hitEllipse;
        if any(ellipse)
            bounds = value.hitBounds(ellipse, :);
            centers = bounds(:, 1:2) + bounds(:, 3:4) ./ 2;
            radii = max(bounds(:, 3:4) ./ 2, eps);
            inEllipse = sum(((point - centers) ./ radii).^2, 2) <= 1;
            ellipseIndices = find(ellipse);
            inside(ellipseIndices(~inEllipse)) = false;
        end
        hitCandidates = find(inside & valid);
        if ~isempty(hitCandidates)
            [~, position] = min(hypot( ...
                value.points(hitCandidates, 1) - point(1), ...
                value.points(hitCandidates, 2) - point(2)));
            index = hitCandidates(position);
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
        points = value.points(value.selectedIndices, :);
        points = points(all(isfinite(points), 2), :);
        if isempty(points)
            selectedLine.XData = NaN;
            selectedLine.YData = NaN;
        else
            selectedLine.XData = points(:, 1);
            selectedLine.YData = points(:, 2);
        end
        refreshGraphicsOwnership();
        session.refresh();
    end

    function refreshGraphicsOwnership()
        graphics = [anchorLine; selectedLine];
        if ~isempty(marquee) && isgraphics(marquee)
            graphics(end + 1, 1) = marquee;
        end
        session.setGraphics(graphics);
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

    function notifySelection()
        onSelectionChanged(value.selectedIndices);
    end

    function deleteEditor()
        session.delete();
        deleteIfValid(anchorLine);
        deleteIfValid(selectedLine);
        deleteIfValid(marquee);
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
        selectedIndex = round(double(optionValue(input, 'selectedIndex', 1)));
        if ~isscalar(selectedIndex) || ~isfinite(selectedIndex)
            selectedIndex = 1;
        end
        selectedIndex = min(max(1, selectedIndex), size(points, 1));
        normalized = struct("points", points, ...
            "selectedIndex", selectedIndex, ...
            "selectedIndices", normalizeSelectedIndices( ...
                input, size(points, 1), selectedIndex), ...
            "hitBounds", normalizeHitBounds(input, size(points, 1)), ...
            "hitEllipse", normalizeHitEllipse(input, size(points, 1)), ...
            "backgroundClickOnly", logical(optionValue( ...
                input, 'backgroundClickOnly', false)), ...
            "locked", logical(optionValue(input, 'locked', false)));
    end
end

function bounds = normalizeHitBounds(value, count)
    bounds = double(optionValue(value, 'hitBounds', NaN(count, 4)));
    if ~isequal(size(bounds), [count 4]) || ...
            any(~isfinite(bounds(~isnan(bounds)))) || ...
            any(bounds(isfinite(bounds(:, 3)), 3) < 0) || ...
            any(bounds(isfinite(bounds(:, 4)), 4) < 0)
        bounds = NaN(count, 4);
    end
end

function ellipse = normalizeHitEllipse(value, count)
    ellipse = logical(optionValue(value, 'hitEllipse', false(count, 1)));
    ellipse = ellipse(:);
    if numel(ellipse) ~= count
        ellipse = false(count, 1);
    end
end

function indices = normalizeSelectedIndices(value, count, selectedIndex)
    indices = optionValue(value, 'selectedIndices', selectedIndex);
    indices = unique(round(double(indices(:).')), 'stable');
    indices = indices(isfinite(indices) & indices >= 1 & indices <= count);
end

function delta = boundedGroupDelta(points, imageSize)
    delta = [0 0];
    if isempty(points)
        return;
    end
    for axis = 1:2
        limit = imageSize(3 - axis);
        low = 1 - min(points(:, axis));
        high = limit - max(points(:, axis));
        delta(axis) = min(max(0, low), high);
    end
end

function position = rectangleFromPoints(first, second)
    low = min(first, second);
    high = max(first, second);
    position = [low, high - low];
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
