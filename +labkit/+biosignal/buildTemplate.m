function template = buildTemplate(segments, opts)
%BUILDTEMPLATE Build a representative segment template.

    if nargin < 2
        opts = struct();
    end
    validateSegments(segments);

    X = double(segments.values);
    if isempty(X)
        template = emptyTemplate(segments);
        return;
    end

    firstPass = mean(X, 2, 'omitnan');
    score = nan(size(X, 2), 1);
    for k = 1:size(X, 2)
        score(k) = localCorrelation(X(:, k), firstPass);
    end

    topN = optionValue(opts, 'topN', min(30, size(X, 2)));
    topN = max(1, min(size(X, 2), round(double(topN))));
    [~, order] = sort(score, 'descend', 'MissingPlacement', 'last');
    keep = order(1:topN);

    template = struct();
    template.type = "biosignalTemplate";
    template.values = mean(X(:, keep), 2, 'omitnan');
    template.timeOffset = segments.timeOffset;
    template.keptSegmentIndex = keep(:);
    template.score = score;
    template.metadata = struct('topN', topN, 'sourceName', string(segments.sourceName));
end

function validateSegments(segments)
    assert(isstruct(segments) && isfield(segments, 'values') && ...
        isfield(segments, 'timeOffset'), ...
        'labkit:biosignal:InvalidSegments', 'Invalid segments struct.');
end

function template = emptyTemplate(segments)
    template = struct( ...
        'type', "biosignalTemplate", ...
        'values', zeros(numel(segments.timeOffset), 0), ...
        'timeOffset', segments.timeOffset, ...
        'keptSegmentIndex', zeros(0, 1), ...
        'score', zeros(0, 1), ...
        'metadata', struct());
end

function r = localCorrelation(a, b)
    a = a(:) - mean(a, 'omitnan');
    b = b(:) - mean(b, 'omitnan');
    denom = sqrt(sum(a.^2, 'omitnan') * sum(b.^2, 'omitnan'));
    if denom <= eps
        r = NaN;
    else
        r = sum(a .* b, 'omitnan') / denom;
    end
end
