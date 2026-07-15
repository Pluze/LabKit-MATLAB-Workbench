% Expected caller: nerve_response_analysis.definition. Output is the durable
% version-1 project: portable filter/protocol sources, reproducible analysis
% parameters, and export records without parsed JSON or analysis tables.
function project = createProject()
    project = struct();
    project.inputs = struct( ...
        "filterSource", emptySources(), ...
        "protocolSource", emptySources());
    project.parameters = struct( ...
        "maxRecordings", 0, ...
        "maxDurationSec", 0);
    project.annotations = struct();
    project.results = struct("lastExport", []);
    project.extensions = struct();
end

function sources = emptySources()
    sources = struct("id", {}, "required", {}, "role", {}, ...
        "reference", {});
end
