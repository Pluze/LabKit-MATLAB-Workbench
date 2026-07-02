% Expected caller: ecg_print.run during debug launch and unit tests. Input is
% a LabKit debug context. Output is a deterministic synthetic ECG recording
% sample pack. Side effects: writes anonymous debug files and records a
% session manifest when available.
function pack = writeSamplePack(debugLog)
%WRITESAMPLEPACK Write ECG Print debug recording files.

    folders = debugFolders(debugLog, "ecg_print");
    sampleFolder = fullfile(char(folders.sampleFolder), "ecg_print");
    ensureFolder(sampleFolder);

    csvPath = string(fullfile(sampleFolder, "ecg_representative_debug.csv"));
    headerlessPath = string(fullfile(sampleFolder, "ecg_valid_headerless_debug.txt"));
    malformedPath = string(fullfile(sampleFolder, "ecg_malformed_text_debug.csv"));

    fs = 500;
    durationSec = 18;
    time = (0:(1 / fs):durationSec).';
    ecg = syntheticEcg(time, 1.15);
    motion = 0.10 .* sin(2 .* pi .* 0.7 .* time) + 0.035 .* sin(2 .* pi .* 3.3 .* time);
    contact = 1.0 + 0.06 .* sin(2 .* pi .* 0.05 .* time) + 0.02 .* syntheticNoise(time, 0.37);
    T = table(time, ecg, motion, contact, ...
        'VariableNames', {'time_s', 'ECG', 'Motion', 'ContactQuality'});
    writetable(T, char(csvPath));

    headerless = [time, syntheticEcg(time, 0.72), motion];
    writematrix(headerless, char(headerlessPath), "Delimiter", "\t");
    writeTextFile(malformedPath, ["time_s,ECG"; "0,ok"; "1,not_numeric"]);

    manifest = struct( ...
        "type", "labkit.debug.samplePack.v1", ...
        "app", "labkit_ECGPrint_app", ...
        "description", "Anonymous ECG CSV boundary pack for debug launch.", ...
        "sampleFolder", string(sampleFolder), ...
        "outputFolder", folders.outputFolder, ...
        "representativeFiles", csvPath, ...
        "boundaryFiles", struct( ...
            "validHeaderlessText", headerlessPath, ...
            "malformedCsv", malformedPath));
    recordManifest(debugLog, manifest);
    pack = manifest;
end

function y = syntheticEcg(time, gain)
    beatTimes = 0.62:0.82:max(time);
    y = 0.03 .* sin(2 .* pi .* 0.24 .* time) + 0.012 .* syntheticNoise(time, 0.19);
    for k = 1:numel(beatTimes)
        t0 = beatTimes(k) + 0.018 .* sin(k .* 0.7);
        y = y + gain .* ( ...
            0.075 .* exp(-((time - (t0 - 0.16)) ./ 0.030).^2) ...
            -0.11 .* exp(-((time - (t0 - 0.026)) ./ 0.010).^2) ...
            +0.95 .* exp(-((time - t0) ./ 0.012).^2) ...
            -0.22 .* exp(-((time - (t0 + 0.030)) ./ 0.014).^2) ...
            +0.20 .* exp(-((time - (t0 + 0.25)) ./ 0.070).^2));
    end
end

function noise = syntheticNoise(time, phase)
    noise = sin(2 .* pi .* 17.3 .* time + phase) + ...
        0.5 .* sin(2 .* pi .* 41.7 .* time + 2 .* phase);
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

function writeTextFile(filepath, lines)
    fid = fopen(char(filepath), "w");
    if fid < 0
        error("ecg_print:debug:SampleWriteFailed", "Could not write debug sample file: %s.", filepath);
    end
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, "%s\n", lines);
end

function ensureFolder(folder)
    if exist(char(folder), "dir") ~= 7
        mkdir(char(folder));
    end
end
