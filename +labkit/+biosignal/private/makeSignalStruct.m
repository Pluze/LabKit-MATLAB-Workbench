function signal = makeSignalStruct(name, sourceName, timeSec, values, metadata, opts)
%MAKESIGNALSTRUCT Build a standard biosignal signal struct.

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
