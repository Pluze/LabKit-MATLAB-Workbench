% Rebuild parsed filter/protocol JSON, output-folder convenience, preview
% state, and workflow messages from one validated project.
function session = createSession(project)
    paths = labkit.ui.runtime.sourcePaths( ...
        project.inputs.sources, ["filterRecord", "protocol"]);
    filterPath = paths(1);
    protocolPath = paths(2);
    filterRecord = loadRequiredJson(filterPath);
    protocol = loadOptionalJson(protocolPath);
    outputFolder = "";
    if strlength(filterPath) > 0
        outputFolder = string(labkit.ui.runtime.defaultOutputFolder( ...
            filterPath, "nerve_response_analysis", ""));
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
    if strlength(filepath) == 0
        return;
    end
    try
        value = jsondecode(fileread(char(filepath)));
    catch
        value = struct();
    end
end
