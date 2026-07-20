% Expected caller: DIC preprocess App SDK actions and unit tests. Input/output is the
% canonical durable project; loaded originals remain and derived work resets.

function project = resetForNewInput(project)
%RESETFORNEWINPUT Reset derived DIC preprocess state for a newly loaded image.

    project.annotations.cropRect = [];
    steps = project.annotations.editSteps;
    project.annotations.editSteps = steps([]);
    project = dic_preprocess.maskEditing.clearOperationDerivedState(project);
    history = project.annotations.history;
    project.annotations.history = history([]);
end
