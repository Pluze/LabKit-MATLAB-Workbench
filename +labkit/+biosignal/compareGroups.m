function result = compareGroups(values, groups)
%COMPAREGROUPS Summarize groups and compute pairwise Welch comparisons.
%
% Usage:
%   result = labkit.biosignal.compareGroups(values, groups);
%
% Inputs:
%   values - numeric vector of measurements.
%   groups - string/cellstr/categorical-compatible vector of group labels.
%
% Output:
%   result - struct with summary table and pairwise Welch-comparison table.
%            Missing values and blank group labels are ignored.

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

    groupA = strings(0, 1);
    groupB = strings(0, 1);
    tStatistic = zeros(0, 1);
    degreesFreedom = zeros(0, 1);
    pValue = zeros(0, 1);
    meanDifference = zeros(0, 1);
    for i = 1:n
        for j = i+1:n
            a = values(groups == labels(i));
            b = values(groups == labels(j));
            stats = welchComparison(a, b);
            groupA(end+1, 1) = labels(i); %#ok<AGROW>
            groupB(end+1, 1) = labels(j); %#ok<AGROW>
            tStatistic(end+1, 1) = stats.t; %#ok<AGROW>
            degreesFreedom(end+1, 1) = stats.df; %#ok<AGROW>
            pValue(end+1, 1) = stats.p; %#ok<AGROW>
            meanDifference(end+1, 1) = stats.meanDiff; %#ok<AGROW>
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
