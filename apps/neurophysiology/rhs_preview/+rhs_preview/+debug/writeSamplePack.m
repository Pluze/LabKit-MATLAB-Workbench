% Expected caller: rhs_preview.definitionActions during debug launch and unit tests. Input
% is a LabKit debug context. Output is a deterministic synthetic RHS sample
% pack. Side effects: writes anonymous debug RHS/protocol files and records a
% session manifest when available.
function pack = writeSamplePack(debugLog)
%WRITESAMPLEPACK Write RHS Preview debug acquisition files.

    folders = debugFolders(debugLog, "rhs_preview");
    sampleFolder = fullfile(char(folders.sampleFolder), "rhs_preview");
    rhsFolder = fullfile(sampleFolder, "acquisition");
    ensureFolder(rhsFolder);

    primaryPath = string(fullfile(rhsFolder, "rhs_representative_primary_debug.rhs"));
    repeatPath = string(fullfile(rhsFolder, "rhs_representative_repeat_debug.rhs"));
    edgePath = string(fullfile(rhsFolder, "rhs_valid_short_debug.rhs"));
    malformedPath = string(fullfile(rhsFolder, "rhs_malformed_header_debug.rhs"));
    protocolPath = string(fullfile(sampleFolder, "rhs_protocol_debug.json"));

    channels = ["PrimaryChannel", "ReferenceChannel", "ReturnChannel", "AuxChannel"];
    writeSyntheticRhs(primaryPath, struct("nBlocks", 18, "amplifierNames", channels, ...
        "sampleRateHz", 30000, "stimPulseSamples", [180 900 1660]));
    writeSyntheticRhs(repeatPath, struct("nBlocks", 14, "amplifierNames", channels, ...
        "sampleRateHz", 30000, "stimPulseSamples", [220 980]));
    writeSyntheticRhs(edgePath, struct("nBlocks", 1, "amplifierNames", channels(1:2), ...
        "sampleRateHz", 30000, "stimPulseSamples", 80));
    writeTextFile(malformedPath, ["not an rhs binary"; "boundary=malformed header"]);
    writeProtocol(protocolPath);

    representative = [primaryPath; repeatPath];
    manifest = struct( ...
        "type", "labkit.debug.samplePack.v1", ...
        "app", "labkit_RHSPreview_app", ...
        "description", "Anonymous RHS acquisition boundary pack for debug launch.", ...
        "sampleFolder", string(sampleFolder), ...
        "outputFolder", folders.outputFolder, ...
        "representativeFiles", struct( ...
            "primaryRhs", primaryPath, ...
            "rhsFiles", representative, ...
            "rhsFolder", string(rhsFolder), ...
            "protocolJson", protocolPath), ...
        "boundaryFiles", struct("validShortRhs", edgePath, "malformedRhs", malformedPath));
    recordManifest(debugLog, manifest);
    pack = manifest;
end

function writeProtocol(filepath)
    roles = [ ...
        struct("id", "reference", "label", "Reference", "nativeName", "ReferenceChannel"), ...
        struct("id", "cp_positive", "label", "CP+", "nativeName", "PrimaryChannel"), ...
        struct("id", "cp_negative", "label", "CP-", "nativeName", "ReturnChannel")];
    payload = struct( ...
        "schemaVersion", "labkit.rhs.protocol.v1", ...
        "protocolId", "debug_rhs_protocol", ...
        "label", "Debug RHS Protocol", ...
        "channels", struct("roles", roles));
    writeJson(filepath, payload);
end

function writeSyntheticRhs(filepath, opts)
    nBlocks = optionValue(opts, "nBlocks", 2);
    amplifierNames = string(optionValue(opts, "amplifierNames", ["PrimaryChannel", "ReferenceChannel"]));
    sampleRate = double(optionValue(opts, "sampleRateHz", 30000));
    stimPulseSamples = double(optionValue(opts, "stimPulseSamples", []));

    fid = fopen(char(filepath), "w", "ieee-le");
    if fid < 0
        error("rhs_preview:debug:SampleWriteFailed", ...
            "Could not write debug sample file: %s.", filepath);
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
    writeQString(fid, "debug");

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
            signal = 32768 + ch .* 80 + 35 .* sin(2 .* pi .* (sampleIdx ./ samplesPerBlock) .* (ch + 1));
            if ch == 1
                for pulse = stimPulseSamples(:).'
                    signal = signal + 260 .* exp(-((absoluteIdx - pulse) ./ 18).^2);
                end
            elseif ch == 3
                for pulse = stimPulseSamples(:).'
                    signal = signal - 180 .* exp(-((absoluteIdx - pulse - 5) ./ 24).^2);
                end
            end
            ampRaw(ch, :) = uint16(round(signal));
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

function folders = debugFolders(debugLog, appToken)
    sampleFolder = "";
    outputFolder = "";
    if isstruct(debugLog)
        if isfield(debugLog, "sampleFolder"), sampleFolder = string(debugLog.sampleFolder); end
        if isfield(debugLog, "outputFolder"), outputFolder = string(debugLog.outputFolder); end
    end
    if strlength(sampleFolder) == 0
        sampleFolder = string(fullfile(tempdir, "LabKit-MATLAB-Workbench", "debug", appToken, "samples"));
    end
    if strlength(outputFolder) == 0
        outputFolder = string(fullfile(tempdir, "LabKit-MATLAB-Workbench", "debug", appToken, "outputs"));
    end
    ensureFolder(sampleFolder);
    ensureFolder(outputFolder);
    folders = struct("sampleFolder", sampleFolder, "outputFolder", outputFolder);
end

function recordManifest(debugLog, manifest)
    if isstruct(debugLog) && isfield(debugLog, "recordArtifacts") && isa(debugLog.recordArtifacts, "function_handle")
        debugLog.recordArtifacts(manifest);
    end
end

function writeJson(filepath, payload)
    fid = fopen(char(filepath), "w");
    if fid < 0
        error("rhs_preview:debug:SampleWriteFailed", ...
            "Could not write debug sample file: %s.", filepath);
    end
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", jsonencode(payload));
end

function writeTextFile(filepath, lines)
    fid = fopen(char(filepath), "w");
    if fid < 0
        error("rhs_preview:debug:SampleWriteFailed", ...
            "Could not write debug sample file: %s.", filepath);
    end
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, "%s\n", lines);
end

function value = optionValue(opts, fieldName, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, fieldName)
        value = opts.(fieldName);
    end
end

function ensureFolder(folder)
    if exist(char(folder), "dir") ~= 7
        mkdir(char(folder));
    end
end
