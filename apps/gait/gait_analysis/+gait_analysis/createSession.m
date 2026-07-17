% Rebuild transient decoded pose, preview selection, export-folder
% convenience, and duplicate-run fingerprint from one validated project.
function session = createSession(project)
    pose = gait_analysis.sourceFiles.emptyPoseData();
    filepath = labkit.ui.runtime.sourcePaths( ...
        project.inputs.sources, "pose");
    outputFolder = "";
    if strlength(filepath) > 0
        pose = gait_analysis.sourceFiles.readPoseFile(filepath);
        outputFolder = string(labkit.ui.runtime.defaultOutputFolder( ...
            filepath, "gait_analysis", ""));
    end
    fingerprint = "";
    if project.results.analysis.ok && pose.ok
        task = gait_analysis.analysisRun.runTask( ...
            filepath, pose, project.parameters);
        fingerprint = task.fingerprint;
    end
    session = struct( ...
        "selection", struct("currentStepIndex", 1), ...
        "workflow", struct("outputFolder", outputFolder), ...
        "cache", struct("filepath", filepath, "pose", pose, ...
            "lastRunFingerprint", fingerprint));
end
