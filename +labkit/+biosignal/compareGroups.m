function result = compareGroups(values, groups)
%COMPAREGROUPS Summarize groups and compute pairwise Welch comparisons.
%
% Usage:
%   result = labkit.biosignal.compareGroups(values, groups)
%
% Description:
%   Calculates descriptive statistics for each group and a two-sided Welch
%   t-test for every pair of groups. Welch's test does not assume equal
%   variances. Group order follows the first occurrence of each label in
%   groups.
%
%   Rows with a nonfinite measurement or a blank group label are discarded
%   before calculation. A pairwise row is still returned when either group
%   has fewer than two observations or the estimated standard error is zero;
%   its test statistic, degrees of freedom, and p-value are NaN.
%
% Inputs:
%   values - Numeric vector of measurements.
%   groups - Vector of labels accepted by string, such as a string array,
%            cell array of character vectors, or categorical array. It must
%            contain one label for each element of values.
%
% Outputs:
%   result - Structure with summary and pairwise tables.
%
% Output Fields:
%   summary - One row per group. Columns are Group, N, Mean, Std, Median,
%             Min, and Max.
%   pairwise - One row per unique group pair. Columns are GroupA, GroupB,
%              MeanDifference, T, DF, and P. MeanDifference is mean(GroupA)
%              minus mean(GroupB); P is the two-sided Welch-test p-value.
%
% Example:
%   values = [4.8 5.1 5.0 6.2 6.0 6.4];
%   groups = ["control" "control" "control" "treated" "treated" "treated"];
%   result = labkit.biosignal.compareGroups(values, groups);

    values = double(values(:));
    groups = string(groups(:));
    keep = isfinite(values) & strlength(groups) > 0;
    values = values(keep);
    groups = groups(keep);

    labels = unique(groups, 'stable');
    n = numel(labels);

    groupName = strings(n, 1);
    count = zeros(n, 1);
    meanValue = nan(n, 1);
    stdValue = nan(n, 1);
    medianValue = nan(n, 1);
    minValue = nan(n, 1);
    maxValue = nan(n, 1);
    for k = 1:n
        v = values(groups == labels(k));
        groupName(k) = labels(k);
        count(k) = numel(v);
        meanValue(k) = mean(v, 'omitnan');
        stdValue(k) = std(v, 0, 'omitnan');
        medianValue(k) = median(v, 'omitnan');
        minValue(k) = min(v);
        maxValue(k) = max(v);
    end
    summary = table(groupName, count, meanValue, stdValue, medianValue, ...
        minValue, maxValue, ...
        'VariableNames', {'Group','N','Mean','Std','Median','Min','Max'});

    pairCount = n * (n - 1) / 2;
    groupA = strings(pairCount, 1);
    groupB = strings(pairCount, 1);
    tStatistic = zeros(pairCount, 1);
    degreesFreedom = zeros(pairCount, 1);
    pValue = zeros(pairCount, 1);
    meanDifference = zeros(pairCount, 1);
    pairIndex = 0;
    for i = 1:n
        for j = i+1:n
            a = values(groups == labels(i));
            b = values(groups == labels(j));
            stats = welchComparison(a, b);
            pairIndex = pairIndex + 1;
            groupA(pairIndex) = labels(i);
            groupB(pairIndex) = labels(j);
            tStatistic(pairIndex) = stats.t;
            degreesFreedom(pairIndex) = stats.df;
            pValue(pairIndex) = stats.p;
            meanDifference(pairIndex) = stats.meanDiff;
        end
    end
    pairwise = table(groupA, groupB, meanDifference, tStatistic, ...
        degreesFreedom, pValue, ...
        'VariableNames', {'GroupA','GroupB','MeanDifference','T','DF','P'});

    result = struct('summary', summary, 'pairwise', pairwise);
end

function stats = welchComparison(a, b)
    a = a(isfinite(a));
    b = b(isfinite(b));
    stats = struct('t', NaN, 'df', NaN, 'p', NaN, 'meanDiff', NaN);
    if numel(a) < 2 || numel(b) < 2
        return;
    end

    ma = mean(a);
    mb = mean(b);
    va = var(a);
    vb = var(b);
    na = numel(a);
    nb = numel(b);
    se2 = va / na + vb / nb;
    if se2 <= 0
        return;
    end

    t = (ma - mb) / sqrt(se2);
    df = se2^2 / ((va / na)^2 / max(na - 1, 1) + (vb / nb)^2 / max(nb - 1, 1));
    p = 2 * studentTCdf(-abs(t), df);

    stats.t = t;
    stats.df = df;
    stats.p = p;
    stats.meanDiff = ma - mb;
end

function p = studentTCdf(t, v)
    if ~isfinite(t) || ~isfinite(v) || v <= 0
        p = NaN;
        return;
    end
    x = v / (v + t^2);
    ib = betainc(x, v / 2, 0.5);
    if t >= 0
        p = 1 - 0.5 * ib;
    else
        p = 0.5 * ib;
    end
end
