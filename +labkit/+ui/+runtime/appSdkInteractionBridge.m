function bridge = appSdkInteractionBridge(figureHandle, targets, dispatch)
%APPSDKINTERACTIONBRIDGE Temporary migration bridge for private native editors.
%
% This function is migration-only and is deleted when the editor/hub
% implementation moves under labkit.app.internal. It is not an App API.
ui = legacyUi(figureHandle, targets);
runtime = struct("ui", ui, "actions", struct(), ...
    "resources", emptyResources());
runtime.interactionHub = v2FigureInteractionHub( ...
    ui, @dispatchEvent, @(~) []);
setappdata(figureHandle, appRuntimeKey(), runtime);
bridge = struct("reconcile", @reconcile, "delete", @deleteBridge);

    function reconcile(declarations, operations)
        specs = compileSpecs(declarations, operations);
        current = getappdata(figureHandle, appRuntimeKey());
        current.actions = actionFields(specs);
        current.interactionHub = runtime.interactionHub;
        current.ui = ui;
        setappdata(figureHandle, appRuntimeKey(), current);
        reconcileV2Interactions(current, specs);
    end

    function dispatchEvent(event)
        id = string(event.id);
        parts = split(id, "__");
        dispatch(parts(1), parts(2), event.value);
    end

    function deleteBridge()
        if isempty(figureHandle) || ~isvalid(figureHandle)
            return;
        end
        try
            v2ResourceRegistry(figureHandle, "clearScope", "interaction");
        catch
        end
        runtime.interactionHub.delete();
        if isappdata(figureHandle, appRuntimeKey())
            rmappdata(figureHandle, appRuntimeKey());
        end
    end
end

function ui = legacyUi(figureHandle, targets)
controls = struct();
names = string({targets.id});
plotIds = unique(extractBefore(names + ".", "."));
for plotIndex = 1:numel(plotIds)
    plotId = plotIds(plotIndex);
    prefix = plotId + ".";
    matches = names(startsWith(names, prefix));
    axesById = struct();
    for keyIndex = 1:numel(matches)
        key = matches(keyIndex);
        axisId = extractAfter(key, prefix);
        index = find(names == key, 1);
        axesById.(char(axisId)) = targets(index).axes;
    end
    controls.(char(plotId)) = struct( ...
        "kind", "previewArea", "axesById", axesById);
end
ui = struct("figure", figureHandle, "controls", controls);
end

function specs = compileSpecs(declarations, operations)
specs = struct();
for k = 1:numel(operations)
    operation = operations{k};
    id = operation.Target;
    match = find(cellfun(@(value) value.Id == id, declarations), 1);
    if isempty(match)
        continue;
    end
    declaration = declarations{match};
    if ~operation.Value.Enabled
        continue;
    end
    changed = declaration.signal("interactionChanged").Id;
    background = signalId(declaration, "backgroundPressed");
    scrolled = signalId(declaration, "scrolled");
    specs.(char(id)) = struct( ...
        "Kind", legacyKind(declaration.Kind), ...
        "Targets", {declaration.Targets}, ...
        "Value", {operation.Value.Value}, ...
        "Event", changed, ...
        "BackgroundEvent", background, ...
        "ScrollEvent", scrolled, ...
        "ChangePolicy", "commit", ...
        "ImageSize", operation.Value.ImageSize, ...
        "Options", declaration.Options, ...
        "Instruction", declaration.Instruction);
end
end

function id = signalId(declaration, name)
binding = declaration.signal(name);
id = "";
if ~isempty(binding)
    id = binding.Id;
end
end

function kind = legacyKind(kind)
switch kind
    case "anchorPath"
        kind = "anchors";
    case "scaleReference"
        kind = "scaleBarReference";
end
end

function actions = actionFields(specs)
actions = struct();
names = string(fieldnames(specs));
for name = names.'
    spec = specs.(char(name));
    ids = [string(spec.Event), string(spec.BackgroundEvent), ...
        string(spec.ScrollEvent)];
    ids = ids(strlength(ids) > 0);
    for id = ids
        actions.(char(id)) = @(varargin) [];
    end
end
end

function resources = emptyResources()
resources = struct("scope", {}, "id", {}, "value", {}, ...
    "cleanup", {}, "disposed", {});
end
