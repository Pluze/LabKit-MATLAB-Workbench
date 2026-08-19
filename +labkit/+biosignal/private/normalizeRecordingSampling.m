% Private biosignal helper. Expected caller: labkit.biosignal.readRecording.
% Inputs are a decoded recording and public import options. Output has a uniform
% seconds time grid for every usable signal. Side effects: none. Large timestamp
% gaps delimit interpolation segments and are compressed rather than bridged.
function recording = normalizeRecordingSampling(recording, opts)
%NORMALIZERECORDINGSAMPLING Clean and resample decoded channels uniformly.

    enabled = optionValue(opts, 'resampleUniform', true);
    if ~(islogical(enabled) && isscalar(enabled))
        error('labkit:biosignal:InvalidUniformSampling', ...
            'resampleUniform must be a logical scalar.');
    end
    gapFactor = double(optionValue(opts, 'gapFactor', 20));
    if ~isscalar(gapFactor) || ~isfinite(gapFactor) || gapFactor <= 0
        error('labkit:biosignal:InvalidGapFactor', ...
            'gapFactor must be a finite positive scalar.');
    end

    for k = 1:numel(recording.signals)
        recording.signals(k) = normalizeSignal(recording.signals(k), enabled, gapFactor);
    end
    infos = {recording.signals.metadata};
    normalization = cellfun(@(metadata) metadata.samplingNormalization, infos);
    recording.metadata.samplingNormalization = struct( ...
        'enabled', logical(enabled), ...
        'uniform', all(arrayfun(@(signal) isUniform(signal.time), recording.signals)), ...
        'channelCount', numel(recording.signals), ...
        'resampledChannelCount', nnz([normalization.resampled]), ...
        'compressedGapCount', sum([normalization.compressedGapCount]), ...
        'removedNonfiniteTimeCount', sum([normalization.removedNonfiniteTimeCount]), ...
        'removedDuplicateTimeCount', sum([normalization.removedDuplicateTimeCount]));
end

function signal = normalizeSignal(signal, enabled, gapFactor)
    inputTime = double(signal.time(:));
    inputValues = double(signal.values(:));
    inputCount = min(numel(inputTime), numel(inputValues));
    inputTime = inputTime(1:inputCount);
    inputValues = inputValues(1:inputCount);
    info = emptyInfo(enabled, inputCount);
    if ~enabled
        signal.metadata.samplingNormalization = info;
        return;
    end

    finiteTime = isfinite(inputTime);
    info.removedNonfiniteTimeCount = nnz(~finiteTime);
    inputTime = inputTime(finiteTime);
    inputValues = inputValues(finiteTime);
    [inputTime, order] = sort(inputTime, 'ascend');
    inputValues = inputValues(order);
    info.reordered = any(order(:) ~= (1:numel(order)).');
    [inputTime, uniqueIndex] = unique(inputTime, 'stable');
    info.removedDuplicateTimeCount = numel(inputValues) - numel(uniqueIndex);
    inputValues = inputValues(uniqueIndex);
    if ~isempty(inputTime)
        inputTime = inputTime - inputTime(1);
    end
    cleaned = info.removedNonfiniteTimeCount > 0 || ...
        info.removedDuplicateTimeCount > 0 || info.reordered;
    if numel(inputTime) < 2
        signal.time = zeros(size(inputTime));
        signal.values = inputValues;
        info.applied = ~isempty(inputTime);
        info.resampled = cleaned;
        info.outputSampleCount = numel(inputTime);
        signal.metadata.samplingNormalization = info;
        return;
    end

    dt = diff(inputTime);
    positiveDt = dt(isfinite(dt) & dt > 0);
    if isempty(positiveDt)
        signal.metadata.samplingNormalization = info;
        return;
    end
    nominalDt = median(positiveDt);
    if ~isfinite(nominalDt) || nominalDt <= 0
        signal.metadata.samplingNormalization = info;
        return;
    end

    gapAfter = find(dt > gapFactor * nominalDt);
    tolerance = max(1e-12, nominalDt * 1e-6);
    timingDeviation = abs(dt - nominalDt);
    finiteDeviation = timingDeviation(isfinite(timingDeviation));
    if isempty(finiteDeviation)
        maxDeviation = NaN;
    else
        maxDeviation = max(finiteDeviation);
    end

    if isempty(gapAfter) && all(isfinite(dt)) && all(dt > 0) && ...
            all(timingDeviation <= tolerance)
        outputValues = inputValues;
        resampled = cleaned;
    else
        segmentStarts = [1; gapAfter + 1];
        segmentEnds = [gapAfter; numel(inputTime)];
        chunks = cell(numel(segmentStarts), 1);
        for j = 1:numel(segmentStarts)
            idx = segmentStarts(j):segmentEnds(j);
            chunks{j} = resampleSegment(inputTime(idx), inputValues(idx), nominalDt);
        end
        outputValues = vertcat(chunks{:});
        resampled = true;
    end

    outputTime = (0:numel(outputValues) - 1).' * nominalDt;
    signal.time = outputTime;
    signal.values = outputValues;
    signal.fs = 1 / nominalDt;
    info.applied = true;
    info.resampled = resampled;
    info.method = "linear_segmented";
    info.nominalIntervalSeconds = nominalDt;
    info.inputSampleCount = inputCount;
    info.outputSampleCount = numel(outputValues);
    info.compressedGapCount = numel(gapAfter);
    info.maxTimingDeviationSeconds = maxDeviation;
    signal.metadata.samplingNormalization = info;
end

function values = resampleSegment(time, values, nominalDt)
    time = double(time(:));
    values = double(values(:));
    time = time - time(1);
    if numel(time) < 2
        values = values(1);
        return;
    end

    duration = time(end);
    outputCount = floor(duration / nominalDt + 1e-9) + 1;
    if outputCount < 2
        target = [0; duration];
    else
        target = (0:outputCount - 1).' * nominalDt;
    end
    values = interp1(time, values, target, 'linear');
end

function info = emptyInfo(enabled, inputCount)
    info = struct( ...
        'enabled', logical(enabled), ...
        'applied', false, ...
        'resampled', false, ...
        'method', "none", ...
        'nominalIntervalSeconds', NaN, ...
        'inputSampleCount', inputCount, ...
        'outputSampleCount', inputCount, ...
        'compressedGapCount', 0, ...
        'removedNonfiniteTimeCount', 0, ...
        'removedDuplicateTimeCount', 0, ...
        'reordered', false, ...
        'maxTimingDeviationSeconds', NaN);
end

function tf = isUniform(time)
    time = double(time(:));
    if numel(time) < 3
        tf = true;
        return;
    end
    dt = diff(time);
    nominalDt = median(dt);
    tf = all(isfinite(dt)) && nominalDt > 0 && ...
        all(abs(dt - nominalDt) <= max(1e-12, nominalDt * 1e-6));
end
