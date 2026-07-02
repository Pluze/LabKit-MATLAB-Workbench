% Expected caller: response_review_stats.run during debug launch and unit
% tests. Input is a LabKit debug context. Output is a deterministic segment
% and analysis-metrics sample pack. Side effects: writes anonymous debug files
% and records a session manifest when available.
function pack = writeSamplePack(debugLog)
%WRITESAMPLEPACK Write Response Review Stats debug files.

    folders = debugFolders(debugLog, "response_review_stats");
    sampleFolder = fullfile(char(folders.sampleFolder), "response_review_stats");
    ensureFolder(sampleFolder);

    segmentPath = string(fullfile(sampleFolder, "response_segments_representative_debug.csv"));
    analysisPath = string(fullfile(sampleFolder, "response_analysis_metrics_debug.json"));
    sparsePath = string(fullfile(sampleFolder, "response_segments_valid_sparse_debug.csv"));
    malformedPath = string(fullfile(sampleFolder, "response_segments_malformed_debug.csv"));

    T = segmentTable(9, 0.0002, 0.030);
    writetable(T, char(segmentPath));
    writeAnalysisJson(analysisPath);

    sparse = segmentTable(2, 0.0008, 0.020);
    writetable(sparse, char(sparsePath));
    writeTextFile(malformedPath, ["Time_s,Segment_A"; "0,1"; "bad,2"]);

    manifest = struct( ...
        "type", "labkit.debug.samplePack.v1", ...
        "app", "labkit_ResponseReviewStats_app", ...
        "description", "Anonymous response segment and metrics boundary pack for debug launch.", ...
        "sampleFolder", string(sampleFolder), ...
        "outputFolder", folders.outputFolder, ...
        "representativeFiles", struct("segmentCsv", segmentPath, "analysisJson", analysisPath), ...
        "boundaryFiles", struct("validSparseSegmentCsv", sparsePath, "malformedCsv", malformedPath));
    recordManifest(debugLog, manifest);
    pack = manifest;
end

function T = segmentTable(count, dt, spanSec)
    time = (-0.010:dt:spanSec).';
    data = table(time, 'VariableNames', {'Time_s'});
    for k = 1:count
        latency = 0.0035 + 0.00035 .* k;
        amp = 0.18 + 0.014 .* k;
        waveform = amp .* exp(-((time - latency) ./ 0.0018).^2) ...
            -0.07 .* exp(-((time - latency - 0.0032) ./ 0.0035).^2) ...
            +0.006 .* sin(2 .* pi .* (190 + 8 .* k) .* time);
        data.(sprintf("Segment_%02d", k)) = waveform;
    end
    T = data;
end

function writeAnalysisJson(filepath)
    metrics = struct( ...
        "recordingId", ["R001"; "R001"; "R002"], ...
        "pairId", ["cp_diff"; "ta_diff"; "cp_diff"], ...
        "pairLabel", ["CP"; "TA"; "CP"], ...
        "eventIndex", [1; 1; 2], ...
        "stimTimeSec", [0.100; 0.100; 0.920], ...
        "baselineMean", [0.001; -0.001; 0.0004], ...
        "noiseRms", [0.004; 0.006; 0.005], ...
        "peakPositive", [0.24; 0.16; 0.22], ...
        "peakNegative", [-0.06; -0.04; -0.05], ...
        "peakToPeak", [0.30; 0.20; 0.27], ...
        "peakTimeSec", [0.104; 0.106; 0.925], ...
        "latencySec", [0.004; 0.006; 0.005], ...
        "snrDb", [28.2; 22.4; 25.9], ...
        "status", ["ok"; "ok"; "ok"]);
    payload = struct("type", "nerveResponseSessionAnalysis", ...
        "version", 1, "metrics", metrics);
    fid = fopen(char(filepath), "w");
    if fid < 0
        error("response_review_stats:debug:SampleWriteFailed", ...
            "Could not write debug sample file: %s.", filepath);
    end
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", jsonencode(payload));
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
        error("response_review_stats:debug:SampleWriteFailed", ...
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
