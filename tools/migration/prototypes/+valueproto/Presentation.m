classdef (Sealed) Presentation
    %PRESENTATION Disposable closed presentation-operation prototype.
    %   value, choices, enabled, table, plot, and interaction return a new
    %   presentation value. No generic property setter is available.
    properties (Access = private)
        Operations (1, :) cell = {}
    end

    methods
        function obj = value(obj, target, value)
            obj = append(obj, "value", target, value, "");
        end

        function obj = choices(obj, target, value)
            obj = append(obj, "choices", target, value, "");
        end

        function obj = enabled(obj, target, value)
            arguments
                obj (1, 1) valueproto.Presentation
                target (1, 1) string
                value (1, 1) logical
            end
            obj = append(obj, "enabled", target, value, "");
        end

        function obj = table(obj, target, model)
            obj = append(obj, "table", target, model, "");
        end

        function obj = plot(obj, target, renderer, model)
            arguments
                obj (1, 1) valueproto.Presentation
                target (1, 1) string
                renderer (1, 1) string
                model
            end
            obj = append(obj, "plot", target, model, renderer);
        end

        function obj = interaction(obj, value)
            arguments
                obj (1, 1) valueproto.Presentation
                value (1, 1) valueproto.Interaction
            end
            obj = append(obj, "interaction", value.Target, value, "");
        end

        function values = operations(obj)
            values = obj.Operations;
        end
    end

    methods (Access = private)
        function obj = append(obj, kind, target, value, reference)
            arguments
                obj (1, 1) valueproto.Presentation
                kind (1, 1) string
                target (1, 1) string
                value
                reference (1, 1) string
            end
            if strlength(target) == 0
                error("prototype:ui:InvalidValue", ...
                    "Presentation target must not be empty.");
            end
            obj.Operations{end + 1} = struct( ...
                "Kind", kind, "Target", target, "Value", value, ...
                "Reference", reference);
        end
    end
end
