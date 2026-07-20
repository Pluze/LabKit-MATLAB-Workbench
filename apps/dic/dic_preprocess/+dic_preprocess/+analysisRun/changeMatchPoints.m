% App-owned implementation for dic_preprocess.analysisRun.changeMatchPoints within the dic_preprocess product workflow.
function state = changeMatchPoints(state, endpoints, ~)
%CHANGEMATCHPOINTS Preserve ordered reference/moving pair acquisition.
if ~iscell(endpoints) || numel(endpoints) ~= 2
    return;
end
referencePoints = double(endpoints{1});
movingPoints = double(endpoints{2});
referenceCount = size(referencePoints, 1);
movingCount = size(movingPoints, 1);
if movingCount > referenceCount || referenceCount > movingCount + 1
    state.session.workflow.details = { ...
        'Select each reference feature before its moving-image match.'};
    return;
end
state.project.annotations.matchReferencePoints = referencePoints;
state.project.annotations.matchMovingPoints = movingPoints;
if referenceCount > movingCount
    next = 'Now select the matching feature in the moving image.';
else
    next = 'Select the next feature in the reference image.';
end
state.session.workflow.details = {sprintf( ...
    'Complete point pairs: %d. %s', movingCount, next)};
end
