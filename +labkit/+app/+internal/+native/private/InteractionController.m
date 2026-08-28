% Private App SDK native-adapter implementation for InteractionController; called only by the internal runtime.
function controller = InteractionController(figureHandle, targets, dispatch)
% Private MATLAB adapter child that owns managed interaction editors.
resources = containers.Map("KeyType", "char", "ValueType", "any");
hub = FigureInteractionHub(figureHandle, targets, ...
    @dispatchEvent, @(id) removeTargetResources(id));
controller = struct("reconcile", @reconcile, "delete", @deleteController);

    function reconcile(declarations, operations)
        specs = compileSpecs(declarations, operations);
        actionIds = actionIdsFor(specs);
        reconcileInteractions(hub, resources, specs, actionIds);
    end

    function dispatchEvent(id, value)
        parts = split(id, "__");
        dispatch(parts(1), parts(2), value);
    end

    function removeTargetResources(target)
        ids = string(keys(resources));
        for id = ids
            controlled = resources(char(id));
            if any(controlled.spec.Targets == string(target))
                controlled.delete();
                remove(resources, char(id));
            end
        end
    end

    function deleteController()
        ids = string(keys(resources));
        for id = ids
            controlled = resources(char(id));
            controlled.delete();
            remove(resources, char(id));
        end
        hub.delete();
    end
end

function specs = compileSpecs(declarations, operations)
specs = struct();
for k = 1:numel(operations)
    operation = operations{k};
    id = operation.Target;
    match = find(cellfun(@(value) value.Id == id, declarations), 1);
    if isempty(match) || ~operation.Value.Enabled
        continue
    end
    declaration = declarations{match};
    changed = declaration.signal("interactionChanged").Id;
    background = signalId(declaration, "backgroundPressed");
    selection = signalId(declaration, "selectionChanged");
    scrolled = signalId(declaration, "scrolled");
    specs.(char(id)) = struct( ...
        "Kind", editorKind(declaration.Kind), ...
        "Targets", {declaration.Targets}, ...
        "Value", {operation.Value.Value}, ...
        "Event", changed, ...
        "BackgroundEvent", background, ...
        "SelectionEvent", selection, ...
        "ScrollEvent", scrolled, ...
        "ChangePolicy", "commit", ...
        "ImageSize", operation.Value.ImageSize, ...
        "Options", declaration.Options, ...
        "Instruction", declaration.Instruction);
end
end

function ids = actionIdsFor(specs)
names = string(fieldnames(specs));
ids = strings(4, numel(names));
for k = 1:numel(names)
    name = names(k);
    spec = specs.(char(name));
    ids(:, k) = [string(spec.Event); string(spec.BackgroundEvent); ...
        string(spec.SelectionEvent); string(spec.ScrollEvent)];
end
ids = ids(:).';
ids = unique(ids(strlength(ids) > 0), "stable");
end

function id = signalId(declaration, name)
binding = declaration.signal(name);
id = "";
if ~isempty(binding)
    id = binding.Id;
end
end

function kind = editorKind(kind)
% The private editors retain concise implementation names.
switch kind
    case "anchorPath"
        kind = "anchors";
    case "scaleReference"
        kind = "scaleBarReference";
end
end
