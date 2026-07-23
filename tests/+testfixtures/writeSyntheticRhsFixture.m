function writeSyntheticRhsFixture(filepath, opts)
%WRITESYNTHETICRHSFIXTURE Write a cross-owner synthetic RHS fixture.
%
% Expected caller: unit tests. Inputs are a destination path and optional
% struct fields nBlocks, amplifierNames, sampleRateHz, and stimPulseSamples.
% Side effect is one synthetic Intan RHS-like binary file with no real data.

    if nargin < 2 || isempty(opts)
        opts = struct();
    end
    nBlocks = optionValue(opts, "nBlocks", 2);
    amplifierNames = string(optionValue(opts, "amplifierNames", ...
        ["C-001", "C-002"]));
    sampleRate = double(optionValue(opts, "sampleRateHz", 30000));
    stimPulseSamples = double(optionValue(opts, "stimPulseSamples", []));

    fid = fopen(filepath, "w", "ieee-le");
    if fid < 0
        error("tests:rhs:FixtureWriteFailed", ...
            "Could not create synthetic RHS fixture.");
    end
    cleaner = onCleanup(@() fclose(fid));

    samplesPerBlock = 128;
    stimStepSize = 1e-6;
    nAmp = numel(amplifierNames);

    fwrite(fid, uint32(hex2dec("d69127ac")), "uint32");
    fwrite(fid, int16([3 4]), "int16");
    fwrite(fid, single(sampleRate), "single");
    fwrite(fid, int16(0), "int16");
    fwrite(fid, single([0 1 1 7500 0 1 1 7500]), "single");
    fwrite(fid, int16(0), "int16");
    fwrite(fid, single([1000 1000]), "single");
    fwrite(fid, int16([0 0]), "int16");
    fwrite(fid, single([stimStepSize 0 0]), "single");
    writeQString(fid, "");
    writeQString(fid, "");
    writeQString(fid, "");
    fwrite(fid, int16(0), "int16");
    fwrite(fid, int16(0), "int16");
    writeQString(fid, "n/a");

    fwrite(fid, int16(1), "int16");
    writeQString(fid, "Port A");
    writeQString(fid, "A");
    fwrite(fid, int16([1 nAmp nAmp]), "int16");
    for k = 1:nAmp
        writeChannel(fid, amplifierNames(k), amplifierNames(k), k - 1, k - 1);
    end

    for block = 1:nBlocks
        base = (block - 1) * samplesPerBlock;
        sampleIdx = 0:(samplesPerBlock - 1);
        absoluteIdx = base + sampleIdx + 1;
        fwrite(fid, int32(base + sampleIdx), "int32");

        ampRaw = zeros(nAmp, samplesPerBlock, "uint16");
        for ch = 1:nAmp
            ampRaw(ch, :) = uint16(32768 + ch * 100 + sampleIdx);
        end
        fwrite(fid, ampRaw.', "uint16");

        stimRaw = zeros(nAmp, samplesPerBlock, "uint16");
        pulseMask = ismember(absoluteIdx, stimPulseSamples);
        if any(pulseMask)
            stimRaw(1, pulseMask) = uint16(1);
        end
        fwrite(fid, stimRaw.', "uint16");
    end
end

function value = optionValue(opts, fieldName, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, fieldName)
        value = opts.(fieldName);
    end
end

function writeChannel(fid, nativeName, customName, nativeOrder, chipChannel)
    writeQString(fid, nativeName);
    writeQString(fid, customName);
    fwrite(fid, int16(nativeOrder), "int16");
    fwrite(fid, int16(nativeOrder), "int16");
    fwrite(fid, int16(0), "int16");
    fwrite(fid, int16(1), "int16");
    fwrite(fid, int16(chipChannel), "int16");
    fwrite(fid, int16(0), "int16");
    fwrite(fid, int16(0), "int16");
    fwrite(fid, int16([0 0 0 0]), "int16");
    fwrite(fid, single([0 0]), "single");
end

function writeQString(fid, value)
    value = char(string(value));
    fwrite(fid, uint32(numel(value) * 2), "uint32");
    fwrite(fid, uint16(value), "uint16");
end
