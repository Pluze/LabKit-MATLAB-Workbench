classdef (Sealed) Schema
    %PROJECTCONTRACT Declare one durable App project contract.
    %
    % Usage:
    %   contract = labkit.app.project.Schema()
    %   contract = labkit.app.project.Schema(Name=Value)
    %
    % Description:
    %   Project Schema owns payload creation, validation, sequential
    %   migration, optional legacy import, resume, and source-relink callback
    %   signatures. App-specific fields and scientific meaning remain inside
    %   the payload and are not interpreted by this value.
    %
    % Default Contract:
    %   With no arguments, Version is 1, Create returns struct(), and
    %   Validate accepts any scalar struct. This is the standard path for a
    %   simple App with no migration or specialized project invariants.
    %
    % Required Name-Value Arguments (custom contract):
    %   Version - Positive integer payload version.
    %   Create - Fixed callback project = create().
    %   Validate - Fixed callback accepted = validate(project).
    %
    % Optional Name-Value Arguments:
    %   Migrate - Fixed callback project = migrate(project,fromVersion).
    %       Required when Version is greater than 1. Default: empty.
    %   LegacyImports - Scalar struct mapping legacy MAT variable names to
    %       fixed callbacks accepting one value and returning project or
    %       [project,resume]. Default: struct().
    %   CreateResume - Fixed callback resume = createResume(session,project).
    %       Default: empty.
    %   ApplyResume - Fixed callback
    %       session = applyResume(session,resume,project). Default: empty.
    %   RelinkSources - Fixed callback
    %       project = relink(project,unresolved,projectFile). Returning empty
    %       cancels the load. Default: empty.
    %   SourceBindings - String or cell array of project-relative field paths
    %       containing portable source records, for example
    %       "inputs.sources". When omitted, Runtime infers bindings from
    %       project-bound file-list nodes for compatibility with existing App
    %       definitions. An explicitly empty value declares no source
    %       bindings. Default: omitted compatibility inference.
    %
    % Outputs:
    %   contract - Immutable labkit.app.project.Schema value.
    %
    % Errors:
    %   labkit:app:contract:UnknownArgument - An option is missing, unknown,
    %       duplicated, or unpaired.
    %   labkit:app:contract:InvalidValue - Version or LegacyImports is invalid.
    %   labkit:app:contract:CallbackRoleMismatch - A callback does not have its
    %       documented fixed input and output count.
    %
    % Typical Call:
    %   contract = labkit.app.project.Schema(Version=1, ...
    %       Create=@createProject, Validate=@validateProject);
    %
    % See also labkit.app.Definition, labkit.app.result.Package

    properties (SetAccess = immutable)
        Version (1, 1) double
        Create
        Validate
        Migrate
        LegacyImports (1, 1) struct
        CreateResume
        ApplyResume
        RelinkSources
        SourceBindings (1, :) string
        UsesInferredSourceBindings (1, 1) logical
    end

    methods
        function obj = Schema(varargin)
            names = ["Version", "Create", "Validate", "Migrate", ...
                "LegacyImports", "CreateResume", "ApplyResume", ...
                "RelinkSources", "SourceBindings"];
            if isempty(varargin)
                varargin = {"Version", 1, "Create", @createProject, ...
                    "Validate", @validateProject};
            end
            options = labkit.app.internal.OptionParser.parse( ...
                "labkit.app.project.Schema", names, varargin{:});
            for name = ["Version", "Create", "Validate"]
                if ~isfield(options, name)
                    error("labkit:app:contract:UnknownArgument", ...
                        "labkit.app.project.Schema requires argument %s.", ...
                        name);
                end
            end

            version = options.Version;
            if ~(isnumeric(version) && isscalar(version) && ...
                    isfinite(version) && version >= 1 && version == fix(version))
                error("labkit:app:contract:InvalidValue", ...
                    "Project Schema Version must be a positive integer.");
            end
            obj.Version = double(version);
            obj.Create = fixedCallback(options.Create, 0, 1, "Create");
            obj.Validate = fixedCallback( ...
                options.Validate, 1, 1, "Validate");
            obj.Migrate = optionalCallback(options, "Migrate", 2, 1);
            if obj.Version > 1 && isempty(obj.Migrate)
                error("labkit:app:contract:InvalidValue", ...
                    "Project Schema Migrate is required above Version 1.");
            end
            obj.LegacyImports = legacyImports( ...
                optionValue(options, "LegacyImports", struct()));
            obj.CreateResume = optionalCallback( ...
                options, "CreateResume", 2, 1);
            obj.ApplyResume = optionalCallback( ...
                options, "ApplyResume", 3, 1);
            obj.RelinkSources = optionalCallback( ...
                options, "RelinkSources", 3, 1);
            obj.UsesInferredSourceBindings = ~isfield(options, "SourceBindings");
            obj.SourceBindings = sourceBindings( ...
                optionValue(options, "SourceBindings", strings(1, 0)));
        end
    end
end

function bindings = sourceBindings(value)
    if ischar(value)
        value = string(value);
    elseif iscell(value)
        if ~all(cellfun(@(item) ischar(item) || ...
                (isstring(item) && isscalar(item)), value), "all")
            error("labkit:app:contract:InvalidValue", ...
                "Project Schema SourceBindings must contain scalar text.");
        end
        value = string(value);
    end
    if ~isstring(value)
        error("labkit:app:contract:InvalidValue", ...
            "Project Schema SourceBindings must be text.");
    end
    bindings = reshape(value, 1, []);
    for binding = bindings
        parts = split(binding, ".");
        if strlength(binding) == 0 || any(strlength(parts) == 0) || ...
                startsWith(binding, "project.") || ...
                ~all(cellfun(@isvarname, cellstr(parts)))
            error("labkit:app:contract:InvalidValue", ...
                "Project Schema SourceBindings must be project-relative field paths.");
        end
    end
    bindings = unique(bindings, "stable");
end

function callback = optionalCallback(options, name, inputs, outputs)
    callback = [];
    if isfield(options, name) && ~isempty(options.(name))
        callback = fixedCallback(options.(name), inputs, outputs, name);
    end
end

function callback = fixedCallback(callback, inputs, outputs, role)
    if ~isa(callback, "function_handle") || ~isscalar(callback) || ...
            nargin(callback) ~= inputs || nargout(callback) ~= outputs
        error("labkit:app:contract:CallbackRoleMismatch", ...
            "Project Schema %s requires %d inputs and %d outputs.", ...
            role, inputs, outputs);
    end
end

function imports = legacyImports(imports)
    if ~isstruct(imports) || ~isscalar(imports)
        error("labkit:app:contract:InvalidValue", ...
            "Project Schema LegacyImports must be a scalar struct.");
    end
    names = string(fieldnames(imports));
    for k = 1:numel(names)
        callback = imports.(names(k));
        outputs = nargout(callback);
        if ~isa(callback, "function_handle") || ~isscalar(callback) || ...
                nargin(callback) ~= 1 || ~any(outputs == [1 2])
            error("labkit:app:contract:CallbackRoleMismatch", ...
                "Project Schema legacy import %s requires one input and " + ...
                "one or two outputs.", names(k));
        end
    end
end

function value = optionValue(options, name, defaultValue)
    value = defaultValue;
    if isfield(options, name)
        value = options.(name);
    end
end

function project = createProject()
    project = struct();
end

function accepted = validateProject(project)
    accepted = isstruct(project) && isscalar(project);
end
