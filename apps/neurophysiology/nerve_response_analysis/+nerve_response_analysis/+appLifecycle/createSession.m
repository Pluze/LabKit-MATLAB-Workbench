% Expected caller: Runtime V2. Input is a validated Nerve Response Analysis
% project with resolved sources. Output owns parsed JSON, analysis, preview
% mode, output-folder convenience, and workflow messages.
function session = createSession(project)
    filterPath = sourcePath(project.inputs.filterSource);
    protocolPath = sourcePath(project.inputs.protocolSource);
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
        "selection", struct(), ...
        "workflow", struct("statusMessage", status, ...
            "lastAction", "Ready", "logLines", strings(0, 1), ...
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

function filepath = sourcePath(sources)
    filepath = "";
    if ~isempty(sources)
        filepath = string(sources(1).reference.originalPath);
    end
end
