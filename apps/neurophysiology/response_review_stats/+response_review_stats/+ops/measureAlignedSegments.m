% Expected caller: response_review_stats.run or tests. Input is an aligned
% segment model and metric options. Output is a manual-segment metric table.
% No side effects.
function metrics = measureAlignedSegments(aligned, opts)
%MEASUREALIGNEDSEGMENTS Measure peak-to-peak, noise, and SNR per segment.

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
            timeSec <= baselineWindowSec(2);
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
        noise = y(noiseMask);
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
