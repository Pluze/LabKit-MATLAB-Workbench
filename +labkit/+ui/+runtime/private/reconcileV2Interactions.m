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
            editor = labkit.ui.interaction.anchorEditor( ...
                hub.adapter(spec.Targets(1), group), ...
                spec.ImageSize, options);
            editors = {editor};
            update = @updateSingleAnchors;
        case "pairedanchors"
            editors = cell(1, numel(spec.Targets));
            for k = 1:numel(spec.Targets)
                options = anchorOptions(spec, @emitPairedValue);
                editors{k} = labkit.ui.interaction.anchorEditor( ...
                    hub.adapter(spec.Targets(k), group), ...
                    imageSizeAt(spec.ImageSize, k), options);
            end
            update = @updatePairedAnchors;
        case "rectangle"
            options = rectangleOptions(spec, @emitValue);
            editor = labkit.ui.interaction.rectangleEditor( ...
                hub.adapter(spec.Targets(1), group), spec.ImageSize, ...
                spec.Value, options);
            editors = {editor};
            update = @updateRectangle;
        otherwise
            error('labkit:ui:runtime:UnknownInteractionKind', ...
                'Interaction "%s" has unsupported Kind "%s".', id, spec.Kind);
    end
    controlled = struct("spec", spec, "update", update, ...
        "delete", @deleteEditors, "editors", {editors});

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
        for index = 1:numel(editors)
            editors{index}.delete();
        end
    end
end

function spec = normalizeSpec(id, value)
    if ~isstruct(value) || ~isscalar(value)
        error('labkit:ui:runtime:InvalidInteractionSpec', ...
            'Interaction "%s" must be a scalar struct.', id);
    end
    spec = struct( ...
        "Kind", string(requiredValue(value, 'Kind', id)), ...
        "Targets", string(requiredValue(value, 'Targets', id)), ...
        "Value", requiredValue(value, 'Value', id), ...
        "Event", string(requiredValue(value, 'Event', id)), ...
        "ChangePolicy", string(optionValue(value, 'ChangePolicy', 'commit')), ...
        "ImageSize", optionValue(value, 'ImageSize', []), ...
        "Options", optionValue(value, 'Options', struct()));
    spec.Targets = spec.Targets(:).';
    if ~isscalar(spec.Kind) || strlength(spec.Kind) == 0 || ...
            isempty(spec.Targets) || any(strlength(spec.Targets) == 0)
        error('labkit:ui:runtime:InvalidInteractionSpec', ...
            'Interaction "%s" requires Kind and semantic Targets.', id);
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
        left.ChangePolicy == right.ChangePolicy;
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

function options = rectangleOptions(spec, callback)
    options = spec.Options;
    options.onMoved = callback;
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
