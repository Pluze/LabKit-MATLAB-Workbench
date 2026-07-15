function def = define(varargin)
%DEFINE Create a LabKit declarative app runtime definition.
%
% App-facing contract:
%   def = labkit.ui.runtime.define("Id", id, "Title", title, ...
%       "Project", projectSpec, "CreateSession", sessionFcn, ...
%       "Layout", layoutFcn, "Actions", actions, ...
%       "Present", presentFcn, "Renderers", renderers, ...
%       "Start", startFcn, "DebugSample", debugSampleFcn)
%
% Project is a struct with Version, Create, Validate, and optional ordered
% Migrations fields. CreateSession, Renderers, Start, and DebugSample are
% optional. DebugSample receives the runtime debug log and is called only for
% debug launches.

    opts = parseOptions(varargin);
    def = createV2Definition(opts);
    validateAppDefinition(def);
end

function def = createV2Definition(opts)
    def = struct();
    def.type = "labkit.ui.runtime.definition";
    def.contractVersion = 2;
    def.id = string(requiredOption(opts, "Id"));
    def.title = string(requiredOption(opts, "Title"));
    def.project = requiredOption(opts, "Project");
    def.createSession = optionValue(opts, "CreateSession", []);
    def.layout = requiredOption(opts, "Layout");
    def.actions = requiredOption(opts, "Actions");
    def.present = requiredOption(opts, "Present");
    def.renderers = optionValue(opts, "Renderers", struct());
    def.start = optionValue(opts, "Start", []);
    def.debugSample = optionValue(opts, "DebugSample", []);
    def.utilities = optionValue(opts, "Utilities", struct());
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
