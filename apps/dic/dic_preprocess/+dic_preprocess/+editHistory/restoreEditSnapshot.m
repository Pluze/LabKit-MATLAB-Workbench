% Expected caller: DIC preprocess actions and unit tests. Inputs are the
% current runtime data and one edit snapshot; output restores its fields.

function project = restoreEditSnapshot(project, snapshot)
%RESTOREEDITSNAPSHOT Restore a DIC preprocess align/crop undo snapshot.

    project.annotations.editSteps = snapshot.editSteps;
    project.annotations.maskImage = snapshot.maskImage;
    project.annotations.maskPoints = snapshot.maskPoints;
end
