% Expected caller: response_review_stats.definition. Output is a durable
% version-2 source/parameter/result project without metric or aligned caches.
function project = createProject()
    project = struct();
    project.inputs = struct("sources", ...
        labkit.ui.runtime.emptySourceRecords());
    project.parameters = struct( ...
        "baselineWindowSec", [0.007 0.009], ...
        "noiseWindowSec", [0.007 0.009]);
    project.annotations = struct();
    project.results = struct("lastExport", []);
    project.extensions = struct();
end
