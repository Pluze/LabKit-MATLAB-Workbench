% Private biosignal helper. Expected caller: the readRecording import plan.
% Inputs are a MAT path and public import options. Output is a normalized
% recording only when the MAT contains one unambiguous nonscalar numeric array.
% Side effects: file reads only.
function recording = readNumericMatRecording(filepath, opts)
%READNUMERICMATRECORDING Decode one unambiguous numeric MAT array.

    data = load(filepath);
    names = fieldnames(data);
    candidates = strings(0, 1);
    for k = 1:numel(names)
        value = data.(names{k});
        if (isnumeric(value) || islogical(value)) && ~isscalar(value) && ismatrix(value)
            candidates(end + 1, 1) = string(names{k}); %#ok<AGROW>
        end
    end
    if numel(candidates) ~= 1
        error('labkit:biosignal:AmbiguousNumericMat', ...
            'Numeric MAT fallback requires exactly one nonscalar numeric array.');
    end

    sourceName = candidates(1);
    values = data.(char(sourceName));
    if isvector(values)
        values = values(:);
    end
    sampleCount = size(values, 1);
    fallbackFs = optionValue(opts, 'fallbackFs', []);
    if ~isempty(fallbackFs) && isnumeric(fallbackFs) && isscalar(fallbackFs) && ...
            isfinite(fallbackFs) && fallbackFs > 0
        timeSec = (0:sampleCount - 1).' / double(fallbackFs);
        timeSource = "synthetic_sample_index";
    else
        timeSec = (0:sampleCount - 1).';
        timeSource = "synthetic_sample_index";
    end

    channelCount = size(values, 2);
    signalCells = cell(1, channelCount);
    for k = 1:channelCount
        if channelCount == 1
            channelName = sourceName;
            displaySource = "";
        else
            channelName = "Column " + string(k);
            displaySource = sourceName;
        end
        metadata = struct( ...
            'sourceKind', "numeric_mat", ...
            'sourceVariable', sourceName, ...
            'sourceColumn', k, ...
            'timeSource', timeSource);
        signalCells{k} = makeSignalStruct(channelName, displaySource, timeSec, ...
            double(values(:, k)), metadata, opts);
    end
    recording = makeRecording(filepath, "mat", [signalCells{:}]);
    recording.metadata.sourceKind = "numeric_mat";
end
