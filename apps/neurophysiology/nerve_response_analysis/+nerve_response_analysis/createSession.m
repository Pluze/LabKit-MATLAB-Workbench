% Rebuild parsed filter/protocol JSON, output-folder convenience, preview
% state, and workflow messages from one validated project.
function session = createSession(project, context)
    filterPath = pathForRole( ...
        project.inputs.sources, "filterRecord", context);
    protocolPath = pathForRole( ...
        project.inputs.sources, "protocol", context);
    filterRecord = loadRequiredJson(filterPath);
    protocol = loadOptionalJson(protocolPath);
    outputFolder = "";
    if strlength(filterPath) > 0
        outputFolder = defaultOutputFolder(filterPath);
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

function folder = defaultOutputFolder(filepath)
    parent = string(fileparts(filepath));
    folder = string(fullfile(parent, "nerve_response_analysis"));
    if exist(folder, "dir") == 7
        return;
    end
    try
        [created, ~, ~] = mkdir(folder);
    catch
        created = false;
    end
    if ~created
        folder = parent;
    end
end

function filepath = pathForRole(sources, role, context)
    filepath = "";
    if isempty(sources)
        return;
    end
    match = find(string({sources.role}) == role, 1);
    if isempty(match)
        return;
    end
    paths = context.resolveSourcePaths(sources(match));
    if ~isempty(paths)
        filepath = paths(1);
    end
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
