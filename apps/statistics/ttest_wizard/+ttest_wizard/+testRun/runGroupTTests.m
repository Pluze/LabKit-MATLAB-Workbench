function results = runGroupTTests(groups, options)
%RUNGROUPTTESTS Compare every group after the first with the first group.
%
% Usage:
%   results = ttest_wizard.testRun.runGroupTTests(groups, options)
%
% Description:
%   Runs one explicit t-test for each group after the first, always using the
%   first group as vector A/reference and the later group as vector B. It
%   preserves group order, copies per-comparison labels and observations into
%   canonical result snapshots, and performs no plotting or file IO.
%
% Inputs:
%   groups - Struct vector with scalar text label and numeric-vector values
%       fields. The first element is the reference group. Nonfinite values are
%       reported through the affected runTTest result.
%   options - Scalar struct with method, alternative, and alpha fields accepted
%       by runTTest. Per-comparison labels are supplied from groups.
%
% Outputs:
%   results - Column struct vector of canonical runTTest results in group
%       order. Element k compares groups(1) minus groups(k+1).
%
% Options:
%   method - Test label from testRun.choices or "welch", "pooled", or
%       "paired". No default is applied; the field is required.
%   alternative - Alternative label from testRun.choices or "two_sided",
%       "greater", or "less". Direction is reference minus comparison. No
%       default is applied; the field is required.
%   alpha - Finite numeric scalar strictly between zero and one. No default is
%       applied; the field is required.
%
% Units:
%   Every group must use the same measurement unit. Means, standard
%   deviations, differences, standard errors, and confidence bounds retain
%   that unit. Test statistics, degrees of freedom, and p-values are
%   dimensionless.
%
% Assumptions:
%   Test choice, independence, and pairing remain the caller's scientific
%   responsibility. A paired method pairs each comparison group separately
%   with the first group by displayed row order. No multiple-comparison
%   correction is applied.
%
% Failure Behavior:
%   Fewer than two groups throws ttest_wizard:InsufficientGroups. A malformed
%   group throws ttest_wizard:InvalidGroups. Individual scientific failures
%   are returned through the stable runTTest result statuses.
%
% Errors:
%   ttest_wizard:InsufficientGroups - groups has fewer than two elements.
%   ttest_wizard:InvalidGroups - A group label is not scalar text or values is
%       not a numeric vector.
%   ttest_wizard:InvalidTestOptions - options is missing method, alternative,
%       or alpha, or runTTest rejects one of their values.
%
% Example:
%   groups = struct( ...
%       "label", {"Reference", "Treatment 1", "Treatment 2"}, ...
%       "values", {[1 2 3], [2 3 4], [1 2 4]});
%   options = struct("method", "welch", ...
%       "alternative", "two_sided", "alpha", 0.05);
%   results = ttest_wizard.testRun.runGroupTTests(groups, options);
%   assert(numel(results) == 2)
%
% See also ttest_wizard.testRun.runTTest

    assert(isstruct(groups) && numel(groups) >= 2, ...
        'ttest_wizard:InsufficientGroups', ...
        'At least two groups are required.');
    assert(all(isfield(groups, {'label', 'values'})) && ...
        all(arrayfun(@validGroup, groups(:))), ...
        'ttest_wizard:InvalidGroups', ...
        'Each group requires one scalar text label and one numeric vector.');
    assert(isstruct(options) && isscalar(options) && ...
        all(isfield(options, {'method', 'alternative', 'alpha'})), ...
        'ttest_wizard:InvalidTestOptions', ...
        'Group test options are incomplete.');

    results = repmat(ttest_wizard.testRun.emptyResult(), ...
        numel(groups) - 1, 1);
    for groupIndex = 2:numel(groups)
        comparisonOptions = options;
        comparisonOptions.labelA = groups(1).label;
        comparisonOptions.labelB = groups(groupIndex).label;
        results(groupIndex - 1) = ttest_wizard.testRun.runTTest( ...
            groups(1).values, groups(groupIndex).values, ...
            comparisonOptions);
    end
end

function tf = validGroup(group)
    tf = (ischar(group.label) || ...
        (isstring(group.label) && isscalar(group.label))) && ...
        isnumeric(group.values) && ...
        (isempty(group.values) || isvector(group.values));
end
