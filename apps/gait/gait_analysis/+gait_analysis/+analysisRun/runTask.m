%RUNTASK Deterministic snapshot for duplicate gait analysis runs.
% Expected caller: run-analysis action and session reconstruction. The
% fingerprint includes semantic inputs only, never UI handles.
function task = runTask(sourcePath, pose, opts)
    task = struct();
    task.sourcePath = string(sourcePath);
    task.frameCount = size(pose.coords, 1);
    task.pointNames = string(pose.pointNames(:));
    task.options = opts;
    task.fingerprint = string(jsonencode(struct( ...
        "sourcePath", task.sourcePath, ...
        "frameCount", task.frameCount, ...
        "pointNames", task.pointNames, ...
        "options", opts)));
end
