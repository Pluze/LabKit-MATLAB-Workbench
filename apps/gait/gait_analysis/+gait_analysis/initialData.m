function project = initialData()
%INITIALDATA Create the App-owned initial in-memory data.
project = createProject();
end

function project = createProject()
    project = struct();
    project.inputs = struct("sources", struct([]));
    project.parameters = gait_analysis.analysisRun.defaultOptions();
    project.results = struct( ...
        "analysis", gait_analysis.analysisRun.emptyResult(), ...
        "lastExport", []);
end
