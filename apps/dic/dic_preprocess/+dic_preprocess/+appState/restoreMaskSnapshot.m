% Expected caller: DIC preprocess V2 actions and unit tests. Inputs are the
% canonical durable project and one mask snapshot; output restores annotations.

function project = restoreMaskSnapshot(project, snapshot)
%RESTOREMASKSNAPSHOT Restore a DIC preprocess mask-edit undo snapshot.

    project.annotations.maskImage = snapshot.maskImage;
    project.annotations.maskPoints = snapshot.maskPoints;
end
