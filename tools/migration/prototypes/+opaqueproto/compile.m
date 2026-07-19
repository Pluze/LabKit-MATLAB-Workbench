function plan = compile(application, presentation)
    app = readToken(application, "application").Payload;
    view = readToken(presentation, "presentation").Payload;
    targets = cellfun(@(item) readToken(item, "target"), app.Targets, ...
        "UniformOutput", false);
    ids = string(cellfun(@(item) item.Payload.Id, targets, ...
        "UniformOutput", false));
    commandValues = cellfun(@(item) readToken(item, "command"), ...
        app.Commands, "UniformOutput", false);
    commandIds = string(cellfun(@(item) item.Payload.Id, commandValues, ...
        "UniformOutput", false));
    for k = 1:numel(view.Operations)
        operation = view.Operations{k};
        index = find(ids == operation.Target, 1);
        if isempty(index)
            error("prototype:ui:UnknownReference", ...
                "Unknown presentation target: %s", operation.Target);
        end
        if ~any(targets{index}.Payload.Capabilities == operation.Kind)
            error("prototype:ui:UnsupportedOperation", ...
                "Target %s does not support %s.", ...
                operation.Target, operation.Kind);
        end
        if operation.Kind == "plot" && ...
                ~any(app.Renderers == operation.Reference)
            error("prototype:ui:UnknownReference", ...
                "Unknown renderer: %s", operation.Reference);
        end
        if operation.Kind == "interaction"
            interaction = readToken(operation.Value, "interaction").Payload;
            command = readToken(interaction.Changed, "command").Payload;
            if ~any(commandIds == command.Id)
                error("prototype:ui:UnknownReference", ...
                    "Unknown interaction command: %s", command.Id);
            end
        end
    end
    plan = struct("ApplicationId", app.Id, ...
        "TargetIds", ids, "Operations", {view.Operations}, ...
        "Capabilities", app.Capabilities);
end
