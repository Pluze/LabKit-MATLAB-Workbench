% Expected callers: DIC preprocess V2 actions and unit tests. Input is the
% canonical durable project, description, and optional undo limit. Output
% appends a project-owned mask snapshot.

function project = appendMaskHistory(project, description, maxUndoSteps)
%APPENDMASKHISTORY Append a DIC preprocess mask edit undo snapshot.

    if nargin < 3
        maxUndoSteps = 20;
    end
    annotations = project.annotations;
    snapshot = struct( ...
        'maskImage', annotations.maskImage, ...
        'maskPoints', annotations.maskPoints, ...
        'description', description);
    history = annotations.maskHistory;
    history(end+1) = snapshot;
    if numel(history) > maxUndoSteps
        history = history((end - maxUndoSteps + 1):end);
    end
    project.annotations.maskHistory = history;
end
