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

        function obj = rectangle(options)
            arguments
                options.Target (1, 1) string {mustBeNonempty}
                options.Bounds (1, 4) double
                options.Changed (1, 1) valueproto.Command
            end
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
