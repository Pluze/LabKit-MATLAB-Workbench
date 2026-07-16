% Expected callers: DIC preprocess V2 actions and unit tests. Input is the
% canonical durable project, an edit description, and optional undo limit.
% Output appends a project-owned image/mask snapshot without flattening state.

function [project, appended] = appendEditHistory(project, description, maxUndoSteps)
%APPENDEDITHISTORY Append a DIC preprocess align/crop undo snapshot.

    if nargin < 3
        maxUndoSteps = 12;
    end
    annotations = project.annotations;
    snapshot = struct( ...
        'editSteps', annotations.editSteps, ...
        'maskImage', annotations.maskImage, ...
        'maskPoints', annotations.maskPoints, ...
        'description', description);
    history = annotations.history;
    history(end+1) = snapshot;
    if numel(history) > maxUndoSteps
        history = history((end - maxUndoSteps + 1):end);
    end
    project.annotations.history = history;
    appended = true;
end
