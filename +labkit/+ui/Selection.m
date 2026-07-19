classdef (Sealed) Selection
    %SELECTION Describe stable selected item identities and indices.
    %
    % Usage:
    %   selection = labkit.ui.Selection(Name=Value)
    %
    % Description:
    %   Selection carries stable item IDs, positive display indices, or both.
    %   When both are supplied they have equal lengths and matching order.
    %
    % Optional Name-Value Arguments:
    %   Ids - Unique row string or cellstr array. Default: empty.
    %   Indices - Unique positive integer numeric row. Default: empty.
    %
    % Outputs:
    %   selection - Immutable labkit.ui.Selection value.
    %
    % Errors:
    %   labkit:ui:contract:UnknownArgument - An option is unknown, duplicated,
    %       or unpaired.
    %   labkit:ui:contract:InvalidValue - IDs or indices are malformed or have
    %       inconsistent lengths.
    %
    % Example:
    %   selection = labkit.ui.Selection( ...
    %       Ids=["sample-a", "sample-b"], Indices=[1 3]);
    %   assert(isequal(selection.Indices, [1 3]))
    %
    % See also labkit.ui.TableEdit, labkit.ui.Command

    properties (SetAccess = immutable)
        Ids (1, :) string
        Indices (1, :) double
    end

    methods
        function obj = Selection(varargin)
            options = parseContractOptions( ...
                "labkit.ui.Selection", ["Ids", "Indices"], varargin{:});
            obj.Ids = ids(optionValue(options, "Ids", strings(1, 0)));
            obj.Indices = indices( ...
                optionValue(options, "Indices", zeros(1, 0)));
            if ~isempty(obj.Ids) && ~isempty(obj.Indices) && ...
                    numel(obj.Ids) ~= numel(obj.Indices)
                error("labkit:ui:contract:InvalidValue", ...
                    "Selection Ids and Indices must have equal lengths.");
            end
        end
    end
end

function values = ids(values)
    if ischar(values)
        values = string(values);
    elseif iscellstr(values)
        values = string(values);
    elseif ~isstring(values)
        error("labkit:ui:contract:InvalidValue", ...
            "Selection Ids must be text.");
    end
    values = reshape(values, 1, []);
    if any(strlength(values) == 0) || numel(unique(values)) ~= numel(values)
        error("labkit:ui:contract:InvalidValue", ...
            "Selection Ids must be unique nonempty text.");
    end
end

function values = indices(values)
    if ~(isnumeric(values) && (isempty(values) || isrow(values)) && ...
            all(isfinite(values)) && all(values >= 1) && ...
            all(values == fix(values)) && numel(unique(values)) == numel(values))
        error("labkit:ui:contract:InvalidValue", ...
            "Selection Indices must be unique positive integers.");
    end
    values = double(reshape(values, 1, []));
end

function value = optionValue(options, name, defaultValue)
    value = defaultValue;
    if isfield(options, name)
        value = options.(name);
    end
end
