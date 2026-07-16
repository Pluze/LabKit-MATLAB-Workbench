function metrics = measureCapMetrics(timeSec, signal, eventTimesSec, opts)
%MEASURECAPMETRICS Measure event-locked CAP response features.
%
% Usage:
%   metrics = nerve_response_analysis.analysisRun.measureCapMetrics( ...
%       timeSec, signal, eventTimesSec)
%   metrics = nerve_response_analysis.analysisRun.measureCapMetrics( ...
%       timeSec, signal, eventTimesSec, opts)
%
% Description:
%   Measures baseline, noise, positive and negative response peaks, peak-to-peak
%   amplitude, dominant-peak latency, and signal-to-noise ratio for each
%   stimulus time. All time options and outputs are in seconds. Signal-derived
%   values retain the units of signal; SNR is reported in decibels.
%
% Inputs:
%   timeSec - Numeric sample-time vector in seconds.
%   signal - Numeric response vector with the same length as timeSec.
%   eventTimesSec - Numeric vector of stimulus times in seconds. One output row
%       is produced for each value, in input order.
%   opts - Optional scalar structure containing the measurement windows below.
%
% Options:
%   baselineWindowSec - Duration before each event used to estimate baseline.
%       The inclusive baseline interval is [event-baselineWindowSec,
%       event-blankingAfterPulseSec]. Default: 0.050 seconds.
%   blankingAfterPulseSec - Time excluded immediately before and after the
%       stimulus. It may also be supplied as opts.segments.capSearch.
%       blankingAfterPulseSec. The nested value takes precedence. Default:
%       0.002 seconds.
%   searchEndAfterPulseSec - End of the inclusive response-search interval,
%       measured after the event. It may also be supplied in
%       opts.segments.capSearch and takes the same precedence. Default:
%       0.008 seconds.
%
% Calculations:
%   baselineMean is the finite-value mean in the baseline interval. noiseRms
%   is the root mean square deviation from that mean. If the interval contains
%   no samples, the recording-wide finite median becomes the baseline and
%   noiseRms remains NaN. The response search is
%   [event+blankingAfterPulseSec, event+searchEndAfterPulseSec]. Peaks are
%   measured after baseline subtraction. peakTimeSec belongs to whichever of
%   the positive or negative peaks has larger absolute amplitude, and
%   latencySec = peakTimeSec-stimTimeSec. When noiseRms is positive and finite,
%   snrDb = 20*log10(abs(peakToPeak)/noiseRms).
%
% Outputs:
%   metrics - Table with one row per event.
%
% Metric Columns:
%   eventIndex - One-based event order.
%   stimTimeSec - Input stimulus time.
%   baselineMean, noiseRms - Pre-stimulus baseline and noise estimate.
%   peakPositive, peakNegative, peakToPeak - Baseline-subtracted extrema and
%       their difference.
%   peakTimeSec, latencySec - Dominant absolute peak time and event-relative
%       latency.
%   snrDb - Peak-to-peak SNR in decibels, or NaN when noise is unavailable or
%       zero.
%   status - "ok" when the search interval contains samples; "noSamples"
%       otherwise. Rows without samples retain NaN response metrics.
%
% Errors:
%   nerve_response_analysis:MetricSizeMismatch - timeSec and signal lengths
%       differ.
%
% Example:
%   timeSec = (0:0.0001:0.04).';
%   signal = zeros(size(timeSec));
%   signal(abs(timeSec-0.014) < 0.0002) = 2;
%   signal(abs(timeSec-0.016) < 0.0002) = -1;
%   opts = struct("baselineWindowSec", 0.004, ...
%       "blankingAfterPulseSec", 0.002, ...
%       "searchEndAfterPulseSec", 0.008);
%   metrics = nerve_response_analysis.analysisRun.measureCapMetrics( ...
%       timeSec, signal, 0.010, opts);
%   assert(metrics.status == "ok" && metrics.peakToPeak > 2.5)
%
% See also nerve_response_analysis.analysisRun.detectEventTrains,
%   nerve_response_analysis.analysisRun.analyzeRecording

    if nargin < 4 || isempty(opts)
        opts = struct();
    end

    timeSec = double(timeSec(:));
    signal = double(signal(:));
    eventTimesSec = double(eventTimesSec(:));
    if numel(timeSec) ~= numel(signal)
        error("nerve_response_analysis:MetricSizeMismatch", ...
            "timeSec and signal must have matching lengths.");
    end

    params = metricOptions(opts);
    nEvents = numel(eventTimesSec);
    eventIndex = (1:nEvents).';
    stimTimeSec = eventTimesSec;
    baselineMean = NaN(nEvents, 1);
    noiseRms = NaN(nEvents, 1);
    peakPositive = NaN(nEvents, 1);
    peakNegative = NaN(nEvents, 1);
    peakToPeak = NaN(nEvents, 1);
    peakTimeSec = NaN(nEvents, 1);
    latencySec = NaN(nEvents, 1);
    snrDb = NaN(nEvents, 1);
    status = strings(nEvents, 1);

    for k = 1:nEvents
        eventTime = eventTimesSec(k);
        baselineMask = timeSec >= eventTime - params.baselineWindowSec & ...
            timeSec <= eventTime - params.blankingAfterPulseSec;
        if any(baselineMask)
            baselineValues = signal(baselineMask);
            baselineMean(k) = mean(baselineValues, "omitnan");
            noiseRms(k) = sqrt(mean((baselineValues - baselineMean(k)) .^ 2, ...
                "omitnan"));
        else
            baselineMean(k) = median(signal, "omitnan");
            noiseRms(k) = NaN;
        end

        searchMask = timeSec >= eventTime + params.blankingAfterPulseSec & ...
            timeSec <= eventTime + params.searchEndAfterPulseSec;
        if ~any(searchMask)
            status(k) = "noSamples";
            continue;
        end

        responseTime = timeSec(searchMask);
        response = signal(searchMask) - baselineMean(k);
        [peakPositive(k), maxIdx] = max(response);
        [peakNegative(k), minIdx] = min(response);
        peakToPeak(k) = peakPositive(k) - peakNegative(k);
        if abs(peakPositive(k)) >= abs(peakNegative(k))
            peakTimeSec(k) = responseTime(maxIdx);
        else
            peakTimeSec(k) = responseTime(minIdx);
        end
        latencySec(k) = peakTimeSec(k) - eventTime;

        if isfinite(noiseRms(k)) && noiseRms(k) > 0
            snrDb(k) = 20 * log10(abs(peakToPeak(k)) / noiseRms(k));
        end
        status(k) = "ok";
    end

    metrics = table(eventIndex, stimTimeSec, baselineMean, noiseRms, ...
        peakPositive, peakNegative, peakToPeak, peakTimeSec, latencySec, ...
        snrDb, status, ...
        'VariableNames', {'eventIndex', 'stimTimeSec', 'baselineMean', ...
        'noiseRms', 'peakPositive', 'peakNegative', 'peakToPeak', ...
        'peakTimeSec', 'latencySec', 'snrDb', 'status'});
end

function params = metricOptions(opts)
    segments = fieldOrDefault(opts, "segments", opts);
    capSearch = fieldOrDefault(segments, "capSearch", struct());
    params = struct( ...
        "baselineWindowSec", double(fieldOrDefault(opts, ...
            "baselineWindowSec", 0.050)), ...
        "blankingAfterPulseSec", double(fieldOrDefault(capSearch, ...
            "blankingAfterPulseSec", fieldOrDefault(opts, ...
            "blankingAfterPulseSec", 0.002))), ...
        "searchEndAfterPulseSec", double(fieldOrDefault(capSearch, ...
            "searchEndAfterPulseSec", fieldOrDefault(opts, ...
            "searchEndAfterPulseSec", 0.008))));
end

function value = fieldOrDefault(S, fieldName, defaultValue)
    value = defaultValue;
    if isstruct(S) && isfield(S, fieldName)
        value = S.(fieldName);
    end
end
