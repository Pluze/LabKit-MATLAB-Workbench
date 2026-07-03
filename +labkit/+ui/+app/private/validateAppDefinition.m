% Private UI app helper. Expected caller: labkit.ui.app.define and
% labkit.ui.app.run. Input is a candidate app definition struct. Side effect:
% throws app-neutral validation errors before runtime construction begins.
function validateAppDefinition(def)
    if ~isstruct(def) || ~isscalar(def)
        error('labkit:ui:app:InvalidDefinition', ...
            'App definition must be a scalar struct.');
    end
    required = ["type", "id", "title", "initialState", "spec", ...
        "actions", "render", "startup", "hydrate"];
    for k = 1:numel(required)
        if ~isfield(def, required(k))
            error('labkit:ui:app:InvalidDefinition', ...
                'App definition is missing field "%s".', required(k));
        end
    end
    if string(def.type) ~= "labkit.ui.app.definition"
        error('labkit:ui:app:InvalidDefinition', ...
            'App definition has unsupported type "%s".', string(def.type));
    end
    assertScalarText(def.id, "id");
    assertScalarText(def.title, "title");
    if ~(isa(def.initialState, 'function_handle') || isstruct(def.initialState))
        error('labkit:ui:app:InvalidDefinition', ...
            'InitialState must be a function handle or struct.');
    end
    if ~isa(def.spec, 'function_handle')
        error('labkit:ui:app:InvalidDefinition', ...
            'Spec must be a function handle.');
    end
    if ~isa(def.render, 'function_handle')
        error('labkit:ui:app:InvalidDefinition', ...
            'Render must be a function handle.');
    end
    validateActions(def.actions);
    validatePhaseIds(def.startup, def.actions, "Startup");
    validatePhaseIds(def.hydrate, def.actions, "Hydrate");
end

function validateActions(actions)
    if ~isstruct(actions) || ~isscalar(actions)
        error('labkit:ui:app:InvalidDefinition', ...
            'Actions must be a scalar struct of function handles.');
    end
    ids = fieldnames(actions);
    if isempty(ids)
        error('labkit:ui:app:InvalidDefinition', ...
            'Actions must define at least one action function.');
    end
    for k = 1:numel(ids)
        if ~isa(actions.(ids{k}), 'function_handle')
            error('labkit:ui:app:InvalidDefinition', ...
                'Action "%s" must be a function handle.', ids{k});
        end
    end
end

function validatePhaseIds(ids, actions, label)
    ids = string(ids);
    ids = ids(ids ~= "");
    actionIds = string(fieldnames(actions));
    missing = setdiff(ids, actionIds);
    if ~isempty(missing)
        error('labkit:ui:app:InvalidDefinition', ...
            '%s phase references unknown action id(s): %s.', ...
            label, strjoin(cellstr(missing), ', '));
    end
end

function assertScalarText(value, name)
    if ~(ischar(value) || (isstring(value) && isscalar(value))) || ...
            strlength(string(value)) == 0
        error('labkit:ui:app:InvalidDefinition', ...
            'App definition %s must be nonempty scalar text.', name);
    end
end
