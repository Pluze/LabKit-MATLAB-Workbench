% Expected caller: Runtime V2. Input is a validated gait project with resolved
% pose source. Output owns decoded pose, current preview mode, output-folder
% convenience, duplicate-run fingerprint, and workflow log.
function session = createSession(project)
    pose = gait_analysis.sourceFiles.emptyPoseData();
    filepath = sourcePath(project.inputs.sources);
    outputFolder = "";
    if strlength(filepath) > 0
        pose = gait_analysis.sourceFiles.readPoseFile(filepath);
        outputFolder = string(labkit.ui.runtime.defaultOutputFolder( ...
            filepath, "gait_analysis", ""));
    end
    fingerprint = "";
    if project.results.analysis.ok && pose.ok
        task = gait_analysis.appState.runTask( ...
            filepath, pose, project.parameters);
        fingerprint = task.fingerprint;
    end
    session = struct( ...
        "selection", struct("currentStepIndex", 1), ...
        "workflow", struct("outputFolder", outputFolder, ...
            "logLines", strings(0, 1)), ...
        "view", struct(), ...
        "cache", struct("filepath", filepath, "pose", pose, ...
            "lastRunFingerprint", fingerprint));
end

function filepath = sourcePath(sources)
    filepath = "";
    if ~isempty(sources)
        filepath = string(sources(1).reference.originalPath);
    end
end
