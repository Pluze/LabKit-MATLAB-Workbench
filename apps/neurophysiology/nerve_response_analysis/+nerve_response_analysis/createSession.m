% Rebuild parsed filter/protocol JSON, output-folder convenience, preview
% state, and workflow messages from one validated project.
function session = createSession(project, context)
    paths = context.resolveSourcePaths( ...
        project.inputs.sources, ["filterRecord", "protocol"]);
    filterPath = paths(1);
    protocolPath = paths(2);
    filterRecord = loadRequiredJson(filterPath);
    protocol = loadOptionalJson(protocolPath);
    outputFolder = "";
    if strlength(filterPath) > 0
        outputFolder = string(fileparts(filterPath));
    end
    status = "No filter record selected.";
    if strlength(filterPath) > 0
        status = "Filter record selected. Analyze session to continue.";
    end
    session = struct( ...
        "workflow", struct("statusMessage", status, ...
            "lastAction", "Ready", ...
            "outputFolder", outputFolder), ...
        "view", struct("previewMode", "Counts"), ...
        "cache", struct("filterPath", filterPath, ...
            "protocolPath", protocolPath, "filterRecord", filterRecord, ...
            "protocol", protocol, "analysis", []));
end

function value = loadRequiredJson(filepath)
    value = [];
    if strlength(filepath) > 0
        value = jsondecode(fileread(char(filepath)));
    end
end

function value = loadOptionalJson(filepath)
    value = struct();
    if strlength(filepath) == 0 || ~isfile(filepath)
        return;
    end
    value = jsondecode(fileread(char(filepath)));
end
