% Expected caller: nerve_response_analysis.actions.table startup action and unit
% tests. Input is a LabKit debug context. Output is a deterministic synthetic
% filter-record/protocol/RHS sample pack. Side effects: writes anonymous debug
% files and records a session manifest when available.
function pack = writeSamplePack(debugLog)
%WRITESAMPLEPACK Write Nerve Response Analysis debug files.

    folders = debugFolders(debugLog, "nerve_response_analysis");
    sampleFolder = fullfile(char(folders.sampleFolder), "nerve_response_analysis");
    rhsFolder = fullfile(sampleFolder, "rhs");
    ensureFolder(rhsFolder);

    rhsA = string(fullfile(rhsFolder, "nerve_response_recording_001_debug.rhs"));
    rhsB = string(fullfile(rhsFolder, "nerve_response_recording_002_debug.rhs"));
    malformedRhs = string(fullfile(rhsFolder, "nerve_response_malformed_debug.rhs"));
    filterRecordPath = string(fullfile(sampleFolder, "nerve_response_filter_record_debug.json"));
    protocolPath = string(fullfile(sampleFolder, "nerve_response_protocol_debug.json"));
    malformedFilterPath = string(fullfile(sampleFolder, "nerve_response_malformed_filter_record_debug.json"));

    channels = ["PrimaryChannel", "ReferenceChannel", "ReturnChannel", "AuxChannel"];
    writeSyntheticRhs(rhsA, channels, [210 980 1710], 18);
    writeSyntheticRhs(rhsB, channels, [300 1280], 16);
    writeTextFile(malformedRhs, ["not an rhs binary"; "boundary=malformed rhs"]);
    writeProtocol(protocolPath);
    writeFilterRecord(filterRecordPath, [rhsA; rhsB], string(rhsFolder));
    writeTextFile(malformedFilterPath, ["{""recordings"": "; "  ""not complete"""]);

    manifest = struct( ...
        "type", "labkit.debug.samplePack.v1", ...
        "app", "labkit_NerveResponseAnalysis_app", ...
        "description", "Anonymous nerve-response RHS/filter-record boundary pack for debug launch.", ...
        "sampleFolder", string(sampleFolder), ...
        "outputFolder", folders.outputFolder, ...
        "representativeFiles", struct( ...
            "filterRecordJson", filterRecordPath, ...
            "protocolJson", protocolPath, ...
            "rhsFiles", [rhsA; rhsB]), ...
        "boundaryFiles", struct( ...
            "malformedFilterRecordJson", malformedFilterPath, ...
            "malformedRhs", malformedRhs));
    recordManifest(debugLog, manifest);
    pack = manifest;
end

function writeFilterRecord(filepath, rhsFiles, rootFolder)
    recordings = repmat(struct("recordingId", "", "filePath", "", ...
        "label", "", "comment", "", "qcFlag", "", "keep", true), numel(rhsFiles), 1);
    for k = 1:numel(rhsFiles)
        recordings(k).recordingId = sprintf("R%03d", k);
        recordings(k).filePath = char(rhsFiles(k));
        recordings(k).label = "good";
        recordings(k).comment = "debug recording";
        recordings(k).qcFlag = "accepted";
        recordings(k).keep = true;
    end
    payload = struct( ...
        "type", "rhsFilterRecord", ...
        "version", 1, ...
        "exportedBy", "labkit_RHSPreview_app", ...
        "rootFolder", char(rootFolder), ...
        "recordings", recordings);
    writeJson(filepath, payload);
end

function writeProtocol(filepath)
    roles = [ ...
        struct("id", "reference", "label", "Reference", "nativeName", "ReferenceChannel"), ...
        struct("id", "cp_positive", "label", "CP+", "nativeName", "PrimaryChannel"), ...
        struct("id", "cp_negative", "label", "CP-", "nativeName", "ReturnChannel")];
    pairs = struct("id", "cp_diff", "label", "CP", ...
        "positive", "cp_positive", "negative", "cp_negative", ...
        "mode", "positive-minus-negative");
    payload = struct( ...
        "schemaVersion", "labkit.rhs.protocol.v1", ...
        "protocolId", "debug_nerve_response_protocol", ...
        "label", "Debug Nerve Response Protocol", ...
        "channels", struct("roles", roles, "pairs", pairs));
    writeJson(filepath, payload);
end

function writeSyntheticRhs(filepath, amplifierNames, stimPulseSamples, nBlocks)
    fid = fopen(char(filepath), "w", "ieee-le");
    if fid < 0
        error("nerve_response_analysis:debug:SampleWriteFailed", ...
            "Could not write debug sample file: %s.", filepath);
    end
    cleaner = onCleanup(@() fclose(fid));

    samplesPerBlock = 128;
    sampleRate = 30000;
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
            signal = 32768 + 45 .* sin(2 .* pi .* sampleIdx ./ (40 + ch .* 7));
            if ch == 1
                signal = signal + pulseResponse(absoluteIdx, stimPulseSamples, 320, 20);
            elseif ch == 2
                signal = signal + pulseResponse(absoluteIdx, stimPulseSamples, 90, 28);
            elseif ch == 3
                signal = signal - pulseResponse(absoluteIdx, stimPulseSamples + 4, 220, 24);
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

function response = pulseResponse(sampleIdx, pulses, amplitude, width)
    response = zeros(size(sampleIdx));
    for pulse = pulses(:).'
        response = response + amplitude .* exp(-((sampleIdx - pulse) ./ width).^2);
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
        error("nerve_response_analysis:debug:SampleWriteFailed", ...
            "Could not write debug sample file: %s.", filepath);
    end
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", jsonencode(payload));
end

function writeTextFile(filepath, lines)
    fid = fopen(char(filepath), "w");
    if fid < 0
        error("nerve_response_analysis:debug:SampleWriteFailed", ...
            "Could not write debug sample file: %s.", filepath);
    end
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, "%s\n", lines);
end

function ensureFolder(folder)
    if exist(char(folder), "dir") ~= 7
        mkdir(char(folder));
    end
end
