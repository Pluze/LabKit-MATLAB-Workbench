function project = initialData()
%INITIALDATA Create the App-owned initial in-memory data.
project = createProject();
end

function project = createProject()
    project = struct();
    project.inputs = struct( ...
        "sources", struct([]));
    project.parameters = struct( ...
        "maxRecordings", 0, ...
        "maxDurationSec", 0);
    project.annotations = struct();
    project.results = struct("lastExport", []);
    project.extensions = struct();
end


