function template = buildTemplate(segments, opts)
%BUILDTEMPLATE Build a representative segment template.
%
% Usage:
%   template = labkit.biosignal.buildTemplate(segments)
%   template = labkit.biosignal.buildTemplate(segments, opts)
%
% Description:
%   Forms a first-pass template by averaging every segment, then ranks each
%   segment by its correlation with that average. The returned waveform is
%   the sample-by-sample mean of the highest-ranked segments. This two-pass
%   procedure reduces the influence of beats or trials whose shape differs
%   from the majority.
%
%   Correlations are computed after subtracting each waveform's mean.
%   Missing samples are omitted from means and correlations. A constant
%   waveform has a NaN score and sorts behind finite scores. If segments
%   contains no waveforms, the function returns an empty template with the
%   same timeOffset vector.
%
% Inputs:
%   segments - Segment struct returned by labkit.biosignal.segmentByEvents.
%              segments.values is an M-by-N matrix, with one segment per
%              column; segments.timeOffset contains the M relative times.
%   opts - Optional scalar struct containing the fields listed below.
%
% Options:
%   topN - Number of ranked segments to average. The default is the smaller
%          of 30 and the number of available segments. The value is rounded
%          to an integer and limited to the range 1:N.
%
% Outputs:
%   template - Structure containing the representative waveform and the
%              ranking information used to construct it.
%
% Output Fields:
%   type - String scalar "biosignalTemplate".
%   values - M-by-1 template waveform, or an M-by-0 array when no segments
%            are available.
%   timeOffset - M-by-1 relative time vector copied from segments.
%   keptSegmentIndex - Indices of the segment columns included in values,
%                      ordered from highest to lowest correlation.
%   score - N-by-1 correlation score for every input segment.
%   metadata.topN - Number of segments included in a nonempty template.
%   metadata.sourceName - Source signal name copied from segments for a
%                         nonempty template. metadata is empty when no
%                         segment waveforms are available.
%
% Errors:
%   labkit:biosignal:InvalidOptions - opts is not a scalar struct or contains
%       an unknown field.
%   labkit:biosignal:InvalidSegments - segments is not a structure with
%       values and timeOffset fields. Invalid numeric values or an unusable
%       topN value may also raise the originating MATLAB conversion error.
%
% Example:
%   segments = struct('values', [0 0; 1 0.9; 0 0], ...
%       'timeOffset', [-1; 0; 1], 'sourceName', "ECG");
%   template = labkit.biosignal.buildTemplate(segments, struct('topN', 1));
%
% See also labkit.biosignal.segmentByEvents,
%   labkit.biosignal.measureSegments

    if nargin < 2
        opts = struct();
    end
    validateOptionStruct(opts, "topN");
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
