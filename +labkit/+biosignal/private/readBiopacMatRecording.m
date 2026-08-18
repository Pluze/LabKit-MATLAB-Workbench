% Private biosignal helper. Expected caller: the readRecording import plan.
% Inputs are a BIOPAC MAT path and public import options. Output is a normalized
% recording. Side effects: file reads only; assumes format selection is owned by
% recordingImportPlan.
function recording = readBiopacMatRecording(filepath, opts)
%READBIOPACMATRECORDING Decode a BIOPAC matrix-plus-metadata MAT export.

    data = load(filepath);
    required = {'data', 'isi', 'isi_units', 'labels', 'units'};
    if ~all(isfield(data, required))
        error('labkit:biosignal:InvalidBiopacMat', ...
            'BIOPAC MAT export is missing data, isi, isi_units, labels, or units.');
    end

    values = data.data;
    if ~(isnumeric(values) || islogical(values)) || ~ismatrix(values) || isempty(values)
        error('labkit:biosignal:InvalidBiopacMat', ...
            'BIOPAC MAT data must be a nonempty numeric sample-by-channel matrix.');
    end

    channelCount = size(values, 2);
    labels = textRows(data.labels);
    units = textRows(data.units);
    if numel(labels) ~= channelCount || numel(units) ~= channelCount
        error('labkit:biosignal:InvalidBiopacMat', ...
            'BIOPAC labels and units must contain one row per data channel.');
    end

    intervalSec = intervalSeconds(data.isi, data.isi_units);
    timeSec = (0:size(values, 1) - 1).' * intervalSec;
    startSample = 0;
    if isfield(data, 'start_sample') && isnumeric(data.start_sample) && ...
            isscalar(data.start_sample) && isfinite(data.start_sample)
        startSample = double(data.start_sample);
    end

    signalCells = cell(1, channelCount);
    for k = 1:channelCount
        name = labels(k);
        if ismissing(name) || strlength(name) == 0
            name = "Channel " + string(k);
        end
        metadata = struct( ...
            'sourceKind', "biopac_mat", ...
            'sourceVariable', "data", ...
            'sourceColumn', k, ...
            'sampleIntervalSeconds', intervalSec, ...
            'startSample', startSample);
        signalCells{k} = makeSignalStruct(name, "", timeSec, ...
            double(values(:, k)), metadata, opts);
        signalCells{k}.unit = units(k);
    end
    recording = makeRecording(filepath, "mat", [signalCells{:}]);
    recording.metadata.sourceKind = "biopac_mat";
end

function rows = textRows(value)
    if ischar(value)
        rows = string(cellstr(value));
    elseif isstring(value)
        rows = value(:);
    elseif iscellstr(value)
        rows = string(value(:));
    else
        error('labkit:biosignal:InvalidBiopacMat', ...
            'BIOPAC labels and units must be text rows.');
    end
    rows = strip(rows(:));
end

function intervalSec = intervalSeconds(interval, unitValue)
    if ~isnumeric(interval) || ~isscalar(interval) || ...
            ~isfinite(interval) || interval <= 0
        error('labkit:biosignal:InvalidBiopacMat', ...
            'BIOPAC isi must be a finite positive scalar.');
    end
    units = textRows(unitValue);
    if numel(units) ~= 1
        error('labkit:biosignal:InvalidBiopacMat', ...
            'BIOPAC isi_units must contain one time unit.');
    end
    clean = regexprep(lower(char(units)), '[^a-z]', '');
    switch clean
        case {'s', 'sec', 'secs', 'second', 'seconds'}
            scale = 1;
        case {'ms', 'msec', 'msecs', 'millisecond', 'milliseconds'}
            scale = 1e-3;
        case {'us', 'usec', 'usecs', 'microsecond', 'microseconds'}
            scale = 1e-6;
        case {'ns', 'nsec', 'nsecs', 'nanosecond', 'nanoseconds'}
            scale = 1e-9;
        otherwise
            error('labkit:biosignal:InvalidBiopacMat', ...
                'Unsupported BIOPAC sample-interval unit: %s.', units);
    end
    intervalSec = double(interval) * scale;
end
