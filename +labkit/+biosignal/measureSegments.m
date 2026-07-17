function result = measureSegments(segments, template, opts)
%MEASURESEGMENTS Measure generic template-residual segment quality.
%
% Usage:
%   result = labkit.biosignal.measureSegments(segments, template)
%   result = labkit.biosignal.measureSegments(segments, template, opts)
%
% Description:
%   Measures each segment against a representative template. SignalP2P is
%   the peak-to-peak amplitude inside the signal window. NoiseRMS is the root
%   mean square of segment minus template inside the selected noise windows.
%   SNRdB is 20*log10(SignalP2P/NoiseRMS), and TemplateCorrelation is the
%   mean-centered correlation between the complete segment and template.
%
%   The function also summarizes the per-segment measurements with means and
%   sample standard deviations. If either the segment matrix or template is
%   empty, both returned tables and metadata are empty.
%
% Inputs:
%   segments - Segment structure returned by
%              labkit.biosignal.segmentByEvents. Its values matrix must have
%              the same number of rows as template.values.
%   template - Template structure returned by
%              labkit.biosignal.buildTemplate.
%   opts - Optional scalar struct containing the fields listed below.
%
% Options:
%   signalWindowSec - Two-element interval used for SignalP2P. The default
%                     is [-0.06 0.06] seconds relative to the event. The
%                     interval must include at least one timeOffset sample.
%   noiseWindowsSec - N-by-2 matrix of intervals used for NoiseRMS. The
%                     default is [-0.30 -0.20; 0.40 0.50] seconds. Their
%                     union must include at least one timeOffset sample.
%
% Outputs:
%   result - Structure containing per-segment measurements, aggregate
%            statistics, and the windows used in the calculation.
%
% Output Fields:
%   type - String scalar "biosignalSegmentMeasurements".
%   perSegment - Table with Segment, EventIndex, EventTime, SignalP2P,
%                NoiseRMS, SNRdB, and TemplateCorrelation columns.
%   summary - One-row table with SegmentCount and the mean and standard
%             deviation of SignalP2P, NoiseRMS, and SNRdB, plus the mean
%             TemplateCorrelation.
%   metadata.signalWindowSec - Signal interval used for the calculation.
%   metadata.noiseWindowsSec - Noise intervals used for the calculation.
%
% Errors:
%   labkit:biosignal:InvalidSegments - segments lacks values or timeOffset.
%   labkit:biosignal:InvalidTemplate - template lacks values.
%
% Example:
%   segments = struct('values', [0 0; 2 1.8; 0 0], ...
%       'timeOffset', [-0.1; 0; 0.1], 'eventIndex', [10; 20], ...
%       'eventTime', [1; 2]);
%   template = struct('values', [0; 1.9; 0]);
%   opts = struct('signalWindowSec', [-0.05 0.05], ...
%       'noiseWindowsSec', [-0.1 -0.05; 0.05 0.1]);
%   result = labkit.biosignal.measureSegments(segments, template, opts);
%
% See also labkit.biosignal.buildTemplate,
%   labkit.biosignal.segmentByEvents

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
