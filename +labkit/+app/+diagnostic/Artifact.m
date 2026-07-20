classdef (Sealed) Artifact
    %ARTIFACT Describe one anonymous diagnostic-sample artifact.
    %
    % Usage:
    %   artifact = labkit.app.diagnostic.Artifact( ...
    %       id,role,relativePath,Name=Value)
    %
    % Inputs:
    %   id - Nonempty semantic identifier unique within a SamplePack.
    %   role - Nonempty App-owned artifact purpose.
    %   relativePath - Nonempty diagnostic-root-relative path without
    %       traversal.
    %
    % Optional Name-Value Arguments:
    %   Expectation - "loads", "rejects", "exports", or "support".
    %       Default: "loads".
    %
    % Outputs:
    %   artifact - Immutable diagnostic artifact value.
    %
    % Errors:
    %   labkit:app:contract:UnknownArgument - An option is unknown,
    %       duplicated, or unpaired.
    %   labkit:app:contract:InvalidValue - Text, path, or Expectation is
    %       malformed.
    %
    % Example:
    %   artifact = labkit.app.diagnostic.Artifact( ...
    %       "input","source","samples/input.csv");
    %   assert(artifact.Expectation == "loads")
    %
    % See also labkit.app.diagnostic.SampleContext,
    %   labkit.app.diagnostic.SamplePack

    properties (SetAccess = immutable)
        Id (1, 1) string
        Role (1, 1) string
        RelativePath (1, 1) string
        Expectation (1, 1) string
    end

    methods
        function obj = Artifact(id, role, relativePath, varargin)
            options = labkit.app.internal.OptionParser.parse( ...
                "labkit.app.diagnostic.Artifact", "Expectation", ...
                varargin{:});
            obj.Id = nonemptyText(id, "Id");
            obj.Role = nonemptyText(role, "Role");
            obj.RelativePath = relativePathValue(relativePath);
            expectation = optionValue(options, "Expectation", "loads");
            expectation = nonemptyText(expectation, "Expectation");
            if ~any(expectation == ...
                    ["loads", "rejects", "exports", "support"])
                error("labkit:app:contract:InvalidValue", ...
                    "Diagnostic Artifact Expectation is unsupported.");
            end
            obj.Expectation = expectation;
        end
    end
end

function value = relativePathValue(value)
value = replace(nonemptyText(value, "RelativePath"), "\", "/");
if startsWith(value, "/") || startsWith(value, "//") || ...
        ~isempty(regexp(char(value), '^[A-Za-z]:', "once"))
    invalid("RelativePath must be diagnostic-root-relative.");
end
parts = split(value, "/");
if any(parts == ["", ".", ".."], "all")
    invalid("RelativePath must not traverse diagnostic boundaries.");
end
value = join(parts, "/");
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

function value = optionValue(options, name, defaultValue)
value = defaultValue;
if isfield(options, name)
    value = options.(name);
end
end

function invalid(message, varargin)
error("labkit:app:contract:InvalidValue", ...
    "Diagnostic Artifact " + message, varargin{:});
end
