% App-owned implementation for ttest_wizard.testRun.runComparisons within the ttest_wizard product workflow.
function state = runComparisons(state, context)
%RUNCOMPARISONS Compute every first-group comparison from current settings.
%
% Expected caller: runComparisons button. Scientific calculation remains in
% runGroupTTests; this boundary callback stores the immutable result family
% and reports partial failures.

arguments
    state (1, 1) struct
    context (1, 1) labkit.app.CallbackContext
end

groups = state.project.inputs.groups;
if numel(groups) < 2
    context.alert( ...
        "Enter at least two groups before running comparisons.", ...
        "T-tests");
    return;
end
options = struct( ...
    "method", state.project.parameters.testMethod, ...
    "alternative", state.project.parameters.alternative, ...
    "alpha", state.project.parameters.alpha);
results = ttest_wizard.testRun.runGroupTTests(groups, options);
state.project.results.current = results;
state.project.results.lastResultExport = "";
okCount = sum([results.ok]);
context.appendStatus(sprintf( ...
    'Completed %d of %d comparison(s) against %s.', ...
    okCount, numel(results), groups(1).label));
if okCount < numel(results)
    failed = results(~[results.ok]);
    context.alert(strjoin(unique([failed.message]), newline), ...
        "Some t-tests were not completed");
end
end
