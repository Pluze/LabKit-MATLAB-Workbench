function value = application(id, targets, commands, renderers)
    arguments
        id (1, 1) string
        targets (1, :) cell
        commands (1, :) cell = {}
        renderers (1, :) string = strings(1, 0)
    end
    if strlength(id) == 0 || ~isvarname(char(id))
        error("prototype:ui:InvalidValue", ...
            "Application ID must be a valid MATLAB name.");
    end
    targetValues = cellfun(@(item) readToken(item, "target"), targets, ...
        "UniformOutput", false);
    commandValues = cellfun(@(item) readToken(item, "command"), commands, ...
        "UniformOutput", false);
    targetIds = string(cellfun(@(item) item.Payload.Id, targetValues, ...
        "UniformOutput", false));
    commandIds = string(cellfun(@(item) item.Payload.Id, commandValues, ...
        "UniformOutput", false));
    assertUnique(targetIds, "target");
    assertUnique(commandIds, "command");
    assertUnique(renderers, "renderer");
    payload = struct("Id", id, "Targets", {targets}, ...
        "Commands", {commands}, "Renderers", renderers);
    value = makeToken("application", payload);
end

function assertUnique(values, label)
    if numel(unique(values)) ~= numel(values)
        error("prototype:ui:DuplicateId", "Duplicate %s ID.", label);
    end
end
