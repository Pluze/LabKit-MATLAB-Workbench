function metrics = measureAlignedSegments(aligned, opts)
%MEASUREALIGNEDSEGMENTS Measure peak-to-peak, noise, and SNR per segment.
%
% Usage:
%   metrics = response_review_stats.analysisRun.measureAlignedSegments(aligned)
%   metrics = response_review_stats.analysisRun.measureAlignedSegments( ...
%       aligned, opts)
%
% Description:
%   Baseline-corrects every aligned trace, measures its positive and negative
%   extrema, and estimates baseline noise and peak-to-peak SNR. Each segment is
%   measured independently and produces one output row. Peaks use only finite
%   samples; nonfinite samples are omitted from baseline and noise means.
%
% Inputs:
%   aligned - Structure returned by
%       response_review_stats.analysisRun.alignSegments. timeSec is G-by-1,
%       values is G-by-N, and segmentNames contains N names.
%   opts - Optional scalar structure containing the measurement windows below.
%
% Options:
%   baselineWindowSec - Inclusive [start end] interval in aligned seconds used
%       to calculate and subtract the baseline mean. Default: [0.007 0.009].
%   noiseWindowSec - Two-element numeric [start end] interval used for noise
%       RMS after baseline subtraction. Default: baselineWindowSec.
%   measurementWindowSec - Inclusive interval used for positive and negative
%       peaks. Empty input uses all aligned samples. Default: [].
%
% Calculations:
%   PeakToPeak = Peak1Value-Peak2Value, where Peak1 is the finite maximum and
%   Peak2 is the finite minimum in the measurement window. NoiseRMS is the root
%   mean square deviation from the finite noise-window mean. When NoiseRMS is
%   positive and PeakToPeak is finite, SNR_dB is
%   20*log10(abs(PeakToPeak)/NoiseRMS). A window without usable samples leaves
%   its metrics as NaN. A missing baseline also makes that segment's corrected
%   trace and downstream measurements NaN.
%
% Outputs:
%   metrics - N-row table with SegmentName, BaselineStart_s, BaselineEnd_s,
%       PeakToPeak, Peak1Time_s, Peak1Value, Peak2Time_s, Peak2Value,
%       NoiseStart_s, NoiseEnd_s, NoiseRMS, and SNR_dB columns.
%
% Failure Behavior:
%   Windows without usable finite samples produce NaN metrics for the affected
%   segment. aligned must provide compatible timeSec, values, and segmentNames
%   fields, and every supplied window must contain two numeric endpoints;
%   malformed values propagate the originating field, indexing, or conversion
%   error.
%
% Example:
%   aligned = struct("timeSec", (0:0.001:0.012).', ...
%       "values", zeros(13, 1), "segmentNames", "response", "status", "ok");
%   aligned.values(7) = 2;
%   aligned.values(11) = -1;
%   opts = struct("baselineWindowSec", [0 0.002], ...
%       "noiseWindowSec", [0 0.002]);
%   metrics = response_review_stats.analysisRun.measureAlignedSegments( ...
%       aligned, opts);
%   assert(metrics.PeakToPeak == 3)
%
% See also response_review_stats.analysisRun.alignSegments,
%   response_review_stats.analysisRun.summarizeMetrics

    if nargin < 2 || isempty(opts)
        opts = struct();
    end

    timeSec = double(aligned.timeSec(:));
    values = double(aligned.values);
    names = string(aligned.segmentNames(:));
    baselineWindowSec = double(fieldOrDefault(opts, "baselineWindowSec", ...
        [0.007 0.009]));
    noiseWindowSec = double(fieldOrDefault(opts, "noiseWindowSec", ...
        baselineWindowSec));
    measurementWindowSec = fieldOrDefault(opts, "measurementWindowSec", []);
    if isempty(measurementWindowSec)
        measurementMask = true(size(timeSec));
    else
        measurementWindowSec = double(measurementWindowSec);
        measurementMask = timeSec >= measurementWindowSec(1) & ...
            timeSec <= measurementWindowSec(2);
    end

    nSegments = size(values, 2);
    SegmentName = names;
    BaselineStart_s = repmat(baselineWindowSec(1), nSegments, 1);
    BaselineEnd_s = repmat(baselineWindowSec(2), nSegments, 1);
    PeakToPeak = NaN(nSegments, 1);
    Peak1Time_s = NaN(nSegments, 1);
    Peak1Value = NaN(nSegments, 1);
    Peak2Time_s = NaN(nSegments, 1);
    Peak2Value = NaN(nSegments, 1);
    NoiseStart_s = repmat(noiseWindowSec(1), nSegments, 1);
    NoiseEnd_s = repmat(noiseWindowSec(2), nSegments, 1);
    NoiseRMS = NaN(nSegments, 1);
    SNR_dB = NaN(nSegments, 1);

    for k = 1:nSegments
        y = values(:, k);
        baselineMask = timeSec >= baselineWindowSec(1) & ...
            timeSec <= baselineWindowSec(2) & isfinite(y);
        baseline = mean(y(baselineMask), "omitnan");
        y = y - baseline;

        usable = measurementMask & isfinite(y);
        if any(usable)
            tMeasure = timeSec(usable);
            yMeasure = y(usable);
            [Peak1Value(k), maxIdx] = max(yMeasure);
            [Peak2Value(k), minIdx] = min(yMeasure);
            Peak1Time_s(k) = tMeasure(maxIdx);
            Peak2Time_s(k) = tMeasure(minIdx);
            PeakToPeak(k) = Peak1Value(k) - Peak2Value(k);
        end

        noiseMask = timeSec >= noiseWindowSec(1) & timeSec <= noiseWindowSec(2);
        noise = y(noiseMask & isfinite(y));
        if any(isfinite(noise))
            NoiseRMS(k) = sqrt(mean((noise - mean(noise, "omitnan")) .^ 2, ...
                "omitnan"));
            if NoiseRMS(k) > 0 && isfinite(PeakToPeak(k))
                SNR_dB(k) = 20 * log10(abs(PeakToPeak(k)) / NoiseRMS(k));
            end
        end
    end

    metrics = table(SegmentName, BaselineStart_s, BaselineEnd_s, ...
        PeakToPeak, Peak1Time_s, Peak1Value, Peak2Time_s, Peak2Value, ...
        NoiseStart_s, NoiseEnd_s, NoiseRMS, SNR_dB);
end

function value = fieldOrDefault(S, fieldName, defaultValue)
    value = defaultValue;
    if isstruct(S) && isfield(S, fieldName)
        value = S.(fieldName);
    end
end
