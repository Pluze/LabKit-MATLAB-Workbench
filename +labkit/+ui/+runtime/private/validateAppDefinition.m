% Private UI runtime helper. Expected caller: labkit.ui.runtime.define and
% labkit.ui.runtime.run. Input is a candidate app definition struct. Side effect:
% throws app-neutral validation errors before runtime construction begins.
function validateAppDefinition(def)
    if ~isstruct(def) || ~isscalar(def)
        error('labkit:ui:runtime:InvalidDefinition', ...
            'App definition must be a scalar struct.');
    end
    required = ["type", "id", "title", "initialState", "layout", ...
        "actions", "render", "startup", "hydrate", "snapshot", ...
        "utilities"];
    for k = 1:numel(required)
        if ~isfield(def, required(k))
            error('labkit:ui:runtime:InvalidDefinition', ...
                'App definition is missing field "%s".', required(k));
        end
    end
    if string(def.type) ~= "labkit.ui.runtime.definition"
        error('labkit:ui:runtime:InvalidDefinition', ...
            'App definition has unsupported type "%s".', string(def.type));
    end
    assertScalarText(def.id, "id");
    assertScalarText(def.title, "title");
    if ~(isa(def.initialState, 'function_handle') || isstruct(def.initialState))
        error('labkit:ui:runtime:InvalidDefinition', ...
            'InitialState must be a function handle or struct.');
    end
    if ~isa(def.layout, 'function_handle')
        error('labkit:ui:runtime:InvalidDefinition', ...
            'Layout must be a function handle.');
    end
    if ~isa(def.render, 'function_handle')
        error('labkit:ui:runtime:InvalidDefinition', ...
            'Render must be a function handle.');
    end
    validateActions(def.actions);
    validatePhaseIds(def.startup, def.actions, "Startup");
    validatePhaseIds(def.hydrate, def.actions, "Hydrate");
    validateSnapshotSpec(def.snapshot);
    validateUtilitiesSpec(def.utilities);
end

function validateActions(actions)
    if ~isstruct(actions) || ~isscalar(actions)
        error('labkit:ui:runtime:InvalidDefinition', ...
            'Actions must be a scalar struct of function handles.');
    end
    ids = fieldnames(actions);
    if isempty(ids)
        error('labkit:ui:runtime:InvalidDefinition', ...
            'Actions must define at least one action function.');
    end
    for k = 1:numel(ids)
        if ~isa(actions.(ids{k}), 'function_handle')
            error('labkit:ui:runtime:InvalidDefinition', ...
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
        error('labkit:ui:runtime:InvalidDefinition', ...
            '%s phase references unknown action id(s): %s.', ...
            label, strjoin(cellstr(missing), ', '));
    end
end

function assertScalarText(value, name)
    if ~(ischar(value) || (isstring(value) && isscalar(value))) || ...
            strlength(string(value)) == 0
        error('labkit:ui:runtime:InvalidDefinition', ...
            'App definition %s must be nonempty scalar text.', name);
    end
end

function validateSnapshotSpec(spec)
    if isempty(spec)
        return;
    end
    if ~isstruct(spec) || ~isscalar(spec)
        error('labkit:ui:runtime:InvalidDefinition', ...
            'Snapshot must be a scalar struct when supplied.');
    end
    if isfield(spec, 'Version')
        value = spec.Version;
        if ~(isnumeric(value) && isscalar(value) && isfinite(value))
            error('labkit:ui:runtime:InvalidDefinition', ...
                'Snapshot.Version must be a finite numeric scalar.');
        end
    end
    optionalHooks = ["Serialize", "Deserialize", "AfterLoad"];
    for k = 1:numel(optionalHooks)
        field = char(optionalHooks(k));
        if isfield(spec, field) && ~isempty(spec.(field)) && ...
                ~isa(spec.(field), 'function_handle')
            error('labkit:ui:runtime:InvalidDefinition', ...
                'Snapshot.%s must be a function handle when supplied.', field);
        end
    end
end

function validateUtilitiesSpec(spec)
    if isempty(spec)
        return;
    end
    if ~isstruct(spec) || ~isscalar(spec)
        error('labkit:ui:runtime:InvalidDefinition', ...
            'Utilities must be a scalar struct when supplied.');
    end
end
