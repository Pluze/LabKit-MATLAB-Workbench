%CREATEINITIALSTATE Initial semantic state for labkit_GaitAnalysis_app.
% Expected caller: LabKit runtime, reset actions, and tests. Output contains
% no UI handles and can be serialized for debugging.
function state = createInitialState()
    state = struct();
    state.sourcePath = "";
    state.sourceSummary = "No pose file loaded";
    state.outputFolder = "";
    state.pose = gait_analysis.sourceFiles.emptyPoseData();
    state.options = gait_analysis.appState.defaultOptions();
    state.result = gait_analysis.appState.emptyResult();
    state.previewMode = "Trajectory";
    state.lastRunFingerprint = "";
end
