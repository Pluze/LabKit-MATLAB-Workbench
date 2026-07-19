classdef (Sealed) Interaction
    %INTERACTION Disposable named managed-interaction value prototype.
    %   anchorPath, rectangle, and scaleReference demonstrate strict,
    %   discoverable constructors without Kind strings or Options structs.
    properties (SetAccess = immutable)
        Kind (1, 1) string
        Target (1, 1) string
        Value
        Changed
    end

    methods (Access = private)
        function obj = Interaction(kind, target, value, changed)
            obj.Kind = kind;
            obj.Target = target;
            obj.Value = value;
            obj.Changed = changed;
        end
    end

    methods (Static)
        function obj = anchorPath(options)
            arguments
                options.Target (1, 1) string {mustBeNonempty}
                options.Points (:, 2) double = zeros(0, 2)
                options.Changed (1, 1) valueproto.Command
            end
            obj = valueproto.Interaction("anchorPath", options.Target, ...
                options.Points, options.Changed);
        end

        function obj = rectangle(varargin)
            options = rectangleOptions(varargin{:});
            obj = valueproto.Interaction("rectangle", options.Target, ...
                options.Bounds, options.Changed);
        end

        function obj = scaleReference(options)
            arguments
                options.Target (1, 1) string {mustBeNonempty}
                options.Points (:, 2) double = zeros(0, 2)
                options.Changed (1, 1) valueproto.Command
            end
            obj = valueproto.Interaction("scaleReference", options.Target, ...
                options.Points, options.Changed);
        end
    end
end

function mustBeNonempty(value)
    if strlength(value) == 0
        error("prototype:ui:InvalidValue", "Target must not be empty.");
    end
end

function options = rectangleOptions(varargin)
    known = ["Target", "Bounds", "Changed"];
    if mod(numel(varargin), 2) ~= 0
        error("labkit:ui:contract:UnknownArgument", ...
            "rectangle requires named arguments.");
    end
    options = struct();
    for k = 1:2:numel(varargin)
        name = string(varargin{k});
        if ~isscalar(name) || ~any(name == known) || isfield(options, name)
            error("labkit:ui:contract:UnknownArgument", ...
                "Unknown or duplicate rectangle argument: %s", name);
        end
        options.(name) = varargin{k + 1};
    end
    if ~all(isfield(options, known))
        error("prototype:ui:InvalidValue", ...
            "rectangle requires Target, Bounds, and Changed.");
    end
    mustBeNonempty(options.Target);
    if ~isequal(size(options.Bounds), [1 4]) || ...
            ~isnumeric(options.Bounds)
        error("prototype:ui:InvalidValue", ...
            "rectangle Bounds must be a 1-by-4 numeric value.");
    end
    if ~isa(options.Changed, "valueproto.Command")
        error("prototype:ui:InvalidValue", ...
            "rectangle Changed must be a Command.");
    end
end
