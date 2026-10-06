function project = initialData()
%INITIALDATA Create the App-owned initial in-memory data.
    project = struct();
    project.inputs = struct("sources", struct([]));
    project.parameters = gait_analysis.analysisRun.defaultOptions();
    project.results = struct( ...
        "analysis", gait_analysis.analysisRun.emptyResult());
end
