% Expected caller: T-Test Wizard presenter. Inputs are a canonical result
% vector, the current ordered group vector, and current method/alternative/
% alpha options. Output is one logical scalar indicating snapshot identity.
% The function recalculates a probe family but has no external side effects.
function tf = resultsMatchGroups(results, groups, options)
%RESULTSMATCHGROUPS Test whether a result family matches current group inputs.

    tf = isstruct(results) && numel(results) == max(0, numel(groups) - 1) && ...
        numel(groups) >= 2;
    if ~tf
        return;
    end
    probe = ttest_wizard.testRun.runGroupTTests(groups, options);
    identityFields = {'method', 'alternative', 'alpha', ...
        'labelA', 'labelB', 'vectorA', 'vectorB'};
    for resultIndex = 1:numel(results)
        for fieldIndex = 1:numel(identityFields)
            field = identityFields{fieldIndex};
            if ~isequaln(results(resultIndex).(field), ...
                    probe(resultIndex).(field))
                tf = false;
                return;
            end
        end
    end
end
