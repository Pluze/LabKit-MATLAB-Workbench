% Private biosignal helper. Expected caller: labkit.biosignal facade and
% internal import/recording pipeline. Inputs and outputs use internal signal,
% recording, time, or option values. Side effects: file reads only in importer
% helpers; assumes public callers own workflow validation and user-facing errors.
function signal = makeSignalStruct(name, sourceName, timeSec, values, metadata, opts)
%MAKESIGNALSTRUCT Build a normalized private biosignal signal struct.
%
% Inputs:
%   name - channel name shown to app code.
%   sourceName - table/timetable source label.
%   timeSec - numeric seconds vector.
%   values - numeric/logical vector; non-finite values are repaired.
%   metadata - source metadata copied into signal.metadata.
%   opts - optional struct. fallbackFs supplies fs when timeSec cannot
%          produce a finite positive sample-rate estimate.
%
% Output:
%   signal - struct with type, name, displayName, sourceName, time, values,
%            fs, unit, and metadata fields. time/values are trimmed to a
%            shared length.

    if nargin < 6
        opts = struct();
    end

    timeSec = double(timeSec(:));
    values = fillVectorMissing(double(values(:)));
    n = min(numel(timeSec), numel(values));
    timeSec = timeSec(1:n);
    values = values(1:n);

    fs = inferSampleRate(timeSec);
    fallbackFs = optionValue(opts, 'fallbackFs', []);
    if (~isfinite(fs) || fs <= 0) && ~isempty(fallbackFs)
        fs = double(fallbackFs);
    end

    signal = struct();
    signal.type = "biosignalSignal";
    signal.name = string(name);
    signal.displayName = string(name);
    signal.sourceName = string(sourceName);
    signal.time = timeSec;
    signal.values = values;
    signal.fs = fs;
    signal.unit = "";
    signal.metadata = metadata;
end
