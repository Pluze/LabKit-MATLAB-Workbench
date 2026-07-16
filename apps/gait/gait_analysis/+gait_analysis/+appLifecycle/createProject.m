% Expected caller: gait_analysis.definition. Output is a durable version-2
% pose source, reproducible analysis parameters/result, and export record.
function project = createProject()
    project = struct();
    project.inputs = struct("source", ...
        labkit.ui.runtime.emptySourceRecords());
    project.parameters = gait_analysis.appState.defaultOptions();
    project.annotations = struct();
    project.results = struct( ...
        "analysis", gait_analysis.appState.emptyResult(), ...
        "lastExport", []);
    project.extensions = struct();
end
