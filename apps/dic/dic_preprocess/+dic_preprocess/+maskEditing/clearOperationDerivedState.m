% Expected caller: DIC preprocess actions and unit tests. Input/output is the
% current runtime data; mask annotations invalidated by pair edits clear.

function project = clearOperationDerivedState(project)
%CLEAROPERATIONDERIVEDSTATE Clear DIC preprocess state derived from the pair.

    project.annotations.maskImage = [];
    project.annotations.maskPoints = zeros(0, 2);
    history = project.annotations.maskHistory;
    project.annotations.maskHistory = history([]);
end
