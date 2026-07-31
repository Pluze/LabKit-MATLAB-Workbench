function [window, status] = readWindow(filepath, opts)
%READWINDOW Read selected channels and times from an Intan RHS file.
%
% Usage:
%   [window, status] = labkit.rhs.readWindow(filepath)
%   [window, status] = labkit.rhs.readWindow(filepath, opts)
%
% Description:
%   Reads only the complete data blocks needed for one time interval and one
%   channel family. Returned values are converted to physical units using the
%   Intan RHS scaling constants. File/header/read failures are returned in
%   status; invalid option values throw errors.
%
% Inputs:
%   filepath - Character vector or string scalar naming one RHS file.
%   opts - Optional scalar structure. See Options.
%
% Options:
%   family - String scalar selecting a channel family. Canonical values are
%       "amplifier", "stim", "dcAmplifier", "boardAdc", "boardDac",
%       "boardDigIn", and "boardDigOut". Matching ignores case and
%       punctuation. Short aliases include "amp", "dc", "adc", "dac",
%       "digin", and "digout". Default: "amplifier".
%   channels - Channel selection within the chosen family. Use [] for all
%       channels; positive one-based numeric indices for positions in that
%       family; or a character vector, string array, or cell array of native or
%       custom channel names. Names are matched exactly first, then with case
%       and punctuation removed. Default: [].
%   timeRangeSec - Two-element numeric vector [start end] in seconds. A
%       negative start is clamped to zero; Inf as the end reads through the
%       last complete sample. Both calculated endpoint samples are included.
%       Default: [0 Inf].
%
% Outputs:
%   window - Scalar structure containing the selected waveform data. On a
%       read failure it retains source identity and contains empty arrays.
%   status - Scalar structure with ok, message, and filepath. A valid request
%       beyond the recording duration returns ok=true, empty values, and a
%       message stating that no samples were in the requested window.
%
% Output Fields:
%   sourcePath - Source RHS path as a character vector.
%   name - Source filename including extension.
%   family - Canonical selected family name.
%   unit - "microvolts" for amplifier, "microamps" for stim, "volts" for
%       DC amplifier and board analog channels, or "logical" for digital
%       channels.
%   sampleRateHz - Sample rate in hertz.
%   sampleRange - One-based inclusive [start end] sample indices.
%   channels - String row vector of returned native channel names.
%   timeSec - Sample-by-one time vector in seconds, derived from stored Intan
%       timestamps.
%   values - Samples-by-channels numeric matrix in the unit named by unit.
%
% Errors:
%   Throws labkit:rhs:InvalidOptions when opts is not a scalar struct or
%   contains an unknown field, labkit:rhs:InvalidFilepath for an invalid path,
%   labkit:rhs:InvalidFamily for an unsupported family,
%   labkit:rhs:InvalidChannel for an unknown or out-of-range channel, and
%   labkit:rhs:InvalidTimeRange for a malformed or reversed time range.
%   Missing files, malformed headers, absent channel families, files without
%   complete data blocks, and waveform read failures return status.ok=false.
%
% Example:
%   opts = struct("family", "stim", ...
%       "channels", ["C-001", "C-002"], ...
%       "timeRangeSec", [0.1 0.2]);
%   [window, status] = labkit.rhs.readWindow("recording.rhs", opts);
%   if status.ok
%       plot(window.timeSec, window.values)
%       xlabel("Time (s)")
%       ylabel("Stimulation current (microamps)")
%       legend(window.channels)
%   end
%
% See also labkit.rhs.indexFile,
%   labkit.rhs.inspectFile

    if nargin < 2
        opts = struct();
    end
    validateOptionStruct(opts, ["family", "channels", "timeRangeSec"]);

    filepath = normalizeFilepath(filepath);
    [index, status] = labkit.rhs.indexFile(filepath);
    window = emptyWindow(filepath);
    if ~status.ok
        return;
    end
    if ~index.hasData
        status = makeStatus(filepath, false, ...
            "RHS file has no waveform data.");
        return;
    end

    family = optionValue(opts, "family", "amplifier");
    spec = familySpec(family, index.info);
    if spec.count == 0
        status = makeStatus(filepath, false, ...
            "Selected RHS channel family has no channels.");
        return;
    end

    channels = optionValue(opts, "channels", []);
    [channelIdx, channelNames] = resolveChannels(channels, spec.channels);
    timeRangeSec = normalizeTimeRange(optionValue(opts, "timeRangeSec", [0 Inf]));
    [startSample, endSample] = sampleBounds(timeRangeSec, index);
    if startSample > endSample
        window = makeWindow(filepath, index, spec, channelNames, zeros(0, 1), ...
            zeros(0, numel(channelIdx)), [startSample endSample]);
        status = makeStatus(filepath, true, "No samples in requested window.");
        return;
    end

    try
        [timeSec, values] = readSamples(filepath, index, spec, channelIdx, ...
            startSample, endSample);
        window = makeWindow(filepath, index, spec, channelNames, timeSec, values, ...
            [startSample endSample]);
        status = makeStatus(filepath, true, "");
        if ~index.exactBlocks
            status.message = "Read full RHS blocks only; file has trailing partial bytes.";
        end
    catch ME
        status = makeStatus(filepath, false, string(ME.message));
    end
end

function value = optionValue(opts, fieldName, defaultValue)
    value = defaultValue;
    fieldName = char(fieldName);
    if isstruct(opts) && isfield(opts, fieldName)
        value = opts.(fieldName);
    end
end

function range = normalizeTimeRange(range)
    range = double(range);
    if ~isvector(range) || numel(range) ~= 2 || any(isnan(range))
        error("labkit:rhs:InvalidTimeRange", ...
            "timeRangeSec must be a two-element numeric vector.");
    end
    range = range(:).';
    if range(1) < 0
        range(1) = 0;
    end
    if range(2) < range(1)
        error("labkit:rhs:InvalidTimeRange", ...
            "timeRangeSec end must be greater than or equal to start.");
    end
end

function [startSample, endSample] = sampleBounds(range, index)
    fs = double(index.sampleRateHz);
    startSample = max(1, floor(range(1) * fs) + 1);
    if isinf(range(2))
        endSample = index.sampleCount;
    else
        endSample = min(index.sampleCount, floor(range(2) * fs) + 1);
    end
end

function spec = familySpec(family, info)
    key = lower(regexprep(char(string(family)), "[^A-Za-z0-9]", ""));
    switch key
        case {"amplifier", "amp"}
            canonical = "amplifier";
            channels = info.channelFamilies.amplifier;
            unit = "microvolts";
        case {"stim", "stimulus", "stimcurrent"}
            canonical = "stim";
            channels = info.channelFamilies.amplifier;
            unit = "microamps";
        case {"dc", "dcamplifier", "dcamp"}
            canonical = "dcAmplifier";
            channels = info.channelFamilies.amplifier;
            unit = "volts";
            if ~info.dcAmplifierSaved
                channels = emptyChannelStruct();
            end
        case {"boardadc", "adc"}
            canonical = "boardAdc";
            channels = info.channelFamilies.boardAdc;
            unit = "volts";
        case {"boarddac", "dac"}
            canonical = "boardDac";
            channels = info.channelFamilies.boardDac;
            unit = "volts";
        case {"boarddigin", "digitalin", "digin"}
            canonical = "boardDigIn";
            channels = info.channelFamilies.boardDigIn;
            unit = "logical";
        case {"boarddigout", "digitalout", "digout"}
            canonical = "boardDigOut";
            channels = info.channelFamilies.boardDigOut;
            unit = "logical";
        otherwise
            error("labkit:rhs:InvalidFamily", ...
                "Unsupported RHS channel family: %s.", string(family));
    end

    spec = struct( ...
        "family", canonical, ...
        "channels", channels, ...
        "count", numel(channels), ...
        "unit", unit);
end

function channels = emptyChannelStruct()
    channels = struct( ...
        "nativeName", {}, ...
        "customName", {}, ...
        "nativeOrder", {}, ...
        "customOrder", {}, ...
        "boardStream", {}, ...
        "chipChannel", {}, ...
        "portName", {}, ...
        "portPrefix", {}, ...
        "portNumber", {}, ...
        "electrodeImpedanceMagnitude", {}, ...
        "electrodeImpedancePhase", {});
end

function [idx, names] = resolveChannels(selection, channels)
    namesAll = string({channels.nativeName});
    if isempty(selection)
        idx = 1:numel(channels);
        names = namesAll;
        return;
    end

    if isnumeric(selection)
        idx = double(selection(:)).';
        if any(idx < 1) || any(idx > numel(channels)) || any(mod(idx, 1) ~= 0)
            error("labkit:rhs:InvalidChannel", ...
                "Numeric channel selection is outside the selected family.");
        end
        names = namesAll(idx);
        return;
    end

    requested = string(selection);
    requested = requested(:).';
    idx = zeros(1, numel(requested));
    normalizedNative = normalizeName(namesAll);
    normalizedCustom = normalizeName(string({channels.customName}));
    for k = 1:numel(requested)
        exact = find(namesAll == requested(k) | string({channels.customName}) == requested(k), 1);
        if isempty(exact)
            key = normalizeName(requested(k));
            exact = find(normalizedNative == key | normalizedCustom == key, 1);
        end
        if isempty(exact)
            error("labkit:rhs:InvalidChannel", ...
                "RHS channel not found in selected family: %s.", requested(k));
        end
        idx(k) = exact;
    end
    names = namesAll(idx);
end

function out = normalizeName(value)
    out = lower(regexprep(string(value), "[^A-Za-z0-9]", ""));
end

function [timeSec, values] = readSamples(filepath, index, spec, channelIdx, ...
        startSample, endSample)
    spb = index.samplesPerBlock;
    nSamples = endSample - startSample + 1;
    timeSec = zeros(nSamples, 1);
    values = zeros(nSamples, numel(channelIdx));

    firstBlock = floor((startSample - 1) / spb) + 1;
    lastBlock = floor((endSample - 1) / spb) + 1;
    outPos = 1;

    fid = fopen(filepath, "r", "ieee-le");
    if fid < 0
        error("labkit:rhs:OpenFailed", "Could not open RHS file.");
    end
    cleaner = onCleanup(@() fclose(fid));

    for block = firstBlock:lastBlock
        blockStart = (block - 1) * spb + 1;
        blockEnd = blockStart + spb - 1;
        localStart = max(1, startSample - blockStart + 1);
        localEnd = min(spb, endSample - blockStart + 1);
        takeCount = localEnd - localStart + 1;

        blockOffset = index.dataOffsetBytes + (block - 1) * index.bytesPerBlock;
        fseek(fid, blockOffset, "bof");
        timestamps = fread(fid, [1 spb], "int32=>double");
        blockValues = readBlockFamily(fid, index.info, spec, channelIdx);

        outRange = outPos:(outPos + takeCount - 1);
        timeSec(outRange) = timestamps(localStart:localEnd).' ./ index.sampleRateHz;
        values(outRange, :) = blockValues(:, localStart:localEnd).';
        outPos = outPos + takeCount;

        if blockEnd >= endSample
            break;
        end
    end
end

function values = readBlockFamily(fid, info, spec, channelIdx)
    % Constant: Intan RHS data-file conversion gains and unsigned offsets
    % convert stored ADC codes to the physical units documented by the format.
    amplifierMicrovoltsPerBit = 0.195;
    amplifierCodeOffset = 32768;
    dcMillivoltsPerBit = -0.01923;
    dcCodeOffset = 512;
    boardVoltsPerBit = 312.5e-6;
    boardCodeOffset = 32768;
    nAmp = numel(info.channelFamilies.amplifier);
    nAdc = numel(info.channelFamilies.boardAdc);
    nDac = numel(info.channelFamilies.boardDac);
    nDigIn = numel(info.channelFamilies.boardDigIn);
    nDigOut = numel(info.channelFamilies.boardDigOut);
    spb = info.samplesPerBlock;
    values = zeros(numel(channelIdx), spb);

    if nAmp > 0
        ampRaw = readUint16Matrix(fid, nAmp, spb);
        if spec.family == "amplifier"
            values = amplifierMicrovoltsPerBit .* ...
                (ampRaw(channelIdx, :) - amplifierCodeOffset);
        end
        if info.dcAmplifierSaved
            dcRaw = readUint16Matrix(fid, nAmp, spb);
            if spec.family == "dcAmplifier"
                values = dcMillivoltsPerBit .* ...
                    (dcRaw(channelIdx, :) - dcCodeOffset);
            end
        end
        stimRaw = readUint16Matrix(fid, nAmp, spb);
        if spec.family == "stim"
            values = scaleStim(stimRaw(channelIdx, :), info.stimParameters.stimStepSize);
        end
    end

    if nAdc > 0
        adcRaw = readUint16Matrix(fid, nAdc, spb);
        if spec.family == "boardAdc"
            values = boardVoltsPerBit .* ...
                (adcRaw(channelIdx, :) - boardCodeOffset);
        end
    end
    if nDac > 0
        dacRaw = readUint16Matrix(fid, nDac, spb);
        if spec.family == "boardDac"
            values = boardVoltsPerBit .* ...
                (dacRaw(channelIdx, :) - boardCodeOffset);
        end
    end
    if nDigIn > 0
        raw = fread(fid, [1 spb], "uint16=>double");
        if spec.family == "boardDigIn"
            values = decodeDigital(raw, info.channelFamilies.boardDigIn, channelIdx);
        end
    end
    if nDigOut > 0
        raw = fread(fid, [1 spb], "uint16=>double");
        if spec.family == "boardDigOut"
            values = decodeDigital(raw, info.channelFamilies.boardDigOut, channelIdx);
        end
    end
end

function raw = readUint16Matrix(fid, nChannels, nSamples)
    raw = fread(fid, [nSamples nChannels], "uint16=>double").';
    if ~isequal(size(raw), [nChannels nSamples])
        error("labkit:rhs:ShortRead", "Unexpected end of RHS data block.");
    end
end

function values = scaleStim(raw, stepSize)
    compliance = raw >= 2^15;
    raw = raw - compliance .* 2^15;
    chargeRecovery = raw >= 2^14;
    raw = raw - chargeRecovery .* 2^14;
    ampSettle = raw >= 2^13;
    raw = raw - ampSettle .* 2^13;
    polarity = raw >= 2^8;
    raw = raw - polarity .* 2^8;
    polarity = 1 - 2 .* polarity;
    % Constant: one microampere converts stimulation amplitude from amperes
    % to the RHS facade's documented microampere output unit.
    amperesPerMicroampere = 1.0e-6;
    values = stepSize .* raw .* polarity ./ amperesPerMicroampere;
end

function values = decodeDigital(raw, channels, channelIdx)
    values = zeros(numel(channelIdx), numel(raw));
    for k = 1:numel(channelIdx)
        bitIndex = channels(channelIdx(k)).nativeOrder + 1;
        values(k, :) = bitget(uint16(raw), bitIndex);
    end
end

function window = makeWindow(filepath, index, spec, channelNames, timeSec, values, ...
        sampleRange)
    [~, name, ext] = fileparts(filepath);
    window = struct( ...
        "type", "rhsWindow", ...
        "version", 1, ...
        "sourcePath", filepath, ...
        "name", string([name ext]), ...
        "family", spec.family, ...
        "unit", spec.unit, ...
        "sampleRateHz", index.sampleRateHz, ...
        "sampleRange", double(sampleRange), ...
        "channels", channelNames(:).', ...
        "timeSec", timeSec(:), ...
        "values", values);
end

function window = emptyWindow(filepath)
    [~, name, ext] = fileparts(filepath);
    window = struct( ...
        "type", "rhsWindow", ...
        "version", 1, ...
        "sourcePath", filepath, ...
        "name", string([name ext]), ...
        "family", "", ...
        "unit", "", ...
        "sampleRateHz", NaN, ...
        "sampleRange", [NaN NaN], ...
        "channels", strings(1, 0), ...
        "timeSec", zeros(0, 1), ...
        "values", zeros(0, 0));
end
