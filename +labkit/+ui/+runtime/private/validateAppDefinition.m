% Private UI runtime helper. Expected caller: labkit.ui.runtime.define and
% labkit.ui.runtime.run. Input is a candidate app definition struct. Side effect:
% throws app-neutral validation errors before runtime construction begins.
function validateAppDefinition(def)
    if ~isstruct(def) || ~isscalar(def)
        error('labkit:ui:runtime:InvalidDefinition', ...
            'App definition must be a scalar struct.');
    end
    validateV2Definition(def);
end

function validateV2Definition(def)
    required = ["type", "contractVersion", "id", "title", "project", ...
        "createSession", "layout", "actions", "present", "renderers", ...
        "start", "debugSample", "utilities"];
    requireFields(def, required);
    if string(def.type) ~= "labkit.ui.runtime.definition"
        error('labkit:ui:runtime:InvalidDefinition', ...
            'App definition has unsupported type "%s".', string(def.type));
    end
    assertScalarText(def.id, "id");
    assertScalarText(def.title, "title");
    validateProjectSpec(def.project);
    if ~isempty(def.createSession) && ~isa(def.createSession, 'function_handle')
        error('labkit:ui:runtime:InvalidDefinition', ...
            'CreateSession must be a function handle when supplied.');
    end
    if ~isa(def.layout, 'function_handle')
        error('labkit:ui:runtime:InvalidDefinition', ...
            'Layout must be a function handle.');
    end
    validateActions(def.actions);
    if ~isa(def.present, 'function_handle')
        error('labkit:ui:runtime:InvalidDefinition', ...
            'Present must be a function handle.');
    end
    validateRenderers(def.renderers);
    if ~isempty(def.start) && ~isa(def.start, 'function_handle') && ...
            ~(ischar(def.start) || (isstring(def.start) && isscalar(def.start)))
        error('labkit:ui:runtime:InvalidDefinition', ...
            'Start must be a function handle or scalar action id when supplied.');
    end
    if ischar(def.start) || isstring(def.start)
        validatePhaseIds(string(def.start), def.actions, "Start");
    end
    if ~isempty(def.debugSample) && ~isa(def.debugSample, 'function_handle')
        error('labkit:ui:runtime:InvalidDefinition', ...
            'DebugSample must be a function handle when supplied.');
    end
    validateUtilitiesSpec(def.utilities);
end

function requireFields(value, required)
    for k = 1:numel(required)
        if ~isfield(value, required(k))
            error('labkit:ui:runtime:InvalidDefinition', ...
                'App definition is missing field "%s".', required(k));
        end
    end
end

function validateProjectSpec(spec)
    if ~isstruct(spec) || ~isscalar(spec)
        error('labkit:ui:runtime:InvalidDefinition', ...
            'Project must be a scalar struct.');
    end
    requireFields(spec, ["Version", "Create", "Validate"]);
    version = spec.Version;
    if ~(isnumeric(version) && isscalar(version) && isfinite(version) && ...
            version >= 1 && version == fix(version))
        error('labkit:ui:runtime:InvalidDefinition', ...
            'Project.Version must be a positive integer scalar.');
    end
    if ~isa(spec.Create, 'function_handle') || ...
            ~isa(spec.Validate, 'function_handle')
        error('labkit:ui:runtime:InvalidDefinition', ...
            'Project.Create and Project.Validate must be function handles.');
    end
    if isfield(spec, 'Migrations') && ~isempty(spec.Migrations)
        migrations = spec.Migrations;
        if ~iscell(migrations) || ...
                ~all(cellfun(@(f) isa(f, 'function_handle'), migrations))
            error('labkit:ui:runtime:InvalidDefinition', ...
                'Project.Migrations must be a cell array of function handles.');
        end
    end
    migrations = {};
    if isfield(spec, 'Migrations')
        migrations = spec.Migrations;
    end
    if numel(migrations) ~= double(version) - 1
        error('labkit:ui:runtime:InvalidDefinition', ...
            'Project.Migrations must define every ordered version step.');
    end
    if isfield(spec, 'LegacyImports') && ...
            (~isstruct(spec.LegacyImports) || ~isscalar(spec.LegacyImports) || ...
            ~all(structfun(@(f) isa(f, 'function_handle'), spec.LegacyImports)))
        error('labkit:ui:runtime:InvalidDefinition', ...
            'Project.LegacyImports must map variable names to import functions.');
    end
    if isfield(spec, 'ApplyResume') && ...
            ~isa(spec.ApplyResume, 'function_handle')
        error('labkit:ui:runtime:InvalidDefinition', ...
            'Project.ApplyResume must be a function handle.');
    end
    if isfield(spec, 'CreateResume') && ...
            ~isa(spec.CreateResume, 'function_handle')
        error('labkit:ui:runtime:InvalidDefinition', ...
            'Project.CreateResume must be a function handle.');
    end
    if isfield(spec, 'RelinkSources') && ...
            ~isa(spec.RelinkSources, 'function_handle')
        error('labkit:ui:runtime:InvalidDefinition', ...
            'Project.RelinkSources must be a function handle.');
    end
end

function validateRenderers(renderers)
    if ~isstruct(renderers) || ~isscalar(renderers)
        error('labkit:ui:runtime:InvalidDefinition', ...
            'Renderers must be a scalar struct of function handles.');
    end
    names = fieldnames(renderers);
    for k = 1:numel(names)
        if ~isa(renderers.(names{k}), 'function_handle')
            error('labkit:ui:runtime:InvalidDefinition', ...
                'Renderer "%s" must be a function handle.', names{k});
        end
    end
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

function validateUtilitiesSpec(spec)
    if isempty(spec)
        return;
    end
    if ~isstruct(spec) || ~isscalar(spec)
        error('labkit:ui:runtime:InvalidDefinition', ...
            'Utilities must be a scalar struct when supplied.');
    end
end
