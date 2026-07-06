function def = define(varargin)
%DEFINE Create a LabKit declarative app runtime definition.
%
% App-facing contract:
%   def = labkit.ui.runtime.define("Id", id, "Title", title, ...
%       "InitialState", stateFcn, "Layout", layoutFcn, ...
%       "Actions", actions, "Render", renderFcn)
%
% Inputs:
%   Id - scalar text app id used for runtime diagnostics.
%   Title - scalar text workbench title.
%   InitialState - function handle returning the initial app state, or a
%       state struct used directly.
%   Layout - function handle returning a labkit.ui.layout.workbench tree. The runtime
%       calls it with generated callbacks and, when accepted, initial state.
%   Actions - struct whose field names are action ids and whose values are
%       function handles called as action(state, payload, services).
%   Render - function handle called as render(state, ui, services).
%   Startup - optional action id array dispatched after the shell paints.
%   Hydrate - optional action id array reserved for later idle hydration.
%   Snapshot - optional struct with Version, Serialize, Deserialize, and
%       AfterLoad hooks for app-owned state cleanup and restore policy.
%   Utilities - optional struct controlling framework utility-bar visibility.
%
% Output:
%   def - plain scalar struct consumed by labkit.ui.runtime.run.

    opts = parseOptions(varargin);
    def = struct();
    def.type = "labkit.ui.runtime.definition";
    def.id = string(requiredOption(opts, "Id"));
    def.title = string(requiredOption(opts, "Title"));
    def.initialState = requiredOption(opts, "InitialState");
    def.layout = requiredOption(opts, "Layout");
    def.actions = requiredOption(opts, "Actions");
    def.render = requiredOption(opts, "Render");
    def.startup = string(optionValue(opts, "Startup", strings(1, 0)));
    def.hydrate = string(optionValue(opts, "Hydrate", strings(1, 0)));
    def.snapshot = optionValue(opts, "Snapshot", struct());
    def.utilities = optionValue(opts, "Utilities", struct());
    validateAppDefinition(def);
end

function opts = parseOptions(args)
    if mod(numel(args), 2) ~= 0
        error('labkit:ui:runtime:InvalidDefinitionOptions', ...
            'labkit.ui.runtime.define options must be name-value pairs.');
    end
    opts = struct();
    for k = 1:2:numel(args)
        name = char(string(args{k}));
        opts.(name) = args{k + 1};
    end
end

function value = requiredOption(opts, name)
    field = char(name);
    if ~isfield(opts, field)
        error('labkit:ui:runtime:MissingDefinitionField', ...
            'App definition is missing required field "%s".', field);
    end
    value = opts.(field);
end

function value = optionValue(opts, name, defaultValue)
    field = char(name);
    value = defaultValue;
    if isfield(opts, field)
        value = opts.(field);
    end
end
