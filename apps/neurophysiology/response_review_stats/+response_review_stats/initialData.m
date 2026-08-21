function project = initialData()
%INITIALDATA Create the App-owned initial in-memory data.
project = createProject();
end

function project = createProject()
    project = struct();
    project.inputs = struct("sources", ...
        struct([]));
    project.parameters = struct( ...
        "baselineWindowSec", [0.007 0.009], ...
        "noiseWindowSec", [0.007 0.009]);
    project.results = struct("lastExport", []);
end
