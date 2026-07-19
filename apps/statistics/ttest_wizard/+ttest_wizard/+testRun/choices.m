% App test-choice owner; returns aligned visible labels and calculation tokens.
function value = choices()
%CHOICES Return the single owner of T-Test Wizard statistical choices.
%
% Expected callers: project defaults, layout, presenter, and runTTest.
% Output labels are user-facing dropdown values; tokens are stable app-local
% calculation identifiers in matching order. Side effects are none.

    value = struct();
    value.methodLabels = [ ...
        "Independent t-test - Welch"
        "Independent t-test - equal variances"
        "Paired t-test"];
    value.methodTokens = ["welch"; "pooled"; "paired"];
    value.alternativeLabels = [ ...
        "Different (two-sided)"
        "A greater than B"
        "A less than B"];
    value.alternativeTokens = ["two_sided"; "greater"; "less"];
end
