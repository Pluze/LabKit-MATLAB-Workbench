% Expected caller: nerve_response_analysis.analysisRun.analyzeRecording or tests.
% Inputs are one time vector, one response signal, event times, and analysis
% metric options. Output is one CAP metric table. No side effects.
function metrics = measureCapMetrics(timeSec, signal, eventTimesSec, opts)
%MEASURECAPMETRICS Measure event-locked CAP response features.
%   metrics = nerve_response_analysis.analysisRun.measureCapMetrics(timeSec,
%   signal, eventTimesSec, opts) accepts equal-length time/signal vectors,
%   event times in seconds, and optional baselineWindowSec,
%   blankingAfterPulseSec, and searchEndAfterPulseSec policies.
%
%   One output row is returned per event with baselineMean, noiseRms, positive
%   and negative peaks, peakToPeak, peakTimeSec, latencySec, snrDb, and status.
%   Baseline is measured before the event; the response search begins after the
%   blanking interval. Missing search samples produce status "noSamples".
%   Length mismatch throws MetricSizeMismatch. No files or graphics are used.
%
%   See also nerve_response_analysis.analysisRun.detectEventTrains.

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
