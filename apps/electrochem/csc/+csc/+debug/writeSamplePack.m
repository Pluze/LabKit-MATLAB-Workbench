% Expected caller: CSC debug launch and unit tests. Input is a
% LabKit debug context. Output is a deterministic synthetic CV/CT DTA sample
% pack. Side effects: writes anonymous debug input files and records a session
% manifest when available.
function pack = writeSamplePack(debugLog)
%WRITESAMPLEPACK Write CSC debug CV/CT DTA files.

    folders = debugFolders(debugLog, "csc");
    dtaFolder = fullfile(char(folders.sampleFolder), "dta");
    ensureFolder(dtaFolder);

    cvPath = string(fullfile(dtaFolder, "cvct_csc_debug.DTA"));
    zeroScanPath = string(fullfile(dtaFolder, "cvct_csc_valid_zero_scanrate_debug.DTA"));
    malformedPath = string(fullfile(dtaFolder, "cvct_csc_malformed_no_curve_debug.DTA"));
    writeTextFile(cvPath, cvctText());
    writeTextFile(zeroScanPath, cvctText(struct("ScanRateMv", 0)));
    writeTextFile(malformedPath, malformedCvctText());

    pack = struct( ...
        "sampleFolder", folders.sampleFolder, ...
        "outputFolder", folders.outputFolder, ...
        "representativeFiles", cvPath, ...
        "boundaryFiles", struct( ...
            "validEdge", zeroScanPath, ...
            "malformed", malformedPath));
    manifest = struct( ...
        "type", "labkit.debug.samplePack.v1", ...
        "app", "labkit_CSC_app", ...
        "description", "Anonymous CV/CT DTA boundary pack for CSC debug launch.", ...
        "inputs", struct( ...
            "representativeCvctDta", cvPath, ...
            "validEdgeCvctDta", zeroScanPath, ...
            "malformedCvctDta", malformedPath), ...
        "outputFolder", folders.outputFolder);
    pack.manifest = manifest;
    recordManifest(debugLog, manifest);
end

function text = cvctText(opts)
    if nargin < 1
        opts = struct();
    end
    scanRateMv = 200;
    if isfield(opts, 'ScanRateMv')
        scanRateMv = opts.ScanRateMv;
    end
    t = linspace(0, 8, 401).';
    vf = -0.8 + 1.6 .* abs(mod(t ./ 4, 2) - 1);
    im = 0.00035 .* vf + 0.00018 .* sin(2 .* pi .* t ./ 4);
    rowsA = curveRows(t, vf, im);
    rowsB = curveRows(t, vf, 0.00032 .* vf + 0.00015 .* cos(2 .* pi .* t ./ 4));
    scanRateLine = "SCANRATE" + tab() + "QUANT" + tab() + sprintf("%.6E", scanRateMv) + tab() + "Scan Rate (mV/s)";
    lines = [
        "EXPLAIN"
        "TAG" + tab() + "TEXT" + tab() + "DEVICE"
        scanRateLine
        "CURVE1" + tab() + "TABLE"
        "Pt" + tab() + "T" + tab() + "Vf" + tab() + "Im" + tab() + "Vu" + tab() + "Sig" + tab() + "Ach" + tab() + "Temp"
        "#" + tab() + "s" + tab() + "V vs. Ref." + tab() + "A" + tab() + "V" + tab() + "V" + tab() + "#" + tab() + "deg C"
        rowsA
        "CURVE2" + tab() + "TABLE"
        "Pt" + tab() + "T" + tab() + "Vf" + tab() + "Im" + tab() + "Vu" + tab() + "Sig" + tab() + "Ach" + tab() + "Temp"
        "#" + tab() + "s" + tab() + "V vs. Ref." + tab() + "A" + tab() + "V" + tab() + "V" + tab() + "#" + tab() + "deg C"
        rowsB
        ];
    text = join(lines, newline) + newline;
end

function text = malformedCvctText()
    lines = [
        "EXPLAIN"
        "TAG" + tab() + "TEXT" + tab() + "DEVICE"
        "SCANRATE" + tab() + "QUANT" + tab() + "2.000000E+002" + tab() + "Scan Rate (mV/s)"
        "This file intentionally omits CURVE TABLE sections."
        ];
    text = join(lines, newline) + newline;
end

function rows = curveRows(t, vf, im)
    rows = strings(numel(t), 1);
    for k = 1:numel(t)
        vu = vf(k) + 0.003 .* sin(2 .* pi .* 0.25 .* t(k));
        sig = 0.00005 .* sin(2 .* pi .* 2 .* t(k));
        temp = 25.0 + 0.02 .* t(k);
        rows(k) = sprintf("%d\t%.6E\t%.6E\t%.6E\t%.6E\t%.6E\t%d\t%.6E", ...
            k - 1, t(k), vf(k), im(k), vu, sig, 0, temp);
    end
end

function folders = debugFolders(debugLog, appToken)
    sampleFolder = ""; outputFolder = "";
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
    ensureFolder(sampleFolder); ensureFolder(outputFolder);
    folders = struct("sampleFolder", sampleFolder, "outputFolder", outputFolder);
end

function recordManifest(debugLog, manifest)
    if isstruct(debugLog) && isfield(debugLog, "recordArtifacts") && isa(debugLog.recordArtifacts, "function_handle")
        debugLog.recordArtifacts(manifest);
    end
end

function writeTextFile(filepath, text)
    fid = fopen(char(filepath), "w", "n", "UTF-8");
    if fid < 0
        error("csc:debug:SampleWriteFailed", "Could not write debug sample file: %s.", filepath);
    end
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", char(text));
end

function ensureFolder(folder)
    if exist(char(folder), "dir") ~= 7
        mkdir(char(folder));
    end
end

function value = tab()
    value = char(9);
end
