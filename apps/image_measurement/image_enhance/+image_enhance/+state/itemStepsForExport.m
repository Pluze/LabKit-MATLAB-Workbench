% Expected caller: Image Enhance export callback. Input is app state. Output
% is empty in shared mode or a cell column of per-image histories.
function itemSteps = itemStepsForExport(S)
    itemSteps = {};
    if ~S.batchMode
        itemSteps = {S.items.steps}.';
    end
end
