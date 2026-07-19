classdef (Sealed) Package
    %RESULT Declare one App-owned result manifest request.
    %
    % Usage:
    %   result = labkit.app.result.Package(Name=Value)
    %
    % Description:
    %   Result contains validated output declarations and App-owned input,
    %   parameter, and summary data. Runtime result writing owns provenance,
    %   App and facade versions, document identity, file bytes, checksums,
    %   creation identity/time, aggregate status, and atomic replacement.
    %
    % Required Name-Value Arguments:
    %   Outputs - Nonempty row cell array of labkit.app.result.File values
    %       with unique IDs and relative paths and at least one success.
    %   Inputs - Scalar App-owned struct describing result inputs.
    %   Parameters - Scalar App-owned struct describing result parameters.
    %   Summary - Scalar App-owned struct describing result summary.
    %
    % Optional Name-Value Arguments:
    %   Warnings - Row string or cellstr array. Default: empty.
    %   ManifestName - Nonempty filename without folders. Default:
    %       "labkit_result.json".
    %
    % Outputs:
    %   result - Immutable labkit.app.result.Package value.
    %
    % Errors:
    %   labkit:app:contract:UnknownArgument - An option is missing, unknown,
    %       duplicated, or unpaired.
    %   labkit:app:contract:InvalidValue - A value or manifest name is invalid.
    %   labkit:app:contract:DuplicateId - Output IDs or paths repeat.
    %
    % Example:
    %   output = labkit.app.result.File( ...
    %       "summary", "primary", "summary.csv", MediaType="text/csv");
    %   result = labkit.app.result.Package(Outputs={output}, Inputs=struct(), ...
    %       Parameters=struct(), Summary=struct("rows", 1));
    %   assert(result.ManifestName == "labkit_result.json")
    %
    % See also labkit.app.result.File, labkit.app.CallbackContext

    properties (SetAccess = immutable)
        Outputs (1, :) cell
        Inputs (1, 1) struct
        Parameters (1, 1) struct
        Summary (1, 1) struct
        Warnings (1, :) string
        ManifestName (1, 1) string
    end

    methods
        function obj = Package(varargin)
            names = ["Outputs", "Inputs", "Parameters", "Summary", ...
                "Warnings", "ManifestName"];
            options = labkit.app.internal.OptionParser.parse( ...
                "labkit.app.result.Package", names, varargin{:});
            for name = ["Outputs", "Inputs", "Parameters", "Summary"]
                if ~isfield(options, name)
                    error("labkit:app:contract:UnknownArgument", ...
                        "labkit.app.result.Package requires argument %s.", name);
                end
            end
            obj.Outputs = outputsValue(options.Outputs);
            obj.Inputs = scalarStruct(options.Inputs, "Inputs");
            obj.Parameters = scalarStruct(options.Parameters, "Parameters");
            obj.Summary = scalarStruct(options.Summary, "Summary");
            obj.Warnings = textRow( ...
                optionValue(options, "Warnings", strings(1, 0)));
            obj.ManifestName = manifestName(optionValue( ...
                options, "ManifestName", "labkit_result.json"));
        end
    end
end

function values = outputsValue(values)
    if ~iscell(values) || isempty(values) || ~isrow(values) || ...
            ~all(cellfun(@(value) isa(value, ...
                "labkit.app.result.File"), values))
        error("labkit:app:contract:InvalidValue", ...
            "Result Outputs must be a nonempty row cell array of result File.");
    end
    ids = string(cellfun(@(value) value.Id, values, ...
        "UniformOutput", false));
    paths = string(cellfun(@(value) value.RelativePath, values, ...
        "UniformOutput", false));
    if numel(unique(ids)) ~= numel(ids)
        error("labkit:app:contract:DuplicateId", ...
            "Result output IDs must be unique.");
    end
    if numel(unique(lower(paths))) ~= numel(paths)
        error("labkit:app:contract:DuplicateId", ...
            "Result output relative paths must be unique.");
    end
    statuses = string(cellfun(@(value) value.Status, values, ...
        "UniformOutput", false));
    if ~any(statuses == "success")
        error("labkit:app:contract:InvalidValue", ...
            "Result requires at least one successful output.");
    end
end

function value = scalarStruct(value, name)
    if ~isstruct(value) || ~isscalar(value)
        error("labkit:app:contract:InvalidValue", ...
            "Result %s must be a scalar App-owned struct.", name);
    end
end

function values = textRow(values)
    if ischar(values)
        values = string(values);
    elseif iscellstr(values)
        values = string(values);
    elseif ~isstring(values)
        error("labkit:app:contract:InvalidValue", ...
            "Result Warnings must be text.");
    end
    values = reshape(values, 1, []);
end

function value = manifestName(value)
    if ~(ischar(value) || (isstring(value) && isscalar(value)))
        error("labkit:app:contract:InvalidValue", ...
            "Result ManifestName must be scalar text.");
    end
    value = string(value);
    [folder, name, extension] = fileparts(value);
    if strlength(value) == 0 || strlength(string(folder)) > 0 || ...
            strlength(string(name)) == 0 || string(extension) ~= ".json"
        error("labkit:app:contract:InvalidValue", ...
            "Result ManifestName must be a JSON filename without folders.");
    end
end

function value = optionValue(options, name, defaultValue)
    value = defaultValue;
    if isfield(options, name)
        value = options.(name);
    end
end
