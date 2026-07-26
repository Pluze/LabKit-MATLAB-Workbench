classdef (Sealed) Options
    %OPTIONS Configure one App SDK diagnostic session.
    %
    % Usage:
    %   options = labkit.app.diagnostic.Options()
    %   options = labkit.app.diagnostic.Options(Name=Value)
    %
    % Description:
    %   Options selects standard or verbose runtime recording and whether a
    %   Definition should build its declared anonymous synthetic sample.
    %   Omitting Diagnostics from Definition.launch is equivalent to the
    %   default standard options. This value never exposes a runtime,
    %   recorder, figure registry, or callback transport.
    %
    % Optional Name-Value Arguments:
    %   Level - "standard" or "verbose". Standard keeps a bounded in-memory
    %       diagnostic history; verbose additionally writes structured
    %       artifacts when ArtifactFolder is nonempty. Default: "standard".
    %   ArtifactFolder - Scalar diagnostic-session folder. Empty keeps
    %       recording in memory only. Default: "".
    %   Sample - "none" or "synthetic". Synthetic requires the Definition's
    %       BuildSyntheticSample contract. Default: "none".
    %
    % Outputs:
    %   options - Immutable diagnostic configuration.
    %
    % Errors:
    %   labkit:app:contract:UnknownArgument - An option is unknown,
    %       duplicated, or unpaired.
    %   labkit:app:contract:InvalidValue - A supplied value is malformed or
    %       outside its documented legal set.
    %
    % Example:
    %   options = labkit.app.diagnostic.Options(Level="verbose");
    %   assert(options.Level == "verbose")
    %
    % See also labkit.app.Definition,
    %   labkit.app.synthetic.Context,
    %   labkit.app.synthetic.Pack

    properties (SetAccess = immutable)
        Level (1, 1) string
        ArtifactFolder (1, 1) string
        Sample (1, 1) string
    end

    methods
        function obj = Options(varargin)
            names = ["Level", "ArtifactFolder", "Sample"];
            options = labkit.app.internal.OptionParser.parse( ...
                "labkit.app.diagnostic.Options", names, varargin{:});
            obj.Level = oneOf(optionValue( ...
                options, "Level", "standard"), ...
                ["standard", "verbose"], "Level");
            obj.ArtifactFolder = scalarText(optionValue( ...
                options, "ArtifactFolder", ""), "ArtifactFolder");
            obj.Sample = oneOf(optionValue( ...
                options, "Sample", "none"), ...
                ["none", "synthetic"], "Sample");
        end
    end
end

function value = oneOf(value, legal, name)
value = scalarText(value, name);
if ~any(value == legal)
    error("labkit:app:contract:InvalidValue", ...
        "Diagnostic Options %s must be %s.", ...
        name, strjoin(legal, " or "));
end
end

function value = scalarText(value, name)
if ~(ischar(value) || (isstring(value) && isscalar(value)))
    error("labkit:app:contract:InvalidValue", ...
        "Diagnostic Options %s must be scalar text.", name);
end
value = string(value);
end

function value = optionValue(options, name, defaultValue)
value = defaultValue;
if isfield(options, name)
    value = options.(name);
end
end
