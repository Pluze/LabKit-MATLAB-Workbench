function tf = resultsMatchGroups(results, groups, options)
%RESULTSMATCHGROUPS Compare snapshot inputs without executing statistics.
% Presenter-only identity check; comparison order does not change test meaning.
tf = numel(groups) >= 2 && numel(results) == numel(groups) - 1;
if ~tf, return; end
choices = ttest_wizard.testRun.choices();
method = canonical(options.method, choices.methodLabels, choices.methodTokens);
alternative = canonical(options.alternative, choices.alternativeLabels, choices.alternativeTokens);
for k = 1:numel(results)
    index = find(string({groups.label}) == results(k).labelB, 1);
    if isempty(index) || index == 1 || ...
            results(k).labelA ~= groups(1).label || ...
            ~isequaln(results(k).vectorA, groups(1).values(:)) || ...
            ~isequaln(results(k).vectorB, groups(index).values(:)) || ...
            results(k).method ~= method || results(k).alternative ~= alternative || ...
            results(k).alpha ~= options.alpha
        tf = false;
        return;
    end
end
end

function value = canonical(value, labels, tokens)
index = find(string(value) == labels | string(value) == tokens, 1);
if ~isempty(index), value = labels(index); end
end
