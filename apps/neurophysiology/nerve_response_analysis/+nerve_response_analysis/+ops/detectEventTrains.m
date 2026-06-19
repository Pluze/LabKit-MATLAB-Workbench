% Expected caller: nerve_response_analysis.ops.analyzeRecording or tests.
% Inputs are one time vector, one event-source signal, and optional analysis
% event-detection options. Outputs are event and train tables. No side effects.
function [events, trains] = detectEventTrains(timeSec, signal, opts)
%DETECTEVENTTRAINS Detect pulse candidates and group them into trains.

    if nargin < 3 || isempty(opts)
        opts = struct();
    end

    timeSec = double(timeSec(:));
    signal = double(signal(:));
    if numel(timeSec) ~= numel(signal)
        error("nerve_response_analysis:EventSizeMismatch", ...
            "timeSec and signal must have the same length.");
    end

    events = emptyEvents();
    trains = emptyTrains();
    if isempty(timeSec)
        return;
    end

    detector = detectorOptions(opts);
    score = abs([0; diff(fillMissing(signal))]);
    noise = robustStd(score);
    threshold = max(detector.minScore, detector.stdMultiplier * noise);
    candidateIdx = localMaxima(score, threshold);
    candidateIdx = enforceMinimumDistance(candidateIdx, timeSec, score, ...
        detector.minPeakDistanceSec);
    if isempty(candidateIdx)
        return;
    end

    rawTimes = timeSec(candidateIdx);
    shiftedTimes = rawTimes + detector.stimShiftSec;
    [events, trains] = makeTables(candidateIdx, rawTimes, shiftedTimes, ...
        score(candidateIdx), detector);
end

function detector = detectorOptions(opts)
    eventDetection = fieldOrDefault(opts, "eventDetection", opts);
    train = fieldOrDefault(eventDetection, "train", fieldOrDefault(opts, ...
        "train", struct()));
    source = firstAnalogSource(eventDetection);

    detector = struct( ...
        "sourceId", string(fieldOrDefault(opts, "sourceId", ...
            fieldOrDefault(source, "id", "analog_derivative"))), ...
        "stdMultiplier", thresholdMultiplier(source, opts), ...
        "minScore", double(fieldOrDefault(opts, "minScore", 0)), ...
        "minPeakDistanceSec", double(fieldOrDefault(source, ...
            "minPeakDistanceSec", fieldOrDefault(opts, ...
            "minPeakDistanceSec", 0.005))), ...
        "groupGapSec", double(fieldOrDefault(train, "groupGapSec", 0.100)), ...
        "minDetectedPulses", double(fieldOrDefault(train, ...
            "minDetectedPulses", 4)), ...
        "maxTrainDurationSec", double(fieldOrDefault(train, ...
            "maxTrainDurationSec", 0.060)), ...
        "isolationWindowSec", double(fieldOrDefault(train, ...
            "isolationWindowSec", 0.500)), ...
        "requireIsolation", logical(fieldOrDefault(train, ...
            "requireIsolation", false)), ...
        "stimShiftSec", double(fieldOrDefault(train, "stimShiftSec", ...
            fieldOrDefault(opts, "stimShiftSec", -0.0005))));
end

function source = firstAnalogSource(eventDetection)
    source = struct();
    if ~isstruct(eventDetection) || ~isfield(eventDetection, "sources")
        return;
    end
    sources = eventDetection.sources;
    for k = 1:numel(sources)
        kind = lower(string(fieldOrDefault(sources(k), "kind", "")));
        if contains(kind, "derivative")
            source = sources(k);
            return;
        end
    end
end

function multiplier = thresholdMultiplier(source, opts)
    multiplier = double(fieldOrDefault(opts, "stdMultiplier", 2));
    if isstruct(source) && isfield(source, "threshold") && ...
            isfield(source.threshold, "multiplier")
        multiplier = double(source.threshold.multiplier);
    end
end

function value = fieldOrDefault(S, fieldName, defaultValue)
    value = defaultValue;
    if isstruct(S) && isfield(S, fieldName)
        value = S.(fieldName);
    end
end

function y = fillMissing(y)
    bad = ~isfinite(y);
    if ~any(bad)
        return;
    end
    good = find(~bad);
    if isempty(good)
        y(:) = 0;
    else
        y(bad) = interp1(good, y(good), find(bad), "linear", "extrap");
    end
end

function value = robustStd(x)
    x = x(isfinite(x));
    if isempty(x)
        value = 0;
        return;
    end
    center = median(x);
    value = median(abs(x - center)) / 0.6745;
    if value == 0 || ~isfinite(value)
        value = std(x);
    end
end

function idx = localMaxima(score, threshold)
    if numel(score) < 3
        idx = find(score >= threshold);
        return;
    end
    left = [-Inf; score(1:end-1)];
    right = [score(2:end); -Inf];
    idx = find(score >= threshold & score >= left & score > right);
end

function idx = enforceMinimumDistance(idx, timeSec, score, minDistanceSec)
    if isempty(idx) || minDistanceSec <= 0
        return;
    end
    keep = false(size(idx));
    lastKeep = 0;
    for k = 1:numel(idx)
        if lastKeep == 0 || timeSec(idx(k)) - timeSec(idx(lastKeep)) >= minDistanceSec
            keep(k) = true;
            lastKeep = k;
        elseif score(idx(k)) > score(idx(lastKeep))
            keep(lastKeep) = false;
            keep(k) = true;
            lastKeep = k;
        end
    end
    idx = idx(keep);
end

function [events, trains] = makeTables(candidateIdx, rawTimes, shiftedTimes, ...
        scores, detector)
    breaks = [1; find(diff(shiftedTimes) > detector.groupGapSec) + 1; ...
        numel(shiftedTimes) + 1];
    nTrains = numel(breaks) - 1;
    nEvents = numel(candidateIdx);

    trainIdCol = (1:nTrains).';
    startSecCol = zeros(nTrains, 1);
    endSecCol = zeros(nTrains, 1);
    pulseCountCol = zeros(nTrains, 1);
    durationSecCol = zeros(nTrains, 1);
    isIsolatedCol = false(nTrains, 1);
    isValidCol = false(nTrains, 1);
    trainSourceCol = strings(nTrains, 1);
    trainStatusCol = strings(nTrains, 1);

    eventTrainId = zeros(nEvents, 1);
    eventPulseIndex = zeros(nEvents, 1);
    eventTimeSec = zeros(nEvents, 1);
    eventRawTimeSec = zeros(nEvents, 1);
    eventSampleIndex = zeros(nEvents, 1);
    eventScore = zeros(nEvents, 1);
    eventSource = strings(nEvents, 1);

    eventRow = 0;
    for trainId = 1:nTrains
        range = breaks(trainId):(breaks(trainId + 1) - 1);
        startSec = shiftedTimes(range(1));
        endSec = shiftedTimes(range(end));
        durationSec = endSec - startSec;
        isIsolated = trainIsolation(trainId, breaks, shiftedTimes, detector);
        isValid = numel(range) >= detector.minDetectedPulses && ...
            durationSec <= detector.maxTrainDurationSec && ...
            (~detector.requireIsolation || isIsolated);
        status = "valid";
        if ~isValid
            status = "needsReview";
        end

        startSecCol(trainId) = startSec;
        endSecCol(trainId) = endSec;
        pulseCountCol(trainId) = numel(range);
        durationSecCol(trainId) = durationSec;
        isIsolatedCol(trainId) = isIsolated;
        isValidCol(trainId) = isValid;
        trainSourceCol(trainId) = detector.sourceId;
        trainStatusCol(trainId) = status;

        for p = 1:numel(range)
            eventRow = eventRow + 1;
            eventTrainId(eventRow) = trainId;
            eventPulseIndex(eventRow) = p;
            eventTimeSec(eventRow) = shiftedTimes(range(p));
            eventRawTimeSec(eventRow) = rawTimes(range(p));
            eventSampleIndex(eventRow) = candidateIdx(range(p));
            eventScore(eventRow) = scores(range(p));
            eventSource(eventRow) = detector.sourceId;
        end
    end

    trains = table(trainIdCol, startSecCol, endSecCol, pulseCountCol, ...
        durationSecCol, isIsolatedCol, isValidCol, trainSourceCol, ...
        trainStatusCol, ...
        'VariableNames', {'trainId', 'startSec', 'endSec', ...
        'pulseCount', 'durationSec', 'isIsolated', 'isValid', ...
        'source', 'status'});
    events = table(eventTrainId, eventPulseIndex, eventTimeSec, ...
        eventRawTimeSec, eventSampleIndex, eventScore, eventSource, ...
        'VariableNames', {'trainId', 'pulseIndex', 'timeSec', ...
        'rawTimeSec', 'sampleIndex', 'score', 'source'});
end

function isIsolated = trainIsolation(trainId, breaks, times, detector)
    startIdx = breaks(trainId);
    endIdx = breaks(trainId + 1) - 1;
    prevGap = Inf;
    nextGap = Inf;
    if trainId > 1
        prevGap = times(startIdx) - times(breaks(trainId) - 1);
    end
    if trainId < numel(breaks) - 1
        nextGap = times(breaks(trainId + 1)) - times(endIdx);
    end
    isIsolated = prevGap >= detector.isolationWindowSec && ...
        nextGap >= detector.isolationWindowSec;
end

function events = emptyEvents()
    events = table(zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
        zeros(0, 1), zeros(0, 1), strings(0, 1), ...
        'VariableNames', {'trainId', 'pulseIndex', 'timeSec', ...
        'rawTimeSec', 'sampleIndex', 'score', 'source'});
end

function trains = emptyTrains()
    trains = table(zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
        zeros(0, 1), false(0, 1), false(0, 1), strings(0, 1), ...
        strings(0, 1), ...
        'VariableNames', {'trainId', 'startSec', 'endSec', ...
        'pulseCount', 'durationSec', 'isIsolated', 'isValid', ...
        'source', 'status'});
end
