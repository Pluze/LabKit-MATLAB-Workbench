% App-owned implementation for cic.analysisRun.recomputeLoaded within the cic product workflow.
function items = recomputeLoaded(items, parameters)
%RECOMPUTELOADED Reanalyze explicit loaded CIC items with shared parameters.
options = cic.analysisRun.optionsFromParameters(parameters);
items = cic.analysisRun.recomputeItems(items, options);
end
