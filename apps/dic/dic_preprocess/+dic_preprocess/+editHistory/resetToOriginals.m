% Expected caller: DIC preprocess App SDK actions and unit tests. Input/output is the
% current runtime data with current images restored from originals.

function project = resetToOriginals(project)
%RESETTOORIGINALS Restore the DIC preprocess current pair to loaded originals.

    project.annotations.cropRect = [];
    steps = project.annotations.editSteps;
    project.annotations.editSteps = steps([]);
    project = dic_preprocess.maskEditing.clearOperationDerivedState(project);
end
