classdef (Sealed) Pack
    %PACK Describe one typed anonymous App reproduction scenario.
    %
    % Usage:
    %   pack = labkit.app.synthetic.Pack( ...
    %       Scenario=scenario,InitialProject=project,Artifacts=artifacts)
    %
    % Description:
    %   Couples one App-authored synthetic project with its anonymous artifact
    %   declarations so users and tests can reproduce a named scenario through
    %   the App's ordinary import workflow.
    %
    % Required Name-Value Arguments:
    %   Scenario - Nonempty stable scenario identifier.
    %   InitialProject - Scalar current App project struct.
    %   Artifacts - Row cell array of labkit.app.synthetic.Artifact values.
    %       Empty is legal for an App whose scenario needs no files.
    %
    % Outputs:
    %   pack - Immutable synthetic-input pack.
    %
    % Errors:
    %   labkit:app:contract:UnknownArgument - An argument is missing, unknown,
    %       duplicated, or unpaired.
    %   labkit:app:contract:InvalidValue - Scenario, project, or Artifacts is
    %       malformed.
    %   labkit:app:contract:DuplicateId - Artifact IDs or relative paths are
    %       duplicated.
    %
    % Example:
    %   artifact = labkit.app.synthetic.Artifact( ...
    %       "input","source","samples/input.csv");
    %   pack = labkit.app.synthetic.Pack( ...
    %       Scenario="representative",InitialProject=struct(), ...
    %       Artifacts={artifact});
    %   assert(pack.Scenario == "representative")
    %
    % See also labkit.app.synthetic.Context,
    %   labkit.app.synthetic.Artifact,
    %   labkit.app.Definition

    properties (SetAccess = immutable)
        Scenario (1, 1) string
        InitialProject (1, 1) struct
        Artifacts (1, :) cell
    end

    methods
        function obj = Pack(varargin)
            names = ["Scenario", "InitialProject", "Artifacts"];
            options = labkit.app.internal.OptionParser.parse( ...
                "labkit.app.synthetic.Pack", names, varargin{:});
            for name = names
                if ~isfield(options, name)
                    error("labkit:app:contract:UnknownArgument", ...
                        "labkit.app.synthetic.Pack requires %s.", ...
                        name);
                end
            end
            obj.Scenario = nonemptyText(options.Scenario, "Scenario");
            if ~isstruct(options.InitialProject) || ...
                    ~isscalar(options.InitialProject)
                invalid("InitialProject must be a scalar struct.");
            end
            obj.InitialProject = options.InitialProject;
            artifacts = options.Artifacts;
            if ~iscell(artifacts) || ...
                    (~isempty(artifacts) && ~isrow(artifacts)) || ...
                    ~all(cellfun(@(value) isa(value, ...
                    "labkit.app.synthetic.Artifact") && isscalar(value), ...
                    artifacts))
                invalid("Artifacts must be a row cell array of Artifact values.");
            end
            artifacts = reshape(artifacts, 1, []);
            ids = string(cellfun(@(value) value.Id, artifacts, ...
                "UniformOutput", false));
            paths = string(cellfun(@(value) value.RelativePath, artifacts, ...
                "UniformOutput", false));
            if numel(unique(ids)) ~= numel(ids) || ...
                    numel(unique(paths)) ~= numel(paths)
                error("labkit:app:contract:DuplicateId", ...
                    "Synthetic Pack artifact IDs and paths must be unique.");
            end
            obj.Artifacts = artifacts;
        end
    end
end

function value = nonemptyText(value, name)
if ~(ischar(value) || (isstring(value) && isscalar(value)))
    invalid("%s must be scalar text.", name);
end
value = string(value);
if strlength(value) == 0
    invalid("%s must be nonempty.", name);
end
end

function invalid(message, varargin)
error("labkit:app:contract:InvalidValue", ...
    "Synthetic Pack " + message, varargin{:});
end
