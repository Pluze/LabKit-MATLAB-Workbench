% Expected caller: DIC preprocess V2 actions and unit tests. Input/output is the
% canonical durable project with current images restored from originals.

function project = resetToOriginals(project)
%RESETTOORIGINALS Restore the DIC preprocess current pair to loaded originals.

    project.annotations.cropRect = [];
    steps = project.annotations.editSteps;
    project.annotations.editSteps = steps([]);
    project = dic_preprocess.appState.clearOperationDerivedState(project);
end
