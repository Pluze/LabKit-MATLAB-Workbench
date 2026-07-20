% App-owned implementation for gait_analysis.createSession within the gait_analysis product workflow.
function session = createSession(project, context)
%CREATESESSION Rebuild decoded pose and transient analysis state from project.
arguments
    project (1, 1) struct
    context (1, 1) labkit.app.CallbackContext
end
paths = strings(0, 1);
if ~isempty(project.inputs.sources)
    paths = context.resolveSourcePaths(project.inputs.sources);
end
pose = gait_analysis.sourceFiles.emptyPoseData();
filepath = "";
outputFolder = "";
if ~isempty(paths)
    filepath = paths(1);
    pose = gait_analysis.sourceFiles.readPoseFile(filepath);
    outputFolder = fullfile(fileparts(filepath), "gait_analysis");
end
fingerprint = "";
if project.results.analysis.ok && pose.ok
    task = gait_analysis.analysisRun.runTask( ...
        filepath, pose, project.parameters);
    fingerprint = task.fingerprint;
end
selection = labkit.app.event.ListSelection(Indices=1:min(1, numel(paths)));
session = struct("selection", struct("files", selection, ...
    "currentStepIndex", 1), "cache", struct("filepath", filepath, ...
    "pose", pose, "lastRunFingerprint", fingerprint), ...
    "workflow", struct("outputFolder", outputFolder));
end
