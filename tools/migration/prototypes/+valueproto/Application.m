classdef (Sealed) Application
    %APPLICATION Disposable application compiler-boundary prototype.
    %   Application validates target, command, and renderer identity. compile
    %   rejects presentation capability/reference errors without a GUI.
    properties (SetAccess = immutable)
        Id (1, 1) string
        Layout
        Commands (1, :) cell
        Renderers (1, :) string
    end

    methods
        function obj = Application(id, layout, commands, renderers)
            arguments
                id (1, 1) string
                layout (1, 1) valueproto.Layout
                commands (1, :) cell = {}
                renderers (1, :) string = strings(1, 0)
            end
            if strlength(id) == 0 || ~isvarname(char(id))
                error("prototype:ui:InvalidValue", ...
                    "Application ID must be a valid MATLAB name.");
            end
            if ~all(cellfun(@(value) ...
                    isa(value, "valueproto.Command"), commands))
                error("prototype:ui:InvalidValue", ...
                    "Commands must be valueproto.Command values.");
            end
            commandIds = string(cellfun(@(value) value.Id, commands, ...
                "UniformOutput", false));
            assertUnique(commandIds, "command");
            assertUnique(renderers, "renderer");
            obj.Id = id;
            obj.Layout = layout;
            obj.Commands = commands;
            obj.Renderers = renderers;
            validateLayout(layout);
        end

        function plan = compile(obj, presentation)
            arguments
                obj (1, 1) valueproto.Application
                presentation (1, 1) valueproto.Presentation
            end
            nodes = obj.Layout.flatten();
            nodes = nodes(cellfun(@(value) ...
                ~isempty(value.Capabilities), nodes));
            ids = string(cellfun(@(value) value.Id, nodes, ...
                "UniformOutput", false));
            operations = presentation.operations();
            for k = 1:numel(operations)
                operation = operations{k};
                index = find(ids == operation.Target, 1);
                if isempty(index)
                    error("prototype:ui:UnknownReference", ...
                        "Unknown presentation target: %s", operation.Target);
                end
                if ~any(nodes{index}.Capabilities == operation.Kind)
                    error("prototype:ui:UnsupportedOperation", ...
                        "Target %s does not support %s.", ...
                        operation.Target, operation.Kind);
                end
                if operation.Kind == "plot" && ...
                        ~any(obj.Renderers == operation.Reference)
                    error("prototype:ui:UnknownReference", ...
                        "Unknown renderer: %s", operation.Reference);
                end
                if operation.Kind == "interaction"
                    commandIds = string(cellfun(@(value) value.Id, ...
                        obj.Commands, "UniformOutput", false));
                    if ~any(commandIds == operation.Value.Changed.Id)
                        error("prototype:ui:UnknownReference", ...
                            "Unknown interaction command: %s", ...
                            operation.Value.Changed.Id);
                    end
                end
            end
            plan = struct("ApplicationId", obj.Id, ...
                "TargetIds", ids, "Operations", {operations});
        end
    end
end

function validateLayout(layout)
    nodes = layout.flatten();
    ids = string(cellfun(@(value) value.Id, nodes, ...
        "UniformOutput", false));
    assertUnique(ids, "layout");
end

function assertUnique(values, label)
    values = values(strlength(values) > 0);
    if numel(unique(values)) ~= numel(values)
        error("prototype:ui:DuplicateId", ...
            "Duplicate %s ID.", label);
    end
end
