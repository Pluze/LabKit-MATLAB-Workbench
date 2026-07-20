% App-owned implementation for gait_analysis.analysisRun.present within the gait_analysis product workflow.
function view = present(pose, result)
%PRESENT Describe analysis availability and current result status.
view = labkit.app.view.Snapshot() ...
    .enabled("runAnalysis", pose.ok) ...
    .value("analysisStatus", string(result.message));
end
