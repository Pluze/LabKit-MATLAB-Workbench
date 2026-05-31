function result = measureSegments(segments, template, opts)
%MEASURESEGMENTS Measure generic template-residual segment quality.

    if nargin < 3
        opts = struct();
    end
    validateInputs(segments, template);

    X = double(segments.values);
    tpl = double(template.values(:));
    if isempty(X) || isempty(tpl)
        result = emptyResult();
        return;
    end

    t = double(segments.timeOffset(:));
    signalWindowSec = double(optionValue(opts, 'signalWindowSec', [-0.06 0.06]));
    noiseWindowsSec = double(optionValue(opts, 'noiseWindowsSec', [-0.30 -0.20; 0.40 0.50]));

    signalIdx = t >= signalWindowSec(1) & t <= signalWindowSec(2);
    noiseIdx = false(size(t));
    for k = 1:size(noiseWindowsSec, 1)
        noiseIdx = noiseIdx | (t >= noiseWindowsSec(k, 1) & t <= noiseWindowsSec(k, 2));
    end

    signalP2P = nan(size(X, 2), 1);
    noiseRMS = nan(size(X, 2), 1);
    snrDB = nan(size(X, 2), 1);
    similarity = nan(size(X, 2), 1);
    for k = 1:size(X, 2)
        seg = X(:, k);
        resid = seg - tpl;
        signalP2P(k) = max(seg(signalIdx)) - min(seg(signalIdx));
        noiseRMS(k) = sqrt(mean(resid(noiseIdx).^2, 'omitnan'));
        if signalP2P(k) > 0 && noiseRMS(k) > 0
            snrDB(k) = 20 * log10(signalP2P(k) / noiseRMS(k));
        end
        similarity(k) = localCorrelation(seg, tpl);
    end

    perSegment = table((1:size(X, 2)).', segments.eventIndex(:), ...
        segments.eventTime(:), signalP2P, noiseRMS, snrDB, similarity, ...
        'VariableNames', {'Segment','EventIndex','EventTime','SignalP2P','NoiseRMS','SNRdB','TemplateCorrelation'});

    summary = table( ...
        size(X, 2), ...
        mean(signalP2P, 'omitnan'), std(signalP2P, 0, 'omitnan'), ...
        mean(noiseRMS, 'omitnan'), std(noiseRMS, 0, 'omitnan'), ...
        mean(snrDB, 'omitnan'), std(snrDB, 0, 'omitnan'), ...
        mean(similarity, 'omitnan'), ...
        'VariableNames', {'SegmentCount', 'SignalP2PMean', 'SignalP2PStd', ...
        'NoiseRMSMean', 'NoiseRMSStd', 'SNRdBMean', 'SNRdBStd', ...
        'TemplateCorrelationMean'});

    result = struct();
    result.type = "biosignalSegmentMeasurements";
    result.perSegment = perSegment;
    result.summary = summary;
    result.metadata = struct( ...
        'signalWindowSec', signalWindowSec, ...
        'noiseWindowsSec', noiseWindowsSec);
end

function validateInputs(segments, template)
    assert(isstruct(segments) && isfield(segments, 'values') && ...
        isfield(segments, 'timeOffset'), ...
        'labkit:biosignal:InvalidSegments', 'Invalid segments struct.');
    assert(isstruct(template) && isfield(template, 'values'), ...
        'labkit:biosignal:InvalidTemplate', 'Invalid template struct.');
end

function result = emptyResult()
    result = struct();
    result.type = "biosignalSegmentMeasurements";
    result.perSegment = table();
    result.summary = table();
    result.metadata = struct();
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
