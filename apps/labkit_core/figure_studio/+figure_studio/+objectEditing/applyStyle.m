%APPLYSTYLE Apply a parsed property at selection, type, role, group, or document scope.
function state = applyStyle(state, callbackContext)
before = state.session.editor.document;
document = before;
property = state.session.editor.activeProperty;
try
    value = parseValue(property, state.session.editor.propertyDraft);
    targets = cascadeTargets(document, state.session.editor.activeScope);
    for k = 1:size(targets, 1)
        document = figure_studio.figureDocument.setStyle( ...
            document, targets(k, 1), targets(k, 2), property, value);
    end
catch exception
    state.session.workflow.status = string(exception.message);
    callbackContext.log("info", "figure_studio.objectediting.style.rejected", ...
        state.session.workflow.status);
    return;
end
state = figure_studio.axisEditing.commitDocument( ...
    state, before, document, "Apply " + property);
end

function targets = cascadeTargets(document, scope)
scope = lower(string(scope));
selected = selectedNodes(document);
switch scope
    case "selection"
        targets = [repmat("object", numel(selected), 1), ...
            string({selected.id}).'];
    case "type"
        values = unique(string({selected.kind}));
        values(values == "group") = [];
        targets = [repmat("kind", numel(values), 1), values(:)];
    case "role"
        values = unique(string({selected.role}));
        targets = [repmat("role", numel(values), 1), values(:)];
    case "group"
        values = unique([string({selected.groupId}), ...
            string({selected(string({selected.kind}) == "group").id})]);
        values(values == "") = [];
        targets = [repmat("group", numel(values), 1), values(:)];
    otherwise
        targets = ["document", "*"];
end
if isempty(targets)
    error("figure_studio:objectEditing:NoStyleTarget", ...
        "Select an object or group for this style scope.");
end
end

function nodes = selectedNodes(document)
ids = document.selection;
nodes = document.nodes(ismember(string({document.nodes.id}), ids));
end

function value = parseValue(property, draft)
property = string(property);
draft = strtrim(string(draft));
if any(property == ["LineWidth", "MarkerSize", "FaceAlpha", ...
        "EdgeAlpha", "FontSize", "Rotation"])
    value = str2double(draft);
    if ~isscalar(value) || ~isfinite(value)
        error("figure_studio:objectEditing:InvalidNumericStyle", ...
            "%s requires one finite number.", property);
    end
    if any(property == ["LineWidth", "MarkerSize", "FontSize"]) && value <= 0
        error("figure_studio:objectEditing:InvalidPositiveStyle", ...
            "%s must be positive.", property);
    end
    if any(property == ["FaceAlpha", "EdgeAlpha"]) && (value < 0 || value > 1)
        error("figure_studio:objectEditing:InvalidAlpha", ...
            "%s must be from 0 to 1.", property);
    end
elseif contains(property, "Color")
    if any(lower(draft) == ["none", "flat", "interp", "auto"])
        value = lower(draft);
    else
        parts = str2double(split(replace(draft, ",", " ")));
        parts = parts(isfinite(parts));
        if numel(parts) ~= 3 || any(parts < 0 | parts > 1)
            error("figure_studio:objectEditing:InvalidColor", ...
                "%s requires an RGB triplet from 0 to 1 or a supported color mode.", property);
        end
        value = reshape(parts, 1, 3);
    end
else
    if strlength(draft) == 0
        error("figure_studio:objectEditing:EmptyStyle", ...
            "%s requires a nonempty value.", property);
    end
    value = draft;
end
end
