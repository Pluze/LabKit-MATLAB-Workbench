% Private UI runtime helper. Expected caller: commitV2Presentation. Inputs are
% the current v2 runtime and a scalar semantic interaction-spec struct. Side
% effects create, update, replace, and dispose controlled interaction resources
% without exposing editor objects or UI handles to app state.
function reconcileV2Interactions(runtime, interactions)
    if isempty(interactions)
        interactions = struct();
    end
    if ~isstruct(interactions) || ~isscalar(interactions)
        error('labkit:ui:runtime:InvalidPresentation', ...
            'Presentation interactions must be a scalar struct.');
    end
    hub = runtime.interactionHub;
    hub.setSuppressed(true);
    cleanup = onCleanup(@() hub.setSuppressed(false));
    desiredIds = string(fieldnames(interactions));
    currentIds = v2ResourceRegistry(runtime.ui.figure, ...
        "listIds", "interaction");
    removedIds = setdiff(currentIds, desiredIds, 'stable');
    for k = 1:numel(removedIds)
        v2ResourceRegistry(runtime.ui.figure, "remove", ...
            "interaction", removedIds(k));
    end
    for k = 1:numel(desiredIds)
        id = desiredIds(k);
        spec = normalizeSpec(id, interactions.(char(id)));
        current = v2ResourceRegistry(runtime.ui.figure, ...
            "get", "interaction", id);
        if isempty(current) || ~sameIdentity(current.spec, spec)
            v2ResourceRegistry(runtime.ui.figure, "remove", ...
                "interaction", id);
            current = createControlledInteraction(hub, id, spec);
            v2ResourceRegistry(runtime.ui.figure, "set", ...
                "interaction", id, current, @(value) value.delete());
        end
        current.update(spec.Value);
    end
    clear cleanup;
end

function controlled = createControlledInteraction(hub, id, spec)
    kind = lower(spec.Kind);
    group = "interaction:" + id;
    suppressed = false;
    switch kind
        case {"anchors", "scalebarreference", "scalebar"}
            options = anchorOptions(spec, @emitValue);
            editor = createAnchorEditor( ...
                hub.adapter(spec.Targets(1), group), ...
                spec.ImageSize, options);
            editors = {editor};
            update = @updateSingleAnchors;
        case "pairedanchors"
            editors = cell(1, numel(spec.Targets));
            for k = 1:numel(spec.Targets)
                options = anchorOptions(spec, @emitPairedValue);
                editors{k} = createAnchorEditor( ...
                    hub.adapter(spec.Targets(k), group), ...
                    imageSizeAt(spec.ImageSize, k), options);
            end
            update = @updatePairedAnchors;
        case "rectangle"
            options = rectangleOptions(spec, @emitValue, @emitBackground);
            editor = createRectangleEditor( ...
                hub.adapter(spec.Targets(1), group), spec.ImageSize, ...
                spec.Value, options);
            editors = {editor};
            update = @updateRectangle;
        case "regionselection"
            editor = createRegionSelection( ...
                hub.adapter(spec.Targets(1), group), spec, ...
                @emitValue, @emitBackground);
            editors = {editor};
            update = @updateRegionSelection;
        case "interval"
            editor = createIntervalEditor( ...
                hub.adapter(spec.Targets(1), group), spec, ...
                @emitValue, @emitScroll);
            editors = {editor};
            update = @updateInterval;
        case "pointslots"
            editor = createPointSlotsEditor( ...
                hub.adapter(spec.Targets(1), group), spec.ImageSize, ...
                spec.Options, @emitValue);
            editors = {editor};
            update = @updatePointSlots;
        otherwise
            error('labkit:ui:runtime:UnknownInteractionKind', ...
                'Interaction "%s" has unsupported Kind "%s".', id, spec.Kind);
    end
    baseUpdate = update;
    instruction = interactionInstruction(spec);
    update = @updateWithInstruction;
    controlled = struct("spec", spec, "update", update, ...
        "delete", @deleteEditors, "editors", {editors});

    function updateWithInstruction(value)
        baseUpdate(value);
        applyInstruction();
    end

    function updateSingleAnchors(value)
        withSuppression(@() setAnchorValue(editors{1}, value));
    end

    function updatePairedAnchors(value)
        values = pairedValues(value, spec.Targets);
        withSuppression(@setValues);

        function setValues()
            for index = 1:numel(editors)
                setAnchorValue(editors{index}, values{index});
            end
        end
    end

    function updateRectangle(value)
        withSuppression(@() editors{1}.setPosition(value));
    end

    function updateRegionSelection(~)
        % Region selection is a transient gesture and has no durable overlay.
    end

    function updateInterval(value)
        withSuppression(@() editors{1}.setRange(value));
    end

    function updatePointSlots(value)
        withSuppression(@() editors{1}.setValue(value));
    end

    function setAnchorValue(targetEditor, value)
        targetEditor.setPoints(value);
        targetEditor.setActive(true);
    end

    function emitValue(value, varargin)
        if ~suppressed
            hub.dispatch(spec.Event, id, value, spec.ChangePolicy);
        end
    end

    function emitPairedValue(varargin)
        if suppressed
            return;
        end
        values = cell(1, numel(editors));
        for index = 1:numel(editors)
            values{index} = editors{index}.getPoints();
        end
        hub.dispatch(spec.Event, id, values, spec.ChangePolicy);
    end

    function emitBackground(varargin)
        if suppressed || strlength(spec.BackgroundEvent) == 0
            return;
        end
        hub.dispatch(spec.BackgroundEvent, id, ...
            hub.point(spec.Targets(1)), "commit");
    end

    function emitScroll(value)
        if ~suppressed && strlength(spec.ScrollEvent) > 0
            hub.dispatch(spec.ScrollEvent, id, value, "commit");
        end
    end

    function withSuppression(callback)
        suppressed = true;
        cleanupSuppression = onCleanup(@() clearSuppression());
        callback();
        clear cleanupSuppression;
    end

    function clearSuppression()
        suppressed = false;
    end

    function deleteEditors()
        clearInstruction();
        for index = 1:numel(editors)
            editors{index}.delete();
        end
    end

    function applyInstruction()
        if strlength(instruction) == 0
            return;
        end
        for index = 1:numel(spec.Targets)
            adapter = hub.adapter(spec.Targets(index), group);
            ax = adapter.axes();
            if isempty(ax) || ~isvalid(ax)
                continue;
            end
            try
                subtitle(ax, instruction, 'Interpreter', 'none');
            catch
            end
        end
    end

    function clearInstruction()
        if strlength(instruction) == 0
            return;
        end
        for index = 1:numel(spec.Targets)
            adapter = hub.adapter(spec.Targets(index), group);
            ax = adapter.axes();
            if isempty(ax) || ~isvalid(ax)
                continue;
            end
            try
                if join(string(ax.Subtitle.String), newline) == instruction
                    subtitle(ax, "");
                end
            catch
            end
        end
    end
end

function editor = createRegionSelection(runtime, spec, onSelected, onPoint)
    ax = runtime.axes();
    imageSize = normalizeRegionImageSize(spec.ImageSize);
    color = optionValue(spec.Options, 'color', [1 1 1]);
    lineWidth = optionValue(spec.Options, 'lineWidth', 1.2);
    lineStyle = optionValue(spec.Options, 'lineStyle', '--');
    threshold = optionValue(spec.Options, 'pointThreshold', 2);
    startPoint = [NaN NaN];
    overlay = gobjects(1, 0);
    session = runtime.createSession(struct( ...
        "name", "regionSelection", ...
        "onPointerDown", @pointerDown, ...
        "installScrollWheel", false));
    session.activate();
    editor = struct("delete", @deleteEditor);

    function pointerDown(~, ~)
        startPoint = clampedPoint();
        if ~all(isfinite(startPoint))
            return;
        end
        deleteOverlay();
        session.captureDrag(@drag, @release);
    end

    function drag(~, ~)
        point = clampedPoint();
        if ~all(isfinite(point))
            return;
        end
        position = rectangleFromPoints(startPoint, point);
        if isempty(overlay) || ~isgraphics(overlay)
            overlay = rectangle(ax, "Position", position, ...
                "EdgeColor", color, "LineWidth", lineWidth, ...
                "LineStyle", lineStyle, "HitTest", "off", ...
                "PickableParts", "none");
        else
            overlay.Position = position;
        end
        session.setGraphics(overlay);
    end

    function release(~, ~)
        point = clampedPoint();
        position = rectangleFromPoints(startPoint, point);
        deleteOverlay();
        if all(isfinite(position)) && max(position(3:4)) > threshold
            onSelected(position);
        elseif all(isfinite(point))
            onPoint();
        end
        startPoint = [NaN NaN];
    end

    function point = clampedPoint()
        current = double(ax.CurrentPoint);
        point = current(1, 1:2);
        if numel(imageSize) >= 2 && all(isfinite(imageSize))
            point = min([imageSize(2), imageSize(1)], max([1 1], point));
        end
    end

    function deleteEditor()
        session.delete();
        deleteOverlay();
    end

    function deleteOverlay()
        if ~isempty(overlay) && all(isgraphics(overlay))
            delete(overlay);
        end
        overlay = gobjects(1, 0);
    end
end

function imageSize = normalizeRegionImageSize(value)
    imageSize = double(value(:).');
    if numel(imageSize) < 2 || ~all(isfinite(imageSize(1:2))) || ...
            any(imageSize(1:2) < 1)
        imageSize = [NaN NaN];
    else
        imageSize = imageSize(1:2);
    end
end

function position = rectangleFromPoints(a, b)
    if numel(a) ~= 2 || numel(b) ~= 2 || ...
            ~all(isfinite([a(:); b(:)]))
        position = [NaN NaN NaN NaN];
        return;
    end
    origin = min(a, b);
    position = [origin, abs(b - a)];
end

function spec = normalizeSpec(id, value)
    if ~isstruct(value) || ~isscalar(value)
        error('labkit:ui:runtime:InvalidInteractionSpec', ...
            'Interaction "%s" must be a scalar struct.', id);
    end
    spec = struct();
    spec.Kind = string(requiredValue(value, 'Kind', id));
    spec.Targets = string(requiredValue(value, 'Targets', id));
    spec.Value = requiredValue(value, 'Value', id);
    spec.Event = string(requiredValue(value, 'Event', id));
    spec.BackgroundEvent = string(optionValue( ...
        value, 'BackgroundEvent', ""));
    spec.ScrollEvent = string(optionValue(value, 'ScrollEvent', ""));
    spec.ChangePolicy = string(optionValue( ...
        value, 'ChangePolicy', 'commit'));
    spec.ImageSize = optionValue(value, 'ImageSize', []);
    spec.Options = optionValue(value, 'Options', struct());
    spec.Instruction = string(optionValue(value, 'Instruction', ""));
    spec.Targets = spec.Targets(:).';
    if ~isscalar(spec.Kind) || strlength(spec.Kind) == 0 || ...
            isempty(spec.Targets) || any(strlength(spec.Targets) == 0)
        error('labkit:ui:runtime:InvalidInteractionSpec', ...
            'Interaction "%s" requires Kind and semantic Targets.', id);
    end
    if ~isscalar(spec.Instruction)
        error('labkit:ui:runtime:InvalidInteractionSpec', ...
            'Interaction "%s" Instruction must be scalar text.', id);
    end
    if ~isscalar(spec.Event) || strlength(spec.Event) == 0
        error('labkit:ui:runtime:InvalidInteractionSpec', ...
            'Interaction "%s" requires one semantic Event.', id);
    end
    if lower(spec.Kind) == "pairedanchors" && numel(spec.Targets) < 2
        error('labkit:ui:runtime:InvalidInteractionSpec', ...
            'pairedAnchors interaction "%s" requires at least two Targets.', id);
    elseif lower(spec.Kind) ~= "pairedanchors" && numel(spec.Targets) ~= 1
        error('labkit:ui:runtime:InvalidInteractionSpec', ...
            'Interaction "%s" requires exactly one Target.', id);
    end
end

function tf = sameIdentity(left, right)
    tf = lower(left.Kind) == lower(right.Kind) && ...
        isequal(left.Targets, right.Targets) && ...
        isequaln(left.ImageSize, right.ImageSize) && ...
        isequaln(left.Options, right.Options) && ...
        left.Event == right.Event && ...
        left.BackgroundEvent == right.BackgroundEvent && ...
        left.ScrollEvent == right.ScrollEvent && ...
        left.Instruction == right.Instruction && ...
        left.ChangePolicy == right.ChangePolicy;
end

function value = interactionInstruction(spec)
    value = spec.Instruction;
    if strlength(value) > 0
        return;
    end
    kind = lower(spec.Kind);
    mode = lower(string(optionValue(spec.Options, 'mode', 'curve')));
    if kind == "pairedanchors"
        value = "Click each preview in matching order; drag points to refine; use Undo to remove a pair.";
    elseif any(kind == ["scalebarreference", "scalebar"])
        value = "Double-click two reference endpoints; drag either endpoint to refine.";
    elseif kind == "anchors" && mode == "points"
        value = "Click blank image space to add points; drag points to refine; use Undo or Clear to remove.";
    elseif kind == "anchors"
        value = "Double-click blank image space to add; drag a point to move; double-click a point to delete.";
    elseif kind == "pointslots"
        value = "Click blank image space to place the selected marker; drag a marker to refine its position.";
    end
end

function editor = createIntervalEditor(runtime, spec, onChanged, onScroll)
    ax = runtime.axes();
    range = normalizeInterval(spec.Value);
    color = optionValue(spec.Options, 'color', [0.2 0.55 1]);
    faceColor = optionValue(spec.Options, 'faceColor', color);
    faceAlpha = optionValue(spec.Options, 'faceAlpha', 0.12);
    overlay = gobjects(1, 0);
    startX = NaN;
    options = struct("name", "intervalEditor", ...
        "onPointerDown", @pointerDown, ...
        "onScroll", @scroll, "installScrollWheel", true);
    session = runtime.createSession(options);
    session.activate();
    editor = struct("setRange", @setRange, "delete", @deleteEditor);
    refresh();

    function setRange(value)
        range = normalizeInterval(value);
        refresh();
    end

    function pointerDown(~, ~)
        point = axesPoint();
        if ~isfinite(point)
            return;
        end
        startX = point;
        range = [point point];
        refresh();
        session.captureDrag(@drag, @release);
    end

    function drag(~, ~)
        point = axesPoint();
        if isfinite(point)
            range = sort([startX point]);
            refresh();
        end
    end

    function release(~, ~)
        if all(isfinite(range)) && diff(range) > 0
            onChanged(range);
        end
    end

    function scroll(~, event)
        point = axesPoint();
        count = scrollCount(event);
        if count ~= 0
            onScroll(struct("anchor", point, "count", count));
        end
    end

    function refresh()
        if ~isgraphics(ax)
            return;
        end
        if isempty(overlay) || ~all(isgraphics(overlay))
            overlay = patch(ax, NaN, NaN, faceColor, ...
                'FaceAlpha', faceAlpha, 'EdgeColor', color, ...
                'LineStyle', ':', 'LineWidth', 1, 'HitTest', 'off', ...
                'PickableParts', 'none');
        end
        if all(isfinite(range))
            limits = ylim(ax);
            overlay.XData = [range(1) range(2) range(2) range(1)];
            overlay.YData = [limits(1) limits(1) limits(2) limits(2)];
        else
            overlay.XData = NaN;
            overlay.YData = NaN;
        end
        session.setGraphics(overlay);
        session.refresh();
    end

    function value = axesPoint()
        current = double(ax.CurrentPoint);
        value = current(1, 1);
    end

    function deleteEditor()
        session.delete();
        if ~isempty(overlay) && all(isgraphics(overlay))
            delete(overlay);
        end
        overlay = gobjects(1, 0);
    end
end

function value = normalizeInterval(value)
    value = double(value(:).');
    if numel(value) ~= 2 || ~all(isfinite(value))
        value = [NaN NaN];
    else
        value = sort(value);
    end
end

function count = scrollCount(event)
    count = 0;
    if isstruct(event) && isfield(event, 'VerticalScrollCount')
        count = double(event.VerticalScrollCount);
    elseif isobject(event) && isprop(event, 'VerticalScrollCount')
        count = double(event.VerticalScrollCount);
    end
    if ~isscalar(count) || ~isfinite(count)
        count = 0;
    end
end

function options = anchorOptions(spec, callback)
    options = spec.Options;
    options.onChanged = callback;
    kind = lower(spec.Kind);
    if any(kind == ["scalebarreference", "scalebar"])
        options.closed = false;
        options.style = "Straight lines";
        options.maxPoints = 2;
    end
end

function options = rectangleOptions(spec, callback, backgroundCallback)
    options = spec.Options;
    options.onMoved = callback;
    if strlength(spec.BackgroundEvent) > 0
        options.onBackgroundDown = backgroundCallback;
    end
end

function values = pairedValues(value, targets)
    if iscell(value) && numel(value) == numel(targets)
        values = reshape(value, 1, []);
        return;
    end
    if isstruct(value) && isscalar(value)
        values = cell(1, numel(targets));
        for k = 1:numel(targets)
            field = matlab.lang.makeValidName(char(targets(k)));
            if ~isfield(value, field)
                error('labkit:ui:runtime:InvalidInteractionValue', ...
                    'Paired interaction value is missing target "%s".', targets(k));
            end
            values{k} = value.(field);
        end
        return;
    end
    error('labkit:ui:runtime:InvalidInteractionValue', ...
        'Paired interaction Value must provide one point array per Target.');
end

function imageSize = imageSizeAt(value, index)
    if iscell(value)
        imageSize = value{index};
    else
        imageSize = value;
    end
end

function value = requiredValue(spec, name, id)
    if ~isfield(spec, name)
        error('labkit:ui:runtime:InvalidInteractionSpec', ...
            'Interaction "%s" requires %s.', id, name);
    end
    value = spec.(name);
end

function value = optionValue(spec, name, defaultValue)
    value = defaultValue;
    if isfield(spec, name)
        value = spec.(name);
    end
end
